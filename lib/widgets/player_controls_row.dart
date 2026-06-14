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
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(currentColorsProvider);
    final state = ref.watch(playerProvider);
    final song = state.current;
    final liked = song != null &&
        ref.watch(playlistProvider
            .select((s) => s.likedSongIds.contains(song.id)));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(liked ? Icons.favorite : Icons.favorite_border,
                color: liked ? colors.primary : colors.textPrimary),
            onPressed: song == null
                ? null
                : () =>
                    ref.read(playlistProvider.notifier).toggleLike(song.id),
          ),
          IconButton(
            iconSize: 36,
            icon: const Icon(Icons.skip_previous),
            onPressed: state.isFmMode
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
              icon: Icon(state.buffering
                  ? Icons.hourglass_empty
                  : (state.isPlaying ? Icons.pause : Icons.play_arrow)),
              onPressed: () => ref.read(playerProvider.notifier).toggle(),
            ),
          ),
          IconButton(
            iconSize: 36,
            icon: const Icon(Icons.skip_next),
            onPressed: () => ref.read(playerProvider.notifier).next(),
          ),
          // FM 模式：垃圾桶；普通模式：播放模式切换
          if (state.isFmMode)
            IconButton(
              iconSize: 28,
              icon: const Icon(Icons.thumb_down_alt_outlined),
              color: colors.textSecondary,
              onPressed:
                  () => ref.read(playerProvider.notifier).trashFm(),
            )
          else
            IconButton(
              icon: Icon(_modeIcon(state.mode), color: colors.textPrimary),
              onPressed:
                  () => ref.read(playerProvider.notifier).cycleMode(),
            ),
        ],
      ),
    );
  }
}
