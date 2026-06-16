import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yuugao/CloudMusic/api/podcast/entity/dj_program_entity.dart';
import 'package:yuugao/CloudMusic/yuugao.dart';
import 'package:yuugao/models/podcast_episode.dart';
import 'package:yuugao/models/song.dart';
import 'package:yuugao/providers/player_provider.dart';
import 'package:yuugao/providers/settings_provider.dart';
import 'package:yuugao/widgets/mini_player_bar.dart';

/// 播客详情页：节目列表 + 点击播放。
class PodcastDetailPage extends ConsumerStatefulWidget {
  final int voiceListId;
  final String title;
  final String coverUrl;

  const PodcastDetailPage({
    super.key,
    required this.voiceListId,
    this.title = '',
    this.coverUrl = '',
  });

  @override
  ConsumerState<PodcastDetailPage> createState() => _PodcastDetailPageState();
}

class _PodcastDetailPageState extends ConsumerState<PodcastDetailPage> {
  final List<DjProgramItem> _episodes = [];
  bool _isLoading = true;
  bool _hasMore = true;
  bool _loadingMore = false;
  int _offset = 0;

  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    Future.microtask(_load);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        _hasMore &&
        !_loadingMore) {
      _loadMore();
    }
  }

  Future<void> _load() async {
    try {
      final res = await MusicManager().djProgramByRadio(
          radioId: widget.voiceListId, limit: 30);
      if (!mounted) return;

      setState(() {
        _episodes.addAll(res?.programs ?? []);
        _isLoading = false;
        _hasMore = res?.more ?? false;
        _offset = _episodes.length;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore) return;
    setState(() => _loadingMore = true);

    try {
      final res = await MusicManager().djProgramByRadio(
        radioId: widget.voiceListId,
        limit: 30,
        offset: _offset,
      );
      if (!mounted) return;
      setState(() {
        _episodes.addAll(res?.programs ?? []);
        _hasMore = res?.more ?? false;
        _offset = _episodes.length;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  void _playEpisode(DjProgramItem item) {
    final songId = item.mainSong?.id;
    if (songId == null || songId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('该节目暂无播放链接')),
      );
      return;
    }

    // 构建全部可播节目的队列，从当前点击的节目开始
    final allSongs = <Song>[];
    final allMeta = <int, Map<String, String>>{};
    int startIndex = 0;

    for (int i = 0; i < _episodes.length; i++) {
      final ep = _episodes[i];
      final sid = ep.mainSong?.id;
      if (sid == null || sid == 0) continue;

      final pe = PodcastEpisode.fromDjProgram(ep, podcastName: widget.title);
      final s = pe.toSong();

      if (ep.id == item.id) startIndex = allSongs.length;
      allSongs.add(s);
      allMeta[s.id] = {
        'name': pe.name,
        'artist': pe.podcastName.isNotEmpty ? pe.podcastName : '播客',
        'coverUrl': pe.coverUrl,
      };
    }

    if (allSongs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('暂无可用播放链接')),
      );
      return;
    }

    // 确保 startIndex 有效
    if (startIndex >= allSongs.length) startIndex = 0;

    if (kDebugMode) {
      debugPrint('[podcast] _playEpisode: allSongs=${allSongs.length} startIndex=$startIndex');
      debugPrint('[podcast] _playEpisode: allMeta keys=${allMeta.keys}');
    }

    ref.read(playerProvider.notifier).play(
      allSongs[startIndex],
      queue: allSongs,
      podcastMeta: allMeta,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(currentColorsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title,
            style: TextStyle(color: colors.textPrimary)),
      ),
      body: Column(
        children: [
          Expanded(child: _buildBody(colors)),
          const MiniPlayerBar(),
        ],
      ),
    );
  }

  Widget _buildBody(ThemeColors colors) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index >= _episodes.length) {
                return _loadingMore
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child:
                            Center(child: CircularProgressIndicator()),
                      )
                    : const SizedBox.shrink();
              }
              final ep = _episodes[index];
              return _EpisodeTile(
                episode: ep,
                label: index + 1,
                colors: colors,
                onTap: () => _playEpisode(ep),
              );
            },
            childCount: _episodes.length + (_hasMore ? 1 : 0),
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 60)),
      ],
    );
  }
}

class _EpisodeTile extends StatelessWidget {
  final DjProgramItem episode;
  final int label;
  final ThemeColors colors;
  final VoidCallback onTap;

  const _EpisodeTile({
    required this.episode,
    required this.label,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasSong =
        episode.mainSong?.id != null && episode.mainSong!.id! > 0;
    final dj = episode.dj?.nickname ?? '';

    return InkWell(
      onTap: hasSong ? onTap : null,
      child: Opacity(
        opacity: hasSong ? 1.0 : 0.4,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: Text(
                  '$label',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 12, color: colors.textSecondary),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      episode.name ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 15,
                          color: hasSong
                              ? colors.textPrimary
                              : colors.textSecondary),
                    ),
                    if (dj.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        dj,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12,
                            color: colors.textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
              if (!hasSong)
                Text('暂不可播',
                    style: TextStyle(
                        fontSize: 11, color: Colors.orange)),
            ],
          ),
        ),
      ),
    );
  }

}
