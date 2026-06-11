import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yuugao/CloudMusic/yuugao.dart';
import 'package:yuugao/models/song.dart';
import 'package:yuugao/providers/player_provider.dart';
import 'package:yuugao/theme.dart';
import 'package:yuugao/widgets/cover_image.dart';
import 'package:yuugao/widgets/mini_player_bar.dart';
import 'package:yuugao/widgets/song_tile.dart';

class PlaylistDetailPage extends ConsumerStatefulWidget {
  final int playlistId;
  final String title;
  final String coverUrl;

  const PlaylistDetailPage({
    super.key,
    required this.playlistId,
    required this.title,
    required this.coverUrl,
  });

  @override
  ConsumerState<PlaylistDetailPage> createState() =>
      _PlaylistDetailPageState();
}

class _PlaylistDetailPageState extends ConsumerState<PlaylistDetailPage> {
  List<Song> _songs = [];
  String _creator = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res =
          await BujuanMusicManager().playlistDetail(id: widget.playlistId);
      final pl = res?.playlist;
      _songs =
          (pl?.tracks ?? []).map((t) => Song.fromPlaylistTrack(t)).toList();
      _creator = pl?.creator?.nickname ?? '';
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    expandedHeight: 200,
                    flexibleSpace: FlexibleSpaceBar(
                      title: Text(widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14)),
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          CoverImage(
                            url: '${widget.coverUrl}?param=600y600',
                            size: double.infinity,
                            radius: 0,
                          ),
                          Container(color: Colors.black45),
                          Center(
                            child: CoverImage(
                                url: '${widget.coverUrl}?param=300y300',
                                size: 120,
                                radius: 8),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_creator.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: Text('by $_creator',
                            style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12)),
                      ),
                    ),
                  SliverToBoxAdapter(child: _playAllBar()),
                  if (_loading)
                    const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => SongTile(
                          song: _songs[i],
                          queue: _songs,
                          index: i,
                        ),
                        childCount: _songs.length,
                      ),
                    ),
                ],
              ),
            ),
            const MiniPlayerBar(),
          ],
        ),
      ),
    );
  }

  Widget _playAllBar() {
    return InkWell(
      onTap: _songs.isEmpty
          ? null
          : () => ref
              .read(playerProvider.notifier)
              .play(_songs.first, queue: _songs),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.play_circle_fill,
                color: AppColors.primary, size: 28),
            const SizedBox(width: 8),
            Text('播放全部',
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(width: 6),
            Text('(${_songs.length})',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
