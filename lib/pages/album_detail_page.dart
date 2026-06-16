import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yuugao/CloudMusic/yuugao.dart';
import 'package:yuugao/models/song.dart';
import 'package:yuugao/providers/player_provider.dart';
import 'package:yuugao/providers/settings_provider.dart';
import 'package:yuugao/widgets/cover_image.dart';
import 'package:yuugao/widgets/song_tile.dart';

class AlbumDetailPage extends ConsumerStatefulWidget {
  final int albumId;
  final String title;
  final String coverUrl;

  const AlbumDetailPage({
    super.key,
    required this.albumId,
    required this.title,
    required this.coverUrl,
  });

  @override
  ConsumerState<AlbumDetailPage> createState() => _AlbumDetailPageState();
}

class _AlbumDetailPageState extends ConsumerState<AlbumDetailPage> {
  List<Song> _songs = [];
  String _artist = '';
  int _publishTime = 0;
  String _company = '';
  String _desc = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await MusicManager().albumInfo(id: widget.albumId);
      if (res?.code != 200) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      final album = res?.album;
      _artist = album?.artist?.name ?? '';
      _publishTime = album?.publishTime ?? 0;
      _company = album?.company ?? '';
      _desc = album?.description ?? '';
      _songs = [
        for (final s in (res?.songs ?? [])) Song.fromAlbumTrack(s),
      ];
    } catch (_) {}

    if (mounted) setState(() => _loading = false);
  }

  String get _dateStr {
    if (_publishTime <= 0) return '';
    final d = DateTime.fromMillisecondsSinceEpoch(_publishTime);
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(currentColorsProvider);

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
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    title: Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14),
                    ),
                    flexibleSpace: FlexibleSpaceBar(
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
                              radius: 8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // 元信息
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_artist.isNotEmpty)
                            Text(
                              _artist,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: colors.textPrimary,
                              ),
                            ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 16,
                            children: [
                              if (_dateStr.isNotEmpty)
                                Text(
                                  _dateStr,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colors.textSecondary,
                                  ),
                                ),
                              if (_company.isNotEmpty)
                                Text(
                                  _company,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colors.textSecondary,
                                  ),
                                ),
                              Text(
                                '${_songs.length}首',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          if (_desc.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              _desc,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.textSecondary,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  // 播放全部
                  SliverToBoxAdapter(
                    child: InkWell(
                      onTap: _songs.isEmpty
                          ? null
                          : () => ref
                                .read(playerProvider.notifier)
                                .play(_songs.first, queue: _songs),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.play_circle_fill,
                              color: colors.primary,
                              size: 28,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '播放全部',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '(${_songs.length})',
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_loading)
                    const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_songs.isEmpty)
                    SliverFillRemaining(
                      child: Center(
                        child: Text(
                          '暂无歌曲',
                          style: TextStyle(color: colors.textSecondary),
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => SongTile(
                          song: _songs[i],
                          queue: _songs,
                          index: i,
                          showCover: false,
                        ),
                        childCount: _songs.length,
                        addAutomaticKeepAlives: false,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
