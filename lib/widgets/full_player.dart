import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import 'package:yuugao/providers/player_provider.dart';
import 'package:yuugao/providers/player_theme_provider.dart';
import 'package:yuugao/providers/settings_provider.dart';
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
  TabController? _tab;
  bool _wasFm = false;

  Color? _prevBg;

  static const _fmTabs = [
    Tab(text: '信息', height: 40),
    Tab(text: '歌词', height: 40),
    Tab(text: '评论', height: 40),
  ];

  static const _normalTabs = [
    Tab(text: '信息', height: 40),
    Tab(text: '列表', height: 40),
    Tab(text: '歌词', height: 40),
    Tab(text: '评论', height: 40),
  ];

  TabController _createTab(bool isFm) {
    _tab?.dispose();
    final count = isFm ? 3 : 4;
    final ctrl = TabController(length: count, vsync: this);
    _tab = ctrl;
    return ctrl;
  }

  @override
  void dispose() {
    _tab?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 动态背景色（来自封面取色）
    final playerColors = ref.watch(playerThemeProvider);
    // UI 控件色（静态主题）
    final colors = ref.watch(currentColorsProvider);
    final song = ref.watch(playerProvider.select((s) => s.current));
    final isFm = ref.watch(playerProvider.select((s) => s.isFmMode));

    // FM 模式变化时重建 TabController
    if (_tab == null || _wasFm != isFm) {
      _wasFm = isFm;
      _createTab(isFm);
    }

    final tab = _tab!;

    // FM 模式下列表面板替换为空白占位
    final panels = isFm
        ? const <Widget>[PlayerInfoPanel(), LyricPanel(), CommentPanel()]
        : const <Widget>[
            PlayerInfoPanel(),
            PlaylistPanel(),
            LyricPanel(),
            CommentPanel(),
          ];

    final result = TweenAnimationBuilder<Color?>(
      tween: ColorTween(
        begin: _prevBg ?? playerColors.background,
        end: playerColors.background,
      ),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      builder: (_, bg, child) {
        return Scaffold(
          backgroundColor: bg ?? playerColors.background,
          body: child,
        );
      },
      child: SafeArea(
        child: Stack(
          children: [
            // 顶部氛围渐变 — 封面主色自然融入
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 300,
              child: IgnorePointer(
                child: TweenAnimationBuilder<Color?>(
                  tween: ColorTween(
                    begin: _prevBg ?? playerColors.background,
                    end: playerColors.background,
                  ),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                  builder: (_, bg, child) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            playerColors.accent.withValues(alpha: 0.12),
                            playerColors.accent.withValues(alpha: 0.02),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            // 主内容 — 控件色全部用静态 ThemeColors
            Column(
              children: [
                // 顶栏
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.keyboard_arrow_down,
                          color: colors.textPrimary),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    if (isFm)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '私人 FM',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: colors.primary,
                          ),
                        ),
                      ),
                    if (isFm) const SizedBox(width: 8),
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
                            style: TextStyle(
                              fontSize: 11,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.share),
                      onPressed: song == null
                          ? null
                          : () => SharePlus.instance.share(ShareParams(
                              text: '我在听「${song.name}」- ${song.artist}')),
                    ),
                  ],
                ),
                // 面板内容
                Expanded(
                  child: TabBarView(
                    controller: tab,
                    children: panels,
                  ),
                ),
                // 进度 + 控制
                const PlayerProgressBar(),
                const PlayerControlsRow(),
                // 底部 Tab 切换
                TabBar(
                  controller: tab,
                  indicatorColor: colors.primary,
                  labelColor: colors.primary,
                  unselectedLabelColor: colors.textSecondary,
                  labelStyle: const TextStyle(fontSize: 12),
                  dividerColor: Colors.transparent,
                  tabs: isFm ? _fmTabs : _normalTabs,
                ),
                const SizedBox(height: 8),
              ],
            ),
          ],
        ),
      ),
    );

    _prevBg = playerColors.background;
    return result;
  }
}
