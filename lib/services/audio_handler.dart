import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

import 'package:yuugao/models/song.dart';
import 'package:yuugao/services/audio_service.dart' as asvc;

/// 自定义 [BaseAudioHandler]，将系统媒体命令（通知栏按钮、耳机线控、蓝牙等）
/// 转发给内部 [asvc.AudioService]，并将播放状态同步到 Android MediaSession。
///
/// 直接使用 [audio_service] 替代 just_audio_background beta 桥接层：
/// - 音频焦点由 audio_service 原生管理，不再依赖 just_audio_background 转接
/// - 通知栏由 audio_service 通过 MediaSession 原生更新
/// - 消除 beta 桥接层带来的后台暂停问题
///
/// 通知栏按钮（从左到右）：
/// - ⏮ 上一首 | ▶/⏸ 播放/暂停 | ⏭ 下一首 | ♥ 喜欢 | ✕ 停止
class YuugaoAudioHandler extends BaseAudioHandler with QueueHandler {
  final asvc.AudioService _audio;

  /// 存储所有流订阅以便在 dispose 时统一取消。
  final List<StreamSubscription> _subscriptions = [];

  YuugaoAudioHandler(this._audio) {
    // 推送初始空闲状态，预建通知渠道，避免 Android 因未在 5 秒内
    // 调用 startForeground() 而杀死服务。
    playbackState.add(PlaybackState(
      controls: [],
      processingState: AudioProcessingState.idle,
      playing: false,
    ));

    _subscriptions.addAll([
      _audio.player.playerStateStream.listen(_onStateChanged),
      _audio.player.currentIndexStream.listen(_onIndexChanged),
      _audio.queueStream.listen(_onQueueChanged),
      _audio.player.positionStream.listen(_onPositionChangedThrottled),
      _audio.player.durationStream.listen(_onDurationChanged),
    ]);
  }

  /// 取消所有流订阅（在 AudioService 关闭时由外部显式调用）。
  void cancelSubscriptions() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
  }

  // ── 位置流节流 ──
  // just_audio 的 positionStream 每秒触发约 5 次，每次触发向 MediaSession
  // 推送 updatePosition 会产生大量平台通道调用。节流到约 1 Hz，减少 CPU 唤醒。

  DateTime _lastPositionPush = DateTime(2000); // 初始化为过去，首次立即推送

  void _onPositionChangedThrottled(Duration pos) {
    final now = DateTime.now();
    if (now.difference(_lastPositionPush).inMilliseconds < 900) return;
    _lastPositionPush = now;
    playbackState.add(playbackState.value.copyWith(
      updatePosition: pos,
    ));
  }

  // ═════════════════════════════════════════════════════════════
  // 状态 → MediaSession 同步
  // ═════════════════════════════════════════════════════════════

  void _onStateChanged(PlayerState ps) {
    final controls = _buildControls();
    // ── 关键修复 ──
    // indexSuppressed 只应抑制 queueIndex 的更新（防止切歌跃迁期间的
    // index=0 等中间态闪烁），但 MUST 仍然推送 playing/processingState/controls，
    // 否则 Android 会在 5 秒内因未调用 startForeground() 而杀死后台服务。
    // 这就是「后台播放 20 秒中断 + 通知栏不显示」的根因。
    final prev = playbackState.value;
    playbackState.add(prev.copyWith(
      controls: controls,
      systemActions: {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2, 3, 4],
      processingState: _mapProcessingState(ps.processingState),
      playing: ps.playing,
      updatePosition: _audio.player.position,
      bufferedPosition: _audio.player.bufferedPosition,
      speed: _audio.player.speed,
      // 跃迁期间保持上一次的 queueIndex，避免中间态闪烁
      queueIndex: _audio.indexSuppressed
          ? prev.queueIndex
          : _audio.player.currentIndex,
    ));
  }

  void _onIndexChanged(int? idx) {
    if (_audio.indexSuppressed) return;
    final q = _audio.queue;
    if (idx != null && idx >= 0 && idx < q.length) {
      mediaItem.add(_songToMediaItem(q[idx]));
    }
    // 切歌后刷新通知栏按钮（喜欢图标需随歌曲变化）
    _notifyControlsChanged();
  }

  void _onQueueChanged(List<Song> q) {
    // ignore: invalid_use_of_protected_member, unnecessary_this
    this.queue.add(q.map(_songToMediaItem).toList());
  }

  void _onDurationChanged(Duration? dur) {
    if (mediaItem.value != null && dur != null) {
      mediaItem.add(mediaItem.value!.copyWith(duration: dur));
    }
  }

  // ═════════════════════════════════════════════════════════════
  // 媒体命令 → AudioService 转发
  // ═════════════════════════════════════════════════════════════

  @override
  Future<void> play() => _audio.toggle();

  @override
  Future<void> pause() => _audio.player.pause();

  /// 停止播放并退出前台服务（通知栏消失，允许系统回收进程）。
  @override
  Future<void> stop() async {
    _audio.shutdown();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) => _audio.seek(position);

  @override
  Future<void> skipToNext() => _audio.next();

  @override
  Future<void> skipToPrevious() => _audio.previous();

  @override
  Future<void> skipToQueueItem(int index) => _audio.playAt(index);

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    switch (repeatMode) {
      case AudioServiceRepeatMode.none:
        await _audio.setLoopMode(LoopMode.off);
      case AudioServiceRepeatMode.one:
        await _audio.setLoopMode(LoopMode.one);
      case AudioServiceRepeatMode.group:
      case AudioServiceRepeatMode.all:
        await _audio.setLoopMode(LoopMode.all);
    }
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    await _audio.setShuffle(
      shuffleMode == AudioServiceShuffleMode.all ||
          shuffleMode == AudioServiceShuffleMode.group,
    );
  }

  /// 处理自定义通知栏动作（喜欢/取消喜欢）。
  @override
  Future<dynamic> customAction(String name, [Map<String, dynamic>? extras]) async {
    if (name == 'toggleLike') {
      final song = _currentSong;
      if (song != null && _audio.toggleLike != null) {
        await _audio.toggleLike!.call(song.id);
        _notifyControlsChanged();
      }
    }
  }

  // ═════════════════════════════════════════════════════════════
  // 辅助
  // ═════════════════════════════════════════════════════════════

  /// 当前正在播放的歌曲。
  Song? get _currentSong {
    final idx = _audio.player.currentIndex;
    final q = _audio.queue;
    if (idx != null && idx >= 0 && idx < q.length) return q[idx];
    return null;
  }

  /// 重新构建控制按钮并推送到 MediaSession。
  void _notifyControlsChanged() {
    final controls = _buildControls();
    final current = playbackState.value;
    playbackState.add(current.copyWith(
      controls: controls,
      androidCompactActionIndices: const [0, 1, 2, 3, 4],
    ));
  }

  /// 构建通知栏媒体控制按钮。
  ///
  /// 全部按钮均为紧凑可见（Android 12+ 支持最多 5 个）。
  /// 顺序（从左到右）：
  ///   [♥ 喜欢] [⏮ 上一首] [▶/⏸ 播放/暂停] [⏭ 下一首] [■ 停止]
  List<MediaControl> _buildControls() {
    final isPlaying = playbackState.value.playing;
    final song = _currentSong;
    final liked = song != null && (_audio.isLiked?.call(song.id) ?? false);

    return [
      MediaControl(
        androidIcon: liked
            ? 'drawable/ic_heart_filled'
            : 'drawable/ic_heart_outlined',
        label: liked ? '取消喜欢' : '喜欢',
        action: MediaAction.custom,
        customAction: const CustomMediaAction(name: 'toggleLike'),
      ),
      MediaControl.skipToPrevious,
      if (isPlaying)
        MediaControl.pause
      else
        MediaControl.play,
      MediaControl.skipToNext,
      MediaControl.stop,
    ];
  }

  AudioProcessingState _mapProcessingState(ProcessingState s) {
    switch (s) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }

  MediaItem _songToMediaItem(Song song) {
    return MediaItem(
      id: song.id.toString(),
      title: song.name,
      artist: song.artist.isNotEmpty ? song.artist : '未知歌手',
      album: song.album,
      artUri:
          song.coverUrl.isEmpty ? null : Uri.tryParse(song.coverThumb(512)),
      duration: song.duration,
    );
  }
}
