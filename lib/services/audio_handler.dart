import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

import 'package:yuugao/CloudMusic/yuugao.dart';
import 'package:yuugao/CloudMusic/api/fm/entity/personal_fm_entity.dart';
import 'package:yuugao/CloudMusic/api/song/entity/song_detail_entity.dart';
import 'package:yuugao/models/song.dart';
import 'package:yuugao/services/cache_service.dart';

/// 分页歌单加载回调：给定 [offset] 和 [limit]，返回下一页歌曲列表。
typedef SongFetcher = Future<List<Song>> Function(int offset, int limit);

/// 统一的音频处理器 —— 直接持有 [AudioPlayer]，管理队列/URL解析/通知栏/FM。
///
/// 通知栏 5 按钮：♥喜欢 | ⏮上一首 | ▶⏸播放暂停 | ⏭下一首 | ✕停止
/// 喜欢按钮使用标准 MediaAction.fastForward/rewind，
/// 图标按 liked 状态在实心/空心之间切换。
class YuugaoAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  static YuugaoAudioHandler? _instance;
  static YuugaoAudioHandler get instance => _instance!;

  final AudioPlayer _player = AudioPlayer();

  // ── 歌曲队列 ──
  List<Song> _songQueue = [];
  List<Song> get songQueue => List.unmodifiable(_songQueue);

  final _songQueueController = StreamController<List<Song>>.broadcast();
  Stream<List<Song>> get songQueueStream => _songQueueController.stream;

  // ── 暴露给 UI 层的流（代理 just_audio）──
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<int?> get currentIndexStream => _player.currentIndexStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  AudioPlayer get player => _player;

  // ── 音质设置 ──
  String level = 'exhigh';

  // ── URL 解析缓存 ──
  final Map<int, String> _resolvedUrls = {};
  final Map<int, String> _resolvedExt = {};

  // ── 长队列后台扩展 ──
  SongFetcher? _fetchMore;
  int _totalCount = 0;
  int _fetchOffset = 0;
  bool _fetchingMore = false;

  // ── FM 模式 ──
  bool _isFmMode = false;
  bool get isFmMode => _isFmMode;
  Song? _fmCurrentTrack;
  bool _fmLoading = false;

  // ── 喜欢状态（fastForward = 喜欢, rewind = 取消喜欢）──
  final Set<int> _likedSongIds = {};
  void Function(int songId, bool like)? onLikeSong;

  // ── 持久化回调（由 player_provider 注入）──
  void Function()? onPersistNeeded;

  YuugaoAudioHandler() {
    _instance = this;
    _player.playbackEventStream.listen(_onPlaybackEvent);
    _player.playerStateStream.listen(_onPlayerState);
    _player.currentIndexStream.listen(_onIndexChanged);

    // 初始占位元数据，确保 startForeground 被调用
    mediaItem.add(
      const MediaItem(id: 'placeholder', title: 'yuugao', artist: '准备播放'),
    );
    playbackState.add(
      PlaybackState(
        controls: [],
        processingState: AudioProcessingState.idle,
        playing: false,
      ),
    );
  }

  /// 同步喜欢歌曲 ID 集合（由 UI 层在 likedSongIds 变化时调用，
  /// 确保通知栏喜欢图标与当前歌曲状态一致）。
  void syncLikedIds(Set<int> ids) {
    _likedSongIds
      ..clear()
      ..addAll(ids);
    // 刷新当前 mediaItem 的 liked extra，触发通知栏图标更新
    final item = mediaItem.value;
    if (item != null && item.id != 'placeholder') {
      final songId = int.tryParse(item.id);
      if (songId != null) {
        final liked = _likedSongIds.contains(songId);
        final extras = Map<String, dynamic>.from(item.extras ?? {});
        extras['liked'] = liked;
        mediaItem.add(item.copyWith(extras: extras));
      }
    }
    _rebuildControls();
  }

  // ═════════════════════════════════════════════════════════════
  // 公开方法
  // ═════════════════════════════════════════════════════════════

  /// 用 [songs] 队列替换并从 [initialIndex] 开始播放。
  Future<void> setQueue(
    List<Song> songs, {
    int initialIndex = 0,
    SongFetcher? fetchMore,
    int totalCount = 0,
    bool autoPlay = true,
  }) async {
    exitFmMode();

    if (songs.isEmpty) return;

    final index = initialIndex.clamp(0, songs.length - 1);
    _fetchMore = fetchMore;
    _totalCount = totalCount;
    _fetchOffset = songs.length;
    _fetchingMore = false;

    await _batchResolve(songs);

    final sources = <AudioSource>[];
    final playableSongs = <Song>[];
    for (final s in songs) {
      final src = _buildSource(s);
      if (src != null) {
        sources.add(src);
        playableSongs.add(s);
      }
    }
    if (sources.isEmpty) return;

    _songQueue = playableSongs;
    _songQueueController.add(List.unmodifiable(_songQueue));

    final targetId = songs[index].id;
    var realIndex = playableSongs.indexWhere((s) => s.id == targetId);
    if (realIndex < 0) realIndex = 0;

    await _player.setAudioSources(
      sources,
      initialIndex: realIndex,
      initialPosition: Duration.zero,
    );
    if (autoPlay) _player.play();

    _pushQueueToMediaSession();

    // 后台补齐缺失的封面（搜索结果的 album.picUrl 可能为空）
    _fetchMissingCovers(playableSongs);
  }

  /// 后台为缺少封面的歌曲补齐元数据。
  ///
  /// 搜索 API 返回的歌曲可能不含 album.picUrl，导致播放器显示占位图。
  /// 此方法异步拉取 songDetail，静默更新队列中对应 Song 的 coverUrl，
  /// 通过 songQueueStream 触发 UI 刷新。
  void _fetchMissingCovers(List<Song> playableSongs) {
    final missing = playableSongs
        .where((s) => s.coverUrl.isEmpty)
        .map((s) => s.id)
        .toList();
    if (missing.isEmpty) return;

    // 最多 30 首一批，跟 songDetail 的单次上限一致
    MusicManager()
        .songDetail(ids: missing.take(30).toList())
        .then((detailRes) {
          final songs = detailRes?.songs;
          if (songs == null || songs.isEmpty) return;

          final idToSong = <int, Song>{};
          for (final d in songs) {
            if (d.id != null && d.id! > 0) {
              idToSong[d.id!] = Song.fromSongDetail(d);
            }
          }
          if (idToSong.isEmpty) return;

          var changed = false;
          for (var i = 0; i < _songQueue.length; i++) {
            final old = _songQueue[i];
            if (old.coverUrl.isNotEmpty) continue;
            final detail = idToSong[old.id];
            if (detail == null || detail.coverUrl.isEmpty) continue;

            _songQueue[i] = Song(
              id: old.id,
              name: old.name,
              artist: old.artist,
              artistIds: old.artistIds,
              album: old.album,
              coverUrl: detail.coverUrl, // 仅替换封面 URL
              durationMs: old.durationMs,
              fee: old.fee,
            );
            changed = true;
          }
          if (changed) {
            _songQueueController.add(List.unmodifiable(_songQueue));
            _pushQueueToMediaSession();
          }
        })
        .catchError((_) {
          // 封面补齐失败不影响播放
        });
  }

  /// 替换当前索引之后的所有歌曲为 [newSongs]。
  ///
  /// 当前正在播放的音频源不受影响 —— 不销毁、不重建、不 seek，
  /// 仅清理后续队列并追加新歌，播放无任何中断。
  /// 使用 player 原生方法逐首操作，避免 ConcatenatingAudioSource
  /// 触发 ExoPlayer 时间线重建导致播放中断。
  Future<void> replaceUpcoming(List<Song> newSongs) async {
    final currentIndex = _player.currentIndex ?? 0;
    final wasPlaying = _player.playing;

    // 删除当前歌曲之后的所有音频源（从末尾删避免索引偏移，
    // 以 _songQueue 为准；越界由 try/catch 兜底）
    for (var i = _songQueue.length - 1; i > currentIndex; i--) {
      try {
        await _player.removeAudioSourceAt(i);
      } catch (_) {
        // 实际序列可能比 _songQueue 短（无 URL 的歌没生成 AudioSource）
      }
      _songQueue.removeAt(i);
    }

    if (newSongs.isEmpty) {
      _songQueueController.add(List.unmodifiable(_songQueue));
      _pushQueueToMediaSession();
      if (wasPlaying && !_player.playing) _player.play();
      return;
    }

    // 解析 URL（若已通过 preloadUrls 预热则命中缓存，零网络开销）
    await _batchResolve(newSongs);

    // 逐个追加到队尾（已清空后续队列，队尾 = currentIndex + 1）
    for (final s in newSongs) {
      final src = _buildSource(s);
      if (src != null) {
        await _player.addAudioSource(src);
        _songQueue.add(s);
      }
    }

    _songQueueController.add(List.unmodifiable(_songQueue));
    _pushQueueToMediaSession();

    // 确保播放状态不变
    if (wasPlaying && !_player.playing) _player.play();
  }

  Future<void> playAt(int index) async {
    if (index < 0 || index >= _songQueue.length) return;
    await _player.seek(Duration.zero, index: index);
    _player.play();
  }

  Future<void> toggle() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      _player.play();
    }
  }

  Future<void> next() async {
    if (_isFmMode) {
      await nextFm();
      return;
    }
    await _player.seekToNext();
  }

  Future<void> previous() async {
    if (_isFmMode) return;
    await _player.seekToPrevious();
  }

  Future<void> setLoopMode(LoopMode mode) => _player.setLoopMode(mode);

  Future<void> setShuffle(bool enabled) async {
    if (enabled) await _player.shuffle();
    await _player.setShuffleModeEnabled(enabled);
  }

  Future<void> removeAt(int index) async {
    if (index < 0 || index >= _songQueue.length) return;
    _songQueue.removeAt(index);
    await _player.removeAudioSourceAt(index);
    _songQueueController.add(List.unmodifiable(_songQueue));
    _pushQueueToMediaSession();
  }

  Future<void> insertNext(Song song) async {
    if (_resolvedUrls[song.id] == null) {
      await _batchResolve([song]);
    }
    final src = _buildSource(song);
    if (src == null) return;
    final curIdx = _player.currentIndex ?? 0;
    final insertAt = curIdx + 1;
    _songQueue.insert(insertAt, song);
    await _player.insertAudioSource(insertAt, src);
    _songQueueController.add(List.unmodifiable(_songQueue));
    _pushQueueToMediaSession();
  }

  Future<void> appendAndPlay(Song song) async {
    AudioSource? src = _buildSource(song);
    if (src == null) {
      await _batchResolve([song]);
      src = _buildSource(song);
    }
    if (src == null) return;
    _songQueue.add(song);
    await _player.addAudioSource(src);
    await playAt(_songQueue.length - 1);
    _songQueueController.add(List.unmodifiable(_songQueue));
    _pushQueueToMediaSession();
  }

  void shutdown() => _player.stop();

  void dispose() {
    _songQueueController.close();
    _player.dispose();
  }

  // ═════════════════════════════════════════════════════════════
  // 音频源构建
  // ═════════════════════════════════════════════════════════════

  AudioSource? _buildSource(Song song) {
    final localPath = CacheService.instance.getLocalPath(song.id);
    if (localPath != null) return AudioSource.file(localPath);

    final url = _resolvedUrls[song.id];
    if (url == null || url.isEmpty) return null;
    return AudioSource.uri(Uri.parse(url));
  }

  // ═════════════════════════════════════════════════════════════
  // URL 批量解析
  // ═════════════════════════════════════════════════════════════

  Future<void> _batchResolve(List<Song> songs) async {
    const chunkSize = 30;
    for (var i = 0; i < songs.length; i += chunkSize) {
      final end = (i + chunkSize).clamp(0, songs.length);
      final chunk = songs.sublist(i, end);
      // 过滤掉已缓存的歌曲，避免重复请求
      final missing = chunk
          .where((s) => !_resolvedUrls.containsKey(s.id))
          .map((s) => s.id.toString())
          .toList();
      if (missing.isEmpty) continue;

      final res = await MusicManager().songUrl(ids: missing, level: level);
      final data = res?.data ?? [];

      for (final d in data) {
        if (d.id != null && d.url != null && d.url!.isNotEmpty) {
          final type = (d.type ?? 'mp3').toLowerCase();
          _resolvedUrls[d.id!] = d.url!;
          _resolvedExt[d.id!] = type.isEmpty ? 'mp3' : type;
        }
      }
    }
  }

  /// 预热 URL 缓存：批量解析 [songIds] 的音频地址并写入 [_resolvedUrls]。
  ///
  /// 与 [_batchResolve] 共享同一缓存，调用方可在构造 [Song] 列表之前
  /// 提前发出请求，后续 [setQueue] 中的 [_batchResolve] 命中缓存即为空操作。
  Future<void> preloadUrls(List<int> songIds) async {
    const chunkSize = 30;
    for (var i = 0; i < songIds.length; i += chunkSize) {
      final end = (i + chunkSize).clamp(0, songIds.length);
      final ids = songIds.sublist(i, end).map((id) => id.toString()).toList();
      if (ids.isEmpty) continue;

      final res = await MusicManager().songUrl(ids: ids, level: level);
      final data = res?.data ?? [];

      for (final d in data) {
        if (d.id != null && d.url != null && d.url!.isNotEmpty) {
          final type = (d.type ?? 'mp3').toLowerCase();
          _resolvedUrls[d.id!] = d.url!;
          _resolvedExt[d.id!] = type.isEmpty ? 'mp3' : type;
        }
      }
    }
  }

  // ═════════════════════════════════════════════════════════════
  // MediaSession 同步 + 通知栏
  // ═════════════════════════════════════════════════════════════

  void _onPlaybackEvent(PlaybackEvent event) {
    final playing = _player.playing;
    playbackState.add(
      playbackState.value.copyWith(
        controls: _buildControls(isPlaying: playing),
        systemActions: const {MediaAction.seek},
        androidCompactActionIndices: const [1, 2, 3],
        processingState: _mapState(_player.processingState),
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: _player.currentIndex,
        shuffleMode: _player.shuffleModeEnabled
            ? AudioServiceShuffleMode.all
            : AudioServiceShuffleMode.none,
      ),
    );
  }

  void _onPlayerState(PlayerState ps) {
    if (ps.processingState == ProcessingState.completed) {
      skipToNext();
    }
  }

  /// 歌曲切换时：更新 mediaItem（含 liked 状态）+ 触发缓存 + 通知 Provider 持久化。
  void _onIndexChanged(int? idx) {
    final q = _songQueue;
    if (idx != null && idx >= 0 && idx < q.length) {
      final song = q[idx];
      mediaItem.add(_songToMediaItem(song));
      // 边播边存
      _cacheSong(song);
      _maybeFetchMore(idx);
    }
    onPersistNeeded?.call();
  }

  Future<void> _maybeFetchMore(int index) async {
    final fetchMore = _fetchMore;
    if (fetchMore == null || _fetchingMore || _isFmMode) return;
    if (_totalCount > 0 && _songQueue.length >= _totalCount) return;
    if (index < _songQueue.length - 3) return;

    _fetchingMore = true;
    try {
      final existingIds = _songQueue.map((s) => s.id).toSet();
      final more = await fetchMore(_fetchOffset, 30);
      _fetchOffset += more.length;
      final fresh = more.where((s) => !existingIds.contains(s.id)).toList();
      if (fresh.isEmpty) return;

      await _batchResolve(fresh);
      var added = false;
      for (final s in fresh) {
        final src = _buildSource(s);
        if (src != null) {
          await _player.addAudioSource(src);
          _songQueue.add(s);
          added = true;
        }
      }
      if (added) {
        _songQueueController.add(List.unmodifiable(_songQueue));
        _pushQueueToMediaSession();
      }
    } catch (_) {
      // 后台扩展失败不打断当前播放。
    } finally {
      _fetchingMore = false;
    }
  }

  /// 仅重建控件（不改变播放状态），用于喜欢状态变化后刷新通知栏图标。
  void _rebuildControls() {
    playbackState.add(
      playbackState.value.copyWith(
        controls: _buildControls(),
        androidCompactActionIndices: const [1, 2, 3],
      ),
    );
  }

  /// 构建通知栏 5 按钮。
  ///
  /// 喜欢按钮使用 fastForward（喜欢）/ rewind（取消喜欢），
  /// 图标按 `mediaItem.extras['liked']` 在实心/空心之间切换。
  List<MediaControl> _buildControls({bool? isPlaying}) {
    final playing = isPlaying ?? playbackState.value.playing;
    final liked = mediaItem.value?.extras?['liked'] == true;

    return [
      MediaControl(
        androidIcon: liked
            ? 'drawable/ic_heart_filled'
            : 'drawable/ic_heart_outlined',
        label: liked ? '取消喜欢' : '喜欢',
        action: liked ? MediaAction.rewind : MediaAction.fastForward,
      ),
      MediaControl.skipToPrevious,
      if (playing) MediaControl.pause else MediaControl.play,
      MediaControl.skipToNext,
      MediaControl.stop,
    ];
  }

  AudioProcessingState _mapState(ProcessingState s) {
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
    final liked = _likedSongIds.contains(song.id);
    return MediaItem(
      id: song.id.toString(),
      title: song.name,
      artist: song.artist.isNotEmpty ? song.artist : '未知歌手',
      album: song.album,
      artUri: song.coverUrl.isEmpty ? null : Uri.tryParse(song.coverThumb(512)),
      duration: song.duration,
      extras: {'liked': liked},
    );
  }

  void _cacheSong(Song song) {
    final url = _resolvedUrls[song.id];
    if (url != null && url.isNotEmpty) {
      CacheService.instance.download(
        url,
        song.id,
        ext: _resolvedExt[song.id] ?? 'mp3',
      );
    }
  }

  void _pushQueueToMediaSession() {
    // ignore: invalid_use_of_protected_member
    queue.add(_songQueue.map(_songToMediaItem).toList());
  }

  Song? get currentSong {
    final idx = _player.currentIndex;
    if (idx != null && idx >= 0 && idx < _songQueue.length) {
      return _songQueue[idx];
    }
    return null;
  }

  // ═════════════════════════════════════════════════════════════
  // audio_service 标准方法重写
  // ═════════════════════════════════════════════════════════════

  @override
  Future<void> play() => toggle();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    _player.stop();
    await super.stop();
  }

  @override
  Future<void> onTaskRemoved() async {
    _player.stop();
    _player.dispose();
    return super.onTaskRemoved();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() => next();

  @override
  Future<void> skipToPrevious() => previous();

  @override
  Future<void> skipToQueueItem(int index) => playAt(index);

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    switch (repeatMode) {
      case AudioServiceRepeatMode.none:
        await _player.setLoopMode(LoopMode.off);
        break;
      case AudioServiceRepeatMode.one:
        await _player.setLoopMode(LoopMode.one);
        break;
      case AudioServiceRepeatMode.group:
      case AudioServiceRepeatMode.all:
        await _player.setLoopMode(LoopMode.all);
        break;
    }
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    await setShuffle(
      shuffleMode == AudioServiceShuffleMode.all ||
          shuffleMode == AudioServiceShuffleMode.group,
    );
  }

  // ── 喜欢按钮：标准 fastForward / rewind ──

  @override
  Future<void> fastForward() async {
    final song = currentSong;
    if (song != null) {
      _likedSongIds.add(song.id);
      onLikeSong?.call(song.id, true);
      _updateMediaItemLiked(true);
      _rebuildControls();
    }
  }

  @override
  Future<void> rewind() async {
    final song = currentSong;
    if (song != null) {
      _likedSongIds.remove(song.id);
      onLikeSong?.call(song.id, false);
      _updateMediaItemLiked(false);
      _rebuildControls();
    }
  }

  void _updateMediaItemLiked(bool liked) {
    final item = mediaItem.value;
    if (item != null && item.id != 'placeholder') {
      final extras = Map<String, dynamic>.from(item.extras ?? {});
      extras['liked'] = liked;
      mediaItem.add(item.copyWith(extras: extras));
    }
  }

  // ═════════════════════════════════════════════════════════════
  // 私人 FM（简化版：移除双缓冲预取，批量拉取后队列播放）
  // ═════════════════════════════════════════════════════════════

  /// 启动 FM：拉取推荐 → 并行 songDetail + songUrl → 优先用完整元数据播放。
  ///
  /// songDetail 和 songUrl 同时发起。songUrl 是出声的必要条件，songDetail
  /// 提供封面/歌手等完整元数据。由于两者并发执行，songDetail 常在 songUrl
  /// 之前或同时返回——此时直接用完整元数据构建队列，避免 FM 原始数据缺少
  /// 封面/歌手导致的 UI 闪烁（"未知歌手"→真实歌手 的跳变）。
  ///
  /// 若 songDetail 确实慢于 songUrl，则退化到 FM 原始数据先行播放，
  /// 后台等 songDetail 完成后静默更新（与旧行为一致）。
  Future<bool> startFm() async {
    if (_fmLoading) return false;
    _fmLoading = true;

    try {
      // 1. 拉取 FM 推荐
      final fmRes = await MusicManager().personalFm();
      final data = fmRes?.data;
      if (data == null || data.isEmpty) return false;
      final ids = data.map((d) => d.id ?? 0).where((id) => id > 0).toList();
      if (ids.isEmpty) return false;

      _resolvedUrls.clear();
      _resolvedExt.clear();

      // 2. 并行启动 songDetail 和 songUrl（future 创建即开始执行）
      final strIds = ids.map((id) => id.toString()).toList();

      // 用标志位捕获 songDetail 结果，避免二次 await
      bool detailDone = false;
      SongDetailEntity? detailResult;
      final detailFuture = MusicManager()
          .songDetail(ids: ids)
          .then((r) { detailDone = true; detailResult = r; return r; });

      final urlFuture = MusicManager().songUrl(ids: strIds, level: level);

      // 3. 只等 songUrl —— 流媒体 URL 一到就可以出声
      final urlRes = await urlFuture;
      if (urlRes != null) {
        final urlData = urlRes.data ?? [];
        for (final d in urlData) {
          if (d.id != null && d.url != null && d.url!.isNotEmpty) {
            final type = (d.type ?? 'mp3').toLowerCase();
            _resolvedUrls[d.id!] = d.url!;
            _resolvedExt[d.id!] = type.isEmpty ? 'mp3' : type;
          }
        }
      }

      // 4. 构建 Song 列表：songDetail 已完成则用完整元数据，否则用 FM 原始数据
      final bool useDetail = detailDone &&
          detailResult != null &&
          detailResult!.songs != null &&
          detailResult!.songs!.isNotEmpty;

      final List<Song> songs;
      if (useDetail) {
        songs = detailResult!.songs!
            .map((s) => Song.fromSongDetail(s))
            .where((s) => s.id > 0)
            .toList();
      } else {
        songs = data
            .map((d) => _songFromFmData(d))
            .where((s) => s.id > 0)
            .toList();
      }
      if (songs.isEmpty) return false;

      // 5. 构建 AudioSource + 播放
      final sources = <AudioSource>[];
      for (final s in songs) {
        final src = _buildSource(s);
        if (src != null) sources.add(src);
      }
      if (sources.isEmpty) return false;

      _isFmMode = true;
      _fmCurrentTrack = songs.first;
      _player.setLoopMode(LoopMode.off);

      _songQueue = songs;
      _songQueueController.add(List.unmodifiable(_songQueue));
      _pushQueueToMediaSession();
      mediaItem.add(_songToMediaItem(songs.first));

      await _player.setAudioSources(
        sources,
        initialIndex: 0,
        initialPosition: Duration.zero,
      );
      _player.play();
      _cacheSong(songs.first);

      // 6. 仅当 songDetail 尚未完成时才后台更新元数据
      if (!useDetail) {
        _updateFmMetadata(detailFuture, songs.first.id);
      }

      return true;
    } catch (_) {
      _isFmMode = false;
      return false;
    } finally {
      _fmLoading = false;
    }
  }

  /// 后台等待 [detailFuture] 完成，用 songDetail 的完整元数据替换队列中
  /// 由 FM 原始数据构建的 Song，并同步通知栏 + UI。
  ///
  /// 通过 songQueueStream 触发 Provider 更新；Provider 侧已改为引用比较
  /// 而非长度比较，所以相同长度 / 相同 ID 的元数据替换也会被 UI 消费。
  void _updateFmMetadata(
    Future<SongDetailEntity?> detailFuture,
    int currentId,
  ) {
    detailFuture
        .then((detailRes) {
          if (detailRes == null ||
              detailRes.songs == null ||
              detailRes.songs!.isEmpty) {
            return;
          }
          final complete = detailRes.songs!
              .map((s) => Song.fromSongDetail(s))
              .where((s) => s.id > 0)
              .toList();
          if (complete.isEmpty) return;

          _songQueue = complete;
          _fmCurrentTrack = complete.firstWhere(
            (s) => s.id == currentId,
            orElse: () => complete.first,
          );
          _songQueueController.add(List.unmodifiable(_songQueue));
          _pushQueueToMediaSession();
          mediaItem.add(_songToMediaItem(_fmCurrentTrack!));
        })
        .catchError((_) {
          // songDetail 失败不影响播放，保留 FM 原始数据
        });
  }

  /// FM 下一首：队列内还有歌就切过去，否则拉取新一批。
  ///
  /// 队列耗尽时不再调用
  /// [AudioPlayer.setAudioSources] 重建整个音频树，而是通过
  /// [AudioPlayer.addAudioSource] 增量追加 + [AudioPlayer.seekToNext]
  /// 无缝过渡到新批次，避免重建导致的播放间隙。
  Future<bool> nextFm() async {
    if (!_isFmMode || _fmLoading) return false;

    final curIdx = _player.currentIndex ?? 0;
    if (curIdx + 1 < _songQueue.length) {
      await _player.seekToNext();
      return true;
    }

    // 队列耗尽 — 增量扩展，不重建播放器
    _fmLoading = true;
    try {
      // 1. FM 推荐
      final fmRes = await MusicManager().personalFm();
      final data = fmRes?.data;
      if (data == null || data.isEmpty) return false;
      final ids = data.map((d) => d.id ?? 0).where((id) => id > 0).toList();
      if (ids.isEmpty) return false;

      // 2. 并行获取元数据 + URL（先等关键路径 urlFuture，detail 通常同步完成）
      final strIds = ids.map((id) => id.toString()).toList();
      final detailFuture = MusicManager().songDetail(ids: ids);
      final urlFuture = MusicManager().songUrl(ids: strIds, level: level);
      final urlRes = await urlFuture;
      final detailRes = await detailFuture;

      // 3. 构建 Song 列表
      List<Song> songs;
      if (detailRes != null &&
          detailRes.songs != null &&
          detailRes.songs!.isNotEmpty) {
        songs = detailRes.songs!
            .map((s) => Song.fromSongDetail(s))
            .where((s) => s.id > 0)
            .toList();
      } else {
        songs = data
            .map((d) => _songFromFmData(d))
            .where((s) => s.id > 0)
            .toList();
      }
      if (songs.isEmpty) return false;

      // 4. 缓存 URL
      if (urlRes != null) {
        final urlData = (urlRes).data ?? [];
        for (final d in urlData) {
          if (d.id != null && d.url != null && (d.url!).isNotEmpty) {
            final type = (d.type ?? 'mp3').toLowerCase();
            _resolvedUrls[d.id!] = d.url!;
            _resolvedExt[d.id!] = type.isEmpty ? 'mp3' : type;
          }
        }
      }

      // 5. 逐个追加到现有队列末尾（避免 setAudioSources 造成的间隙）
      int added = 0;
      for (final s in songs) {
        final src = _buildSource(s);
        if (src != null) {
          await _player.addAudioSource(src);
          _songQueue.add(s);
          added++;
        }
      }
      if (added == 0) return false;

      _fmCurrentTrack = songs.first;

      // 切到第一首新歌
      await _player.seekToNext();

      // 清理已播放的前半段，防止队列无限膨胀
      // （seekToNext 后 currentIndex 指向新批次第一首，移除其之前的所有旧条目）
      final newCurIdx = _player.currentIndex ?? 0;
      for (var i = 0; i < newCurIdx; i++) {
        await _player.removeAudioSourceAt(0);
        _songQueue.removeAt(0);
      }

      _songQueueController.add(List.unmodifiable(_songQueue));
      _pushQueueToMediaSession();
      _cacheSong(songs.first);
      return true;
    } catch (_) {
      return false;
    } finally {
      _fmLoading = false;
    }
  }

  /// FM 垃圾桶：跳过当前并标记为不喜欢。
  Future<void> trashFm() async {
    if (!_isFmMode) return;
    final currentId = _fmCurrentTrack?.id;
    final moved = await nextFm();
    if (moved && currentId != null) {
      MusicManager().fmTrash(id: currentId);
    }
  }

  void exitFmMode() {
    _isFmMode = false;
    _fmCurrentTrack = null;
  }

  /// 从 [PersonalFmData] 构建 [Song]（兜底路径）。
  Song _songFromFmData(PersonalFmData d) {
    final ar = d.ar ?? [];
    final artists = ar
        .map((a) => a.name ?? '')
        .where((n) => n.isNotEmpty)
        .join(' / ');
    final rawUrl = d.al?.picUrl ?? '';
    // http:// 强制转 https://，避免网易云 CDN 返回 403
    final coverUrl = rawUrl.startsWith('http://')
        ? rawUrl.replaceFirst('http://', 'https://')
        : rawUrl;
    return Song(
      id: d.id ?? 0,
      name: d.name ?? '',
      artist: artists,
      artistIds: ar.map((a) => a.id ?? 0).where((id) => id > 0).toList(),
      album: d.al?.name ?? '',
      coverUrl: coverUrl,
      durationMs: d.dt ?? 0,
      fee: d.fee ?? 0,
    );
  }
}
