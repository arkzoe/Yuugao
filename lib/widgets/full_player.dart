import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import 'package:yuugao/providers/player_provider.dart';
import 'package:yuugao/theme.dart';
import 'package:yuugao/widgets/comment_panel.dart';
import 'package:yuugao/widgets/lyric_panel.dart';
import 'package:yuugao/widgets/player_controls_row.dart';
import 'package:yuugao/widgets/player_info_panel.dart';
import 'package:yuugao/widgets/player_progress_bar.dart';
import 'package:yuugao/widgets/playlist_panel.dart';

/// 以全屏 modal 形式打开播放器。
void showFullPlayer(BuildContext context) {
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: true,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, _, _) => const FullPlayer(),
      transitionsBuilder: (_, anim, _, child) {
        return SlideTransition(
          position: Tween(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
          child: child,
        );
      },
    ),
  );
}

class FullPlayer extends ConsumerStatefulWidget {
  const FullPlayer({super.key});

  @override
  ConsumerState<FullPlayer> createState() => _FullPlayerState();
}

class _FullPlayerState extends ConsumerState<FullPlayer>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final song = ref.watch(playerProvider.select((s) => s.current));

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 顶栏：折叠 + 分享
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_down),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        song?.name ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        song?.artist ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: song == null
                      ? null
                      : () => Share.share('我在听「${song.name}」- ${song.artist}'),
                ),
              ],
            ),
            // 四个面板
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: const [
                  PlayerInfoPanel(),
                  PlaylistPanel(),
                  LyricPanel(),
                  CommentPanel(),
                ],
              ),
            ),
            // 进度 + 控制
            const PlayerProgressBar(),
            const PlayerControlsRow(),
            // 面板切换 Tab
            TabBar(
              controller: _tab,
              indicatorColor: AppColors.primary,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: const TextStyle(fontSize: 12),
              tabs: const [
                Tab(text: '信息', height: 40),
                Tab(text: '列表', height: 40),
                Tab(text: '歌词', height: 40),
                Tab(text: '评论', height: 40),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
