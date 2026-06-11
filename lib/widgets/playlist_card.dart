import 'package:flutter/material.dart';

import 'package:yuugao/CloudMusic/api/user/entity/user_playlist_entity.dart';
import 'package:yuugao/pages/playlist_detail_page.dart';
import 'package:yuugao/theme.dart';
import 'package:yuugao/widgets/cover_image.dart';

/// 歌单条目：左侧封面 + 右侧歌单名与歌曲数，单列横向布局。
class PlaylistCard extends StatelessWidget {
  final UserPlaylistPlaylist playlist;

  const PlaylistCard({super.key, required this.playlist});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => PlaylistDetailPage(
            playlistId: playlist.id ?? 0,
            title: playlist.name ?? '',
            coverUrl: playlist.coverImgUrl ?? '',
          ),
        ));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            CoverImage(
              url: '${playlist.coverImgUrl ?? ''}?param=150y150',
              size: 56,
              radius: 8,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    playlist.name ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${playlist.trackCount ?? 0} 首',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
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
