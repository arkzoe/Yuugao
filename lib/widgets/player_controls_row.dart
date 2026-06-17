import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yuugao/providers/player_provider.dart';
import 'package:yuugao/providers/playlist_provider.dart';
import 'package:yuugao/providers/player_theme_provider.dart';
import 'package:yuugao/providers/settings_provider.dart';

/// 喜欢 / 上一首 / 播放暂停(大圆按钮+边框环) / 下一首 / 播放模式。
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
    final playerColors = ref.watch(playerThemeProvider);
    final isFm = ref.watch(playerProvider.select((s) => s.isFmMode));
    final isPlaying = ref.watch(playerProvider.select((s) => s.isPlaying));
    final buffering = ref.watch(playerProvider.select((s) => s.buffering));
    final mode = ref.watch(playerProvider.select((s) => s.mode));
    ref.listen<String?>(playerProvider.select((s) => s.modeMessage), (
      previous,
      next,
    ) {
      if (next == null || next == previous) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next)));
      ref.read(playerProvider.notifier).clearModeMessage();
    });
    final songId = ref.watch(playerProvider.select((s) => s.current?.id));
    final liked =
        songId != null &&
        ref.watch(
          playlistProvider.select((s) => s.likedSongIds.contains(songId)),
        );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── 喜欢 ──
          IconButton(
            icon: Icon(
              liked ? Icons.favorite : Icons.favorite_border,
              color: liked ? colors.primary : colors.textPrimary,
              size: 26,
            ),
            onPressed: songId == null
                ? null
                : () => ref.read(playlistProvider.notifier).toggleLike(songId),
          ),

          // ── 上一首 ──
          IconButton(
            iconSize: 32,
            icon: Icon(Icons.skip_previous, color: colors.textPrimary),
            onPressed: isFm
                ? null
                : () => ref.read(playerProvider.notifier).prev(),
          ),

          // ── 播放/暂停
          SizedBox(
            width: 72,
            height: 72,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(36),
                onTap: () => ref.read(playerProvider.notifier).toggle(),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: playerColors.accent.withValues(alpha: 0.2),
                      width: 3,
                    ),
                    color: playerColors.accent.withValues(alpha: 0.08),
                  ),
                  child: Icon(
                    buffering
                        ? Icons.hourglass_empty
                        : (isPlaying ? Icons.pause : Icons.play_arrow),
                    size: 36,
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ),
          ),

          // ── 下一首 ──
          IconButton(
            iconSize: 32,
            icon: Icon(Icons.skip_next, color: colors.textPrimary),
            onPressed: () => ref.read(playerProvider.notifier).next(),
          ),

          // ── FM 垃圾桶 / 播放模式 ──
          if (isFm)
            IconButton(
              iconSize: 26,
              icon: Icon(
                Icons.thumb_down_alt_outlined,
                color: colors.textSecondary,
              ),
              onPressed: () => ref.read(playerProvider.notifier).trashFm(),
            )
          else
            IconButton(
              icon: Icon(_modeIcon(mode), color: colors.textPrimary, size: 26),
              onPressed: () => ref.read(playerProvider.notifier).cycleMode(),
            ),
        ],
      ),
    );
  }
}
