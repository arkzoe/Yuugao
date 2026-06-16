import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:yuugao/services/audio_service.dart';

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
const _audioQualityKey = 'audio_quality';
const _defaultAudioQuality = 'exhigh';

class SettingsState {
  final ThemeMode themeMode;
  /// 睡眠定时器结束时刻（Unix 毫秒）；null 表示未启用
  final int? sleepTimerEndMs;
  /// 播放音质标识（standard, exhigh, lossless, hires, jymaster 等）
  final String audioQuality;

  const SettingsState({
    this.themeMode = ThemeMode.light,
    this.sleepTimerEndMs,
    this.audioQuality = _defaultAudioQuality,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    int? sleepTimerEndMs,
    String? audioQuality,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      sleepTimerEndMs: sleepTimerEndMs ?? this.sleepTimerEndMs,
      audioQuality: audioQuality ?? this.audioQuality,
    );
  }
}

class SettingsNotifier extends Notifier<SettingsState> {
  Timer? _sleepTimer;

  @override
  SettingsState build() {
    // 异步加载持久化的主题设置，初始默认浅色
    _loadPersistedTheme();
    _restoreSleepTimer();
    _loadAudioQuality();
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

  /// 加载持久化的音质设置并应用到 AudioService。
  Future<void> _loadAudioQuality() async {
    final prefs = await SharedPreferences.getInstance();
    final quality = prefs.getString(_audioQualityKey) ?? _defaultAudioQuality;
    AudioService.instance.level = quality;
    state = state.copyWith(audioQuality: quality);
  }

  /// 恢复持久化的睡眠定时器（跨进程重启）
  Future<void> _restoreSleepTimer() async {
    final prefs = await SharedPreferences.getInstance();
    final endMs = prefs.getInt(_sleepTimerKey);
    if (endMs == null) return;
    final remainingMs = endMs - DateTime.now().millisecondsSinceEpoch;
    if (remainingMs <= 0) {
      // 已过期，清理
      await prefs.remove(_sleepTimerKey);
      return;
    }
    state = state.copyWith(sleepTimerEndMs: endMs);
    _startSleepCheck();
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

  /// 设置播放音质。持久化并同步到 AudioService。
  Future<void> setAudioQuality(String level) async {
    AudioService.instance.level = level;
    state = state.copyWith(audioQuality: level);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_audioQualityKey, level);
  }

  // ═══ 睡眠定时器 ═══

  static const _sleepTimerKey = 'sleep_timer_end_ms';

  /// 启动睡眠定时器，[minutes] 分钟后暂停播放。
  Future<void> startSleepTimer(int minutes) async {
    cancelSleepTimer();
    final endMs = DateTime.now().millisecondsSinceEpoch + minutes * 60 * 1000;
    state = state.copyWith(sleepTimerEndMs: endMs);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_sleepTimerKey, endMs);
    _startSleepCheck();
  }

  /// 取消睡眠定时器。
  Future<void> cancelSleepTimer() async {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    state = state.copyWith(sleepTimerEndMs: null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sleepTimerKey);
  }

  /// 启动定时检查（每 30 秒），到期后暂停播放。
  void _startSleepCheck() {
    _sleepTimer?.cancel();
    _sleepTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      final endMs = state.sleepTimerEndMs;
      if (endMs == null) {
        _sleepTimer?.cancel();
        _sleepTimer = null;
        return;
      }
      if (DateTime.now().millisecondsSinceEpoch >= endMs) {
        AudioService.instance.player.pause();
        cancelSleepTimer();
      }
    });
  }
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, SettingsState>(SettingsNotifier.new);
