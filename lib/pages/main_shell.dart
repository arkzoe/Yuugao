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
class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  /// Key for the inner Navigator, so external code can push/pop routes.
  static final innerNavigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drawerOpen = ref.watch(drawerOpenProvider);

    return AnimatedContainer(
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
    );
  }
}
