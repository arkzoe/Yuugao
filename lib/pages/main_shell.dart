import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yuugao/pages/home_page.dart';
import 'package:yuugao/widgets/player_panel.dart';

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
    return PlayerPanel(
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
                builder: (_) =>
                    const Scaffold(body: Center(child: Text('Unknown route'))),
              );
          }
        },
      ),
    );
  }
}
