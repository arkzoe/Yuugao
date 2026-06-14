import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 主题感知色板 — 替代硬编码 AppColors，在深浅切换时自动更新。
class ThemeColors {
  final Color primary;
  final Color background;
  final Color card;
  final Color textPrimary;
  final Color textSecondary;
  final Color divider;

  const ThemeColors({
    required this.primary,
    required this.background,
    required this.card,
    required this.textPrimary,
    required this.textSecondary,
    required this.divider,
  });

  static const dark = ThemeColors(
    primary: Color(0xFFC3473A),
    background: Color(0xFF1A1A1A),
    card: Color(0xFF2A2A2A),
    textPrimary: Color(0xFFE8E8E8),
    textSecondary: Color(0xFF9A9A9A),
    divider: Color(0xFF333333),
  );

  static const light = ThemeColors(
    primary: Color(0xFFC3473A),
    background: Color(0xFFF5F5F5),
    card: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF1A1A1A),
    textSecondary: Color(0xFF666666),
    divider: Color(0xFFE0E0E0),
  );
}

/// 根据当前主题模式返回对应的色板，任何 watcher 都会在切换时自动重建。
final currentColorsProvider = Provider<ThemeColors>((ref) {
  final mode = ref.watch(settingsProvider.select((s) => s.themeMode));
  return mode == ThemeMode.dark ? ThemeColors.dark : ThemeColors.light;
});

const _themePrefsKey = 'theme_mode';

class SettingsState {
  final ThemeMode themeMode;

  const SettingsState({this.themeMode = ThemeMode.light});

  SettingsState copyWith({ThemeMode? themeMode}) {
    return SettingsState(themeMode: themeMode ?? this.themeMode);
  }
}

class SettingsNotifier extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    // 异步加载持久化的主题设置，初始默认浅色
    _loadPersistedTheme();
    return const SettingsState();
  }

  Future<void> _loadPersistedTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_themePrefsKey);
    if (stored != null) {
      final mode = stored == 'dark' ? ThemeMode.dark : ThemeMode.light;
      state = state.copyWith(themeMode: mode);
    }
  }

  Future<void> toggleTheme() async {
    final next =
        state.themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    state = state.copyWith(themeMode: next);

    // 持久化
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _themePrefsKey,
      next == ThemeMode.dark ? 'dark' : 'light',
    );
  }
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, SettingsState>(SettingsNotifier.new);
