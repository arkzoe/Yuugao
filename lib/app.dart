import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yuugao/providers/player_provider.dart';
import 'package:yuugao/providers/playlist_provider.dart';
import 'package:yuugao/providers/settings_provider.dart';
import 'package:yuugao/providers/user_provider.dart';
import 'package:yuugao/pages/home_page.dart';
import 'package:yuugao/pages/login_page.dart';
import 'package:yuugao/services/audio_service.dart' as audio;
import 'package:yuugao/theme.dart';

class YuugaoApp extends ConsumerWidget {
  const YuugaoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(
      settingsProvider.select((s) => s.themeMode),
    );

    return MaterialApp(
      title: 'yuugao',
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: themeMode,
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

    // 通知栏「喜欢」按钮回调：注入 Provider 层读写方法到 AudioService 单例。
    // 闭包每次调用时读取最新 Provider 状态，确保喜欢图标与数据同步。
    audio.AudioService.instance.isLiked = (songId) =>
        ref.read(playlistProvider).likedSongIds.contains(songId);
    audio.AudioService.instance.toggleLike = (songId) =>
        ref.read(playlistProvider.notifier).toggleLike(songId);

    Future.microtask(() async {
      await ref.read(userProvider.notifier).restore();
      // 登录态恢复后尝试恢复上次播放状态
      final userState = ref.read(userProvider);
      if (userState.status == AuthStatus.authenticated) {
        ref.read(playerProvider.notifier).restore();
      }
    });
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
