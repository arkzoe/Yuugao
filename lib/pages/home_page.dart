import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yuugao/pages/search_page.dart';
import 'package:yuugao/providers/playlist_provider.dart';
import 'package:yuugao/providers/settings_provider.dart';
import 'package:yuugao/providers/user_provider.dart';
import 'package:yuugao/widgets/cover_image.dart';
import 'package:yuugao/widgets/home_action_buttons.dart';
import 'package:yuugao/widgets/home_drawer.dart';
import 'package:yuugao/widgets/mini_player_bar.dart';
import 'package:yuugao/widgets/playlist_card.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool _isDrawerOpen = false;
  int _lastHour = -1;
  String _cachedGreeting = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  void _toggleDrawer() => setState(() => _isDrawerOpen = !_isDrawerOpen);
  void _openDrawer() {
    if (!_isDrawerOpen) setState(() => _isDrawerOpen = true);
  }

  void _closeDrawer() {
    if (_isDrawerOpen) setState(() => _isDrawerOpen = false);
  }

  Future<void> _load() async {
    await ref.read(playlistProvider.notifier).fetchAll();
  }

  /// 根据当前小时返回问候语，按小时缓存避免每次 build 都 new DateTime。
  String _greeting() {
    final h = DateTime.now().hour;
    if (h == _lastHour) return _cachedGreeting;
    _lastHour = h;
    if (h < 6) return _cachedGreeting = '夜深了';
    if (h < 12) return _cachedGreeting = '上午好';
    if (h < 14) return _cachedGreeting = '中午好';
    if (h < 18) return _cachedGreeting = '下午好';
    return _cachedGreeting = '晚上好';
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(currentColorsProvider);
    final user = ref.watch(userProvider);
    final playlistState = ref.watch(playlistProvider);

    return Stack(
      children: [
        // ── 第 1 层：抽屉面板（底层）──
        HomeDrawer(onClose: _closeDrawer),

        // ── 第 2 层：主页面 + 平移动画 ──
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(
            _isDrawerOpen ? homeDrawerWidth : 0,
            0,
            0,
          ),
          child: Scaffold(
            body: SafeArea(
              child: Column(
                children: [
                  _buildAppBar(user.avatarUrl, colors),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.only(bottom: 24),
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                            child: Text(
                              '${_greeting()}，${user.nickname}~',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: colors.textSecondary,
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: HomeActionButtons(),
                          ),
                          const SizedBox(height: 8),
                          _buildPlaylistSection(playlistState, colors),
                        ],
                      ),
                    ),
                  ),
                  const MiniPlayerBar(),
                ],
              ),
            ),
          ),
        ),

        // ── 第 3 层：左边缘拖拽打开 ──
        if (!_isDrawerOpen)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 20,
            child: _EdgeDragDetector(onDragOpen: _openDrawer),
          ),

        // ── 第 4 层：点击主页区域关闭（仅覆盖抽屉右侧，不与抽屉按钮重叠）──
        if (_isDrawerOpen)
          Positioned(
            left: homeDrawerWidth,
            top: 0,
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: _closeDrawer,
              behavior: HitTestBehavior.opaque,
            ),
          ),
      ],
    );
  }

  Widget _buildAppBar(String avatar, ThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: _toggleDrawer,
            child: ClipOval(
              child: CoverImage(url: avatar, size: 36, radius: 18),
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const SearchPage()));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistSection(PlaylistState state, ThemeColors colors) {
    final all = [...state.created, ...state.subscribed];
    if (all.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text('暂无歌单', style: TextStyle(color: colors.textSecondary)),
        ),
      );
    }

    final liked = all.first;
    final rest = all.sublist(1); // 剩余歌单（空列表时不会触发，all 非空已在外层保证）

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 我喜欢的音乐 ──
        _sectionHeader(Icons.favorite, '我喜欢的音乐', colors),
        PlaylistCard(playlist: liked),

        if (rest.isNotEmpty) ...[
          const SizedBox(height: 12),
          // ── 我的歌单 ──
          _sectionHeader(Icons.queue_music, '我的歌单', colors),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: rest.length,
            itemBuilder: (context, i) => PlaylistCard(playlist: rest[i]),
          ),
        ],
      ],
    );
  }

  Widget _sectionHeader(IconData icon, String title, ThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Icon(icon, color: colors.primary, size: 18),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// 左边缘拖拽检测器 — 检测从屏幕左边缘向右的拖拽手势来打开抽屉。
class _EdgeDragDetector extends StatefulWidget {
  final VoidCallback onDragOpen;
  const _EdgeDragDetector({required this.onDragOpen});

  @override
  State<_EdgeDragDetector> createState() => _EdgeDragDetectorState();
}

class _EdgeDragDetectorState extends State<_EdgeDragDetector> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _isDragging = true,
      onPointerMove: (event) {
        if (!_isDragging) return;
        if (event.delta.dx > 10) {
          _isDragging = false;
          widget.onDragOpen();
        }
      },
      onPointerUp: (_) => _isDragging = false,
      onPointerCancel: (_) => _isDragging = false,
    );
  }
}
