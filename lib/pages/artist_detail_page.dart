import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yuugao/CloudMusic/yuugao.dart';
import 'package:yuugao/models/song.dart';
import 'package:yuugao/providers/player_provider.dart';
import 'package:yuugao/providers/settings_provider.dart';
import 'package:yuugao/widgets/cover_image.dart';
import 'package:yuugao/widgets/mini_player_bar.dart';
import 'package:yuugao/widgets/song_tile.dart';
import 'package:yuugao/pages/album_detail_page.dart';

class ArtistDetailPage extends ConsumerStatefulWidget {
  final int artistId;
  final String title;
  final String coverUrl;

  const ArtistDetailPage({
    super.key,
    required this.artistId,
    required this.title,
    required this.coverUrl,
  });

  @override
  ConsumerState<ArtistDetailPage> createState() => _ArtistDetailPageState();
}

class _ArtistDetailPageState extends ConsumerState<ArtistDetailPage>
    with TickerProviderStateMixin {
  late final TabController _tabCtrl;

  // 歌手信息
  String _artistName = '';
  String _artistPic = '';
  int _albumCount = 0;
  int _songCount = 0;
  int _mvCount = 0;
  String _desc = '';

  // 单曲
  List<Song> _songs = [];

  // 专辑
  final _albums = <_ArtistAlbumItem>[];
  final _albumsScrollCtrl = ScrollController();
  bool _albumsLoading = true;
  bool _loadingMoreAlbums = false;
  bool _albumsExhausted = false;
  int _albumsOffset = 0;
  static const int _albumsPageSize = 30;

  bool _songsLoading = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _artistName = widget.title;
    _artistPic = widget.coverUrl;
    _albumsScrollCtrl.addListener(_onAlbumsScroll);
    _loadAll();
  }

  @override
  void dispose() {
    _albumsScrollCtrl.removeListener(_onAlbumsScroll);
    _albumsScrollCtrl.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  void _onAlbumsScroll() {
    if (_albumsExhausted || _loadingMoreAlbums || _albumsLoading) return;
    if (_albumsScrollCtrl.position.pixels >=
        _albumsScrollCtrl.position.maxScrollExtent - 300) {
      _loadMoreAlbums();
    }
  }

  Future<void> _loadAll() async {
    await Future.wait([_loadSongs(), _loadAlbums(), _loadDesc()]);
  }

  Future<void> _loadSongs() async {
    try {
      final res = await MusicManager().artistSongs(id: widget.artistId);
      if (res?.code != 200) {
        if (mounted) setState(() => _songsLoading = false);
        return;
      }
      final artist = res?.artist;
      _artistName = artist?.name?.isNotEmpty == true
          ? artist!.name!
          : widget.title;
      _artistPic = artist?.picUrl?.isNotEmpty == true
          ? artist!.picUrl!
          : widget.coverUrl;
      _albumCount = artist?.albumSize ?? 0;
      _songCount = artist?.musicSize ?? 0;
      _mvCount = artist?.mvSize ?? 0;
      _desc = artist?.briefDesc ?? '';
      _songs = [
        for (final s in (res?.hotSongs ?? [])) Song.fromArtistHotSong(s),
      ];
    } catch (_) {}
    if (mounted) setState(() => _songsLoading = false);
  }

  Future<void> _loadAlbums() async {
    _albumsOffset = 0;
    _albumsExhausted = false;
    try {
      final res = await MusicManager().artistAlbum(
        id: widget.artistId,
        limit: _albumsPageSize,
        offset: 0,
      );
      if (res?.code != 200) {
        if (mounted) setState(() => _albumsLoading = false);
        return;
      }
      _albums.clear();
      for (final a in (res?.hotAlbums ?? [])) {
        _albums.add(_ArtistAlbumItem(
          id: a.id ?? 0,
          name: a.name ?? '',
          picUrl: a.picUrl ?? '',
          size: a.size ?? 0,
          publishTime: a.publishTime ?? 0,
        ));
      }
      _albumsOffset = _albums.length;
      _albumsExhausted = res?.more != true;
      if (_albumCount == 0 && _albums.isNotEmpty) {
        _albumCount = _albums.length;
      }
    } catch (_) {}
    if (mounted) setState(() => _albumsLoading = false);
  }

  Future<void> _loadMoreAlbums() async {
    if (_loadingMoreAlbums || _albumsExhausted) return;
    _loadingMoreAlbums = true;
    if (mounted) setState(() {});

    try {
      final res = await MusicManager().artistAlbum(
        id: widget.artistId,
        limit: _albumsPageSize,
        offset: _albumsOffset,
      );
      if (res?.code != 200) {
        _albumsExhausted = true;
        if (mounted) setState(() => _loadingMoreAlbums = false);
        return;
      }
      final batch = <_ArtistAlbumItem>[];
      for (final a in (res?.hotAlbums ?? [])) {
        batch.add(_ArtistAlbumItem(
          id: a.id ?? 0,
          name: a.name ?? '',
          picUrl: a.picUrl ?? '',
          size: a.size ?? 0,
          publishTime: a.publishTime ?? 0,
        ));
      }
      _albums.addAll(batch);
      _albumsOffset += batch.length;
      _albumsExhausted = res?.more != true;
    } catch (_) {
      _albumsExhausted = true;
    }
    if (mounted) setState(() => _loadingMoreAlbums = false);
  }

  Future<void> _loadDesc() async {
    try {
      final res = await MusicManager().artistDesc(id: widget.artistId);
      if (res?.code != 200) return;
      // 合并 introduction 各项的 txt
      final introBuf = StringBuffer();
      for (final item in (res?.introduction ?? [])) {
        final txt = item.txt;
        if (txt != null && txt.isNotEmpty) {
          if (introBuf.isNotEmpty) introBuf.write('\n\n');
          introBuf.write(txt);
        }
      }
      final merged = introBuf.toString();
      if (merged.isNotEmpty) {
        _desc = merged;
        if (mounted) setState(() {});
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(currentColorsProvider);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _artistName.isNotEmpty ? _artistName : widget.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 16),
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          dividerColor: Colors.transparent,
          indicator: const UnderlineTabIndicator(
            borderSide: BorderSide(width: 2, color: Colors.red),
            insets: EdgeInsets.symmetric(horizontal: 16),
          ),
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 14),
          tabs: const [
            Tab(text: '详情'),
            Tab(text: '单曲'),
            Tab(text: '专辑'),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  _buildDetailTab(colors),
                  _buildSongsTab(colors),
                  _buildAlbumsTab(colors),
                ],
              ),
            ),
            const MiniPlayerBar(),
          ],
        ),
      ),
    );
  }

  // ═══ 详情 Tab ═══

  Widget _buildDetailTab(ThemeColors colors) {
    final statsParts = <String>[];
    if (_albumCount > 0) statsParts.add('$_albumCount 专辑');
    if (_songCount > 0) statsParts.add('$_songCount 单曲');
    if (_mvCount > 0) statsParts.add('$_mvCount MV');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 头像 + 名称
        Center(
          child: ClipOval(
            child: CoverImage(url: _artistPic, size: 120, radius: 60),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            _artistName,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
        ),
        if (statsParts.isNotEmpty) ...[
          const SizedBox(height: 8),
          Center(
            child: Text(
              statsParts.join(' · '),
              style: TextStyle(fontSize: 13, color: colors.textSecondary),
            ),
          ),
        ],
        if (_desc.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            _desc,
            style: TextStyle(
              fontSize: 14,
              color: colors.textPrimary,
              height: 1.6,
            ),
          ),
        ],
      ],
    );
  }

  // ═══ 单曲 Tab ═══

  Widget _buildSongsTab(ThemeColors colors) {
    if (_songsLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_songs.isEmpty) {
      return Center(
        child: Text('暂无热门歌曲', style: TextStyle(color: colors.textSecondary)),
      );
    }
    return Column(
      children: [
        // 播放全部
        InkWell(
          onTap: () => ref
              .read(playerProvider.notifier)
              .play(_songs.first, queue: _songs),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.play_circle_fill, color: colors.primary, size: 28),
                const SizedBox(width: 8),
                const Text(
                  '播放全部',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 6),
                Text(
                  '(${_songs.length})',
                  style: TextStyle(color: colors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _songs.length,
            itemBuilder: (context, i) => SongTile(
              song: _songs[i],
              queue: _songs,
              index: i,
              showCover: false,
            ),
          ),
        ),
      ],
    );
  }

  // ═══ 专辑 Tab ═══

  Widget _buildAlbumsTab(ThemeColors colors) {
    if (_albumsLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_albums.isEmpty) {
      return Center(
        child: Text('暂无专辑', style: TextStyle(color: colors.textSecondary)),
      );
    }
    return ListView.builder(
      controller: _albumsScrollCtrl,
      itemCount: _albums.length + (_albumsExhausted ? 0 : 1),
      itemBuilder: (context, i) {
        if (i >= _albums.length) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        final a = _albums[i];
        String sub = '${a.size}首';
        if (a.publishTime > 0) {
          final d = DateTime.fromMillisecondsSinceEpoch(a.publishTime);
          sub +=
              ' · ${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
        }
        return ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: CoverImage(url: a.picUrl, size: 48, radius: 6),
          ),
          title: Text(
            a.name,
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
              builder: (_) => AlbumDetailPage(
                albumId: a.id,
                title: a.name,
                coverUrl: a.picUrl,
              ),
            ));
          },
        );
      },
    );
  }
}

/// 轻量专辑数据
class _ArtistAlbumItem {
  final int id;
  final String name;
  final String picUrl;
  final int size;
  final int publishTime;

  const _ArtistAlbumItem({
    required this.id,
    required this.name,
    required this.picUrl,
    this.size = 0,
    this.publishTime = 0,
  });
}
