import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yuugao/CloudMusic/yuugao.dart';
import 'package:yuugao/models/song.dart';
import 'package:yuugao/providers/player_provider.dart';
import 'package:yuugao/providers/settings_provider.dart';
import 'package:yuugao/widgets/song_tile.dart';

class DailySongsPage extends ConsumerStatefulWidget {
  const DailySongsPage({super.key});

  @override
  ConsumerState<DailySongsPage> createState() => _DailySongsPageState();
}

class _DailySongsPageState extends ConsumerState<DailySongsPage> {
  List<Song> _songs = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await MusicManager().recommendSongs();
      _songs = (res?.data?.dailySongs ?? [])
          .map((s) => Song.fromDailySong(s))
          .toList();
    } catch (_) {
      _error = '每日推荐加载失败，请重试';
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(currentColorsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('每日推荐')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? _errorView(colors)
                  : _songs.isEmpty
                  ? Center(
                      child: Text(
                        '暂无推荐（需登录）',
                        style: TextStyle(color: colors.textSecondary),
                      ),
                    )
                  : Column(
                      children: [
                        _playAllBar(),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _songs.length,
                            itemBuilder: (context, i) => SongTile(
                              song: _songs[i],
                              queue: _songs,
                              index: i,
                            ),
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

  Widget _errorView(ThemeColors colors) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_error!, style: TextStyle(color: colors.textSecondary)),
          const SizedBox(height: 8),
          TextButton(onPressed: _load, child: const Text('重试')),
        ],
      ),
    );
  }

  Widget _playAllBar() {
    final colors = ref.watch(currentColorsProvider);
    return InkWell(
      onTap: () =>
          ref.read(playerProvider.notifier).play(_songs.first, queue: _songs),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.play_circle_fill, color: colors.primary, size: 28),
            const SizedBox(width: 8),
            Text(
              '播放全部 (${_songs.length})',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
