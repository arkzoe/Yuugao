import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yuugao/pages/main_shell.dart';
import 'package:yuugao/providers/player_provider.dart';
import 'package:yuugao/providers/playlist_provider.dart';
import 'package:yuugao/providers/settings_provider.dart';
import 'package:yuugao/providers/user_provider.dart';
import 'package:yuugao/pages/login_page.dart';
import 'package:yuugao/services/audio_handler.dart';
import 'package:yuugao/theme.dart';

class YuugaoApp extends ConsumerWidget {
  const YuugaoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(settingsProvider.select((s) => s.themeMode));

    return MaterialApp(
      title: 'yuugao',
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: themeMode,
      home: const _AuthGate(),
      routes: {
        '/login': (_) => const LoginPage(),
        '/main': (_) => const MainShell(),
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

    // 通知栏「喜欢」按钮回调（fastForward=喜欢, rewind=取消喜欢）
    YuugaoAudioHandler.instance.onLikeSong = (songId, like) {
      final isCurrentlyLiked = ref
          .read(playlistProvider)
          .likedSongIds
          .contains(songId);
      if (isCurrentlyLiked != like) {
        ref.read(playlistProvider.notifier).toggleLike(songId);
      }
    };

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
    // 同步喜欢歌曲 ID 到音频处理器，确保通知栏喜欢图标实时更新
    ref.listen(playlistProvider.select((s) => s.likedSongIds), (_, next) {
      YuugaoAudioHandler.instance.syncLikedIds(next);
    });

    final status = ref.watch(userProvider.select((s) => s.status));
    switch (status) {
      case AuthStatus.unknown:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case AuthStatus.authenticated:
        return const MainShell();
      case AuthStatus.unauthenticated:
        return const LoginPage();
    }
  }
}
