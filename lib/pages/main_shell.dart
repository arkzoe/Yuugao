import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yuugao/pages/home_page.dart';
import 'package:yuugao/widgets/home_drawer.dart';
import 'package:yuugao/widgets/player_panel.dart';

/// 首页抽屉是否打开，由 HomePage 写入、MainShell 读取以同步平移动画。
final drawerOpenProvider = NotifierProvider<DrawerOpenNotifier, bool>(
  DrawerOpenNotifier.new,
);

class DrawerOpenNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void setOpen(bool value) => state = value;
}

/// 迷你播放器是否隐藏（设置页不显示迷你播放器）。
final miniPlayerHiddenProvider = NotifierProvider<MiniPlayerHiddenNotifier, bool>(
  MiniPlayerHiddenNotifier.new,
);

class MiniPlayerHiddenNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void setHidden(bool value) => state = value;
}

/// Shell with PlayerPanel + nested Navigator.
///
/// This wraps all authenticated pages with a persistent
/// SlidingUpPanel. The mini player bar is visible on every page, and the full
/// player panel slides up without pushing a new page.
///
/// FM mode only changes the panel's tab layout (3 vs 4 tabs) and opens the
/// existing panel — no page push needed.
///
/// The drawer lives in a Stack at this level so it stays fixed while the
/// PlayerPanel (body + mini player) translates right to reveal it.
class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  /// Key for the inner Navigator, so external code can push/pop routes.
  static final innerNavigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drawerOpen = ref.watch(drawerOpenProvider);

    return Stack(
      children: [
        // ── 第 1 层：抽屉面板（固定不动）──
        HomeDrawer(
          onClose: () =>
              ref.read(drawerOpenProvider.notifier).setOpen(false),
        ),

        // ── 第 2 层：主内容 + 迷你播放器（同步平移）──
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(
            drawerOpen ? homeDrawerWidth : 0,
            0,
            0,
          ),
          child: PlayerPanel(
            body: Navigator(
              key: innerNavigatorKey,
              initialRoute: '/',
              onGenerateRoute: (settings) {
                switch (settings.name) {
                  case '/':
                    return MaterialPageRoute(
                      builder: (_) => const HomePage(),
                      settings: settings,
                    );
                  default:
                    return MaterialPageRoute(
                      builder: (_) => const Scaffold(
                        body: Center(child: Text('Unknown route')),
                      ),
                    );
                }
              },
            ),
          ),
        ),

        // ── 第 3 层：点击内容区关闭抽屉（仅覆盖抽屉右侧，不遮挡抽屉按钮）──
        if (drawerOpen)
          Positioned(
            left: homeDrawerWidth,
            top: 0,
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: () =>
                  ref.read(drawerOpenProvider.notifier).setOpen(false),
              behavior: HitTestBehavior.opaque,
            ),
          ),
      ],
    );
  }
}
