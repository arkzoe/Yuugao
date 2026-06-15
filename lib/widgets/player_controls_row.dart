import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yuugao/providers/player_provider.dart';
import 'package:yuugao/providers/playlist_provider.dart';
import 'package:yuugao/providers/settings_provider.dart';

/// 控制行：喜欢 / 上一首 / 播放暂停 / 下一首 / 播放模式。
class PlayerControlsRow extends ConsumerWidget {
  const PlayerControlsRow({super.key});

  IconData _modeIcon(PlayMode mode) {
    switch (mode) {
      case PlayMode.sequential:
        return Icons.repeat;
      case PlayMode.shuffle:
        return Icons.shuffle;
      case PlayMode.repeatOne:
        return Icons.repeat_one;
      case PlayMode.heartbeat:
        return Icons.favorite;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(currentColorsProvider);
    // 仅监听影响按钮外观的字段，避免每 ~200ms 整行重建
    final isFm = ref.watch(playerProvider.select((s) => s.isFmMode));
    final isPlaying = ref.watch(playerProvider.select((s) => s.isPlaying));
    final buffering = ref.watch(playerProvider.select((s) => s.buffering));
    final mode = ref.watch(playerProvider.select((s) => s.mode));
    final songId = ref.watch(playerProvider.select((s) => s.current?.id));
    final liked = songId != null &&
        ref.watch(playlistProvider
            .select((s) => s.likedSongIds.contains(songId)));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(liked ? Icons.favorite : Icons.favorite_border,
                color: liked ? colors.primary : colors.textPrimary),
            onPressed: songId == null
                ? null
                : () =>
                    ref.read(playlistProvider.notifier).toggleLike(songId),
          ),
          IconButton(
            iconSize: 36,
            icon: const Icon(Icons.skip_previous),
            onPressed: isFm
                ? null // FM 无上一首
                : () => ref.read(playerProvider.notifier).prev(),
          ),
          Container(
            decoration: BoxDecoration(
              color: colors.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              iconSize: 44,
              color: Colors.white,
              icon: Icon(buffering
                  ? Icons.hourglass_empty
                  : (isPlaying ? Icons.pause : Icons.play_arrow)),
              onPressed: () => ref.read(playerProvider.notifier).toggle(),
            ),
          ),
          IconButton(
            iconSize: 36,
            icon: const Icon(Icons.skip_next),
            onPressed: () => ref.read(playerProvider.notifier).next(),
          ),
          // FM 模式：垃圾桶；普通模式：播放模式切换
          if (isFm)
            IconButton(
              iconSize: 28,
              icon: const Icon(Icons.thumb_down_alt_outlined),
              color: colors.textSecondary,
              onPressed:
                  () => ref.read(playerProvider.notifier).trashFm(),
            )
          else
            IconButton(
              icon: Icon(_modeIcon(mode), color: colors.textPrimary),
              onPressed:
                  () => ref.read(playerProvider.notifier).cycleMode(),
            ),
        ],
      ),
    );
  }
}
