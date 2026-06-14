import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yuugao/providers/settings_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(currentColorsProvider);
    final themeMode = ref.watch(
      settingsProvider.select((s) => s.themeMode),
    );
    final isDark = themeMode == ThemeMode.dark;

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
        ],
      ),
    );
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
