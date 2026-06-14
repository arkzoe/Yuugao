import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// 元数据缓存：轻量级 JSON 文件缓存，用于歌曲详情、歌词、专辑信息。
///
/// 缓存目录: `<docs>/metadata_cache/`
/// 文件命名: `{type}_{id}.json`
/// TTL: 歌曲详情 24h, 歌词 7d, 专辑 7d
///
/// 使用 Cache-First + Network-Update 模式：
/// 先返回缓存数据（即时渲染），后台请求最新数据并更新缓存。
class MetadataCacheService {
  MetadataCacheService._();
  static final MetadataCacheService instance = MetadataCacheService._();

  static const _ttlTrackDetail = Duration(hours: 24);
  static const _ttlLyric = Duration(days: 7);
  static const _ttlAlbum = Duration(days: 7);

  late Directory _cacheDir;
  bool _ready = false;

  /// 启动时调用：建立缓存目录。
  Future<void> init() async {
    if (_ready) return;
    final docs = await getApplicationDocumentsDirectory();
    _cacheDir = Directory('${docs.path}/metadata_cache');
    if (!await _cacheDir.exists()) {
      await _cacheDir.create(recursive: true);
    }
    _ready = true;
  }

  // ── 歌曲详情 ──

  Future<Map<String, dynamic>?> getTrackDetail(int songId) async {
    return _read('track', songId.toString(), _ttlTrackDetail);
  }

  Future<void> cacheTrackDetail(int songId, Map<String, dynamic> data) async {
    await _write('track', songId.toString(), data);
  }

  // ── 歌词 ──

  Future<Map<String, dynamic>?> getLyric(int songId) async {
    return _read('lyric', songId.toString(), _ttlLyric);
  }

  Future<void> cacheLyric(int songId, Map<String, dynamic> data) async {
    await _write('lyric', songId.toString(), data);
  }

  // ── 专辑 ──

  Future<Map<String, dynamic>?> getAlbum(int albumId) async {
    return _read('album', albumId.toString(), _ttlAlbum);
  }

  Future<void> cacheAlbum(int albumId, Map<String, dynamic> data) async {
    await _write('album', albumId.toString(), data);
  }

  // ── 通用 ──

  Future<void> remove(String type, String id) async {
    final file = File('${_cacheDir.path}/${type}_$id.json');
    if (await file.exists()) await file.delete();
  }

  Future<void> clearAll() async {
    if (await _cacheDir.exists()) {
      await for (final entity in _cacheDir.list()) {
        if (entity is File) await entity.delete();
      }
    }
  }

  Future<Map<String, dynamic>?> _read(
    String type,
    String id,
    Duration ttl,
  ) async {
    if (!_ready) return null;
    try {
      final file = File('${_cacheDir.path}/${type}_$id.json');
      if (!await file.exists()) return null;

      // TTL 检查
      final modified = await file.lastModified();
      if (DateTime.now().difference(modified) > ttl) {
        await file.delete();
        return null;
      }

      final raw = await file.readAsString();
      if (raw.trim().isEmpty) return null;
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> _write(String type, String id, Map<String, dynamic> data) async {
    if (!_ready) return;
    try {
      final file = File('${_cacheDir.path}/${type}_$id.json');
      await file.writeAsString(jsonEncode(data));
    } catch (_) {
      // 写入失败静默忽略
    }
  }
}
