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

  // 搜索
  bool _searching = false;
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  List<Song> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _songs;
    return _songs.where((s) {
      return s.name.toLowerCase().contains(q) ||
          s.artist.toLowerCase().contains(q);
    }).toList();
  }

  int _originIndex(Song s) => _songs.indexOf(s) + 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await BujuanMusicManager().playlistDetail(
        id: widget.playlistId,
        n: 1000,
      );
      final pl = res?.playlist;
      if (pl == null) { setState(() => _loading = false); return; }

      _creator = pl.creator?.nickname ?? '';
      final total = pl.trackCount ?? 0;

      final songs = <Song>[
        for (final t in (pl.tracks ?? [])) Song.fromPlaylistTrack(t),
      ];

      final allIds = <int>[];
      for (final ti in (pl.trackIds ?? [])) {
        if (ti.id != null && ti.id! > 0) allIds.add(ti.id!);
      }

      if (songs.length < total) {
        final haveIds = songs.map((s) => s.id).toSet();
        final missing = allIds.where((id) => !haveIds.contains(id)).toList();

        if (missing.isNotEmpty) {
          const chunk = 1000;
          for (var i = 0; i < missing.length; i += chunk) {
            final batchIds = missing.skip(i).take(chunk).toList();
            final detail = await BujuanMusicManager().songDetail(ids: batchIds);
            final batch = (detail?.songs ?? [])
                .map((s) => Song.fromSongDetail(s))
                .where((s) => s.id > 0)
                .toList();
            songs.addAll(batch);
          }
        }
      }

      final songMap = {for (final s in songs) s.id: s};
      _songs = allIds
          .map((id) => songMap[id])
          .where((s) => s != null)
          .cast<Song>()
          .toList();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  void _closeSearch() {
    _searchFocus.unfocus();
    setState(() {
      _searching = false;
      _query = '';
      _searchCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;

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
                    title: _searching
                        ? SizedBox(
                            height: 38,
                            child: TextField(
                              controller: _searchCtrl,
                              focusNode: _searchFocus,
                              autofocus: true,
                              style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textPrimary),
                              decoration: InputDecoration(
                                hintText: '搜索歌名或歌手…',
                                hintStyle: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary),
                                prefixIcon: const Icon(Icons.search,
                                    size: 18,
                                    color: AppColors.textSecondary),
                                suffixIcon: _query.isNotEmpty
                                    ? GestureDetector(
                                        onTap: () {
                                          _searchCtrl.clear();
                                          setState(() => _query = '');
                                        },
                                        child: const Icon(Icons.clear,
                                            size: 18,
                                            color: AppColors.textSecondary),
                                      )
                                    : null,
                                filled: true,
                                fillColor: AppColors.card,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 10),
                              ),
                              onChanged: (v) => setState(() => _query = v),
                            ),
                          )
                        : Text(widget.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14)),
                    actions: [
                      IconButton(
                        icon: Icon(
                            _searching ? Icons.close : Icons.search,
                            size: 22),
                        onPressed: () {
                          if (_searching) {
                            _closeSearch();
                          } else {
                            setState(() => _searching = true);
                          }
                        },
                      ),
                    ],
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
                  SliverToBoxAdapter(
                    child: InkWell(
                      onTap: _songs.isEmpty
                          ? null
                          : () => ref.read(playerProvider.notifier).play(
                              _songs.first, queue: _songs),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            const Icon(Icons.play_circle_fill,
                                color: AppColors.primary, size: 28),
                            const SizedBox(width: 8),
                            Text('播放全部',
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(width: 6),
                            Text(
                                _query.isEmpty
                                    ? '(${_songs.length})'
                                    : '(${list.length}/${_songs.length})',
                                style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_loading)
                    const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (list.isEmpty && !_loading)
                    const SliverFillRemaining(
                      child: Center(
                        child: Text('未找到匹配歌曲',
                            style:
                                TextStyle(color: AppColors.textSecondary)),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => SongTile(
                          song: list[i],
                          queue: _query.isEmpty ? _songs : list,
                          index: i,
                          showCover: false,
                          label: _originIndex(list[i]),
                        ),
                        childCount: list.length,
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
}
