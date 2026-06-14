import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yuugao/pages/settings_page.dart';
import 'package:yuugao/providers/settings_provider.dart';
import 'package:yuugao/providers/playlist_provider.dart';
import 'package:yuugao/providers/user_provider.dart';
import 'package:yuugao/widgets/cover_image.dart';

/// 首页侧边栏：用户信息、设置入口、退出登录。
class HomeDrawer extends ConsumerWidget {
  const HomeDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(currentColorsProvider);
    final user = ref.watch(userProvider);

    return Drawer(
      backgroundColor: Theme.of(context).cardColor,
      child: SafeArea(
        child: Column(
          children: [
            // ── 用户信息 ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: Row(
                children: [
                  ClipOval(
                    child: CoverImage(
                      url: user.avatarUrl,
                      size: 48,
                      radius: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.nickname,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '网易云音乐',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // ── 设置 ──
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('设置'),
              trailing: const Icon(Icons.chevron_right, size: 20),
              onTap: () {
                // 先关闭抽屉，再打开设置页
                Navigator.of(context).pop();
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const SettingsPage()));
              },
            ),

            const Spacer(),

            // ── 退出登录 ──
            const Divider(height: 1),
            ListTile(
              leading: Icon(Icons.logout, color: colors.primary),
              title: Text('退出登录', style: TextStyle(color: colors.primary)),
              onTap: () async {
                Navigator.of(context).pop();
                await ref.read(userProvider.notifier).logout();
                ref.read(playlistProvider.notifier).clear();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
