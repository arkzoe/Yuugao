import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yuugao/CloudMusic/api/cloud/cloud_entity.dart';
import 'package:yuugao/CloudMusic/yuugao.dart';
import 'package:yuugao/models/song.dart';
import 'package:yuugao/providers/player_provider.dart';
import 'package:yuugao/providers/settings_provider.dart';
import 'package:yuugao/widgets/cover_image.dart';
import 'package:yuugao/widgets/player_panel.dart';

/// 云盘页面 — 展示用户上传到网易云云盘的歌曲列表。
///
/// 支持分页加载，点击歌曲播放。
class CloudPage extends ConsumerStatefulWidget {
  const CloudPage({super.key});

  @override
  ConsumerState<CloudPage> createState() => _CloudPageState();
}

class _CloudPageState extends ConsumerState<CloudPage> {
  final List<CloudDataEntity> _items = [];
  bool _loading = false;
  bool _hasMore = true;
  int _offset = 0;
  static const int _pageSize = 30;
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadMore();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    setState(() => _loading = true);
    try {
      final res =
          await MusicManager().cloudSongList(offset: _offset, limit: _pageSize);
      if (!mounted) return;
      if (res != null && res.code == 200) {
        final data = res.data ?? [];
        setState(() {
          _items.addAll(data);
          _offset += data.length;
          _hasMore = res.hasMore ?? false;
        });
      } else {
        setState(() => _hasMore = false);
      }
    } catch (_) {
      if (mounted) setState(() => _hasMore = false);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _items.clear();
      _offset = 0;
      _hasMore = true;
    });
    await _loadMore();
  }

  void _playSong(CloudDataEntity item) {
    final ss = item.simpleSong;
    if (ss == null) return;

    final ar0 = ss.ar ?? [];
    final song = Song(
      id: ss.id ?? 0,
      name: ss.name ?? item.songName ?? '未知歌曲',
      artist: ar0
          .map((a) => a.name ?? '')
          .where((n) => n.isNotEmpty)
          .join(' / '),
      artistIds: ar0.map((a) => a.id ?? 0).where((id) => id > 0).toList(),
      album: ss.al?.name ?? '',
      coverUrl: ss.al?.picUrl ?? '',
      durationMs: ss.dt ?? 0,
    );

    // 从当前云盘列表构建播放队列
    final queue = _items
        .where((e) => e.simpleSong != null)
        .map((e) {
          final s = e.simpleSong!;
          final ar = s.ar ?? [];
          return Song(
            id: s.id ?? 0,
            name: s.name ?? e.songName ?? '',
            artist: ar
                .map((a) => a.name ?? '')
                .where((n) => n.isNotEmpty)
                .join(' / '),
            artistIds: ar.map((a) => a.id ?? 0).where((id) => id > 0).toList(),
            album: s.al?.name ?? '',
            coverUrl: s.al?.picUrl ?? '',
            durationMs: s.dt ?? 0,
          );
        })
        .toList();

    ref.read(playerProvider.notifier).play(
          song,
          queue: queue,
        );
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(currentColorsProvider);

    return PlayerPanel(
      body: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Text('云盘',
                  style: TextStyle(color: colors.textPrimary, fontSize: 18)),
              const SizedBox(width: 8),
              Icon(Icons.cloud_queue, color: colors.primary, size: 20),
            ],
          ),
          backgroundColor: colors.background,
          elevation: 0,
        ),
        body: RefreshIndicator(
          onRefresh: _refresh,
          child: _items.isEmpty && _loading
              ? const Center(child: CircularProgressIndicator())
              : _items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.cloud_off,
                              size: 64, color: colors.textSecondary),
                          const SizedBox(height: 16),
                          Text('云盘暂无歌曲',
                              style: TextStyle(
                                  color: colors.textSecondary, fontSize: 16)),
                          const SizedBox(height: 8),
                          Text('你可以通过网易云音乐 App 上传歌曲',
                              style: TextStyle(
                                  color: colors.textSecondary, fontSize: 12)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: _items.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= _items.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        return _buildItem(_items[index], colors);
                      },
                    ),
        ),
      ),
    );
  }

  Widget _buildItem(CloudDataEntity item, ThemeColors colors) {
    final ss = item.simpleSong;
    final name = ss?.name ?? item.songName ?? '未知歌曲';
    final artistFromSs = (ss?.ar ?? [])
        .map((a) => a.name ?? '')
        .where((n) => n.isNotEmpty)
        .join(' / ');
    final artist = artistFromSs.isNotEmpty
        ? artistFromSs
        : (item.artist?.isNotEmpty == true ? item.artist! : '未知歌手');
    final cover = ss?.al?.picUrl ?? '';

    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: CoverImage(url: cover, size: 44, radius: 0),
      ),
      title: Text(name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 14, color: colors.textPrimary)),
      subtitle: Text(artist,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12, color: colors.textSecondary)),
      trailing: IconButton(
        icon: Icon(Icons.play_circle_outline, color: colors.primary),
        onPressed: () => _playSong(item),
      ),
      onTap: () => _playSong(item),
    );
  }
}
