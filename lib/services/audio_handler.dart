import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

import 'package:yuugao/models/song.dart';
import 'package:yuugao/services/audio_service.dart' as asvc;

/// 自定义 [BaseAudioHandler]，将系统媒体命令（通知栏按钮、耳机线控、蓝牙等）
/// 转发给内部 [asvc.AudioService]，并将播放状态同步到 Android MediaSession。
///
/// 直接使用 [audio_service] 替代 [just_audio_background] beta 桥接层：
/// - 音频焦点由 audio_service 原生管理，不再依赖 just_audio_background 转接
/// - 通知栏由 audio_service 通过 MediaSession 原生更新
/// - 消除 beta 桥接层带来的后台暂停问题
class YuugaoAudioHandler extends BaseAudioHandler with QueueHandler {
  final asvc.AudioService _audio;

  YuugaoAudioHandler(this._audio) {
    _audio.player.playerStateStream.listen(_onStateChanged);
    _audio.player.currentIndexStream.listen(_onIndexChanged);
    _audio.queueStream.listen(_onQueueChanged);
    _audio.player.positionStream.listen(_onPositionChanged);
    _audio.player.durationStream.listen(_onDurationChanged);
  }

  // ═════════════════════════════════════════════════════════════
  // 状态 → MediaSession 同步
  // ═════════════════════════════════════════════════════════════

  void _onStateChanged(PlayerState ps) {
    if (_audio.indexSuppressed) return;

    final controls = _buildControls();
    playbackState.add(playbackState.value.copyWith(
      controls: controls,
      systemActions: {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices:
          List.generate(controls.length, (i) => i),
      processingState: _mapProcessingState(ps.processingState),
      playing: ps.playing,
      updatePosition: _audio.player.position,
      bufferedPosition: _audio.player.bufferedPosition,
      speed: _audio.player.speed,
      queueIndex: _audio.player.currentIndex,
    ));
  }

  void _onIndexChanged(int? idx) {
    if (_audio.indexSuppressed) return;
    final q = _audio.queue;
    if (idx != null && idx >= 0 && idx < q.length) {
      mediaItem.add(_songToMediaItem(q[idx]));
    }
  }

  void _onQueueChanged(List<Song> q) {
    // BaseAudioHandler.queue 是 ValueStream<List<MediaItem>>
    // BaseAudioHandler.queue 是 ValueStream<List<MediaItem>>
    // ignore: invalid_use_of_protected_member, unnecessary_this
    this.queue.add(q.map(_songToMediaItem).toList());
  }

  void _onPositionChanged(Duration pos) {
    playbackState.add(playbackState.value.copyWith(
      updatePosition: pos,
    ));
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

  @override
  Future<void> stop() => _audio.player.pause();

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

  // ═════════════════════════════════════════════════════════════
  // 辅助
  // ═════════════════════════════════════════════════════════════

  List<MediaControl> _buildControls() {
    return [
      MediaControl.skipToPrevious,
      if (playbackState.value.playing)
        MediaControl.pause
      else
        MediaControl.play,
      MediaControl.skipToNext,
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
