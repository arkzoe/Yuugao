import 'dart:ui';

import 'package:animated_background/animated_background.dart';
import 'package:cached_network_image/cached_network_image.dart';
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

/// 全屏播放器（已弃用，保留为参考）。
///
/// 当前播放器使用 [PlayerPanel]（SlidingUpPanel），不再通过
/// Navigator.push 打开独立页面。FM 模式同样复用 PlayerPanel。
class FullPlayer extends ConsumerStatefulWidget {
  const FullPlayer({super.key});

  @override
  ConsumerState<FullPlayer> createState() => _FullPlayerState();
}

class _FullPlayerState extends ConsumerState<FullPlayer>
    with TickerProviderStateMixin {
  /// 两个独立 TabController，避免 build() 中动态创建/销毁。
  /// 原因：在 build() 中 dispose 旧 controller 会导致其仍被
  /// TabBar/TabBarView 引用时提前销毁，触发"点击即退出"等异常。
  late final TabController _fmTab;
  late final TabController _normalTab;
  Color? _prevBg;
  double _dragOffsetY = 0;

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

  @override
  void initState() {
    super.initState();
    _fmTab = TabController(length: 3, vsync: this);
    _normalTab = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _fmTab.dispose();
    _normalTab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playerColors = ref.watch(playerThemeProvider);
    final colors = ref.watch(currentColorsProvider);
    final song = ref.watch(playerProvider.select((s) => s.current));
    final isFm = ref.watch(playerProvider.select((s) => s.isFmMode));
    final isPlaying = ref.watch(playerProvider.select((s) => s.isPlaying));

    final tab = isFm ? _fmTab : _normalTab;

    final panels = isFm
        ? const <Widget>[PlayerInfoPanel(), LyricPanel(), CommentPanel()]
        : const <Widget>[
            PlayerInfoPanel(),
            PlaylistPanel(),
            LyricPanel(),
            CommentPanel(),
          ];

    final coverUrl = song?.coverUrl ?? '';

    final result = TweenAnimationBuilder<Color?>(
      tween: ColorTween(
        begin: _prevBg ?? playerColors.background,
        end: playerColors.background,
      ),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      builder: (_, bg, child) {
        return Scaffold(
          backgroundColor: bg ?? playerColors.background,
          body: child,
        );
      },
      child: GestureDetector(
        onVerticalDragUpdate: (d) => _dragOffsetY += d.delta.dy,
        onVerticalDragEnd: (d) {
          final v = d.primaryVelocity ?? 0;
          if (_dragOffsetY > 80 || v > 500) Navigator.of(context).pop();
          _dragOffsetY = 0;
        },
        child: SafeArea(
          child: Stack(
            children: [
              // ── 第 1 层：封面图背景（低透明度 + 高斯模糊）──
              if (coverUrl.isNotEmpty)
                Positioned.fill(
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                      child: Opacity(
                        opacity: 0.45,
                        child: CachedNetworkImage(
                          imageUrl: coverUrl.startsWith('http://')
                              ? coverUrl.replaceFirst('http://', 'https://')
                              : coverUrl,
                          fit: BoxFit.cover,
                          httpHeaders: const {
                            'Referer': 'https://music.163.com',
                            'User-Agent':
                                'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
                          },
                        ),
                      ),
                    ),
                  ),
                ),

              // ── 第 2 层：色彩渐变叠加 ──
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          playerColors.accent.withValues(alpha: 0.15),
                          playerColors.background.withValues(alpha: 0.3),
                          playerColors.background.withValues(alpha: 0.75),
                          playerColors.background,
                        ],
                        stops: const [0.0, 0.3, 0.7, 1.0],
                      ),
                    ),
                  ),
                ),
              ),

              // ── 第 3 层：粒子（仅播放时显示）──
              if (isPlaying)
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedBackground(
                      vsync: this,
                      behaviour: RandomParticleBehaviour(
                        options: ParticleOptions(
                          baseColor: playerColors.accent.withValues(
                            alpha: 0.08,
                          ),
                          spawnMaxSpeed: 60,
                          spawnMinSpeed: 20,
                          spawnOpacity: 0.12,
                          particleCount: 8,
                          spawnMaxRadius: 16,
                        ),
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),

              // ── 第 4 层：主内容 ──
              Column(
                children: [
                  // 顶栏
                  SizedBox(
                    height: 48,
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.keyboard_arrow_down,
                            color: colors.textPrimary,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              'Now Playing',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: colors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.share,
                            size: 20,
                            color: colors.textPrimary,
                          ),
                          onPressed: song == null
                              ? null
                              : () => SharePlus.instance.share(
                                  ShareParams(
                                    text:
                                        '我在听「${song.name}」- ${song.artist}\n'
                                        'https://music.163.com/song?id=${song.id}',
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),

                  // 面板内容
                  Expanded(
                    child: TabBarView(controller: tab, children: panels),
                  ),

                  // 进度 + 频谱 + 控制 + 底部 tab
                  const PlayerProgressBar(),
                  const PlayerControlsRow(),
                  // 点击已选中的 tab 收起播放器
                  TabBar(
                    controller: tab,
                    indicatorColor: colors.primary,
                    labelColor: colors.primary,
                    unselectedLabelColor: colors.textSecondary,
                    labelStyle: const TextStyle(fontSize: 12),
                    dividerColor: Colors.transparent,
                    indicatorSize: TabBarIndicatorSize.label,
                    tabs: isFm ? _fmTabs : _normalTabs,
                    onTap: (i) {
                      if (i == tab.index) {
                        // 再次点击同一 tab → 折叠播放器
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    _prevBg = playerColors.background;
    return result;
  }
}
