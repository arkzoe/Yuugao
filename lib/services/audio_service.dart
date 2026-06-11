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

  /// 当前队列（与播放器 audio source 顺序一致）
  List<Song> _queue = [];
  List<Song> get queue => List.unmodifiable(_queue);

  /// 已解析的播放直链，songId -> url。仅用于对"当前播放"这一首做后台缓存，
  /// 避免对整个队列发起下载导致磁盘暴涨。
  final Map<int, String> _resolvedUrls = {};
  final Map<int, String> _resolvedExt = {};

  // exhigh(约 320kbps) 体积约为 lossless flac 的 1/4，默认走它即可。
  String _level = 'exhigh';
  set level(String v) => _level = v;

  // 暴露给 provider 的流
  Stream<Duration> get positionStream => player.positionStream;
  Stream<Duration?> get durationStream => player.durationStream;
  Stream<PlayerState> get playerStateStream => player.playerStateStream;
  Stream<int?> get currentIndexStream => player.currentIndexStream;

  /// 只缓存"正在播放"的那一首，而不是整个队列。
  void _bindCaching() {
    player.currentIndexStream.listen((idx) {
      if (idx == null || idx < 0 || idx >= _queue.length) return;
      final song = _queue[idx];
      final url = _resolvedUrls[song.id];
      if (url == null || url.isEmpty) return;
      CacheService.instance
          .download(url, song.id, ext: _resolvedExt[song.id] ?? 'mp3');
    });
  }

  /// 用队列替换并从 [initialIndex] 开始播放。
  Future<void> setQueue(List<Song> songs, {int initialIndex = 0}) async {
    _queue = List.of(songs);
    _resolvedUrls.clear();
    _resolvedExt.clear();
    final sources = <AudioSource>[];
    for (final s in _queue) {
      final src = await _buildSource(s);
      if (src != null) sources.add(src);
    }
    if (sources.isEmpty) return;
    await player.setAudioSources(
      sources,
      initialIndex: initialIndex.clamp(0, sources.length - 1),
      initialPosition: Duration.zero,
    );
    player.play();
  }

  /// 构建单个音频源：命中缓存用本地文件，否则取流式 url。
  /// 注意：这里**不**触发下载，缓存只针对当前播放曲目（见 [_bindCaching]）。
  Future<AudioSource?> _buildSource(Song song) async {
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

    // songUrl 接口收 List<String>
    final res = await BujuanMusicManager().songUrl(
      ids: [song.id.toString()],
      level: _level,
    );
    final data = (res?.data ?? []);
    if (data.isEmpty) return null;
    final url = data.first.url ?? '';
    if (url.isEmpty) return null; // 无版权 / 付费不可播

    // 记录直链，留待"当前播放"时再缓存这一首。
    final type = (data.first.type ?? 'mp3').toLowerCase();
    _resolvedUrls[song.id] = url;
    _resolvedExt[song.id] = type.isEmpty ? 'mp3' : type;

    return AudioSource.uri(Uri.parse(url), tag: tag);
  }

  Future<void> playAt(int index) async {
    if (index < 0 || index >= _queue.length) return;
    await player.seek(Duration.zero, index: index);
    player.play();
  }

  Future<void> toggle() async {
    if (player.playing) {
      await player.pause();
    } else {
      player.play();
    }
  }

  Future<void> next() => player.seekToNext();
  Future<void> previous() => player.seekToPrevious();
  Future<void> seek(Duration pos) => player.seek(pos);

  Future<void> setLoopMode(LoopMode mode) => player.setLoopMode(mode);
  Future<void> setShuffle(bool enabled) async {
    if (enabled) await player.shuffle();
    await player.setShuffleModeEnabled(enabled);
  }

  /// 在当前队列末尾追加并立即跳转（用于 FM "下一首"）。
  Future<void> appendAndPlay(Song song) async {
    final src = await _buildSource(song);
    if (src == null) return;
    _queue.add(song);
    await player.addAudioSource(src);
    await playAt(_queue.length - 1);
  }

  void dispose() {
    player.dispose();
  }
}
