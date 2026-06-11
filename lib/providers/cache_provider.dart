import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yuugao/services/cache_service.dart';

class CacheState {
  final Map<int, String> cachedSongs;
  final int sizeBytes;

  const CacheState({this.cachedSongs = const {}, this.sizeBytes = 0});

  CacheState copyWith({Map<int, String>? cachedSongs, int? sizeBytes}) {
    return CacheState(
      cachedSongs: cachedSongs ?? this.cachedSongs,
      sizeBytes: sizeBytes ?? this.sizeBytes,
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

class CacheNotifier extends StateNotifier<CacheState> {
  CacheNotifier() : super(const CacheState());

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
    StateNotifierProvider<CacheNotifier, CacheState>((ref) {
  return CacheNotifier();
});
