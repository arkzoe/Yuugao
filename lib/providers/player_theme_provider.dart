import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yuugao/providers/palette_provider.dart';
import 'package:yuugao/providers/settings_provider.dart';

/// 播放器专用色板 — 由封面取色驱动，无结果时回退到静态主题色。
class PlayerThemeColors {
  final Color background;
  final Color surface;
  final Color accent;
  final Color onBackground;
  final Color subtitle;
  final Color divider;

  const PlayerThemeColors({
    required this.background,
    required this.surface,
    required this.accent,
    required this.onBackground,
    required this.subtitle,
    required this.divider,
  });

  /// 从封面色板构建。
  factory PlayerThemeColors.fromPalette(SongPalette p, ThemeMode mode) {
    final isDark = mode == ThemeMode.dark;
    final baseBg = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5);
    final baseSurface =
        isDark ? const Color(0xFF2A2A2A) : const Color(0xFFFFFFFF);

    // 背景融入封面主色 8%（暗）/ 5%（亮）
    final background = Color.alphaBlend(
      p.dominant.withValues(alpha: isDark ? 0.08 : 0.05),
      baseBg,
    );

    // 卡片融入柔和色
    final surface = Color.alphaBlend(
      p.safeMuted.withValues(alpha: 0.10),
      baseSurface,
    );

    // 根据 dominant 明度选文字色
    final onBg =
        p.isDark ? const Color(0xFFE8E8E8) : const Color(0xFF1A1A1A);
    final sub =
        p.isDark ? const Color(0xFF9A9A9A) : const Color(0xFF666666);

    final divider =
        isDark ? const Color(0xFF333333) : const Color(0xFFE0E0E0);

    return PlayerThemeColors(
      background: background,
      surface: surface,
      accent: p.safeVibrant,
      onBackground: onBg,
      subtitle: sub,
      divider: divider,
    );
  }

  /// 无封面取色时的静态回退。
  factory PlayerThemeColors.fallback(ThemeMode mode) {
    final isDark = mode == ThemeMode.dark;
    return PlayerThemeColors(
      background: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5),
      surface: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFFFFFFF),
      accent: const Color(0xFFC3473A),
      onBackground:
          isDark ? const Color(0xFFE8E8E8) : const Color(0xFF1A1A1A),
      subtitle: isDark ? const Color(0xFF9A9A9A) : const Color(0xFF666666),
      divider: isDark ? const Color(0xFF333333) : const Color(0xFFE0E0E0),
    );
  }
}

/// 播放器页面使用的主题色 provider。
final playerThemeProvider = Provider<PlayerThemeColors>((ref) {
  final palette = ref.watch(playerPaletteProvider);
  final mode = ref.watch(settingsProvider.select((s) => s.themeMode));
  if (palette != null) {
    return PlayerThemeColors.fromPalette(palette, mode);
  }
  return PlayerThemeColors.fallback(mode);
});
