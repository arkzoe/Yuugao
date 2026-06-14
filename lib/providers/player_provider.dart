import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:yuugao/CloudMusic/yuugao.dart';
import 'package:yuugao/models/song.dart';
import 'package:yuugao/services/audio_service.dart';

// ignore: unused_import — SongFetcher 在 play() 签名中使用
export 'package:yuugao/services/audio_service.dart' show SongFetcher;

enum PlayMode { sequential, shuffle, repeatOne }

class PlayerState {
  final List<Song> queue;
  final int currentIndex;
  final bool isPlaying;
  final PlayMode mode;
  final Duration position;
  final Duration duration;
  final bool buffering;
  final bool isFmMode;

  const PlayerState({
    this.queue = const [],
    this.currentIndex = -1,
    this.isPlaying = false,
    this.mode = PlayMode.sequential,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.buffering = false,
    this.isFmMode = false,
  });

  Song? get current =>
      (currentIndex >= 0 && currentIndex < queue.length)
          ? queue[currentIndex]
          : null;

  bool get hasSong => current != null;

  double get progress {
    final total = duration.inMilliseconds;
    if (total <= 0) return 0;
    return (position.inMilliseconds / total).clamp(0.0, 1.0);
  }

  PlayerState copyWith({
    List<Song>? queue,
    int? currentIndex,
    bool? isPlaying,
    PlayMode? mode,
    Duration? position,
    Duration? duration,
    bool? buffering,
    bool? isFmMode,
  }) {
    return PlayerState(
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      isPlaying: isPlaying ?? this.isPlaying,
      mode: mode ?? this.mode,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      buffering: buffering ?? this.buffering,
      isFmMode: isFmMode ?? this.isFmMode,
    );
  }
}

class PlayerNotifier extends Notifier<PlayerState> {
  @override
  PlayerState build() {
    _bind();
    return const PlayerState();
  }

  final _audio = AudioService.instance;

  /// 预期目标 index：切歌操作前设置，匹配后才接受 currentIndexStream 事件，
  /// 防止 just_audio 跃迁期间发射的中间态（0、null、旧 index）覆盖 UI。
  int? _intendedIndex;

  /// 持久化防抖计时器
  Timer? _persistTimer;

  // ═══ 持久化 ═══

  static const _kQueueJson = 'player_queue_json';
  static const _kIndex = 'player_index';
  static const _kPositionMs = 'player_position_ms';
  static const _kMode = 'player_mode';
  static const _kFmMode = 'player_fm_mode';

  /// 将当前播放状态保存到 SharedPreferences（防抖 2 秒）。
  Future<void> _persistState() async {
    _persistTimer?.cancel();
    _persistTimer = Timer(const Duration(seconds: 2), () async {
      final prefs = await SharedPreferences.getInstance();
      final s = state;
      await prefs.setString(
        _kQueueJson,
        jsonEncode(s.queue.map((song) => song.id).toList()),
      );
      await prefs.setInt(_kIndex, s.currentIndex);
      await prefs.setInt(_kPositionMs, s.position.inMilliseconds);
      await prefs.setString(_kMode, s.mode.name);
      await prefs.setBool(_kFmMode, s.isFmMode);
    });
  }

  /// 从 SharedPreferences 恢复上次播放状态。
  /// 返回 true 表示有可恢复的状态。
  Future<bool> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final queueJson = prefs.getString(_kQueueJson);
    if (queueJson == null || queueJson.isEmpty) return false;

    final ids = (jsonDecode(queueJson) as List<dynamic>)
        .map((e) => (e as num).toInt())
        .toList();
    if (ids.isEmpty) return false;

    final index = prefs.getInt(_kIndex) ?? 0;
    final posMs = prefs.getInt(_kPositionMs) ?? 0;
    final fmMode = prefs.getBool(_kFmMode) ?? false;
    final modeStr = prefs.getString(_kMode) ?? 'sequential';
    final mode = PlayMode.values.firstWhere(
      (m) => m.name == modeStr,
      orElse: () => PlayMode.sequential,
    );

    // 通过 songDetail 还原 Song 对象，然后恢复播放。
    // 容错：部分歌曲下架仍恢复剩余队列，不全丢。
    try {
      final detail = await BujuanMusicManager().songDetail(ids: ids);
      final idToSong = <int, Song>{};
      for (final s in (detail?.songs ?? [])) {
        if (s.id != null && s.id! > 0) {
          idToSong[s.id!] = Song.fromSongDetail(s);
        }
      }
      // 按原顺序过滤，保留仍存在的歌曲
      final songs = ids
          .map((id) => idToSong[id])
          .whereType<Song>()
          .toList();
      if (songs.isEmpty) return false;

      final clampedIndex = index.clamp(0, songs.length - 1);
      state = state.copyWith(
        queue: songs,
        currentIndex: clampedIndex,
        mode: mode,
        isFmMode: fmMode,
      );
      // 先设 mode 再 setQueue，避免后台扩展期间模式变更冲突
      await setMode(mode);
      await _audio.setQueue(
        songs,
        initialIndex: clampedIndex,
        autoPlay: false, // 恢复状态但不自动播放
      );
      await _audio.seek(Duration(milliseconds: posMs));
      return true;
    } catch (_) {
      return false;
    }
  }

  void _bind() {
    _audio.positionStream.listen((pos) {
      state = state.copyWith(position: pos);
      _persistState();
    });
    _audio.durationStream.listen((dur) {
      state = state.copyWith(duration: dur ?? Duration.zero);
    });
    _audio.currentIndexStream.listen((idx) {
      if (idx == null || _audio.indexSuppressed) return;
      // 有预期的 index 时只接受匹配值，拒绝跃迁过期事件
      if (_intendedIndex != null && idx != _intendedIndex) return;
      _intendedIndex = null; // 匹配成功，后续事件正常接受
      state = state.copyWith(currentIndex: idx);
      _persistState();
    });
    _audio.playerStateStream.listen((ps) {
      // 切歌时 seek / setAudioSources 内部会短暂发射 playing=false，
      // 抑制该窗口期避免底边栏播放/暂停图标闪烁。
      if (_audio.indexSuppressed) return;
      state = state.copyWith(
        isPlaying: ps.playing,
        buffering: ps.processingState == ProcessingState.loading ||
            ps.processingState == ProcessingState.buffering,
      );
    });
    // 两阶段加载时队列会逐步扩展，同步到 UI
    _audio.queueStream.listen((q) {
      if (state.queue.length != q.length) {
        // 队列变化时也修正可能越界的 currentIndex
        final cur = _audio.player.currentIndex;
        final idx = (cur != null && cur >= 0 && cur < q.length)
            ? cur
            : state.currentIndex.clamp(0, q.length - 1);
        state = state.copyWith(queue: q, currentIndex: idx);
        _persistState();
      }
    });
  }

  /// 播放一首歌，可附带其所属队列。无队列时单曲成队。
  ///
  /// 传入 [fetchMore] 回调后，播放器在当前候选列表耗尽时自动分页拉取后续歌曲，
  /// 配合滑动窗口实现超长歌单的内存友好播放。
  Future<void> play(
    Song song, {
    List<Song>? queue,
    SongFetcher? fetchMore,
    int totalCount = 0,
  }) async {
    final list = queue ?? [song];
    var index = list.indexWhere((s) => s.id == song.id);
    if (index < 0) index = 0;
    _intendedIndex = index;
    state = state.copyWith(queue: list, currentIndex: index);
    await _audio.setQueue(
      list,
      initialIndex: index,
      fetchMore: fetchMore,
      totalCount: totalCount,
    );
    _intendedIndex = null; // setQueue 完成，后续 currentIndexStream 正常接受
    final q = _audio.queue;
    final cur = _audio.player.currentIndex;
    state = state.copyWith(
      queue: q,
      currentIndex: (cur != null && cur >= 0 && cur < q.length) ? cur : state.currentIndex,
    );
  }

  Future<void> toggle() => _audio.toggle();

  Future<void> next() {
    final nxt = state.currentIndex + 1;
    if (nxt < state.queue.length) {
      state = state.copyWith(currentIndex: nxt);
    }
    return _audio.next();
  }

  Future<void> prev() {
    final prv = state.currentIndex - 1;
    if (prv >= 0) {
      state = state.copyWith(currentIndex: prv);
    }
    return _audio.previous();
  }

  Future<void> seek(Duration pos) => _audio.seek(pos);

  Future<void> playAt(int index) {
    final q = _audio.queue;
    if (index >= 0 && index < q.length) {
      _intendedIndex = index;
      state = state.copyWith(currentIndex: index, queue: q);
    }
    return _audio.playAt(index);
  }

  Future<void> appendAndPlay(Song song) async {
    await _audio.appendAndPlay(song);
    state = state.copyWith(queue: _audio.queue);
  }

  /// 在当前歌曲之后插入一首（下一首播放）
  Future<void> insertNext(Song song) async {
    await _audio.insertNext(song);
    state = state.copyWith(queue: _audio.queue);
  }

  /// 从队列中移除指定位置的歌曲
  Future<void> removeAt(int index) async {
    await _audio.removeAt(index);
    state = state.copyWith(queue: _audio.queue);
  }

  Future<void> setMode(PlayMode mode) async {
    state = state.copyWith(mode: mode);
    _audio.setPlayMode(mode == PlayMode.sequential);
    switch (mode) {
      case PlayMode.sequential:
        await _audio.setShuffle(false);
        await _audio.setLoopMode(LoopMode.all);
        break;
      case PlayMode.shuffle:
        await _audio.setLoopMode(LoopMode.all);
        await _audio.setShuffle(true);
        break;
      case PlayMode.repeatOne:
        await _audio.setShuffle(false);
        await _audio.setLoopMode(LoopMode.one);
        break;
    }
    _persistState(); // 模式变更立即持久化，不等进度触发
  }

  /// 循环切换播放模式
  Future<void> cycleMode() {
    final next = PlayMode.values[(state.mode.index + 1) % PlayMode.values.length];
    return setMode(next);
  }

  // ═══ 私人 FM ═══

  /// 启动私人 FM 模式。
  Future<bool> startFm() async {
    final ok = await _audio.startFm();
    if (ok) {
      state = state.copyWith(
        isFmMode: true,
        queue: _audio.queue,
        currentIndex: 0,
      );
    }
    return ok;
  }

  /// FM 切到下一首。
  Future<void> nextFm() async {
    await _audio.nextFm();
    state = state.copyWith(
      queue: _audio.queue,
      currentIndex: 0,
    );
  }

  /// FM 垃圾桶（跳过 + 标记不喜欢）。
  Future<void> trashFm() async {
    await _audio.trashFm();
    state = state.copyWith(
      queue: _audio.queue,
      currentIndex: 0,
    );
  }
}

final playerProvider =
    NotifierProvider<PlayerNotifier, PlayerState>(PlayerNotifier.new);
