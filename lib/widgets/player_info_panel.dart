import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yuugao/pages/artist_detail_page.dart';
import 'package:yuugao/providers/player_provider.dart';
import 'package:yuugao/providers/player_theme_provider.dart';
import 'package:yuugao/providers/settings_provider.dart';
import 'package:yuugao/widgets/cover_image.dart';

/// 歌曲信息面板 — 封面（Hero 过渡）/ 歌名 / 歌手列表。
///
/// 封面居中大图 + 歌名在封面下方，
/// 封面带彩色阴影增加层次感。
///
/// 封面支持左右滑动切歌
///
/// 歌手区域
/// 每位歌手独立一行，点击可跳转到歌手详情页。
class PlayerInfoPanel extends ConsumerWidget {
  final bool hideCover;
  const PlayerInfoPanel({super.key, this.hideCover = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(currentColorsProvider);
    final playerColors = ref.watch(playerThemeProvider);
    final song = ref.watch(playerProvider.select((s) => s.current));
    if (song == null) return const SizedBox.shrink();

    final screenHeight = MediaQuery.of(context).size.height;
    // 封面大小：屏幕高度的 28%（缩小一点为下方内容留空间）
    final coverSize = (screenHeight * 0.28).clamp(180.0, 260.0);

    // 拆分歌手名与 ID（按 " / " 分割）
    final artistNames = song.artist.split(' / ');
    final artistIds = song.artistIds;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // ── 封面（面板头部已有封面时可隐藏）──
          if (!hideCover) ...[
            const SizedBox(height: 16),
            Center(
              child: GestureDetector(
                onHorizontalDragEnd: (details) {
                  final v = details.primaryVelocity ?? 0;
                  if (v.abs() < 300) return;
                  if (v < 0) {
                    ref.read(playerProvider.notifier).next();
                  } else {
                    ref.read(playerProvider.notifier).prev();
                  }
                },
                child: Container(
                  width: coverSize,
                  height: coverSize,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: playerColors.accent.withValues(alpha: 0.35),
                        blurRadius: 40,
                        offset: const Offset(0, 16),
                      ),
                      BoxShadow(
                        color: playerColors.accent.withValues(alpha: 0.15),
                        blurRadius: 80,
                        offset: const Offset(0, 32),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CoverImage(
                      url: song.coverThumb(500),
                      size: coverSize,
                      radius: 0,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
          // ── 歌名 ──
          Text(
            song.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          // ── 歌手列表
          if (artistNames.isNotEmpty && artistNames.any((n) => n.isNotEmpty))
            _buildSectionHeader('歌手', colors)
          else
            const SizedBox(height: 8),
          ...List.generate(artistNames.length, (i) {
            final name = artistNames[i].trim();
            if (name.isEmpty) return const SizedBox.shrink();

            final hasId = i < artistIds.length && artistIds[i] > 0;
            return _buildArtistTile(
              context,
              name,
              artistId: hasId ? artistIds[i] : null,
              coverUrl: song.coverUrl,
              colors: colors,
            );
          }),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// 段落标题
  Widget _buildSectionHeader(String title, ThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
      ),
    );
  }

  /// 单个歌手行：名字 + 箭头，可点击跳转歌手详情。
  Widget _buildArtistTile(
    BuildContext context,
    String name, {
    required int? artistId,
    required String coverUrl,
    required ThemeColors colors,
  }) {
    final tile = Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.divider, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: colors.textPrimary,
              ),
            ),
          ),
          if (artistId != null)
            Icon(Icons.chevron_right, size: 22, color: colors.textSecondary),
        ],
      ),
    );

    if (artistId != null) {
      return GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ArtistDetailPage(
                artistId: artistId,
                title: name,
                coverUrl: coverUrl,
              ),
            ),
          );
        },
        child: tile,
      );
    }
    return tile;
  }
}
