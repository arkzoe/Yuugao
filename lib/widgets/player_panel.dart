import 'dart:ui';

import 'package:animated_background/animated_background.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import 'package:yuugao/models/song.dart';
import 'package:yuugao/providers/player_provider.dart';
import 'package:yuugao/providers/player_theme_provider.dart';
import 'package:yuugao/providers/settings_provider.dart';
import 'package:yuugao/widgets/comment_panel.dart';
import 'package:yuugao/widgets/cover_image.dart';
import 'package:yuugao/widgets/lyric_panel.dart';
import 'package:yuugao/widgets/player_controls_row.dart';
import 'package:yuugao/widgets/player_progress_bar.dart';
import 'package:yuugao/widgets/playlist_panel.dart';
import 'package:yuugao/widgets/player_info_panel.dart';

/// 封面只有一份在 header 中动画。
///
/// 折叠态 (panel height=60)：header 顶部 60px 可见
///   → 封面左上角小圆(44) + 右侧歌名/歌手 + 播放按钮 + 顶部进度条
/// 展开态 (panel height=全屏)：header 全部可见
///   → 封面移到大尺寸(240)居中 + 歌名/歌手移到下方 body
///   → body: 歌名/歌手 + TabBarView + 进度条 + 控制 + TabBar
class PlayerPanel extends ConsumerStatefulWidget {
  final Widget body;
  const PlayerPanel({super.key, required this.body});

  @override
  ConsumerState<PlayerPanel> createState() => _PlayerPanelState();
}

class _PlayerPanelState extends ConsumerState<PlayerPanel>
    with TickerProviderStateMixin {
  final _panelCtrl = PanelController();
  final _innerCtrl = PanelController();
  TabController? _tab;
  bool _wasFm = false;
  double _panelPos = 0.0;

  static const _miniCover = 44.0;
  static const _bigCover = 240.0;

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
  void dispose() {
    _tab?.dispose();
    super.dispose();
  }

  TabController _ensureTab(bool isFm) {
    if (_tab == null || _wasFm != isFm) {
      _wasFm = isFm;
      _tab?.dispose();
      _tab = TabController(length: isFm ? 3 : 4, vsync: this);
    }
    return _tab!;
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final miniH = _miniCover + 16 + bottomPad; // ~60

    final song = ref.watch(playerProvider.select((s) => s.current));
    final isFm = ref.watch(playerProvider.select((s) => s.isFmMode));
    final isPlaying = ref.watch(playerProvider.select((s) => s.isPlaying));
    final colors = ref.watch(currentColorsProvider);
    final playerColors = ref.watch(playerThemeProvider);

    final tab = _ensureTab(isFm);
    final panels = isFm
        ? const <Widget>[
            PlayerInfoPanel(hideCover: true),
            LyricPanel(),
            CommentPanel(),
          ]
        : const <Widget>[
            PlayerInfoPanel(hideCover: true),
            PlaylistPanel(),
            LyricPanel(),
            CommentPanel(),
          ];

    final coverUrl = song?.coverUrl ?? '';

    return SlidingUpPanel(
      controller: _panelCtrl,
      minHeight: song != null ? miniH : 0,
      maxHeight: MediaQuery.of(context).size.height,
      backdropEnabled: true,
      backdropOpacity: _panelPos * 0.3,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      parallaxEnabled: true,
      parallaxOffset: 0.3,
      onPanelSlide: (pos) {
        if (mounted) setState(() => _panelPos = pos);
      },
      header: song == null
          ? const SizedBox.shrink()
          : LayoutBuilder(
              builder: (_, cts) {
                final w = cts.maxWidth.isInfinite
                    ? MediaQuery.of(context).size.width
                    : cts.maxWidth;
                return _buildHeader(song, isPlaying, colors, playerColors, w);
              },
            ),
      panelBuilder: (_) => _buildPanelBody(
        tab,
        panels,
        isFm,
        colors,
        playerColors,
        song,
        isPlaying,
        coverUrl,
      ),
      body: widget.body,
    );
  }

  // ═══ Header（折叠/展开共用，t=0 时顶部 60px 为迷你播放器）═══
  //
  // t=0: 封面在 top=8 left=10, 小圆 44px，右邻歌名/歌手 + 播放按钮
  // t=1: 封面在 top=52 left=居中, 大方块 240px，显示关闭按钮 + 标题 + 分享

  Widget _buildHeader(
    Song song,
    bool isPlaying,
    ThemeColors colors,
    PlayerThemeColors playerColors,
    double w,
  ) {
    final t = _panelPos.clamp(0.0, 1.0);

    // 封面：从左上小圆 → 居中大方块
    final coverSz = _lerp(_miniCover, _bigCover, t);
    final coverLeft = _lerp(10.0, (w - _bigCover) / 2, t);
    final coverTop = _lerp(8.0, 52.0, t);
    final coverRadius = _lerp(_miniCover / 2, 12.0, t);
    // 折叠态元素：1 → 0
    final miniOpacity = (1.0 - t * 2.5).clamp(0.0, 1.0);
    // 展开态元素：0 → 1
    final expandOpacity = ((t - 0.4) * 3).clamp(0.0, 1.0);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (_panelCtrl.isPanelClosed) {
          _panelCtrl.open();
        } else {
          _panelCtrl.close();
        }
      },
      child: Container(
        width: w,
        height: 280,
        decoration: BoxDecoration(
          color: t < 0.3 ? playerColors.surface : Colors.transparent,
          boxShadow: t < 0.1
              ? [
                  BoxShadow(
                    color: playerColors.accent.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ]
              : null,
        ),
        child: DefaultTextStyle(
          style: TextStyle(decoration: TextDecoration.none),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // ── 迷你进度条 ──
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Opacity(opacity: miniOpacity, child: _MiniProgressBar()),
              ),

              // ── 封面（唯一，动画）──
              Positioned(
                left: coverLeft,
                top: coverTop,
                child: CoverImage(
                  url: song.coverThumb(500),
                  size: coverSz,
                  radius: coverRadius,
                ),
              ),

              // ── 歌名 + 歌手（封面右侧，折叠态）──
              Positioned(
                left: coverLeft + coverSz + 12,
                top: coverTop,
                right: 52,
                child: Opacity(
                  opacity: miniOpacity,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 2),
                      Text(
                        song.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        song.artist.isEmpty ? '未知歌手' : song.artist,
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
              ),

              // ── 播放/暂停按钮（折叠态）──
              Positioned(
                right: 4,
                top: coverTop + _miniCover / 2 - 18,
                child: Opacity(
                  opacity: miniOpacity,
                  child: IconButton(
                    icon: Icon(
                      isPlaying ? Icons.pause_circle : Icons.play_circle,
                      size: 36,
                      color: colors.primary,
                    ),
                    onPressed: () => ref.read(playerProvider.notifier).toggle(),
                  ),
                ),
              ),

              // ── 展开态顶栏 ──
              Opacity(
                opacity: expandOpacity,
                child: SizedBox(
                  height: 48,
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.keyboard_arrow_down,
                          color: colors.textPrimary,
                        ),
                        onPressed: () => _panelCtrl.close(),
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
                        onPressed: () => SharePlus.instance.share(
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══ 展开态 body ───

  // ═══ 展开态 body（嵌套内层面板）═══
  //
  //   内层 SlidingUpPanel
  //   body    = 播放器页面（歌名/歌手 + 进度条 + 控制按钮）
  //   header  = TabBar（拖拽手柄，位于播放器页面下方）
  //   panel   = Tab 内容（信息/列表/歌词/评论）
  //
  // 折叠时 TabBar 在底部，向上滑动展开 Tab 内容。

  Widget _buildPanelBody(
    TabController tab,
    List<Widget> panels,
    bool isFm,
    ThemeColors colors,
    PlayerThemeColors playerColors,
    Song? song,
    bool isPlaying,
    String coverUrl,
  ) {
    if (song == null) return const SizedBox.shrink();

    final bottomPad = MediaQuery.of(context).padding.bottom;
    // 内层面板折叠高度：控制按钮行 + TabBar
    final innerMinH = 90.0 + 40 + bottomPad;

    return SlidingUpPanel(
      controller: _innerCtrl,
      minHeight: innerMinH,
      maxHeight: MediaQuery.of(context).size.height * 0.7,
      backdropEnabled: false,
      borderRadius: BorderRadius.zero,
      color: Colors.transparent,
      panelBuilder: (_) => Material(
        color: playerColors.background,
        child: DefaultTextStyle(
          style: TextStyle(decoration: TextDecoration.none),
          child: Column(
            children: [
              const SizedBox(height: 8),
              // 拖拽指示条
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: TabBarView(controller: tab, children: panels),
              ),
            ],
          ),
        ),
      ),
      header: Container(
        color: playerColors.background,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
                if (_innerCtrl.isPanelClosed && i != tab.index) {
                  _innerCtrl.open();
                }
              },
            ),
          ],
        ),
      ),
      body: Material(
        color: Colors.transparent,
        child: Container(
          color: playerColors.background,
          child: Stack(
            children: [
              // 背景：模糊 + 渐变 + 粒子
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

              // 播放器页面
              SafeArea(
                child: DefaultTextStyle(
                  style: TextStyle(decoration: TextDecoration.none),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      Text(
                        song.name,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        song.artist.isEmpty ? '未知歌手' : song.artist,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          color: colors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      const PlayerProgressBar(),
                      const PlayerControlsRow(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══ 迷你进度条 ═══

class _MiniProgressBar extends ConsumerWidget {
  const _MiniProgressBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(playerProvider.select((s) => s.progress));
    final colors = ref.watch(currentColorsProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        if (w.isInfinite || w <= 0) return const SizedBox(height: 2);
        final fillW = (w * progress).clamp(0.0, w);
        return SizedBox(
          height: 2,
          child: Stack(
            children: [
              Container(color: colors.divider),
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: fillW,
                child: Container(color: colors.primary),
              ),
            ],
          ),
        );
      },
    );
  }
}
