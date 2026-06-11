import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yuugao/providers/cache_provider.dart';
import 'package:yuugao/providers/player_provider.dart';
import 'package:yuugao/theme.dart';
import 'package:yuugao/widgets/cover_image.dart';

/// 歌曲信息面板：封面 / 歌名 / 歌手 / 专辑 / 缓存状态。
class PlayerInfoPanel extends ConsumerWidget {
  const PlayerInfoPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final song = ref.watch(playerProvider.select((s) => s.current));
    if (song == null) return const SizedBox.shrink();
    final cached = ref.watch(cacheProvider).cachedSongs.containsKey(song.id);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Center(
            child: CoverImage(
              url: song.coverThumb(500),
              size: 240,
              radius: 12,
            ),
          ),
          const SizedBox(height: 24),
          Text(song.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _infoRow('歌手', song.artist.isEmpty ? '未知' : song.artist),
          _infoRow('专辑', song.album.isEmpty ? '未知' : song.album),
          _infoRow('缓存', cached ? '已缓存（离线可播）' : '未缓存'),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 48,
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
