import 'dart:async';

import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'package:yuugao/CloudMusic/yuugao.dart';
import 'package:yuugao/models/song.dart';
import 'package:yuugao/services/cache_service.dart';

/// just_audio 封装：负责把 [Song] 队列加载进播放器，
/// 优先使用本地缓存，否则流式播放并触发后台下载。
class AudioService {
  AudioService._() {
    _bindCaching();
  }
  static final AudioService instance = AudioService._();

  final AudioPlayer player = AudioPlayer();

  /// 当前可播队列（与播放器音频源一一对应，不含无版权/付费不可播的歌曲）
  List<Song> _queue = [];
  List<Song> get queue => List.unmodifiable(_queue);

  /// 在 setQueue / playAt 跃迁期间抑制 currentIndexStream 流向 UI，
  /// 避免 just_audio 中间态（index=0 等）导致的"闪烁第一首信息"。
  bool indexSuppressed = false;

  /// 队列变动通知流，用于 UI 同步（两阶段加载时队列会逐步扩展）。
  final _queueController = StreamController<List<Song>>.broadcast();
  Stream<List<Song>> get queueStream => _queueController.stream;

  final Map<int, String> _resolvedUrls = {};
  final Map<int, String> _resolvedExt = {};

  int _generation = 0;

  String _level = 'exhigh';
  set level(String v) => _level = v;

  Stream<Duration> get positionStream => player.positionStream;
  Stream<Duration?> get durationStream => player.durationStream;
  Stream<PlayerState> get playerStateStream => player.playerStateStream;
  Stream<int?> get currentIndexStream => player.currentIndexStream;

  /// 当前歌曲播放时后台下载本曲，同时预下载下一首。
  void _bindCaching() {
    player.currentIndexStream.listen((idx) {
      if (idx == null || idx < 0 || idx >= _queue.length) return;
      final song = _queue[idx];
      final url = _resolvedUrls[song.id];
      if (url != null && url.isNotEmpty) {
        CacheService.instance
            .download(url, song.id, ext: _resolvedExt[song.id] ?? 'mp3');
      }
      // 预缓存下一首（顺序播放时切歌零延迟）
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
    });
  }

  /// 用队列替换并从 [initialIndex] 开始播放。
  ///
  /// 单次 setAudioSources 原子操作：避免两阶段模式在 x86_64 模拟器上
  /// 频繁 insertAudioSource/addAudioSource 触发平台通道 buffer 损坏。
  /// URL 解析通过 priorityIndex 优先处理目标歌曲所在 chunk。
  Future<void> setQueue(List<Song> candidates, {int initialIndex = 0}) async {
    final gen = ++_generation;

    _resolvedUrls.clear();
    _resolvedExt.clear();
    if (candidates.isEmpty) return;

    final startIdx = initialIndex.clamp(0, candidates.length - 1);
    final target = candidates[startIdx];

    // 批量解析所有直链，目标歌曲所在 chunk 排最前
    await _batchResolve(candidates, priorityIndex: startIdx);
    if (gen != _generation) return;

    // 构建可播列表：_queue 与 sources 一一对应
    final sources = <AudioSource>[];
    _queue = [];
    for (final s in candidates) {
      final src = _buildSource(s);
      if (src != null) {
        sources.add(src);
        _queue.add(s);
      }
    }
    if (sources.isEmpty) return;

    var curIdx = _queue.indexWhere((s) => s.id == target.id);
    if (curIdx < 0) curIdx = 0;

    indexSuppressed = true;
    await player.setAudioSources(
      sources,
      initialIndex: curIdx,
      initialPosition: Duration.zero,
    );
    indexSuppressed = false;
    if (gen != _generation) return;
    player.play();

    _queueController.add(List.unmodifiable(_queue));
  }

  /// 批量解析直链，[priorityIndex] 所在 chunk 优先处理以缩短起播延迟。
  Future<void> _batchResolve(List<Song> songs, {int priorityIndex = 0}) async {
    const chunkSize = 100;
    final n = songs.length;
    if (n == 0) return;

    // 计算各 chunk 的起止位置，把 priorityIndex 所在 chunk 移到最前面
    final chunks = <({int start, int end})>[];
    for (var i = 0; i < n; i += chunkSize) {
      chunks.add((start: i, end: i + chunkSize < n ? i + chunkSize : n));
    }
    // 找到优先 chunk
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

    for (final ch in chunks) {
      final ids = <String>[];
      for (var i = ch.start; i < ch.end; i++) {
        ids.add(songs[i].id.toString());
      }
      final res = await BujuanMusicManager().songUrl(
        ids: ids,
        level: _level,
      );
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

  AudioSource? _buildSource(Song song) {
    final tag = MediaItem(
      id: song.id.toString(),
      title: song.name,
      artist: song.artist,
      album: song.album,
      artUri: song.coverUrl.isEmpty ? null : Uri.tryParse(song.coverUrl),
      duration: song.durationMs > 0 ? song.duration : null,
    );

    final localPath = CacheService.instance.getLocalPath(song.id);
    if (localPath != null) {
      return AudioSource.file(localPath, tag: tag);
    }

    final url = _resolvedUrls[song.id];
    if (url == null || url.isEmpty) return null;
    return AudioSource.uri(Uri.parse(url), tag: tag);
  }

  Future<void> playAt(int index) async {
    if (index < 0 || index >= _queue.length) return;
    indexSuppressed = true;
    await player.seek(Duration.zero, index: index);
    indexSuppressed = false;
    player.play();
  }

  Future<void> toggle() async {
    if (player.playing) {
      await player.pause();
    } else {
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
    if (enabled) await player.shuffle();
    await player.setShuffleModeEnabled(enabled);
  }

  Future<void> removeAt(int index) async {
    if (index < 0 || index >= _queue.length) return;
    _queue.removeAt(index);
    await player.removeAudioSourceAt(index);
    _queueController.add(List.unmodifiable(_queue));
  }

  Future<void> insertNext(Song song) async {
    if (_resolvedUrls[song.id] == null) {
      await _batchResolve([song]);
    }
    final src = _buildSource(song);
    if (src == null) return;

    final curIdx = player.currentIndex ?? 0;
    final insertAt = curIdx + 1;
    _queue.insert(insertAt, song);
    await player.insertAudioSource(insertAt, src);
    _queueController.add(List.unmodifiable(_queue));
  }

  Future<void> appendAndPlay(Song song) async {
    final src = _buildSource(song);
    if (src == null) {
      await _batchResolve([song]);
      final retry = _buildSource(song);
      if (retry == null) return;
      _queue.add(song);
      await player.addAudioSource(retry);
    } else {
      _queue.add(song);
      await player.addAudioSource(src);
    }
    await playAt(_queue.length - 1);
    _queueController.add(List.unmodifiable(_queue));
  }

  void dispose() {
    _queueController.close();
    player.dispose();
  }
}
