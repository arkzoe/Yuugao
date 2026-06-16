import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yuugao/services/cache_service.dart';

class CacheState {
  final Map<int, String> cachedSongs;
  final int sizeBytes;

  /// 当前活跃的下载进度：songId → 0.0..1.0
  final Map<int, double> downloadProgress;

  const CacheState({
    this.cachedSongs = const {},
    this.sizeBytes = 0,
    this.downloadProgress = const {},
  });

  CacheState copyWith({
    Map<int, String>? cachedSongs,
    int? sizeBytes,
    Map<int, double>? downloadProgress,
  }) {
    return CacheState(
      cachedSongs: cachedSongs ?? this.cachedSongs,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      downloadProgress: downloadProgress ?? this.downloadProgress,
    );
  }

  String get sizeLabel {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    if (sizeBytes < 1024 * 1024 * 1024) {
      return '${(sizeBytes / 1024 / 1024).toStringAsFixed(1)} MB';
    }
    return '${(sizeBytes / 1024 / 1024 / 1024).toStringAsFixed(2)} GB';
  }
}

class CacheNotifier extends Notifier<CacheState> {
  StreamSubscription<Map<int, double>>? _progressSub;

  @override
  CacheState build() {
    _progressSub = CacheService.instance.downloadProgressStream.listen(
      (progress) {
        state = state.copyWith(downloadProgress: progress);
      },
    );
    ref.onDispose(() => _progressSub?.cancel());
    return const CacheState();
  }

  final _service = CacheService.instance;

  Future<void> refresh() async {
    final size = await _service.cacheSize();
    state = state.copyWith(cachedSongs: _service.index, sizeBytes: size);
  }

  bool isCached(int songId) => _service.isCached(songId);

  Future<void> remove(int songId) async {
    await _service.remove(songId);
    await refresh();
  }

  Future<void> clearAll() async {
    await _service.clearAll();
    await refresh();
  }
}

final cacheProvider =
    NotifierProvider<CacheNotifier, CacheState>(CacheNotifier.new);
