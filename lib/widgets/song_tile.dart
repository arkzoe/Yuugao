import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yuugao/models/song.dart';
import 'package:yuugao/providers/player_provider.dart';
import 'package:yuugao/providers/playlist_provider.dart';
import 'package:yuugao/theme.dart';
import 'package:yuugao/widgets/cover_image.dart';

/// 歌曲列表项：封面 + 歌名/歌手 + 喜欢按钮。
class SongTile extends ConsumerWidget {
  final Song song;
  final List<Song> queue;
  final int index;

  const SongTile({
    super.key,
    required this.song,
    required this.queue,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liked = ref.watch(
      playlistProvider.select((s) => s.likedSongIds.contains(song.id)),
    );
    final current = ref.watch(
      playerProvider.select((s) => s.current?.id == song.id),
    );

    return InkWell(
      onTap: () => ref.read(playerProvider.notifier).play(song, queue: queue),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            CoverImage(url: song.coverThumb(80), size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      color: current ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    song.artist.isEmpty ? '未知歌手' : song.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                liked ? Icons.favorite : Icons.favorite_border,
                color: liked ? AppColors.primary : AppColors.textSecondary,
                size: 20,
              ),
              onPressed: () =>
                  ref.read(playlistProvider.notifier).toggleLike(song.id),
            ),
          ],
        ),
      ),
    );
  }
}
