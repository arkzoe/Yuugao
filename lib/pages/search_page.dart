import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yuugao/CloudMusic/yuugao.dart';
import 'package:yuugao/CloudMusic/api/search/entity/search_entity.dart';
import 'package:yuugao/models/song.dart';
import 'package:yuugao/providers/settings_provider.dart';
import 'package:yuugao/pages/album_detail_page.dart';
import 'package:yuugao/pages/artist_detail_page.dart';
import 'package:yuugao/pages/playlist_detail_page.dart';
import 'package:yuugao/widgets/cover_image.dart';
import 'package:yuugao/widgets/song_tile.dart';

/// 搜索类型常量
const _kTypeSong = 1;
const _kTypeAlbum = 10;
const _kTypeArtist = 100;
const _kTypePlaylist = 1000;

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage>
    with TickerProviderStateMixin {
  final _controller = TextEditingController();
  late final TabController _tabController;

  // 每个 tab 独立的结果 + 状态
  List<Song> _songResults = [];
  List<SearchArtistItem> _artistResults = [];
  List<SearchAlbumItem> _albumResults = [];
  List<SearchPlaylistItem> _playlistResults = [];

  final _loading = <int, bool>{};
  final _searched = <int, bool>{};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChange);
  }

  @override
  void dispose() {
    _controller.dispose();
    _tabController.removeListener(_onTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChange() {
    if (!_tabController.indexIsChanging) return;
    // 切表时若已有 keyword 且新 tab 未搜过则自动搜索
    final kw = _controller.text.trim();
    if (kw.isNotEmpty && _searched[_currentType] != true) {
      _search();
    }
    setState(() {}); // 刷新 UI 以切换列表
  }

  int get _currentType {
    switch (_tabController.index) {
      case 1:
        return _kTypePlaylist;
      case 2:
        return _kTypeAlbum;
      case 3:
        return _kTypeArtist;
      default:
        return _kTypeSong;
    }
  }

  Future<void> _search() async {
    final kw = _controller.text.trim();
    if (kw.isEmpty) return;
    FocusScope.of(context).unfocus();
    final type = _currentType;
    setState(() => _loading[type] = true);
    try {
      final res = await MusicManager().search(
        keywords: kw,
        type: type,
        limit: 50,
      );
      if (!mounted) return;
      switch (type) {
        case _kTypeSong:
          _songResults = (res?.result?.songs ?? [])
              .map((s) => Song.fromSearchItem(s))
              .toList();
        case _kTypeArtist:
          _artistResults = res?.result?.artists ?? [];
        case _kTypeAlbum:
          _albumResults = res?.result?.albums ?? [];
        case _kTypePlaylist:
          _playlistResults = res?.result?.playlists ?? [];
      }
      _searched[type] = true;
    } catch (_) {
      if (!mounted) return;
      _clearType(type);
    }
    if (mounted) {
      setState(() => _loading[type] = false);
    }
  }

  void _clearType(int type) {
    switch (type) {
      case _kTypeSong:
        _songResults = [];
      case _kTypeArtist:
        _artistResults = [];
      case _kTypeAlbum:
        _albumResults = [];
      case _kTypePlaylist:
        _playlistResults = [];
    }
  }

  bool get _isLoading => _loading[_currentType] == true;
  bool get _hasSearched => _searched[_currentType] == true;

  bool get _isEmpty {
    switch (_currentType) {
      case _kTypeSong:
        return _songResults.isEmpty;
      case _kTypeArtist:
        return _artistResults.isEmpty;
      case _kTypeAlbum:
        return _albumResults.isEmpty;
      case _kTypePlaylist:
        return _playlistResults.isEmpty;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _search(),
          decoration: const InputDecoration(
            hintText: '搜索音乐、歌手、歌单',
            border: InputBorder.none,
          ),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: _search),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Material(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: TabBar(
                controller: _tabController,
                isScrollable: false,
                dividerHeight: 0,
                indicator: const UnderlineTabIndicator(
                  borderSide: BorderSide(width: 2, color: Colors.red),
                  insets: EdgeInsets.symmetric(horizontal: 16),
                ),
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: const TextStyle(fontSize: 14),
                tabs: const [
                  Tab(text: '单曲'),
                  Tab(text: '歌单'),
                  Tab(text: '专辑'),
                  Tab(text: '歌手'),
                ],
              ),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    final colors = ref.watch(currentColorsProvider);
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (!_hasSearched) {
      return Center(
        child: Text('输入关键词搜索', style: TextStyle(color: colors.textSecondary)),
      );
    }
    if (_isEmpty) {
      return Center(
        child: Text('没有找到结果', style: TextStyle(color: colors.textSecondary)),
      );
    }

    switch (_currentType) {
      case _kTypeArtist:
        return _buildArtistList(colors);
      case _kTypeAlbum:
        return _buildAlbumList(colors);
      case _kTypePlaylist:
        return _buildPlaylistList(colors);
      default:
        return _buildSongList();
    }
  }

  // ═══ 单曲列表 ═══

  Widget _buildSongList() {
    return ListView.builder(
      itemCount: _songResults.length,
      itemBuilder: (context, i) => SongTile(
        song: _songResults[i],
        queue: _songResults,
        index: i,
        showCover: false,
      ),
    );
  }

  // ═══ 歌手列表 ═══

  Widget _buildArtistList(ThemeColors colors) {
    return ListView.builder(
      itemCount: _artistResults.length,
      itemBuilder: (context, i) {
        final a = _artistResults[i];
        final subtitle = [
          if ((a.musicSize ?? 0) > 0) '单曲: ${a.musicSize}',
          if ((a.albumSize ?? 0) > 0) '专辑: ${a.albumSize}',
        ].join('  ');
        return ListTile(
          leading: ClipOval(
            child: CoverImage(
              url: a.img1v1Url?.isNotEmpty == true
                  ? a.img1v1Url!
                  : a.picUrl ?? '',
              size: 48,
              radius: 24,
            ),
          ),
          title: Text(
            a.name ?? '',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: colors.textPrimary,
            ),
          ),
          subtitle: subtitle.isNotEmpty
              ? Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                )
              : null,
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => ArtistDetailPage(
                artistId: a.id ?? 0,
                title: a.name ?? '',
                coverUrl: (a.picUrl?.isNotEmpty == true
                        ? a.picUrl
                        : a.img1v1Url) ??
                    '',
              ),
            ));
          },
        );
      },
    );
  }

  // ═══ 专辑列表 ═══

  Widget _buildAlbumList(ThemeColors colors) {
    return ListView.builder(
      itemCount: _albumResults.length,
      itemBuilder: (context, i) {
        final a = _albumResults[i];
        return ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: CoverImage(url: a.picUrl ?? '', size: 48, radius: 6),
          ),
          title: Text(
            a.name ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: colors.textPrimary,
            ),
          ),
          subtitle: Text(
            '${a.artist?.name ?? '未知歌手'}  ${(a.size ?? 0) > 0 ? '· ${a.size}首' : ''}',
            style: TextStyle(fontSize: 12, color: colors.textSecondary),
          ),
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => AlbumDetailPage(
                albumId: a.id ?? 0,
                title: a.name ?? '',
                coverUrl: a.picUrl ?? '',
              ),
            ));
          },
        );
      },
    );
  }

  // ═══ 歌单列表 ═══

  Widget _buildPlaylistList(ThemeColors colors) {
    return ListView.builder(
      itemCount: _playlistResults.length,
      itemBuilder: (context, i) {
        final p = _playlistResults[i];
        final sub = [
          '${p.trackCount ?? 0}首',
          if ((p.playCount ?? 0) > 0) _formatCount(p.playCount!),
          if ((p.creator?.nickname?.isNotEmpty ?? false))
            'by ${p.creator!.nickname}',
        ].join(' · ');
        return ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: CoverImage(url: p.coverImgUrl ?? '', size: 48, radius: 6),
          ),
          title: Text(
            p.name ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: colors.textPrimary,
            ),
          ),
          subtitle: Text(
            sub,
            style: TextStyle(fontSize: 12, color: colors.textSecondary),
          ),
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => PlaylistDetailPage(
                playlistId: p.id ?? 0,
                title: p.name ?? '',
                coverUrl: p.coverImgUrl ?? '',
              ),
            ));
          },
        );
      },
    );
  }

  /// 播放量格式化：1.2万 / 345.6万 / 1234
  String _formatCount(int n) {
    if (n >= 10000) {
      final v = n / 10000.0;
      return '${v.toStringAsFixed(v < 10 ? 1 : 0)}万';
    }
    return n.toString();
  }
}
