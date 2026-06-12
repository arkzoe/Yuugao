import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yuugao/models/song.dart';
import 'package:yuugao/providers/player_provider.dart';
import 'package:yuugao/theme.dart';
import 'package:yuugao/widgets/cover_image.dart';
import 'package:yuugao/widgets/full_player.dart';

/// 首页底部固定迷你播放条。无播放内容时返回空。
/// 切歌过渡期间记住最后一首有效歌曲，避免底边栏消失再出现。
class MiniPlayerBar extends ConsumerStatefulWidget {
  const MiniPlayerBar({super.key});

  @override
  ConsumerState<MiniPlayerBar> createState() => _MiniPlayerBarState();
}

class _MiniPlayerBarState extends ConsumerState<MiniPlayerBar> {
  Song? _lastSong;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(playerProvider);
    final song = state.current;

    if (song != null) _lastSong = song;
    // 过渡期间 current 可能短暂为 null，回退到上一首已知歌曲
    final display = song ?? _lastSong;
    if (display == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => showFullPlayer(context),
      child: Container(
        height: 60,
        decoration: const BoxDecoration(
          color: AppColors.card,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: [
            const SizedBox(width: 10),
            CoverImage(url: display.coverThumb(80), size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(display.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.textPrimary)),
                  Text(display.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                state.isPlaying ? Icons.pause_circle : Icons.play_circle,
                size: 36,
                color: AppColors.primary,
              ),
              onPressed: () => ref.read(playerProvider.notifier).toggle(),
            ),
            IconButton(
              icon: const Icon(Icons.skip_next, color: AppColors.textPrimary),
              onPressed: () => ref.read(playerProvider.notifier).next(),
            ),
          ],
        ),
      ),
    );
  }
}
