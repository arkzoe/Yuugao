import 'dart:async';

import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'package:yuugao/CloudMusic/yuugao.dart';
import 'package:yuugao/models/song.dart';
import 'package:yuugao/services/cache_service.dart';

/// 分页歌单加载回调：给定 [offset] 和 [limit]，返回下一页歌曲列表。
/// 返回空列表表示已无更多数据。
typedef SongFetcher = Future<List<Song>> Function(int offset, int limit);

/// just_audio 封装：负责把 [Song] 队列加载进播放器，
/// 优先使用本地缓存，否则流式播放并触发后台下载。
///
/// ## 请求策略
///
/// **就近窗口解析**：setQueue 时只解析目标歌曲 ±[_resolveWindow] 范围内的直链，
/// 起播后后台并行加载剩余歌曲，避免大歌单全量解析阻塞起播。
///
/// **URL 过期保护**：记录每首歌曲直链的 expi 过期时间；起播/切歌前校验，
/// 过期时自动重新解析。
///
/// **网络感知音质**：exhigh 解析大面积空结果时自动降级到 standard。
///
/// **随机模式缓存**：shuffle 时不预下载下一首（下一首随机，预下载白费流量）。
///
/// **串行操作守卫**：所有 player 平台通道调用通过 [_guard] 串行化，
/// 杜绝后台扩展与用户操作间的 Connection aborted 错误。
class AudioService {
  AudioService._() {
    _bindCaching();
  }
  static final AudioService instance = AudioService._();

  final AudioPlayer player = AudioPlayer();

  /// 当前可播队列（与播放器音频源一一对应，不含无版权/付费不可播的歌曲）。
  /// 初始仅包含窗口内歌曲，后台逐步扩展至全量。
  List<Song> _queue = [];
  List<Song> get queue => List.unmodifiable(_queue);

  /// 用户请求播放的全部候选歌曲，用于 URL 过期刷新时反查 Song 对象。
  List<Song> _fullCandidates = [];

  /// 在 setQueue / playAt 跃迁期间抑制 currentIndexStream 流向 UI，
  /// 避免 just_audio 中间态（index=0 等）导致的"闪烁第一首信息"。
  bool indexSuppressed = false;

  /// 队列变动通知流，用于 UI 同步（两阶段加载时队列会逐步扩展）。
  final _queueController = StreamController<List<Song>>.broadcast();
  Stream<List<Song>> get queueStream => _queueController.stream;

  /// 已解析的音频直链。
  final Map<int, String> _resolvedUrls = {};
  final Map<int, String> _resolvedExt = {};

  /// URL 过期记录：songId → 过期时刻（Unix 秒）。
  /// expi 通常为 1200（20 分钟），过期后 _buildSource 返回 null 并触发重新解析。
  final Map<int, int> _resolvedExpiry = {};

  /// 串行操作守卫：防止多个异步操作同时调用 player 平台通道。
  /// 所有 player 修改操作必须通过此 guard 执行。
  /// 利用 Dart 单线程特性实现简单 async mutex：等待上一操作完成，
  /// 然后执行自己的操作并设置回压，保证同一时刻只有一个通道调用在途。
  Future<void> _guard(Future<void> Function() op) async {
    if (_pendingOp != null) {
      try {
        await _pendingOp;
      } catch (_) {}
    }
    final fut = op();
    _pendingOp = fut;
    try {
      await fut;
    } finally {
      if (_pendingOp == fut) _pendingOp = null;
    }
  }

  Future<void>? _pendingOp;

  /// 后台扩充队列的代次（与 _generation 独立，仅用于取消旧扩充任务）。
  int _expandGen = 0;

  /// setQueue 代次守卫：防止快速切歌时旧的异步 setQueue 覆盖最新状态。
  int _generation = 0;

  /// 解析窗口半径：setQueue 时仅解析目标前后各 20 首，其余后台加载。
  static const int _resolveWindow = 20;

  /// 后台并行加载的并发上限。
  static const int _expandConcurrency = 2;

  /// 请求音质（可运行时切换）。
  String _level = 'exhigh';
  set level(String v) => _level = v;

  /// 当前实际生效的音质（网络自适应降级后可能与 _level 不同）。
  String _effectiveLevel = 'exhigh';

  /// 降级计数器：连续 exhigh 空结果 chunk 数。
  int _exhighEmptyChunks = 0;
  static const int _degradeThreshold = 2;

  /// 是否顺序播放（用于预下载策略：shuffle/repeatOne 时不预下载下一首）。
  bool _isSequential = true;

  /// 是否启用了随机播放（用于后台扩展后重新洗牌）。
  bool _shuffleEnabled = false;

  /// 分页歌单回调：当本地候选歌曲耗尽时，通过此回调拉取后续页。
  SongFetcher? _fetchMore;

  /// 歌单总歌曲数（由调用方传入，用于判断是否还有更多页）。
  int _playlistTotal = 0;

  /// 活跃队列上限：超出后从队首回收旧歌曲，保持内存友好。
  static const int _maxQueueSize = 200;

  /// 分页大小（与歌单详情页保持一致）。
  static const int _pageSize = 30;

  Stream<Duration> get positionStream => player.positionStream;
  Stream<Duration?> get durationStream => player.durationStream;
  Stream<PlayerState> get playerStateStream => player.playerStateStream;
  Stream<int?> get currentIndexStream => player.currentIndexStream;

  // ═════════════════════════════════════════════════════════════
  // 公开方法
  // ═════════════════════════════════════════════════════════════

  /// 用队列替换并从 [initialIndex] 开始播放。
  ///
  /// **单曲先行策略**：先解析目标歌曲直链 → 立即起播（仅 1 次 HTTP），
  /// 然后解析相邻窗口 → 塞入队列前后，最后后台扩展剩余歌曲。
  /// 无论歌曲在歌单哪个位置，起播延迟恒定为 1 次 songUrl 请求。
  ///
  /// 传入 [fetchMore] 回调后，当本地候选列表耗尽时自动分页拉取后续歌曲，
  /// 配合滑动窗口实现内存友好的超长歌单播放。
  /// [totalCount] 为歌单总歌曲数，用于判断是否还有更多页。
  Future<void> setQueue(
    List<Song> candidates, {
    int initialIndex = 0,
    SongFetcher? fetchMore,
    int totalCount = 0,
  }) async {
    final gen = ++_generation;
    _expandGen++; // 取消旧的扩充任务

    _resolvedUrls.clear();
    _resolvedExt.clear();
    _resolvedExpiry.clear();
    _fullCandidates = List.from(candidates);
    _fetchMore = fetchMore;
    _playlistTotal = totalCount > 0 ? totalCount : candidates.length;
    _effectiveLevel = _level;
    _exhighEmptyChunks = 0;

    if (candidates.isEmpty) return;

    final startIdx = initialIndex.clamp(0, candidates.length - 1);
    final target = candidates[startIdx];

    // ── 第 1 步：仅解析目标歌曲，立即起播（1 次 HTTP） ──
    await _batchResolve([target]);
    if (gen != _generation) return;

    final targetSrc = _buildSource(target);
    if (targetSrc == null) return;

    _queue = [target];

    indexSuppressed = true;
    try {
      await player.setAudioSources(
        [targetSrc],
        initialIndex: 0,
        initialPosition: Duration.zero,
      );
      indexSuppressed = false;
      if (gen != _generation) return;
      player.play();
    } catch (_) {
      indexSuppressed = false;
      return;
    }
    _queueController.add(List.unmodifiable(_queue));

    // ── 第 2 步：解析窗口邻居，塞入目标歌曲前后 ──
    final winStart = (startIdx - _resolveWindow).clamp(0, candidates.length);
    final winEnd =
        (startIdx + _resolveWindow + 1).clamp(0, candidates.length);
    final window = candidates.sublist(winStart, winEnd);

    // 邻居 = 窗口中除目标外的歌曲
    final targetInWindow = startIdx - winStart;
    final beforeTarget = window.sublist(0, targetInWindow);
    final afterTarget = window.sublist(targetInWindow + 1);
    final neighbors = [...beforeTarget, ...afterTarget];

    if (neighbors.isNotEmpty) {
      await _batchResolve(neighbors);
      if (gen != _generation) return;

      // 前邻居：倒序插入队首（每次 insert(0) 后后续插入位置自然正确）
      for (final s in beforeTarget.reversed) {
        final src = _buildSource(s);
        if (src != null) {
          _queue.insert(0, s);
          await _guard(() => player.insertAudioSource(0, src));
        }
      }

      // 后邻居：追加到队尾
      for (final s in afterTarget) {
        final src = _buildSource(s);
        if (src != null) {
          _queue.add(s);
          await _guard(() => player.addAudioSource(src));
        }
      }

      _queueController.add(List.unmodifiable(_queue));
    }

    // ── 第 3 步：后台扩展窗口之后的剩余歌曲 ──
    // 窗口之前的歌最多 20 首（窗口半径），用户可从歌单详情页重新点击。
    if (winEnd < candidates.length) {
      _expandForward(gen, candidates, winEnd, candidates.length);
    }
  }

  /// 在指定位置切歌（队列内操作，不走网络）。
  Future<void> playAt(int index) async {
    if (index < 0 || index >= _queue.length) return;

    // 校验目标歌曲 URL 是否过期
    final song = _queue[index];
    if (_isUrlExpired(song.id)) {
      await _refreshUrls([song.id]);
      final src = _buildSource(song);
      if (src != null) {
        await _guard(() async {
          await player.removeAudioSourceAt(index);
          await player.insertAudioSource(index, src);
        });
      }
    }

    indexSuppressed = true;
    try {
      await player.seek(Duration.zero, index: index);
    } catch (_) {}
    indexSuppressed = false;
    player.play();
  }

  Future<void> toggle() async {
    if (player.playing) {
      await player.pause();
    } else {
      // 恢复播放前校验当前歌曲 URL 是否过期
      final idx = player.currentIndex;
      if (idx != null && idx >= 0 && idx < _queue.length) {
        if (_isUrlExpired(_queue[idx].id)) {
          await _refreshUrls([_queue[idx].id]);
          final src = _buildSource(_queue[idx]);
          if (src != null) {
            await _guard(() async {
              await player.removeAudioSourceAt(idx);
              await player.insertAudioSource(idx, src);
            });
          }
        }
      }
      player.play();
    }
  }

  Future<void> next() async {
    indexSuppressed = true;
    await player.seekToNext();
    indexSuppressed = false;
  }

  Future<void> previous() async {
    indexSuppressed = true;
    await player.seekToPrevious();
    indexSuppressed = false;
  }

  Future<void> seek(Duration pos) => player.seek(pos);

  Future<void> setLoopMode(LoopMode mode) => player.setLoopMode(mode);

  Future<void> setShuffle(bool enabled) async {
    _shuffleEnabled = enabled;
    if (enabled) await player.shuffle();
    await player.setShuffleModeEnabled(enabled);
  }

  /// 更新播放模式（用于预下载策略：仅顺序模式预下载下一首）。
  void setPlayMode(bool sequential) => _isSequential = sequential;

  Future<void> removeAt(int index) async {
    if (index < 0 || index >= _queue.length) return;
    _queue.removeAt(index);
    await _guard(() => player.removeAudioSourceAt(index));
    _queueController.add(List.unmodifiable(_queue));
  }

  /// 在当前歌曲之后插入一首（下一首播放）。
  Future<void> insertNext(Song song) async {
    if (_resolvedUrls[song.id] == null) {
      await _batchResolve([song]);
    }
    final src = _buildSource(song);
    if (src == null) return;

    final curIdx = player.currentIndex ?? 0;
    final insertAt = curIdx + 1;
    _queue.insert(insertAt, song);
    await _guard(() => player.insertAudioSource(insertAt, src));
    _queueController.add(List.unmodifiable(_queue));
  }

  /// 追加到队尾并立即播放。
  Future<void> appendAndPlay(Song song) async {
    AudioSource? src = _buildSource(song);
    if (src == null) {
      await _batchResolve([song]);
      src = _buildSource(song);
    }
    if (src == null) return;
    _queue.add(song);
    await _guard(() => player.addAudioSource(src!));
    await playAt(_queue.length - 1);
    _queueController.add(List.unmodifiable(_queue));
  }

  void dispose() {
    _queueController.close();
    player.dispose();
  }

  // ═════════════════════════════════════════════════════════════
  // 内部：URL 解析
  // ═════════════════════════════════════════════════════════════

  /// 批量解析直链，[priorityIndex] 所在 chunk 优先处理以缩短起播延迟。
  ///
  /// 优先级 chunk 串行先发；其余 chunk 并行请求（上限 [_expandConcurrency]）。
  Future<void> _batchResolve(List<Song> songs, {int priorityIndex = 0}) async {
    const chunkSize = 30;
    final n = songs.length;
    if (n == 0) return;

    // 分块
    final chunks = <({int start, int end})>[];
    for (var i = 0; i < n; i += chunkSize) {
      chunks.add((start: i, end: i + chunkSize < n ? i + chunkSize : n));
    }

    // 优先 chunk 移到最前
    var prio = 0;
    for (var c = 0; c < chunks.length; c++) {
      if (priorityIndex >= chunks[c].start &&
          priorityIndex < chunks[c].end) {
        prio = c;
        break;
      }
    }
    if (prio != 0) {
      final tmp = chunks[prio];
      chunks.removeAt(prio);
      chunks.insert(0, tmp);
    }

    // 优先 chunk 先发（串行，确保起播 chunk 最先返回）
    await _resolveChunk(songs, chunks.first);

    // 其余 chunk 并行
    if (chunks.length > 1) {
      final rest = chunks.sublist(1);
      for (var i = 0; i < rest.length; i += _expandConcurrency) {
        final batch = rest.skip(i).take(_expandConcurrency).toList();
        await Future.wait(batch.map((ch) => _resolveChunk(songs, ch)));
      }
    }
  }

  /// 解析单个 chunk 的直链。
  Future<void> _resolveChunk(
    List<Song> songs,
    ({int start, int end}) ch,
  ) async {
    final ids = <String>[];
    for (var i = ch.start; i < ch.end; i++) {
      ids.add(songs[i].id.toString());
    }

    final res = await BujuanMusicManager().songUrl(
      ids: ids,
      level: _effectiveLevel,
    );
    final data = res?.data ?? [];

    // 网络自适应降级：exhigh 返回大面积空结果时降级到 standard
    if (_effectiveLevel == 'exhigh') {
      final validCount =
          data.where((d) => d.url != null && d.url!.isNotEmpty).length;
      if (validCount == 0 && ids.isNotEmpty) {
        _exhighEmptyChunks++;
        if (_exhighEmptyChunks >= _degradeThreshold) {
          _effectiveLevel = 'standard';
        }
      } else if (validCount > 0) {
        _exhighEmptyChunks = 0; // 有有效结果则重置
      }
    }

    final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    for (final d in data) {
      if (d.id != null && d.url != null && d.url!.isNotEmpty) {
        final type = (d.type ?? 'mp3').toLowerCase();
        _resolvedUrls[d.id!] = d.url!;
        _resolvedExt[d.id!] = type.isEmpty ? 'mp3' : type;
        // 记录过期时间（expi 为相对秒数）
        if (d.expi != null && d.expi! > 0) {
          _resolvedExpiry[d.id!] = nowSec + d.expi!;
        } else {
          _resolvedExpiry[d.id!] = nowSec + 1200; // 默认 20 分钟
        }
      }
    }
  }

  /// 检查某个 songId 的直链是否过期（提前 30 秒判定）。
  bool _isUrlExpired(int songId) {
    final expiry = _resolvedExpiry[songId];
    if (expiry == null) return false; // 未记录 → 不过期（容忍）
    final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return nowSec >= expiry - 30;
  }

  /// 重新解析指定歌曲的直链。
  Future<void> _refreshUrls(List<int> songIds) async {
    if (songIds.isEmpty) return;
    final songs = songIds
        .map((id) => _fullCandidates.cast<Song?>().firstWhere(
              (s) => s?.id == id,
              orElse: () => null,
            ))
        .whereType<Song>()
        .toList();
    if (songs.isEmpty) return;
    await _batchResolve(songs);
  }

  // ═════════════════════════════════════════════════════════════
  // 内部：队列扩展
  // ═════════════════════════════════════════════════════════════

  /// 后台扩展队列：从 [from] 偏移开始，持续解析并追加歌曲。
  ///
  /// 当本地 [candidates] 耗尽时，通过 [_fetchMore] 分页拉取后续歌曲。
  /// 每批追加后检查队列长度，超出 [_maxQueueSize] 时从队首回收旧歌。
  Future<void> _expandForward(
    int setGen,
    List<Song> candidates,
    int from,
    int to,
  ) async {
    final gen = _expandGen;
    const chunkSize = 30;

    // 确保 candidates 是可变列表（支持动态追加）
    final songs = List<Song>.from(candidates);
    var offset = from;
    var end = to;

    while (offset < end || (_fetchMore != null && songs.length < _playlistTotal)) {
      if (_generation != setGen || _expandGen != gen) return;

      // 若本地候选耗尽，尝试分页拉取
      if (offset >= songs.length && _fetchMore != null) {
        final fetched = await _fetchMore!(songs.length, _pageSize);
        if (fetched.isEmpty) break; // 无更多数据
        songs.addAll(fetched);
        _fullCandidates.addAll(fetched); // 同步更新全量候选，供 URL 过期刷新用
        end = songs.length;
      }

      if (offset >= songs.length) break;

      // 取当前批次（1-2 chunk 并行解析）
      final batchEnd = (offset + chunkSize * _expandConcurrency)
          .clamp(0, songs.length);
      final batch = <({int start, int end})>[];
      for (var i = offset; i < batchEnd; i += chunkSize) {
        batch.add((
          start: i,
          end: (i + chunkSize).clamp(0, batchEnd),
        ));
      }

      // 并行解析该批次的 URL
      await Future.wait(batch.map((ch) => _resolveChunk(songs, ch)));

      if (_generation != setGen || _expandGen != gen) return;

      // 逐个追加到队列（通过 guard 串行化平台通道调用）
      for (final ch in batch) {
        for (var j = ch.start; j < ch.end; j++) {
          final s = songs[j];
          final src = _buildSource(s);
          if (src != null) {
            _queue.add(s);
            await _guard(() => player.addAudioSource(src));
          }
        }
      }

      offset = batchEnd;

      // 随机模式下重新洗牌，将新加入的歌曲纳入随机序列
      if (_shuffleEnabled) {
        await _guard(() => player.shuffle());
      }

      // 滑动窗口回收：队列超出上限时从队首移除旧歌
      await _trimQueue();

      _queueController.add(List.unmodifiable(_queue));
    }
  }

  /// 滑动窗口回收：当队列超过 [_maxQueueSize] 时，
  /// 从队首移除已远去的歌曲（当前播放位置前 50 首之外的旧歌）。
  Future<void> _trimQueue() async {
    final curIdx = player.currentIndex ?? 0;
    const keepBefore = 50; // 当前歌曲前保留 50 首

    while (_queue.length > _maxQueueSize && curIdx > keepBefore) {
      // 移除队首第一首（最旧的）
      await _guard(() => player.removeAudioSourceAt(0));
      _queue.removeAt(0);
    }
  }

  // ═════════════════════════════════════════════════════════════
  // 内部：音频源构建
  // ═════════════════════════════════════════════════════════════

  /// 构建 [song] 的 AudioSource。
  ///
  /// 优先级：本地缓存 > 流式 URL（过期检查）> null（不可播）。
  AudioSource? _buildSource(Song song) {
    final tag = MediaItem(
      id: song.id.toString(),
      title: song.name,
      artist: song.artist,
      album: song.album,
      artUri: song.coverUrl.isEmpty ? null : Uri.tryParse(song.coverUrl),
      duration: song.durationMs > 0 ? song.duration : null,
    );

    // 第 1 优先：本地缓存
    final localPath = CacheService.instance.getLocalPath(song.id);
    if (localPath != null) {
      return AudioSource.file(localPath, tag: tag);
    }

    // 第 2 优先：已解析的流式 URL（检查过期）
    final url = _resolvedUrls[song.id];
    if (url == null || url.isEmpty || _isUrlExpired(song.id)) return null;
    return AudioSource.uri(Uri.parse(url), tag: tag);
  }

  // ═════════════════════════════════════════════════════════════
  // 内部：边播边存 + 预下载
  // ═════════════════════════════════════════════════════════════

  /// 当前歌曲播放时后台缓存本曲。
  /// 顺序播放时额外预缓存下一首（切歌零延迟）；
  /// 随机/单曲循环时仅缓存当前曲，避免无效预下载。
  void _bindCaching() {
    player.currentIndexStream.listen((idx) {
      if (idx == null || idx < 0 || idx >= _queue.length) return;
      final song = _queue[idx];
      final url = _resolvedUrls[song.id];
      if (url != null && url.isNotEmpty) {
        CacheService.instance
            .download(url, song.id, ext: _resolvedExt[song.id] ?? 'mp3');
      }

      // 预缓存下一首：仅顺序模式有效（shuffle 下一首随机，repeatOne 重复当前首）
      if (_isSequential) {
        final nextIdx = idx + 1;
        if (nextIdx < _queue.length) {
          final nextSong = _queue[nextIdx];
          final nextUrl = _resolvedUrls[nextSong.id];
          if (nextUrl != null && nextUrl.isNotEmpty) {
            CacheService.instance.download(
              nextUrl,
              nextSong.id,
              ext: _resolvedExt[nextSong.id] ?? 'mp3',
            );
          }
        }
      }
    });
  }
}
