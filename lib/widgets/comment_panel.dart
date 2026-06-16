import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yuugao/CloudMusic/yuugao.dart';
import 'package:yuugao/CloudMusic/api/song/entity/comment_entity.dart';
import 'package:yuugao/providers/player_provider.dart';
import 'package:yuugao/providers/settings_provider.dart';
import 'package:yuugao/widgets/cover_image.dart';

/// 评论面板：热评置顶 + 最新评论（分页加载）。
class CommentPanel extends ConsumerStatefulWidget {
  const CommentPanel({super.key});

  @override
  ConsumerState<CommentPanel> createState() => _CommentPanelState();
}

class _CommentPanelState extends ConsumerState<CommentPanel> {
  int _songId = -1;
  bool _loading = false;
  bool _loadingMore = false;
  int _loadGen = 0; // 代次守卫，防快速切歌时旧结果覆盖新结果
  List<CommentItem> _hot = [];
  List<CommentItem> _latest = [];

  /// 是否还有更多最新评论（由 API 的 more 字段指示）。
  bool _hasMore = false;

  static const _pageSize = 30;

  Future<void> _loadFor(int songId) async {
    if (songId == _songId) return;
    _songId = songId;
    final gen = ++_loadGen;
    setState(() {
      _loading = true;
      _loadingMore = false;
      _hot = [];
      _latest = [];
      _hasMore = false;
    });
    try {
      final res = await MusicManager().songComments(
        id: songId,
        limit: _pageSize,
        offset: 0,
      );
      if (gen != _loadGen || !mounted) return;
      _hot = res?.hotComments ?? [];
      _latest = res?.comments ?? [];
      _hasMore = res?.more ?? false;
    } catch (_) {
      if (gen != _loadGen || !mounted) return;
    }
    if (!mounted) return;
    if (gen == _loadGen) setState(() => _loading = false);
  }

  /// 加载更多最新评论。
  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    final gen = _loadGen;
    try {
      final res = await MusicManager().songComments(
        id: _songId,
        limit: _pageSize,
        offset: _latest.length,
      );
      if (gen != _loadGen || !mounted) return;
      _latest.addAll(res?.comments ?? []);
      _hasMore = res?.more ?? false;
    } catch (_) {
      if (gen != _loadGen || !mounted) return;
    }
    if (!mounted) return;
    if (gen == _loadGen) setState(() => _loadingMore = false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(currentColorsProvider);
    final songId = ref.watch(playerProvider.select((s) => s.current?.id));
    // 歌曲切换时加载评论（listen 仅响应变化，不触发初始值）
    ref.listen(playerProvider.select((s) => s.current?.id), (prev, next) {
      if (next != null && next != prev) _loadFor(next);
    });
    // 首次挂载或 songId 为初始值时触发加载（_loadFor 内部 _songId 守卫防重复）
    if (songId != null) _loadFor(songId);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_hot.isEmpty && _latest.isEmpty) {
      return Center(
        child: Text('暂无评论', style: TextStyle(color: colors.textSecondary)),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        if (_hot.isNotEmpty) ...[
          _sectionTitle('热门评论'),
          ..._hot.map((c) => _CommentRow(comment: c)),
        ],
        if (_latest.isNotEmpty) ...[
          _sectionTitle('最新评论'),
          ..._latest.map((c) => _CommentRow(comment: c)),
          // 加载更多按钮
          if (_hasMore)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: _loadingMore
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : TextButton(
                        onPressed: _loadMore,
                        child: const Text('加载更多'),
                      ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _sectionTitle(String text) {
    final colors = ref.watch(currentColorsProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: colors.textSecondary,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _CommentRow extends ConsumerWidget {
  final CommentItem comment;
  const _CommentRow({required this.comment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(currentColorsProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipOval(
            child: CoverImage(
              url: comment.user?.avatarUrl ?? '',
              size: 34,
              radius: 17,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        comment.user?.nickname ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.thumb_up_alt_outlined,
                          size: 12,
                          color: colors.textSecondary,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${comment.likedCount ?? 0}',
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.content ?? '',
                  style: TextStyle(fontSize: 14, color: colors.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  comment.timeStr ?? '',
                  style: TextStyle(fontSize: 10, color: colors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
