import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:yuugao/CloudMusic/api/song/entity/song_detail_entity.dart';
import 'package:yuugao/CloudMusic/yuugao.dart';
import 'package:yuugao/models/song.dart';
import 'package:yuugao/providers/playlist_provider.dart';
import 'package:yuugao/services/audio_handler.dart';

// ignore: unused_import — SongFetcher 在 play() 签名中使用
export 'package:yuugao/services/audio_handler.dart' show SongFetcher;

enum PlayMode { sequential, shuffle, repeatOne, heartbeat }

class PlayerState {
  final List<Song> queue;
  final int currentIndex;
  final bool isPlaying;
  final PlayMode mode;
  final Duration position;
  final Duration duration;
  final bool buffering;
  final bool isFmMode;
  final String? modeMessage;

  /// 当前队列源自的歌单 ID（用于心动模式）。
  final int? playlistId;

  /// 播客节目元数据覆盖：songId → {name, artist, coverUrl}。
  ///
  /// 播客通过 mainSong.id 播放，但歌曲本身的 name/artist 与节目不同。
  /// 此字段在持久化时保存，恢复时覆盖 Song.fromSongDetail 的字段。
  final Map<int, Map<String, String>>? podcastMeta;

  const PlayerState({
    this.queue = const [],
    this.currentIndex = -1,
    this.isPlaying = false,
    this.mode = PlayMode.sequential,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.buffering = false,
    this.isFmMode = false,
    this.modeMessage,
    this.playlistId,
    this.podcastMeta,
  });

  Song? get current => (currentIndex >= 0 && currentIndex < queue.length)
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
    Object? modeMessage = _keepModeMessage,
    int? playlistId,
    Map<int, Map<String, String>>? podcastMeta,
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
      modeMessage: modeMessage == _keepModeMessage
          ? this.modeMessage
          : modeMessage as String?,
      playlistId: playlistId ?? this.playlistId,
      podcastMeta: podcastMeta ?? this.podcastMeta,
    );
  }
}

const _keepModeMessage = Object();

class PlayerNotifier extends Notifier<PlayerState> {
  @override
  PlayerState build() {
    _bind();
    return const PlayerState();
  }

  final _audio = YuugaoAudioHandler.instance;

  /// 预期目标 index：切歌操作前设置，匹配后才接受 currentIndexStream 事件，
  /// 防止 just_audio 跃迁期间发射的中间态（0、null、旧 index）覆盖 UI。
  int? _intendedIndex;

  // ═══ 持久化 ═══

  static const _kQueueJson = 'player_queue_json';
  static const _kIndex = 'player_index';
  static const _kPositionMs = 'player_position_ms';
  static const _kMode = 'player_mode';
  static const _kFmMode = 'player_fm_mode';
  static const _kPodcastMeta = 'player_podcast_meta';

  /// 上次持久化的毫秒时间戳（用于位置流的节流）。
  int _lastPersistMs = 0;

  /// 位置流的最小持久化间隔（毫秒）。
  ///
  /// positionStream 每秒约触发 5 次。若每次触发都写 SharedPreferences，
  /// 会有大量无效 I/O。5 秒间隔意味着每个间隔写一次，其余调用零开销返回。
  /// 重要事件（切歌、队列变更、模式切换）通过 [immediate] 跳过节流。
  static const int _persistThrottleMs = 5000;

  /// 将当前播放状态持久化到 SharedPreferences。
  ///
  /// [immediate] 为 true 时跳过节流（用于队列/模式变更等低频关键事件）。
  /// 位置流调用时 [immediate] 为 false，受 [_persistThrottleMs] 节流。
  void _persistState({bool immediate = false}) {
    if (!immediate) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - _lastPersistMs < _persistThrottleMs) return;
      _lastPersistMs = now;
    }
    // 队列为空说明尚未恢复 / 无播放内容，跳过持久化避免覆盖已有数据。
    final s = state;
    if (s.queue.isEmpty) return;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString(
        _kQueueJson,
        jsonEncode(s.queue.map((song) => song.id).toList()),
      );
      prefs.setInt(_kIndex, s.currentIndex);
      prefs.setInt(_kPositionMs, s.position.inMilliseconds);
      prefs.setString(_kMode, s.mode.name);
      prefs.setBool(_kFmMode, s.isFmMode);
      final meta = s.podcastMeta;
      if (meta != null && meta.isNotEmpty) {
        final json = jsonEncode(meta.map((k, v) => MapEntry(k.toString(), v)));
        if (kDebugMode) debugPrint('[podcast] persist SAVE: $json');
        prefs.setString(_kPodcastMeta, json);
      }
      // 普通歌曲无需写空字符串 — restore 对 null 和 '' 的处理一致
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
      final detail = await MusicManager().songDetail(ids: ids);
      final idToSong = <int, Song>{};
      for (final s in (detail?.songs ?? [])) {
        if (s.id != null && s.id! > 0) {
          idToSong[s.id!] = Song.fromSongDetail(s);
        }
      }

      // 播客元数据覆盖：播客通过 mainSong.id 播放，歌曲原始 name/artist
      // 与节目信息不同。用持久化的播客元数据覆盖。
      final podcastMetaJson = prefs.getString(_kPodcastMeta);
      if (kDebugMode) debugPrint('[podcast] restore READ: $podcastMetaJson');
      Map<int, Map<String, String>>? podcastMeta;
      if (podcastMetaJson != null && podcastMetaJson.isNotEmpty) {
        final decoded = jsonDecode(podcastMetaJson);
        if (decoded is Map) {
          final raw = decoded as Map<String, dynamic>;
          if (raw.isNotEmpty) {
            podcastMeta = raw.map(
              (k, v) => MapEntry(int.parse(k), Map<String, String>.from(v)),
            );
          }
        }
      }
      if (podcastMeta != null && podcastMeta.isNotEmpty) {
        if (kDebugMode) {
          debugPrint('[podcast] restore APPLY: ${podcastMeta.length} entries');
        }
        for (final e in podcastMeta.entries) {
          final song = idToSong[e.key];
          if (song != null) {
            final m = e.value;
            if (kDebugMode) {
              debugPrint(
                '[podcast] restore OVERRIDE songId=${e.key} name=${m['name']} artist=${m['artist']}',
              );
            }
            idToSong[e.key] = Song(
              id: song.id,
              name: m['name'] ?? song.name,
              artist: m['artist'] ?? song.artist,
              album: song.album,
              coverUrl: m['coverUrl'] ?? song.coverUrl,
              durationMs: song.durationMs,
              fee: song.fee,
            );
          }
        }
      }

      // 按原顺序过滤，保留仍存在的歌曲
      final songs = ids.map((id) => idToSong[id]).whereType<Song>().toList();
      if (songs.isEmpty) return false;

      final clampedIndex = index.clamp(0, songs.length - 1);
      state = state.copyWith(
        queue: songs,
        currentIndex: clampedIndex,
        mode: mode,
        isFmMode: fmMode,
        podcastMeta: podcastMeta,
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
      final audioDur = dur ?? Duration.zero;
      // 优先使用歌曲元数据的时长（VIP 试听歌曲的音频源可能只有 30 秒，
      // 但元数据包含真实总时长）
      final metaDurMs = state.current?.durationMs ?? 0;
      final effectiveDur = metaDurMs > audioDur.inMilliseconds
          ? Duration(milliseconds: metaDurMs)
          : audioDur;
      state = state.copyWith(duration: effectiveDur);
    });
    _audio.currentIndexStream.listen((idx) {
      if (idx == null) return;
      // 有预期的 index 时只接受匹配值，拒绝跃迁过期事件
      if (_intendedIndex != null && idx != _intendedIndex) return;
      _intendedIndex = null; // 匹配成功，后续事件正常接受
      state = state.copyWith(currentIndex: idx);
      _persistState(immediate: true);
    });
    _audio.playerStateStream.listen((ps) {
      state = state.copyWith(
        isPlaying: ps.playing,
        buffering:
            ps.processingState == ProcessingState.loading ||
            ps.processingState == ProcessingState.buffering,
      );
    });
    // 队列变化时同步到 UI（包括同长度的元数据替换，如 FM 后台补齐歌手/封面）
    _audio.songQueueStream.listen((q) {
      // 引用比较：_songQueueController 每次 add 都创建新的 unmodifiable 包装，
      // 旧引用与新引用不同即表示队列已变化（新增 / 替换元数据）
      if (state.queue == q) return;
      final cur = _audio.player.currentIndex;
      final idx = (cur != null && cur >= 0 && cur < q.length)
          ? cur
          : state.currentIndex.clamp(0, q.length - 1);
      state = state.copyWith(queue: q, currentIndex: idx);
      _persistState(immediate: true);
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
    int? playlistId,
    Map<int, Map<String, String>>? podcastMeta,
  }) async {
    if (kDebugMode) {
      debugPrint('[podcast] play() received podcastMeta=$podcastMeta');
    }
    final list = queue ?? [song];
    var index = list.indexWhere((s) => s.id == song.id);
    if (index < 0) index = 0;
    _intendedIndex = index;
    state = state.copyWith(
      queue: list,
      currentIndex: index,
      playlistId: playlistId,
      podcastMeta: podcastMeta,
      isFmMode: false, // 播放歌单/搜索歌曲时退出 FM 模式
      mode: state.mode == PlayMode.heartbeat ? PlayMode.sequential : state.mode,
    );
    await _audio.setQueue(
      list,
      initialIndex: index,
      fetchMore: fetchMore,
      totalCount: totalCount,
    );
    _intendedIndex = null; // setQueue 完成，后续 currentIndexStream 正常接受
    final q = _audio.songQueue;
    final cur = _audio.player.currentIndex;
    state = state.copyWith(
      queue: q,
      currentIndex: (cur != null && cur >= 0 && cur < q.length)
          ? cur
          : state.currentIndex,
    );

    _persistState(immediate: true);

    // 喜欢的音乐歌单默认启动心动模式
    if (playlistId != null && playlistId == _likedPlaylistId) {
      setMode(PlayMode.heartbeat);
    }
  }

  Future<void> toggle() => _audio.toggle();

  Future<void> next() async {
    // FM 模式由 AudioService 内部双缓冲接管，队列会在调用后整体替换，
    // 必须等 _audio.next() 完成再同步状态，否则 UI 停留在第一首。
    if (state.isFmMode) {
      _intendedIndex = 0; // 防止 FM 切歌时 just_audio 的中间态 index
      await _audio.next();
      state = state.copyWith(queue: _audio.songQueue, currentIndex: 0);
      return;
    }
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
    final q = _audio.songQueue;
    if (index >= 0 && index < q.length) {
      _intendedIndex = index;
      state = state.copyWith(currentIndex: index, queue: q);
    }
    return _audio.playAt(index);
  }

  Future<void> appendAndPlay(Song song) async {
    await _audio.appendAndPlay(song);
    state = state.copyWith(queue: _audio.songQueue);
  }

  /// 在当前歌曲之后插入一首（下一首播放）
  Future<void> insertNext(Song song) async {
    await _audio.insertNext(song);
    state = state.copyWith(queue: _audio.songQueue);
  }

  /// 从队列中移除指定位置的歌曲
  Future<void> removeAt(int index) async {
    await _audio.removeAt(index);
    state = state.copyWith(queue: _audio.songQueue);
  }

  void clearModeMessage() {
    if (state.modeMessage == null) return;
    state = state.copyWith(modeMessage: null);
  }

  Future<void> setMode(PlayMode mode) async {
    // 心动模式：仅在「我喜欢的音乐」歌单可用
    if (mode == PlayMode.heartbeat) {
      final pid = state.playlistId;
      if (pid == null || pid != _likedPlaylistId) {
        // 不是喜欢的音乐歌单，跳过心动模式
        state = state.copyWith(
          mode: PlayMode.sequential,
          modeMessage: '仅我喜欢的音乐支持心动模式',
        );
        await _audio.setShuffle(false);
        await _audio.setLoopMode(LoopMode.all);
        _persistState(immediate: true);
        return;
      }
      // 立即显示心形图标 + 设置播放参数
      state = state.copyWith(mode: PlayMode.heartbeat);
      await _audio.setShuffle(false);
      await _audio.setLoopMode(LoopMode.all);
      _persistState(immediate: true);
      // 后台异步加载智能列表
      _startHeartbeat();
      return;
    }
    state = state.copyWith(mode: mode);
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
      case PlayMode.heartbeat:
        break; // unreachable
    }
    _persistState(immediate: true);
  }

  /// 循环切换播放模式
  Future<void> cycleMode() {
    final next =
        PlayMode.values[(state.mode.index + 1) % PlayMode.values.length];
    return setMode(next);
  }

  // ═══ 私人 FM ═══

  /// 启动私人 FM 模式。
  ///
  /// 设置 [_intendedIndex] 防止 just_audio 在
  /// AudioPlayer.setAudioSources 期间发出的中间态 index
  /// （null、旧 index 等）污染 UI。
  Future<bool> startFm() async {
    _intendedIndex = 0;
    final ok = await _audio.startFm();
    if (ok) {
      state = state.copyWith(
        isFmMode: true,
        queue: _audio.songQueue,
        currentIndex: 0,
      );
    }
    return ok;
  }

  /// FM 切到下一首。
  Future<void> nextFm() async {
    _intendedIndex = 0;
    await _audio.nextFm();
    state = state.copyWith(queue: _audio.songQueue, currentIndex: 0);
  }

  /// FM 垃圾桶（跳过 + 标记不喜欢）。
  Future<void> trashFm() async {
    _intendedIndex = 0;
    await _audio.trashFm();
    state = state.copyWith(queue: _audio.songQueue, currentIndex: 0);
  }

  // ═══ 心动模式 ═══

  /// 「我喜欢的音乐」歌单 ID，心动模式仅对此歌单开放。
  int? get _likedPlaylistId => ref.read(playlistProvider).likedPlaylist?.id;

  /// 后台加载智能播放列表并替换队列。
  ///
  /// 保留当前播放的歌曲在队首，心动列表追加到后面，
  /// 替换后 seek 回原位置，避免中断用户正在听的歌。
  Future<void> _startHeartbeat() async {
    final seed = state.current;
    final pid = state.playlistId;
    if (seed == null || pid == null) {
      if (kDebugMode) debugPrint('[heartbeat] FAIL: precondition lost');
      _revertHeartbeat();
      return;
    }

    try {
      // ── 第一步：获取智能列表 ID ──
      if (kDebugMode) {
        debugPrint('[heartbeat] loading… songId=${seed.id} playlistId=$pid');
      }
      final res = await MusicManager().playmodeIntelligenceList(
        songId: seed.id,
        playlistId: pid,
        startMusicId: seed.id,
        count: 30,
      );
      if (res == null || res.code != 200) {
        if (kDebugMode) debugPrint('[heartbeat] FAIL: API code=${res?.code}');
        _revertHeartbeat();
        return;
      }
      final items = res.data;
      if (items == null || items.isEmpty) {
        if (kDebugMode) debugPrint('[heartbeat] FAIL: empty data');
        _revertHeartbeat();
        return;
      }

      final ids = items.map((e) => e.id ?? 0).where((id) => id > 0).toList();
      if (ids.isEmpty) {
        if (kDebugMode) debugPrint('[heartbeat] FAIL: no valid ids');
        _revertHeartbeat();
        return;
      }
      if (kDebugMode) debugPrint('[heartbeat] got ${ids.length} ids');

      // ── 第二步：并行获取全部歌曲详情 + 音频 URL ──
      final results = await Future.wait([
        MusicManager().songDetail(ids: ids),
        _audio.preloadUrls(ids),
      ]);
      final detail = results[0] as SongDetailEntity?;
      final newSongs = (detail?.songs ?? [])
          .map((s) => Song.fromSongDetail(s))
          .where((s) => s.id > 0)
          .toList();
      if (newSongs.isEmpty) {
        if (kDebugMode) debugPrint('[heartbeat] FAIL: no songs from detail');
        _revertHeartbeat();
        return;
      }
      if (kDebugMode) {
        debugPrint('[heartbeat] songDetail returned ${newSongs.length} songs');
      }

      if (state.mode != PlayMode.heartbeat) return;

      // ── 第三步：替换后续队列，当前歌继续播不中断 ──
      // URL 已全部预热，replaceUpcoming 内的 _batchResolve 命中缓存零网络开销
      final upcoming = newSongs.where((s) => s.id != seed.id).toList();
      await _audio.replaceUpcoming(upcoming);
      state = state.copyWith(
        queue: _audio.songQueue,
        currentIndex: _audio.player.currentIndex ?? 0,
        position: _audio.player.position,
      );
      if (kDebugMode) {
        debugPrint('[heartbeat] SUCCESS queue=${_audio.songQueue.length}');
      }
    } catch (e, st) {
      if (kDebugMode) debugPrint('[heartbeat] EXCEPTION: $e\n$st');
      _revertHeartbeat();
    }
  }

  /// 心动模式加载失败时回退到顺序播放。
  void _revertHeartbeat([String message = '心动模式暂不可用，已切回顺序播放']) {
    if (state.mode != PlayMode.heartbeat) return;
    state = state.copyWith(mode: PlayMode.sequential, modeMessage: message);
    // fire-and-forget，不阻塞
    _audio.setShuffle(false);
    _audio.setLoopMode(LoopMode.all);
    _persistState(immediate: true);
  }
}

final playerProvider = NotifierProvider<PlayerNotifier, PlayerState>(
  PlayerNotifier.new,
);
