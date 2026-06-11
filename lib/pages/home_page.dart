import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yuugao/pages/search_page.dart';
import 'package:yuugao/providers/playlist_provider.dart';
import 'package:yuugao/providers/user_provider.dart';
import 'package:yuugao/theme.dart';
import 'package:yuugao/widgets/cover_image.dart';
import 'package:yuugao/widgets/home_action_buttons.dart';
import 'package:yuugao/widgets/mini_player_bar.dart';
import 'package:yuugao/widgets/playlist_card.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    await ref.read(playlistProvider.notifier).fetchAll();
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 6) return '夜深了';
    if (h < 12) return '上午好';
    if (h < 14) return '中午好';
    if (h < 18) return '下午好';
    return '晚上好';
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final playlistState = ref.watch(playlistProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(user.avatarUrl),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Text(
                        '${_greeting()}，${user.nickname}',
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: HomeActionButtons(),
                    ),
                    const SizedBox(height: 8),
                    _buildPlaylistSection(playlistState),
                  ],
                ),
              ),
            ),
            const MiniPlayerBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(String avatar) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: _showAccountSheet,
            child: ClipOval(
              child: CoverImage(url: avatar, size: 36, radius: 18),
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const SearchPage(),
              ));
            },
          ),
        ],
      ),
    );
  }

  void _showAccountSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.primary),
              title: const Text('退出登录'),
              onTap: () async {
                Navigator.pop(context);
                await ref.read(userProvider.notifier).logout();
                ref.read(playlistProvider.notifier).clear();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaylistSection(PlaylistState state) {
    // 包含"我喜欢的音乐"在内的全部歌单，单列展示。
    final all = [...state.created, ...state.subscribed];
    if (all.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Text('暂无歌单', style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Icon(Icons.queue_music, color: AppColors.primary, size: 18),
              SizedBox(width: 6),
              Text('我的歌单',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: all.length,
          itemBuilder: (context, i) => PlaylistCard(playlist: all[i]),
        ),
      ],
    );
  }
}
