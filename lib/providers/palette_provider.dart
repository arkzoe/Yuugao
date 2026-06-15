import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette_generator_master/palette_generator_master.dart';

import 'package:yuugao/models/song.dart';
import 'package:yuugao/providers/player_provider.dart';

/// 从封面提取的色板 — 6 个语义化色槽。
class SongPalette {
  final Color dominant;
  final Color? vibrant;
  final Color? lightVibrant;
  final Color? darkVibrant;
  final Color? muted;
  final Color? lightMuted;
  final Color? darkMuted;

  const SongPalette({
    required this.dominant,
    this.vibrant,
    this.lightVibrant,
    this.darkVibrant,
    this.muted,
    this.lightMuted,
    this.darkMuted,
  });

  factory SongPalette.fromGenerator(PaletteGeneratorMaster g) {
    return SongPalette(
      dominant: g.dominantColor?.color ?? Colors.grey,
      vibrant: g.vibrantColor?.color,
      lightVibrant: g.lightVibrantColor?.color,
      darkVibrant: g.darkVibrantColor?.color,
      muted: g.mutedColor?.color,
      lightMuted: g.lightMutedColor?.color,
      darkMuted: g.darkMutedColor?.color,
    );
  }

  /// dominant 偏暗时返回 true，用于决定叠加文字用白/黑。
  bool get isDark => dominant.computeLuminance() < 0.5;

  /// 回退链：vibrant → dominant
  Color get safeVibrant => vibrant ?? dominant;

  /// 回退链：muted → dominant
  Color get safeMuted => muted ?? dominant;
}

/// 管理当前歌曲封面的取色状态。
/// 按 song.id 缓存，避免重复计算；带代次守卫防止旧结果覆盖。
///
/// 缓存上限 20 条，超出后淘汰最旧的条目，防止长时间 session 内存膨胀。
class PaletteNotifier extends Notifier<SongPalette?> {
  final Map<int, SongPalette> _cache = {};
  static const int _maxCacheSize = 20;
  int _pendingId = -1;

  @override
  SongPalette? build() {
    // 监听歌曲切换，自动取色
    ref.listen(playerProvider.select((s) => s.current), (prev, next) {
      if (next != null && next.id != prev?.id) {
        extract(next);
      }
    });
    // 已有歌曲时立即取色
    final current = ref.read(playerProvider.select((s) => s.current));
    if (current != null) extract(current);
    return null;
  }

  Future<void> extract(Song song) async {
    if (song.coverUrl.isEmpty) return;
    if (_cache.containsKey(song.id)) {
      state = _cache[song.id];
      return;
    }

    _pendingId = song.id;
    final safeUrl = song.coverUrl.startsWith('http://')
        ? song.coverUrl.replaceFirst('http://', 'https://')
        : song.coverUrl;
    // 使用 128px 缩略图即可，兼顾速度与准确性
    final thumbUrl = '$safeUrl?param=128y128';

    try {
      final palette = await PaletteGeneratorMaster.fromImageProvider(
        NetworkImage(thumbUrl),
        size: const Size(128, 128),
        maximumColorCount: 16,
        timeout: const Duration(seconds: 8),
      );

      if (_pendingId != song.id) return; // 代次守卫

      final sp = SongPalette.fromGenerator(palette);
      // LRU 淘汰：缓存超出上限时移除最旧条目
      if (_cache.length >= _maxCacheSize) {
        _cache.remove(_cache.keys.first);
      }
      _cache[song.id] = sp;
      state = sp;
    } catch (_) {
      // 取色失败静默，UI 回退 fallback
    }
  }
}

/// 全局播放器色板 provider。
final playerPaletteProvider =
    NotifierProvider<PaletteNotifier, SongPalette?>(PaletteNotifier.new);
