import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yuugao/pages/settings_page.dart';
import 'package:yuugao/providers/settings_provider.dart';
import 'package:yuugao/providers/playlist_provider.dart';
import 'package:yuugao/providers/user_provider.dart';
import 'package:yuugao/widgets/cover_image.dart';

/// 抽屉面板宽度（仅图标，紧凑模式）
const homeDrawerWidth = 72.0;

/// 首页抽屉面板：头像 + 功能图标，无文字。
/// 作为普通 widget 嵌入 Stack 中，配合主页面的平移动画实现"推入"效果。
class HomeDrawer extends ConsumerWidget {
  final VoidCallback? onClose;

  const HomeDrawer({super.key, this.onClose});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(currentColorsProvider);
    final user = ref.watch(userProvider);

    return Material(
      color: Theme.of(context).cardColor,
      child: Container(
        width: homeDrawerWidth,
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(
              color: colors.divider,
              width: 0.5,
            ),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── 头像 ──
              Padding(
                padding: const EdgeInsets.only(top: 24, bottom: 20),
                child: ClipOval(
                  child: CoverImage(
                    url: user.avatarUrl,
                    size: 44,
                    radius: 22,
                  ),
                ),
              ),

              // ── 设置 ──
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                tooltip: '设置',
                onPressed: () {
                  onClose?.call();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsPage()),
                  );
                },
              ),

              const Spacer(),

              // ── 退出登录 ──
              IconButton(
                icon: Icon(Icons.logout, color: colors.primary),
                tooltip: '退出登录',
                onPressed: () async {
                  onClose?.call();
                  await ref.read(userProvider.notifier).logout();
                  ref.read(playlistProvider.notifier).clear();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
