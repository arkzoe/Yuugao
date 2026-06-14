import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yuugao/models/song.dart';
import 'package:yuugao/pages/song_comments_page.dart';
import 'package:yuugao/providers/player_provider.dart';
import 'package:yuugao/providers/settings_provider.dart';
import 'package:yuugao/widgets/cover_image.dart';

/// 歌曲列表项：序号 + 封面 + 歌名/歌手 + VIP + 更多菜单。
///
/// [showCover] 为 false 时省略封面缩略图以加速长列表加载。
/// [label] 非 null 时在最左侧显示序号。
class SongTile extends ConsumerWidget {
  final Song song;
  final List<Song> queue;
  final int index;
  final bool showCover;
  final int? label;

  const SongTile({
    super.key,
    required this.song,
    required this.queue,
    this.index = 0,
    this.showCover = true,
    this.label,
  });

  void _showMenu(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(currentColorsProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 歌曲信息
                Text(song.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary)),
                const SizedBox(height: 4),
                Text(
                    song.artist.isEmpty ? '未知歌手' : song.artist,
                    style: TextStyle(
                        fontSize: 13, color: colors.textSecondary)),
                const SizedBox(height: 12),
                Divider(color: colors.divider),
                // 下一首播放
                ListTile(
                  leading:
                      Icon(Icons.skip_next, color: colors.textPrimary),
                  title: Text('下一首播放',
                      style: TextStyle(color: colors.textPrimary)),
                  onTap: () {
                    ref.read(playerProvider.notifier).insertNext(song);
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('「${song.name}」将在当前歌曲后播放'),
                        backgroundColor: colors.card,
                      ),
                    );
                  },
                ),
                // 查看评论
                ListTile(
                  leading: Icon(Icons.comment_outlined,
                      color: colors.textPrimary),
                  title: Text('查看评论',
                      style: TextStyle(color: colors.textPrimary)),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SongCommentsPage(song: song),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(currentColorsProvider);
    final current = ref.watch(
      playerProvider.select((s) => s.current?.id == song.id),
    );

    return InkWell(
      onTap: () => ref.read(playerProvider.notifier).play(song, queue: queue),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            if (label != null) ...[
              SizedBox(
                width: 28,
                child: Text(
                  '$label',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 12, color: colors.textSecondary),
                ),
              ),
              const SizedBox(width: 4),
            ],
            if (showCover) ...[
              CoverImage(url: song.coverThumb(80), size: 44),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          song.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            color: current
                                ? colors.primary
                                : colors.textPrimary,
                          ),
                        ),
                      ),
                      // fee==1 才是 VIP 专享；fee==4/8 是数字专辑/付费单曲，不是 VIP
                      if (song.fee == 1) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 3, vertical: 1),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: colors.primary, width: 0.7),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            'VIP',
                            style: TextStyle(
                              fontSize: 9,
                              color: colors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    song.artist.isEmpty ? '未知歌手' : song.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 12, color: colors.textSecondary),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.more_vert,
                  color: colors.textSecondary, size: 20),
              onPressed: () => _showMenu(context, ref),
            ),
          ],
        ),
      ),
    );
  }
}
