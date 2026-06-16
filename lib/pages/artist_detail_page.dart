import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yuugao/CloudMusic/yuugao.dart';
import 'package:yuugao/models/song.dart';
import 'package:yuugao/providers/player_provider.dart';
import 'package:yuugao/providers/settings_provider.dart';
import 'package:yuugao/widgets/cover_image.dart';
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

  // 专辑（合并首屏 + 分页为单一方法）
  final _albums = <_ArtistAlbumItem>[];
  final _albumsScrollCtrl = ScrollController();
  bool _albumsLoading = true;
  bool _loadingMore = false;
  bool _noMoreAlbums = false;
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
    if (_noMoreAlbums || _loadingMore || _albumsLoading) return;
    if (_albumsScrollCtrl.position.pixels >=
        _albumsScrollCtrl.position.maxScrollExtent - 300) {
      _fetchAlbums(append: true);
    }
  }

  Future<void> _loadAll() async {
    await Future.wait([_loadSongs(), _fetchAlbums(), _loadDesc()]);
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

  /// 拉取专辑列表。[append] 为 true 时追加到已有列表（分页），否则替换。
  Future<void> _fetchAlbums({bool append = false}) async {
    if (append && (_loadingMore || _noMoreAlbums)) return;
    if (append) {
      _loadingMore = true;
    } else {
      _albums.clear();
      _noMoreAlbums = false;
    }
    if (mounted && append) setState(() {});

    try {
      final res = await MusicManager().artistAlbum(
        id: widget.artistId,
        limit: _albumsPageSize,
        offset: append ? _albums.length : 0,
      );
      if (res?.code != 200) {
        _noMoreAlbums = true;
        if (mounted) {
          setState(() {
            _albumsLoading = false;
            _loadingMore = false;
          });
        }
        return;
      }
      for (final a in (res?.hotAlbums ?? [])) {
        _albums.add(
          _ArtistAlbumItem(
            id: a.id ?? 0,
            name: a.name ?? '',
            picUrl: a.picUrl ?? '',
            size: a.size ?? 0,
            publishTime: a.publishTime ?? 0,
          ),
        );
      }
      _noMoreAlbums = res?.more != true;
      if (_albumCount == 0 && _albums.isNotEmpty) {
        _albumCount = _albums.length;
      }
    } catch (_) {
      _noMoreAlbums = true;
    }
    if (mounted) {
      setState(() {
        _albumsLoading = false;
        _loadingMore = false;
      });
    }
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
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
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
          ],
        ),
      ),
    );
  }

  // ═══ 详情 Tab ═══
  //
  //  Stack 卡片布局：大头像叠在圆角卡片上方，
  // 卡片内展示歌手名 + 专辑/单曲/MV 统计，卡片下方展示简介。

  Widget _buildDetailTab(ThemeColors colors) {
    const avatarSize = 130.0;
    const overlap = avatarSize / 2; // 头像与卡片重叠量

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // ── 头像 + 卡片 Stack ──
          Stack(
            alignment: Alignment.topCenter,
            children: [
              // 圆角卡片（位于下方，给头像留出空间）
              Container(
                width: double.infinity,
                margin: EdgeInsets.only(top: overlap),
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  bottom: 24,
                  top: overlap + 10,
                ),
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    // 歌手名
                    Text(
                      _artistName.isNotEmpty ? _artistName : widget.title,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    // 统计行：专辑 / 单曲 / MV
                    if (_albumCount > 0 || _songCount > 0 || _mvCount > 0) ...[
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _statItem('$_albumCount', '专辑', colors),
                          _statItem('$_songCount', '单曲', colors),
                          _statItem('$_mvCount', 'MV', colors),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // 圆形头像（叠在卡片上方）
              ClipOval(
                child: CoverImage(
                  url: _artistPic,
                  size: avatarSize,
                  radius: avatarSize / 2,
                ),
              ),
            ],
          ),
          // ── 简介（卡片下方）──
          if (_desc.isNotEmpty) ...[
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _desc,
                style: TextStyle(
                  fontSize: 14,
                  color: colors.textPrimary,
                  height: 1.7,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 统计数字 + 标签（用于详情 Tab）。
  Widget _statItem(String value, String label, ThemeColors colors) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: colors.textSecondary),
        ),
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
      itemCount: _albums.length + (_noMoreAlbums ? 0 : 1),
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
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AlbumDetailPage(
                  albumId: a.id,
                  title: a.name,
                  coverUrl: a.picUrl,
                ),
              ),
            );
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
