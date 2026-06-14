import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yuugao/CloudMusic/yuugao.dart';
import 'package:yuugao/models/song.dart';
import 'package:yuugao/providers/player_provider.dart';
import 'package:yuugao/providers/settings_provider.dart';
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
  static const int _pageSize = 30;

  List<Song> _songs = [];
  /// 歌单全量曲目 ID（第一次 playlistDetail 即返回），用于分页索引。
  List<int> _allTrackIds = [];
  /// 已加载的曲目 ID，防止 _fetchPage 和 _fetchMore 重叠时重复添加。
  final Set<int> _loadedIds = {};
  String _creator = '';
  bool _initialLoading = true;
  bool _loadingMore = false;
  int _totalCount = 0;
  bool _exhausted = false;

  final _scrollCtrl = ScrollController();

  // 搜索
  bool _searching = false;
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  String _query = '';

  @override
  void dispose() {
    _scrollCtrl.dispose();
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
    _scrollCtrl.addListener(_onScroll);
    _loadFirstPage();
  }

  /// 滚动到底部时自动加载下一页。
  void _onScroll() {
    if (_exhausted || _loadingMore || _initialLoading) return;
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 300) {
      _loadNextPage();
    }
  }

  /// 首屏：playlistDetail 拉取前 [_pageSize] 首 + 全量 trackIds。
  Future<void> _loadFirstPage() async {
    try {
      final res = await BujuanMusicManager().playlistDetail(
        id: widget.playlistId,
        n: _pageSize,
      );
      final pl = res?.playlist;
      if (pl == null) {
        if (mounted) setState(() => _initialLoading = false);
        return;
      }

      _creator = pl.creator?.nickname ?? '';
      _totalCount = pl.trackCount ?? 0;

      // 全量 ID（用于后续分页；playlistDetail 始终返回全量 trackIds）
      _allTrackIds = [
        for (final ti in (pl.trackIds ?? []))
          if (ti.id != null && ti.id! > 0) ti.id!,
      ];
      // fallback：若 trackIds 为空但 tracks 有数据，从 tracks 提取 ID
      if (_allTrackIds.isEmpty && (pl.tracks?.isNotEmpty ?? false)) {
        _allTrackIds = [
          for (final t in pl.tracks!)
            if (t.id != null && t.id! > 0) t.id!,
        ];
      }

      _songs = [
        for (final t in (pl.tracks ?? [])) Song.fromPlaylistTrack(t),
      ];
      _loadedIds.addAll(_songs.map((s) => s.id));

      _exhausted = _songs.length >= _totalCount;
    } catch (_) {}
    if (mounted) setState(() => _initialLoading = false);
  }

  /// 下一页：通过 songDetail 按 trackIds 批量拉取详情。
  Future<void> _loadNextPage() async {
    if (_loadingMore || _exhausted) return;
    _loadingMore = true;
    if (mounted) setState(() {});

    await _fetchPage(_songs.length, _pageSize);

    _loadingMore = false;
    if (mounted) setState(() {});
  }

  /// 按 trackIds 分页拉取（页面和播放器后台扩展共用）。
  Future<void> _fetchPage(int offset, int limit) async {
    final end = (offset + limit).clamp(0, _allTrackIds.length);
    // 跳过已加载的 ID（防止与播放器后台扩展重叠时重复）
    final batchIds = _allTrackIds
        .sublist(offset, end)
        .where((id) => !_loadedIds.contains(id))
        .toList();
    if (batchIds.isEmpty) {
      _exhausted = _songs.length >= _totalCount;
      return;
    }
    try {
      final detail = await BujuanMusicManager().songDetail(ids: batchIds);
      final batch = [
        for (final s in (detail?.songs ?? []))
          if (s.id > 0) Song.fromSongDetail(s),
      ];
      _loadedIds.addAll(batch.map((s) => s.id));
      _songs.addAll(batch);
      _exhausted = _songs.length >= _totalCount;
    } catch (_) {}
  }

  /// 供 AudioService 后台分页拉取的 fetcher。
  Future<List<Song>> _fetchMore(int offset, int limit) async {
    final end = (offset + limit).clamp(0, _allTrackIds.length);
    final batchIds = _allTrackIds.sublist(offset, end);
    if (batchIds.isEmpty) return [];
    try {
      final detail = await BujuanMusicManager().songDetail(ids: batchIds);
      return [
        for (final s in (detail?.songs ?? []))
          if (s.id > 0) Song.fromSongDetail(s),
      ];
    } catch (_) {
      return [];
    }
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
    final colors = ref.watch(currentColorsProvider);
    final list = _filtered;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                controller: _scrollCtrl,
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
                              style: TextStyle(
                                  fontSize: 14,
                                  color: colors.textPrimary),
                              decoration: InputDecoration(
                                hintText: '搜索歌名或歌手…',
                                hintStyle: TextStyle(
                                    fontSize: 13,
                                    color: colors.textSecondary),
                                prefixIcon: Icon(Icons.search,
                                    size: 18,
                                    color: colors.textSecondary),
                                suffixIcon: _query.isNotEmpty
                                    ? GestureDetector(
                                        onTap: () {
                                          _searchCtrl.clear();
                                          setState(() => _query = '');
                                        },
                                        child: Icon(Icons.clear,
                                            size: 18,
                                            color: colors.textSecondary),
                                      )
                                    : null,
                                filled: true,
                                fillColor: colors.card,
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
                            style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: 12)),
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: InkWell(
                      onTap: _songs.isEmpty
                          ? null
                          : () => ref.read(playerProvider.notifier).play(
                                _songs.first,
                                queue: _songs,
                                fetchMore: _exhausted ? null : _fetchMore,
                                totalCount: _totalCount,
                              ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Icon(Icons.play_circle_fill,
                                color: colors.primary, size: 28),
                            const SizedBox(width: 8),
                            Text('播放全部',
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(width: 6),
                            Text(
                                _query.isEmpty
                                    ? '($_totalCount)'
                                    : '(${list.length}/$_totalCount)',
                                style: TextStyle(
                                    color: colors.textSecondary,
                                    fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_initialLoading)
                    const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (list.isEmpty && !_initialLoading)
                    SliverFillRemaining(
                      child: Center(
                        child: Text('未找到匹配歌曲',
                            style:
                                TextStyle(color: colors.textSecondary)),
                      ),
                    )
                  else ...[
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
                        addAutomaticKeepAlives: false,
                      ),
                    ),
                    // 底部指示器
                    SliverToBoxAdapter(
                      child: _loadingMore
                          ? const Padding(
                              padding: EdgeInsets.all(20),
                              child: Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                ),
                              ),
                            )
                          : _exhausted && _songs.isNotEmpty
                              ? Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Center(
                                    child: Text(
                                        '已加载全部 $_totalCount 首',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: colors.textSecondary)),
                                  ),
                                )
                              : const SizedBox.shrink(),
                    ),
                  ],
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
