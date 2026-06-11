import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yuugao/providers/player_provider.dart';
import 'package:yuugao/theme.dart';

/// 当前播放队列：高亮当前项，点击切歌。
///
/// 注：just_audio 队列重排需同步底层 audio source，第一版仅支持点击播放，
/// 拖动排序留作后续迭代（避免与 shuffle 模式下的索引错乱）。
class PlaylistPanel extends ConsumerWidget {
  const PlaylistPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playerProvider);
    if (state.queue.isEmpty) {
      return const Center(
        child: Text('队列为空', style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              const Icon(Icons.queue_music, size: 18),
              const SizedBox(width: 6),
              Text('播放队列 (${state.queue.length})',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: state.queue.length,
            itemBuilder: (context, i) {
              final song = state.queue[i];
              final active = i == state.currentIndex;
              return ListTile(
                dense: true,
                leading: active
                    ? const Icon(Icons.volume_up,
                        color: AppColors.primary, size: 18)
                    : Text('${i + 1}',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 13)),
                title: Text(
                  song.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    color:
                        active ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  song.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
                onTap: () => ref.read(playerProvider.notifier).playAt(i),
              );
            },
          ),
        ),
      ],
    );
  }
}
