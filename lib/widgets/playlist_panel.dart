import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yuugao/providers/player_provider.dart';
import 'package:yuugao/providers/player_theme_provider.dart';
import 'package:yuugao/providers/settings_provider.dart';

/// 当前播放队列：高亮当前项，点击切歌，右侧删除按钮。
///
/// 使用固定高度 ListView.builder 实现虚拟化渲染：
/// 仅构建屏幕可见的 ~10 行，其余滚动时按需创建/回收。
class PlaylistPanel extends ConsumerWidget {
  const PlaylistPanel({super.key});

  /// 每行固定高度，Flutter 可跳过布局计算直接定位。
  static const double _itemHeight = 52.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(currentColorsProvider);
    final playerColors = ref.watch(playerThemeProvider);
    final queue = ref.watch(playerProvider.select((s) => s.queue));
    final currentIndex =
        ref.watch(playerProvider.select((s) => s.currentIndex));
    if (queue.isEmpty) {
      return Center(
        child: Text('队列为空', style: TextStyle(color: colors.textSecondary)),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Icon(Icons.queue_music, size: 18, color: colors.textPrimary),
              const SizedBox(width: 6),
              Text('播放队列 (${queue.length})',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: colors.textPrimary)),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: queue.length,
            itemExtent: _itemHeight,
            addRepaintBoundaries: true,
            itemBuilder: (context, i) {
              final song = queue[i];
              final active = i == currentIndex;
              return _PlaylistItem(
                songName: song.name,
                artist: song.artist.isEmpty ? '未知歌手' : song.artist,
                index: i,
                active: active,
                colors: colors,
                accent: playerColors.accent,
                onTap: () => ref.read(playerProvider.notifier).playAt(i),
                onRemove: () =>
                    ref.read(playerProvider.notifier).removeAt(i),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// 单行播放队列项：轻量 Row 替代 ListTile，减少 Widget 层级。
class _PlaylistItem extends StatelessWidget {
  final String songName;
  final String artist;
  final int index;
  final bool active;
  final ThemeColors colors;
  final Color accent;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _PlaylistItem({
    required this.songName,
    required this.artist,
    required this.index,
    required this.active,
    required this.colors,
    required this.accent,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SizedBox(
          height: PlaylistPanel._itemHeight,
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: active
                    ? Icon(Icons.volume_up, color: accent, size: 18)
                    : Text('${index + 1}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: colors.textSecondary, fontSize: 13)),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        songName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          color: active ? accent : colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 11, color: colors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.close,
                    size: 18, color: colors.textSecondary),
                onPressed: onRemove,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
