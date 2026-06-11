import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yuugao/CloudMusic/yuugao.dart';
import 'package:yuugao/models/song.dart';
import 'package:yuugao/pages/daily_songs_page.dart';
import 'package:yuugao/providers/player_provider.dart';
import 'package:yuugao/theme.dart';

/// 首页四个功能入口：每日 / FM / 博客 / 云盘。
class HomeActionButtons extends ConsumerWidget {
  const HomeActionButtons({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = [
      (
        _Action(Icons.wb_sunny, '每日推荐', AppColors.primary),
        () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const DailySongsPage()));
        },
      ),
      (
        _Action(Icons.radio, '私人FM', Colors.orange),
        () => _startFm(context, ref),
      ),
      (
        _Action(Icons.article, '博客', Colors.lightBlue),
        () => _todo(context, '博客'),
      ),
      (
        _Action(Icons.cloud, '云盘', Colors.tealAccent),
        () => _todo(context, '云盘'),
      ),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: items.map((e) {
        final action = e.$1;
        return _ActionButton(action: action, onTap: e.$2);
      }).toList(),
    );
  }

  Future<void> _startFm(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    // FM 无独立 API：复用推荐新歌作为随机流
    final res = await BujuanMusicManager().recommendNewSong(limit: 20);
    final songs = (res?.result ?? [])
        .map((r) {
          final s = r.song;
          if (s == null) return null;
          return Song(
            id: s.id ?? 0,
            name: s.name ?? '',
            artist: (s.artists ?? [])
                .map((a) => a.name ?? '')
                .where((n) => n.isNotEmpty)
                .join(' / '),
            album: s.album?.name ?? '',
            coverUrl: s.album?.picUrl ?? '',
            durationMs: s.duration ?? 0,
          );
        })
        .whereType<Song>()
        .where((s) => s.id > 0)
        .toList();
    if (songs.isEmpty) {
      messenger.showSnackBar(
          const SnackBar(content: Text('FM 暂无可用歌曲')));
      return;
    }
    await ref.read(playerProvider.notifier).play(songs.first, queue: songs);
    await ref.read(playerProvider.notifier).setMode(PlayMode.shuffle);
  }

  void _todo(BuildContext context, String name) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$name 功能开发中')));
  }
}

class _Action {
  final IconData icon;
  final String label;
  final Color color;
  _Action(this.icon, this.label, this.color);
}

class _ActionButton extends StatelessWidget {
  final _Action action;
  final VoidCallback onTap;
  const _ActionButton({required this.action, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: action.color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(action.icon, color: action.color, size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            action.label,
            style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}
