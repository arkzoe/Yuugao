import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yuugao/providers/settings_provider.dart';
import 'package:yuugao/services/audio_service.dart';
import 'package:yuugao/services/cache_service.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  static const _qualityOptions = [
    ('standard', '标准'),
    ('exhigh', '极高 (~320kbps)'),
    ('lossless', '无损'),
    ('hires', 'Hi-Res'),
    ('jymaster', '臻品母带'),
  ];

  void _showSleepTimerDialog(BuildContext context, WidgetRef ref) {
    final colors = ref.read(currentColorsProvider);
    final endMs = ref.read(settingsProvider).sleepTimerEndMs;
    final remaining = endMs != null
        ? ((endMs - DateTime.now().millisecondsSinceEpoch) ~/ 60000).clamp(0, 999)
        : null;

    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text('睡眠定时器',
            style: TextStyle(color: colors.textPrimary)),
        children: [
          if (remaining != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              child: Text('剩余约 $remaining 分钟',
                  style: TextStyle(color: colors.textSecondary, fontSize: 13)),
            ),
          for (final mins in const [15, 30, 45, 60, 90, 120])
            SimpleDialogOption(
              onPressed: () {
                ref.read(settingsProvider.notifier).startSleepTimer(mins);
                Navigator.of(ctx).pop();
              },
              child: Text('$mins 分钟',
                  style: TextStyle(color: colors.textPrimary)),
            ),
          if (endMs != null)
            SimpleDialogOption(
              onPressed: () {
                ref.read(settingsProvider.notifier).cancelSleepTimer();
                Navigator.of(ctx).pop();
              },
              child: Text('取消定时',
                  style: TextStyle(color: colors.primary)),
            ),
        ],
      ),
    );
  }

  void _showQualityDialog(BuildContext context, WidgetRef ref) {
    final colors = ref.read(currentColorsProvider);
    final current = AudioService.instance.level; // 直接读 AudioService 的 _level

    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text('播放音质',
            style: TextStyle(color: colors.textPrimary)),
        children: [
          for (final opt in _qualityOptions)
            SimpleDialogOption(
              onPressed: () {
                AudioService.instance.level = opt.$1;
                Navigator.of(ctx).pop();
              },
              child: Row(
                children: [
                  if (opt.$1 == current)
                    Icon(Icons.check, size: 18, color: colors.primary)
                  else
                    const SizedBox(width: 18),
                  const SizedBox(width: 12),
                  Text(opt.$2,
                      style: TextStyle(
                        color: opt.$1 == current
                            ? colors.primary
                            : colors.textPrimary,
                        fontWeight: opt.$1 == current
                            ? FontWeight.w600
                            : FontWeight.normal,
                      )),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(currentColorsProvider);
    final themeMode = ref.watch(
      settingsProvider.select((s) => s.themeMode),
    );
    final isDark = themeMode == ThemeMode.dark;
    final sleepEndMs = ref.watch(
      settingsProvider.select((s) => s.sleepTimerEndMs),
    );
    final remainingMin = sleepEndMs != null
        ? ((sleepEndMs - DateTime.now().millisecondsSinceEpoch) ~/ 60000).clamp(0, 999)
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        children: [
          // ── UI 设置 ──
          _SectionHeader(title: 'UI 设置', colors: colors),
          SwitchListTile(
            secondary: const Icon(Icons.brightness_6),
            title: const Text('深色模式'),
            subtitle: Text(isDark ? '当前：深色' : '当前：浅色'),
            value: isDark,
            onChanged: (_) => ref.read(settingsProvider.notifier).toggleTheme(),
          ),

          const Divider(height: 1),

          // ── 播放设置 ──
          _SectionHeader(title: '播放设置', colors: colors),
          ListTile(
            leading: const Icon(Icons.music_note),
            title: const Text('播放音质'),
            subtitle: Text(_qualityLabel(AudioService.instance.level)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showQualityDialog(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.bedtime),
            title: const Text('睡眠定时器'),
            subtitle: Text(remainingMin != null
                ? '剩余约 $remainingMin 分钟'
                : '未启用'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showSleepTimerDialog(context, ref),
          ),

          const Divider(height: 1),

          // ── App 设置 ──
          _SectionHeader(title: 'App 设置', colors: colors),
          ListTile(
            leading: const Icon(Icons.system_update),
            title: const Text('检查更新'),
            subtitle: const Text('当前版本 1.0.0'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('已是最新版本')),
              );
            },
          ),

          const Divider(height: 1),

          // ── 缓存管理 ──
          _SectionHeader(title: '缓存', colors: colors),
          FutureBuilder<int>(
            future: CacheService.instance.cacheSize(),
            builder: (context, snapshot) {
              final sizeMB = (snapshot.data ?? 0) ~/ (1024 * 1024);
              return ListTile(
                leading: const Icon(Icons.storage),
                title: const Text('离线缓存'),
                subtitle: Text('已使用 $sizeMB MB（上限 512 MB）'),
                trailing: sizeMB > 0
                    ? TextButton(
                        onPressed: () async {
                          await CacheService.instance.clearAll();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('缓存已清空')),
                            );
                          }
                        },
                        child: const Text('清空'),
                      )
                    : null,
              );
            },
          ),
        ],
      ),
    );
  }

  String _qualityLabel(String level) {
    for (final opt in _qualityOptions) {
      if (opt.$1 == level) return opt.$2;
    }
    return level;
  }
}

/// 分组标题
class _SectionHeader extends StatelessWidget {
  final String title;
  final ThemeColors colors;
  const _SectionHeader({required this.title, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: colors.textSecondary,
        ),
      ),
    );
  }
}
