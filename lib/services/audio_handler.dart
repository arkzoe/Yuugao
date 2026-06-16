import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

import 'package:yuugao/CloudMusic/yuugao.dart';
import 'package:yuugao/CloudMusic/api/fm/entity/personal_fm_entity.dart';
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

    await _batchResolve(songs);

    final sources = <AudioSource>[];
    for (final s in songs) {
      final src = _buildSource(s);
      if (src != null) sources.add(src);
    }
    if (sources.isEmpty) return;

    _songQueue = List.from(songs);
    _songQueueController.add(List.unmodifiable(_songQueue));

    final realIndex = index.clamp(0, sources.length - 1);

    await _player.setAudioSources(
      sources,
      initialIndex: realIndex,
      initialPosition: Duration.zero,
    );
    if (autoPlay) _player.play();

    _pushQueueToMediaSession();
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
      final ids = songs.sublist(i, end).map((s) => s.id.toString()).toList();
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
    }
    onPersistNeeded?.call();
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

  /// 启动 FM：拉取一批歌曲，批量解析 URL，构建队列并播放。
  Future<bool> startFm() async {
    if (_fmLoading) return false;
    _fmLoading = true;

    try {
      final songs = await _fetchFmSongs();
      if (songs.isEmpty) return false;

      await _batchResolve(songs);
      final sources = <AudioSource>[];
      for (final s in songs) {
        final src = _buildSource(s);
        if (src != null) sources.add(src);
      }
      if (sources.isEmpty) return false;

      _isFmMode = true;
      _fmCurrentTrack = songs.first;

      _resolvedUrls.clear();
      _resolvedExt.clear();

      _songQueue = songs;
      await _player.setAudioSources(
        sources,
        initialIndex: 0,
        initialPosition: Duration.zero,
      );
      _player.play();
      _songQueueController.add(List.unmodifiable(_songQueue));
      _pushQueueToMediaSession();
      _cacheSong(songs.first);
      return true;
    } catch (_) {
      _isFmMode = false;
      return false;
    } finally {
      _fmLoading = false;
    }
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
      final songs = await _fetchFmSongs();
      if (songs.isEmpty) return false;

      await _batchResolve(songs);

      // 逐个追加到现有队列末尾（避免 setAudioSources 造成的间隙）
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

  /// 拉取一批 FM 歌曲并转为 [Song] 列表。
  Future<List<Song>> _fetchFmSongs() async {
    final res = await MusicManager().personalFm();
    final data = res?.data;
    if (data == null || data.isEmpty) return [];
    return _fmIdsToSongs(data);
  }

  Future<List<Song>> _fmIdsToSongs(List<PersonalFmData> data) async {
    if (data.isEmpty) return [];
    final ids = data.map((d) => d.id ?? 0).where((id) => id > 0).toList();
    if (ids.isNotEmpty) {
      try {
        final detail = await MusicManager().songDetail(ids: ids);
        if (detail != null &&
            detail.songs != null &&
            detail.songs!.isNotEmpty) {
          return detail.songs!
              .map((s) => Song.fromSongDetail(s))
              .where((s) => s.id > 0)
              .toList();
        }
      } catch (_) {}
    }
    return data.map((d) => _songFromFmData(d)).where((s) => s.id > 0).toList();
  }

  Song _songFromFmData(PersonalFmData d) {
    final ar = d.ar ?? [];
    final artists = ar
        .map((a) => a.name ?? '')
        .where((n) => n.isNotEmpty)
        .join(' / ');
    return Song(
      id: d.id ?? 0,
      name: d.name ?? '',
      artist: artists,
      artistIds: ar.map((a) => a.id ?? 0).where((id) => id > 0).toList(),
      album: d.al?.name ?? '',
      coverUrl: d.al?.picUrl ?? '',
      durationMs: d.dt ?? 0,
      fee: d.fee ?? 0,
    );
  }
}
