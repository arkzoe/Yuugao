import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yuugao/models/song.dart';
import 'package:yuugao/providers/player_provider.dart';
import 'package:yuugao/providers/player_theme_provider.dart';
import 'package:yuugao/providers/settings_provider.dart';
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
    // 只在歌曲切换或主题变化时重建，不再每 ~200ms 重绘整行
    final song =
        ref.watch(playerProvider.select((s) => s.current));
    final isPlaying =
        ref.watch(playerProvider.select((s) => s.isPlaying));
    final playerColors = ref.watch(playerThemeProvider);
    final colors = ref.watch(currentColorsProvider);

    if (song != null) _lastSong = song;
    final display = song ?? _lastSong;
    if (display == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => showFullPlayer(context),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: playerColors.surface,
        ),
        child: Column(
          children: [
            // 顶部细进度条 — 独立监听 progress 避免父级跟着每 ~200ms 重建
            const _MiniProgressBar(),
            Expanded(
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
                            style: TextStyle(
                                fontSize: 14, color: colors.textPrimary)),
                        const SizedBox(height: 2),
                        Text(display.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 11, color: colors.textSecondary)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isPlaying
                          ? Icons.pause_circle
                          : Icons.play_circle,
                      size: 36,
                      color: colors.primary,
                    ),
                    onPressed: () =>
                        ref.read(playerProvider.notifier).toggle(),
                  ),
                  IconButton(
                    icon: Icon(Icons.skip_next, color: colors.textPrimary),
                    onPressed: () => ref.read(playerProvider.notifier).next(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 迷你进度条 — 仅监听 progress，与父级解耦，每 ~200ms 只重建这 2px 高的小条。
class _MiniProgressBar extends ConsumerWidget {
  const _MiniProgressBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress =
        ref.watch(playerProvider.select((s) => s.progress));
    final colors = ref.watch(currentColorsProvider);

    return SizedBox(
      height: 2,
      child: Stack(
        children: [
          Container(color: colors.divider),
          FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(color: colors.primary),
          ),
        ],
      ),
    );
  }
}
