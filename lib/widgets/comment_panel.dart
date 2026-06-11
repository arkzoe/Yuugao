import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yuugao/CloudMusic/yuugao.dart';
import 'package:yuugao/CloudMusic/api/song/entity/comment_entity.dart';
import 'package:yuugao/providers/player_provider.dart';
import 'package:yuugao/theme.dart';
import 'package:yuugao/widgets/cover_image.dart';

/// 评论面板：热评置顶 + 最新评论。
class CommentPanel extends ConsumerStatefulWidget {
  const CommentPanel({super.key});

  @override
  ConsumerState<CommentPanel> createState() => _CommentPanelState();
}

class _CommentPanelState extends ConsumerState<CommentPanel> {
  int _songId = -1;
  bool _loading = false;
  List<CommentItem> _hot = [];
  List<CommentItem> _latest = [];

  Future<void> _loadFor(int songId) async {
    if (songId == _songId) return;
    _songId = songId;
    setState(() {
      _loading = true;
      _hot = [];
      _latest = [];
    });
    try {
      final res = await BujuanMusicManager().songComments(id: songId, limit: 30);
      _hot = res?.hotComments ?? [];
      _latest = res?.comments ?? [];
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final song = ref.watch(playerProvider.select((s) => s.current));
    if (song != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadFor(song.id));
    }

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_hot.isEmpty && _latest.isEmpty) {
      return const Center(
        child: Text('暂无评论', style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        if (_hot.isNotEmpty) ...[
          _sectionTitle('热门评论'),
          ..._hot.map((c) => _CommentRow(comment: c)),
        ],
        if (_latest.isNotEmpty) ...[
          _sectionTitle('最新评论'),
          ..._latest.map((c) => _CommentRow(comment: c)),
        ],
      ],
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
        child: Text(text,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                fontSize: 13)),
      );
}

class _CommentRow extends StatelessWidget {
  final CommentItem comment;
  const _CommentRow({required this.comment});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipOval(
            child: CoverImage(
                url: comment.user?.avatarUrl ?? '', size: 34, radius: 17),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(comment.user?.nickname ?? '',
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary)),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.thumb_up_alt_outlined,
                            size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 3),
                        Text('${comment.likedCount ?? 0}',
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(comment.content ?? '',
                    style: const TextStyle(
                        fontSize: 14, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text(comment.timeStr ?? '',
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
