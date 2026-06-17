import 'dart:ui';

import 'package:animated_background/animated_background.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import 'package:yuugao/models/song.dart';
import 'package:yuugao/pages/main_shell.dart';
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

/// 全局 PanelController，暴露给 FM 按钮等外部调用方。
///
/// [PlayerPanel] 在 initState 中将自己创建的 controller 赋值给此 provider，
/// 确保外部始终拿到当前挂载的 panel 的 controller。
final panelControllerProvider = Provider<PanelController?>((ref) {
  // 由 PlayerPanel 的实际实例通过 _registry 赋值
  return _panelControllerRegistry;
});

PanelController? _panelControllerRegistry;

/// 风格单面板播放器。
///
/// 折叠态显示迷你播放器（collapsed），展开态显示完整内容（panelBuilder），
/// 背景层叠加模糊封面 + 渐变 + 粒子动画。

class PlayerPanel extends ConsumerStatefulWidget {
  final Widget body;
  const PlayerPanel({super.key, required this.body});

  @override
  ConsumerState<PlayerPanel> createState() => _PlayerPanelState();
}

class _PlayerPanelState extends ConsumerState<PlayerPanel>
    with TickerProviderStateMixin {
  final _panelCtrl = PanelController();

  late final TabController _tab;

  /// 当前选中的 tab 索引；null 表示未选中任何 tab（TabBarView 隐藏）。
  int? _activeTab;

  /// 防止 onPanelSlide 中展开→折叠→展开的循环振荡。
  bool _resettingPanel = false;

  static const _coverSz = 240.0;

  static const _tabs = [
    Tab(text: '信息', height: 40),
    Tab(text: '列表', height: 40),
    Tab(text: '歌词', height: 40),
    Tab(text: '评论', height: 40),
  ];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
    _tab.addListener(_onTabChanged);
    // 注册全局 controller，供 FM 按钮等外部调用
    _panelControllerRegistry = _panelCtrl;
  }

  @override
  void dispose() {
    _panelControllerRegistry = null;
    _tab.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_activeTab != null && _tab.index != _activeTab) {
      setState(() => _activeTab = _tab.index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final screenH = MediaQuery.of(context).size.height;
    final screenW = MediaQuery.of(context).size.width;
    final miniH = 44.0 + 16 + bottomPad; // ~60px

    final song = ref.watch(playerProvider.select((s) => s.current));
    final isPlaying = ref.watch(playerProvider.select((s) => s.isPlaying));
    final colors = ref.watch(currentColorsProvider);
    final playerColors = ref.watch(playerThemeProvider);
    final miniPlayerHidden = ref.watch(miniPlayerHiddenProvider);

    const panels = <Widget>[
      PlayerInfoPanel(hideCover: true, hideSongName: true),
      PlaylistPanel(),
      LyricPanel(),
      CommentPanel(),
    ];

    final coverUrl = song?.coverUrl ?? '';

    return SlidingUpPanel(
      controller: _panelCtrl,
      minHeight: (song != null && !miniPlayerHidden) ? miniH : 0,
      maxHeight: screenH,
      color: playerColors.background,
      parallaxEnabled: false,
      backdropEnabled: true,
      backdropOpacity: 0.25,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      onPanelSlide: (pos) {
        // ★ tab 栏展开时下滑：先折叠 tab 栏，阻止面板关闭
        if (_activeTab != null && pos < 0.93 && !_resettingPanel) {
          _resettingPanel = true;
          setState(() => _activeTab = null);
          // 下一帧将面板动画回完全展开，阻断关闭
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _panelCtrl.open();
              // open 动画结束后允许再次检测
              Future.delayed(const Duration(milliseconds: 400), () {
                if (mounted) _resettingPanel = false;
              });
            }
          });
          return;
        }
        // 安全网：面板完全折叠后清理 tab 状态
        if (!_resettingPanel && pos <= 0.02 && _activeTab != null) {
          setState(() => _activeTab = null);
        }
      },
      // ═══ collapsed：迷你播放器 ═══
      collapsed: (song == null || miniPlayerHidden)
          ? const SizedBox.shrink()
          : _buildMiniPlayer(song, isPlaying, colors, playerColors, screenW),
      // ═══ panelBuilder：完整内容 ═══
      panelBuilder: (scrollCtrl) => _buildPanel(
        _tab,
        panels,
        _tabs,
        colors,
        playerColors,
        song,
        isPlaying,
        coverUrl,
        scrollCtrl,
        screenH,
      ),
      body: widget.body,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // 迷你播放器（collapsed — 面板折叠时显示）
  // ═══════════════════════════════════════════════════════════════

  Widget _buildMiniPlayer(
    Song song,
    bool isPlaying,
    ThemeColors colors,
    PlayerThemeColors playerColors,
    double w,
  ) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _panelCtrl.open(),
      child: Container(
        width: w,
        decoration: BoxDecoration(color: playerColors.surface),
        child: DefaultTextStyle(
          style: const TextStyle(decoration: TextDecoration.none),
          child: Column(
            children: [
              // 迷你进度条（顶部）
              const _MiniProgressBar(),
              // 主内容：封面 + 歌名歌手 + 播放按钮（竖直居中）
              Expanded(
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    CoverImage(url: song.coverThumb(500), size: 44, radius: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            song.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
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
                    IconButton(
                      icon: Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        size: 36,
                        color: colors.textPrimary,
                      ),
                      onPressed: () =>
                          ref.read(playerProvider.notifier).toggle(),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // 展开态完整内容 — 两种布局模式
  //
  // 默认（_activeTab == null）：封面居中 → 歌名 → 进度 → 控制 → TabBar 底部
  // 紧凑（_activeTab != null）：封面缩至右上角 → TabBar 上移 header → 内容区
  // ═══════════════════════════════════════════════════════════════

  Widget _buildPanel(
    TabController tab,
    List<Widget> panels,
    List<Widget> tabs,
    ThemeColors colors,
    PlayerThemeColors playerColors,
    Song? song,
    bool isPlaying,
    String coverUrl,
    ScrollController scrollCtrl,
    double screenH,
  ) {
    if (song == null) return const SizedBox.shrink();

    final rawUrl = coverUrl;
    final bgUrl = rawUrl.startsWith('//')
        ? 'https:$rawUrl'
        : rawUrl.startsWith('http://')
            ? rawUrl.replaceFirst('http://', 'https://')
            : rawUrl;

    final selected = _activeTab != null;

    final content = SizedBox(
      height: screenH,
      child: Material(
        color: playerColors.background,
        child: DefaultTextStyle(
          style: const TextStyle(decoration: TextDecoration.none),
          child: Stack(
            children: [
              // ── 第 1 层：模糊封面背景 ──
              if (bgUrl.isNotEmpty)
                Positioned.fill(
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                      child: Opacity(
                        opacity: 0.45,
                        child: CachedNetworkImage(
                          imageUrl: bgUrl,
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

              // ── 第 2 层：渐变叠加 ──
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

              // ── 第 3 层：粒子动画（仅播放时）──
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
                  // ═══ Header：默认 / 紧凑 两态 ═══
                  if (!selected)
                    _buildDefaultHeader(colors, song, isPlaying)
                  else
                    _buildCompactHeader(
                      tab,
                      tabs,
                      colors,
                      playerColors,
                      song,
                      isPlaying,
                    ),

                  // ═══ 中间区域 ═══
                  Expanded(
                    child: !selected
                        ? NotificationListener<OverscrollNotification>(
                            onNotification: (notif) {
                              if (notif.overscroll < -50) {
                                setState(() => _activeTab = 0);
                                tab.animateTo(0);
                                return true;
                              }
                              return false;
                            },
                            child: SingleChildScrollView(
                              controller: scrollCtrl,
                              physics: const BouncingScrollPhysics(),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // 封面（大，居中）
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 24),
                                    child: Center(
                                      child: CoverImage(
                                        url: song.coverThumb(500),
                                        size: _coverSz,
                                        radius: 12,
                                      ),
                                    ),
                                  ),
                                  // 歌名 + 歌手
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 32,
                                    ),
                                    child: Text(
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
                                  const SizedBox(height: 16),
                                ],
                              ),
                            ),
                          )
                        : TabBarView(controller: tab, children: panels),
                  ),

                  // ═══ 进度条 + 控制按钮（仅默认模式）═══
                  if (!selected) ...[
                    const PlayerProgressBar(),
                    const PlayerControlsRow(),
                    const SizedBox(height: 4),
                  ],

                  // ═══ TabBar：默认模式在底部；紧凑模式已在 header 中 ═══
                  if (!selected)
                    TabBar(
                      controller: tab,
                      indicatorColor: Colors.transparent,
                      labelColor: colors.textSecondary,
                      unselectedLabelColor: colors.textSecondary,
                      labelStyle: const TextStyle(fontSize: 12),
                      dividerColor: Colors.transparent,
                      indicatorSize: TabBarIndicatorSize.label,
                      tabs: tabs,
                      onTap: (i) {
                        setState(() => _activeTab = i);
                        tab.animateTo(i);
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    return content;
  }

  // ── Default header ──

  Widget _buildDefaultHeader(ThemeColors colors, Song song, bool isPlaying) {
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.keyboard_arrow_down, color: colors.textPrimary),
            onPressed: () {
              _panelCtrl.close();
              setState(() => _activeTab = null);
            },
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
            icon: Icon(Icons.share, size: 20, color: colors.textPrimary),
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
    );
  }

  // ── 紧凑顶栏 ──
  //
  //  Row 1：[▼] [歌名 / 歌手（左对齐）]  [📷 封面盖住按钮]
  //  Row 2：[  TabBar  .........................]
  //
  //  封面在右上角盖住播放按钮的位置，点击封面退出紧凑模式。
  //  进度条和控制按钮在紧凑模式下隐藏。

  Widget _buildCompactHeader(
    TabController tab,
    List<Widget> tabs,
    ThemeColors colors,
    PlayerThemeColors playerColors,
    Song song,
    bool isPlaying,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Row 1：封面（左侧盖住返回按钮）+ 歌曲信息 + 播放暂停 ──
        SizedBox(
          height: 48,
          child: Row(
            children: [
              // 封面（左侧，盖住 ▼ 位置，点击退出紧凑模式）
              GestureDetector(
                onTap: () => setState(() => _activeTab = null),
                child: Padding(
                  padding: const EdgeInsets.only(left: 12, right: 10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CoverImage(
                      url: song.coverThumb(200),
                      size: 32,
                      radius: 0,
                    ),
                  ),
                ),
              ),
              // 歌名 + 歌手（左对齐，垂直居中）
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
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
              // 播放/暂停
              IconButton(
                icon: Icon(
                  isPlaying ? Icons.pause_circle : Icons.play_circle,
                  size: 26,
                  color: playerColors.accent,
                ),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                onPressed: () => ref.read(playerProvider.notifier).toggle(),
              ),
            ],
          ),
        ),
        // ── Row 2：TabBar（app bar 下方，透明背景）──
        TabBar(
          controller: tab,
          indicatorColor: playerColors.accent,
          labelColor: playerColors.accent,
          unselectedLabelColor: colors.textSecondary,
          labelStyle: const TextStyle(fontSize: 12),
          dividerColor: Colors.transparent,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: tabs,
          onTap: (i) {
            if (_activeTab == i) {
              setState(() => _activeTab = null);
            } else {
              setState(() => _activeTab = i);
              tab.animateTo(i);
            }
          },
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Mini progress bar
// ═══════════════════════════════════════════════════════════════

class _MiniProgressBar extends ConsumerWidget {
  const _MiniProgressBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(playerProvider.select((s) => s.progress));
    final colors = ref.watch(currentColorsProvider);
    final playerColors = ref.watch(playerThemeProvider);

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
                child: Container(color: playerColors.accent),
              ),
            ],
          ),
        );
      },
    );
  }
}
