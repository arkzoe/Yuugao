import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yuugao/providers/settings_provider.dart';
import 'package:yuugao/services/cache_service.dart';

/// 设置页面 — 卡片式分组布局
///
/// 各设置项按功能分组到圆角卡片中，每组有标题头。
/// 开关使用图标切换替代标准 Switch，视觉上更统一。
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  static const _qualityOptions = [
    ('standard', '标准'),
    ('exhigh', '极高 (~320kbps)'),
    ('lossless', '无损'),
    ('hires', 'Hi-Res'),
    ('jymaster', '臻品母带'),
  ];

  // ── 对话框 ──

  void _showQualityDialog(BuildContext context, WidgetRef ref) {
    final colors = ref.read(currentColorsProvider);
    final current = ref.read(settingsProvider).audioQuality;

    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text('播放音质', style: TextStyle(color: colors.textPrimary)),
        children: [
          for (final opt in _qualityOptions)
            SimpleDialogOption(
              onPressed: () {
                ref.read(settingsProvider.notifier).setAudioQuality(opt.$1);
                Navigator.of(ctx).pop();
              },
              child: Row(
                children: [
                  if (opt.$1 == current)
                    Icon(Icons.check, size: 18, color: colors.primary)
                  else
                    const SizedBox(width: 18),
                  const SizedBox(width: 12),
                  Text(
                    opt.$2,
                    style: TextStyle(
                      color: opt.$1 == current
                          ? colors.primary
                          : colors.textPrimary,
                      fontWeight: opt.$1 == current
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
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
    final themeMode = ref.watch(settingsProvider.select((s) => s.themeMode));
    final isDark = themeMode == ThemeMode.dark;
    final sleepEndMs = ref.watch(
      settingsProvider.select((s) => s.sleepTimerEndMs),
    );
    final remainingMin = sleepEndMs != null
        ? ((sleepEndMs - DateTime.now().millisecondsSinceEpoch) ~/ 60000).clamp(
            0,
            999,
          )
        : null;
    final audioQuality = ref.watch(
      settingsProvider.select((s) => s.audioQuality),
    );

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 18,
              color: colors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
            text: 'Here  ',
            children: [
              TextSpan(
                text: '设置～',
                style: TextStyle(color: colors.primary.withValues(alpha: 0.9)),
              ),
            ],
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            // ── UI 设置 ──
            _SettingsCard(
              title: 'UI 设置',
              colors: colors,
              children: [
                _ToggleRow(
                  icon: Icons.brightness_6,
                  title: '深色模式',
                  subtitle: isDark ? '当前：深色' : '当前：浅色',
                  value: isDark,
                  colors: colors,
                  onTap: () =>
                      ref.read(settingsProvider.notifier).toggleTheme(),
                ),
              ],
            ),

            // ── 播放设置 ──
            _SettingsCard(
              title: '播放设置',
              colors: colors,
              children: [
                _NavRow(
                  icon: Icons.music_note,
                  title: '播放音质',
                  subtitle: _qualityLabel(audioQuality),
                  colors: colors,
                  onTap: () => _showQualityDialog(context, ref),
                ),
                const _CardDivider(),
                _SleepTimerRow(
                  remainingMin: remainingMin,
                  colors: colors,
                  onSet: (mins) =>
                      ref.read(settingsProvider.notifier).startSleepTimer(mins),
                  onCancel: () =>
                      ref.read(settingsProvider.notifier).cancelSleepTimer(),
                ),
              ],
            ),

            // ── App 设置 ──
            _SettingsCard(
              title: 'App 设置',
              colors: colors,
              children: [
                _NavRow(
                  icon: Icons.system_update,
                  title: '检查更新',
                  subtitle: '当前版本 1.0.0',
                  colors: colors,
                  onTap: () {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('已是最新版本')));
                  },
                ),
              ],
            ),

            // ── 缓存管理 ──
            _SettingsCard(
              title: '缓存',
              colors: colors,
              children: [
                FutureBuilder<CacheInfo>(
                  future: CacheService.instance.cacheInfo(),
                  builder: (context, snapshot) {
                    final info = snapshot.data;
                    final sizeMB = (info?.totalBytes ?? 0) ~/ (1024 * 1024);
                    final fileCount = info?.fileCount ?? 0;
                    return Column(
                      children: [
                        _InfoRow(
                          icon: Icons.storage,
                          title: '离线缓存',
                          subtitle: fileCount > 0
                              ? '$fileCount 首 · $sizeMB MB（上限 512 MB）'
                              : '暂无缓存',
                          colors: colors,
                        ),
                        if (sizeMB > 0)
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 52,
                              right: 16,
                              top: 8,
                              bottom: 12,
                            ),
                            child: Row(
                              children: [
                                _buildCacheBar(sizeMB, colors),
                                const SizedBox(width: 12),
                                SizedBox(
                                  height: 32,
                                  child: TextButton(
                                    style: TextButton.styleFrom(
                                      foregroundColor: colors.primary,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                    ),
                                    onPressed: () async {
                                      await CacheService.instance.clearAll();
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text('缓存已清空'),
                                          ),
                                        );
                                      }
                                    },
                                    child: const Text(
                                      '清空',
                                      style: TextStyle(fontSize: 13),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 32),

            // ── 底部版本信息 ──
            Text(
              'yuugao v1.0.0',
              style: TextStyle(fontSize: 12, color: colors.textSecondary),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCacheBar(int sizeMB, ThemeColors colors) {
    final ratio = (sizeMB / 512).clamp(0.0, 1.0);
    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: LinearProgressIndicator(
          value: ratio,
          minHeight: 6,
          backgroundColor: colors.divider,
          valueColor: AlwaysStoppedAnimation<Color>(
            ratio > 0.8
                ? colors.primary
                : colors.primary.withValues(alpha: 0.6),
          ),
        ),
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

// ═══════════════════════════════════════════════════════════════
// 卡片容器
// ═══════════════════════════════════════════════════════════════

class _SettingsCard extends StatelessWidget {
  final String title;
  final ThemeColors colors;
  final List<Widget> children;

  const _SettingsCard({
    required this.title,
    required this.colors,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary.withValues(alpha: 0.7),
              ),
            ),
          ),
          ...children,
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 各行组件
// ═══════════════════════════════════════════════════════════════

class _CardDivider extends StatelessWidget {
  const _CardDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(left: 52),
      child: Divider(height: 1, thickness: 0.5),
    );
  }
}

/// 带导航箭头的行（用于导航到子页/弹窗）。
class _NavRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final ThemeColors colors;
  final VoidCallback onTap;

  const _NavRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: colors.textPrimary, size: 22),
      title: Text(
        title,
        style: TextStyle(fontSize: 15, color: colors.textPrimary),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: colors.textSecondary),
      ),
      trailing: Icon(
        Icons.chevron_right,
        size: 20,
        color: colors.textSecondary.withValues(alpha: 0.5),
      ),
      onTap: onTap,
    );
  }
}

/// 仅信息展示行（无交互）。
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final ThemeColors colors;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: colors.textPrimary, size: 22),
      title: Text(
        title,
        style: TextStyle(fontSize: 15, color: colors.textPrimary),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: colors.textSecondary),
      ),
    );
  }
}

/// 开关行 — 使用图标切换
class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ThemeColors colors;
  final VoidCallback onTap;

  const _ToggleRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: colors.textPrimary, size: 22),
      title: Text(
        title,
        style: TextStyle(fontSize: 15, color: colors.textPrimary),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: colors.textSecondary),
      ),
      trailing: Icon(
        value ? Icons.toggle_on : Icons.toggle_off,
        size: 40,
        color: value
            ? colors.primary
            : colors.textSecondary.withValues(alpha: 0.4),
      ),
      onTap: onTap,
    );
  }
}

/// 睡眠定时器行 — 可展开选择分钟数。
class _SleepTimerRow extends StatefulWidget {
  final int? remainingMin;
  final ThemeColors colors;
  final void Function(int minutes) onSet;
  final VoidCallback onCancel;

  const _SleepTimerRow({
    required this.remainingMin,
    required this.colors,
    required this.onSet,
    required this.onCancel,
  });

  @override
  State<_SleepTimerRow> createState() => _SleepTimerRowState();
}

class _SleepTimerRowState extends State<_SleepTimerRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final remainingMin = widget.remainingMin;

    return Column(
      children: [
        ListTile(
          leading: Icon(Icons.bedtime, color: colors.textPrimary, size: 22),
          title: Text(
            '睡眠定时器',
            style: TextStyle(fontSize: 15, color: colors.textPrimary),
          ),
          subtitle: Text(
            remainingMin != null ? '剩余约 $remainingMin 分钟' : '未启用',
            style: TextStyle(fontSize: 12, color: colors.textSecondary),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (remainingMin != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: widget.onCancel,
                    child: Icon(
                      Icons.close,
                      size: 18,
                      color: colors.textSecondary.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.expand_more,
                    size: 22,
                    color: colors.textSecondary.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ),
          onTap: () => setState(() => _expanded = !_expanded),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: _buildExpandedOptions(colors),
          crossFadeState: _expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 250),
        ),
      ],
    );
  }

  Widget _buildExpandedOptions(ThemeColors colors) {
    const options = [15, 30, 45, 60, 90, 120];
    return Container(
      padding: const EdgeInsets.only(left: 52, right: 12, bottom: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: options.map((mins) {
          final isActive = widget.remainingMin != null;
          return ActionChip(
            label: Text(
              '$mins 分钟',
              style: TextStyle(
                fontSize: 13,
                color: isActive ? colors.textPrimary : colors.textPrimary,
              ),
            ),
            backgroundColor: isActive
                ? colors.background
                : colors.divider.withValues(alpha: 0.3),
            side: BorderSide.none,
            onPressed: () {
              widget.onSet(mins);
              setState(() => _expanded = false);
            },
          );
        }).toList(),
      ),
    );
  }
}
