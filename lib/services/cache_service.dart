import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

/// 离线缓存：分块下载歌曲到内部存储，并以 cache_index.json 持久化索引。
///
/// 索引结构：
/// {
///   "version": 1,
///   "songs": { "songId": "文件名" }
/// }
class CacheService {
  CacheService._();
  static final CacheService instance = CacheService._();

  static const int _indexVersion = 1;

  /// 缓存上限：512MB。超过后按文件最后修改时间淘汰最旧的。
  static const int _maxCacheBytes = 512 * 1024 * 1024;

  final Dio _dio = Dio();
  final Map<int, String> _index = {}; // songId -> 文件名
  final Set<int> _downloading = {};

  late Directory _cacheDir;
  late File _indexFile;
  bool _ready = false;

  Map<int, String> get index => Map.unmodifiable(_index);

  /// 启动时调用：建立缓存目录并载入索引。
  Future<void> init() async {
    if (_ready) return;
    final docs = await getApplicationDocumentsDirectory();
    _cacheDir = Directory('${docs.path}/cache');
    if (!await _cacheDir.exists()) {
      await _cacheDir.create(recursive: true);
    }
    _indexFile = File('${docs.path}/cache_index.json');
    await _loadIndex();
    _ready = true;
  }

  Future<void> _loadIndex() async {
    try {
      if (!await _indexFile.exists()) return;
      final raw = await _indexFile.readAsString();
      if (raw.trim().isEmpty) return;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final songs = (map['songs'] as Map<String, dynamic>?) ?? {};
      _index.clear();
      songs.forEach((k, v) {
        final id = int.tryParse(k);
        if (id != null && v is String) _index[id] = v;
      });
    } catch (_) {
      // 索引损坏时忽略，从空索引重建
    }
  }

  Future<void> _saveIndex() async {
    final map = {
      'version': _indexVersion,
      'songs': _index.map((k, v) => MapEntry(k.toString(), v)),
    };
    await _indexFile.writeAsString(jsonEncode(map));
  }

  bool isCached(int songId) => _index.containsKey(songId);

  /// 返回本地完整路径；未缓存或文件丢失返回 null。
  String? getLocalPath(int songId) {
    final name = _index[songId];
    if (name == null) return null;
    final path = '${_cacheDir.path}/$name';
    if (!File(path).existsSync()) {
      // 文件被外部删除，清理索引
      _index.remove(songId);
      return null;
    }
    return path;
  }

  /// 后台下载并写入索引。已缓存或正在下载时直接跳过。
  Future<void> download(String url, int songId, {String ext = 'mp3'}) async {
    if (!_ready || url.isEmpty) return;
    if (isCached(songId) || _downloading.contains(songId)) return;
    _downloading.add(songId);
    final fileName = '$songId.$ext';
    final target = '${_cacheDir.path}/$fileName';
    try {
      await _dio.download(url, target);
      _index[songId] = fileName;
      await _saveIndex();
      await _enforceLimit();
    } catch (_) {
      // 下载失败：删除半成品
      final f = File(target);
      if (await f.exists()) await f.delete();
    } finally {
      _downloading.remove(songId);
    }
  }

  /// 缓存超过上限时，按最后修改时间从旧到新淘汰，直到回到上限以内。
  Future<void> _enforceLimit() async {
    if (!await _cacheDir.exists()) return;
    final files = <File>[];
    var total = 0;
    await for (final entity in _cacheDir.list()) {
      if (entity is File) {
        files.add(entity);
        total += await entity.length();
      }
    }
    if (total <= _maxCacheBytes) return;

    files.sort((a, b) =>
        a.statSync().modified.compareTo(b.statSync().modified));
    // 反查 文件名 -> songId，便于同步清理索引
    final nameToId = {for (final e in _index.entries) e.value: e.key};

    for (final f in files) {
      if (total <= _maxCacheBytes) break;
      final len = await f.length();
      final name = f.uri.pathSegments.last;
      try {
        await f.delete();
        total -= len;
        final id = nameToId[name];
        if (id != null) _index.remove(id);
      } catch (_) {}
    }
    await _saveIndex();
  }

  Future<void> remove(int songId) async {
    final name = _index.remove(songId);
    if (name != null) {
      final f = File('${_cacheDir.path}/$name');
      if (await f.exists()) await f.delete();
      await _saveIndex();
    }
  }

  Future<void> clearAll() async {
    _index.clear();
    await _saveIndex();
    if (await _cacheDir.exists()) {
      await for (final entity in _cacheDir.list()) {
        if (entity is File) await entity.delete();
      }
    }
  }

  /// 缓存占用字节数
  Future<int> cacheSize() async {
    var total = 0;
    if (await _cacheDir.exists()) {
      await for (final entity in _cacheDir.list()) {
        if (entity is File) total += await entity.length();
      }
    }
    return total;
  }
}
