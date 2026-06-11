import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yuugao/providers/user_provider.dart';
import 'package:yuugao/pages/home_page.dart';
import 'package:yuugao/pages/login_page.dart';
import 'package:yuugao/theme.dart';

class YuugaoApp extends StatelessWidget {
  const YuugaoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'yuugao',
      debugShowCheckedModeBanner: false,
      theme: buildDarkTheme(),
      home: const _AuthGate(),
      routes: {
        '/login': (_) => const LoginPage(),
        '/home': (_) => const HomePage(),
      },
    );
  }
}

/// 启动时恢复登录态，按结果路由到首页或登录页。
class _AuthGate extends ConsumerStatefulWidget {
  const _AuthGate();

  @override
  ConsumerState<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<_AuthGate> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(userProvider.notifier).restore());
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(userProvider.select((s) => s.status));
    switch (status) {
      case AuthStatus.unknown:
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      case AuthStatus.authenticated:
        return const HomePage();
      case AuthStatus.unauthenticated:
        return const LoginPage();
    }
  }
}
