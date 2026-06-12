import 'package:flutter/material.dart';

import 'package:yuugao/CloudMusic/yuugao.dart';
import 'package:yuugao/CloudMusic/api/song/entity/comment_entity.dart';
import 'package:yuugao/models/song.dart';
import 'package:yuugao/theme.dart';
import 'package:yuugao/widgets/cover_image.dart';

/// 歌曲评论独立页。
class SongCommentsPage extends StatefulWidget {
  final Song song;

  const SongCommentsPage({super.key, required this.song});

  @override
  State<SongCommentsPage> createState() => _SongCommentsPageState();
}

class _SongCommentsPageState extends State<SongCommentsPage> {
  bool _loading = true;
  List<CommentItem> _hot = [];
  List<CommentItem> _latest = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await BujuanMusicManager()
          .songComments(id: widget.song.id);
      if (res == null) { setState(() => _loading = false); return; }
      _hot = res.hotComments ?? [];
      _latest = res.comments ?? [];
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('歌曲评论'),
        backgroundColor: AppColors.background,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                // 歌曲信息头
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CoverImage(
                          url: widget.song.coverThumb(120), size: 64),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.song.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary)),
                            const SizedBox(height: 4),
                            Text(
                                widget.song.artist.isEmpty
                                    ? '未知歌手'
                                    : widget.song.artist,
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: AppColors.divider),
                if (_hot.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Text('热门评论',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary)),
                  ),
                  ..._hot.map((c) => _commentTile(c)),
                  const Divider(color: AppColors.divider),
                ],
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text('最新评论',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                ),
                if (_latest.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('暂无评论',
                        style: TextStyle(color: AppColors.textSecondary)),
                  )
                else
                  ..._latest.map((c) => _commentTile(c)),
              ],
            ),
    );
  }

  Widget _commentTile(CommentItem c) {
    final avatarUrl = c.user?.avatarUrl ?? '';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipOval(
            child: SizedBox(
              width: 32,
              height: 32,
              child: avatarUrl.isNotEmpty
                  ? CoverImage(url: avatarUrl, size: 32, radius: 0)
                  : Container(
                      color: AppColors.card,
                      child: const Icon(Icons.person,
                          size: 16, color: AppColors.textSecondary),
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(c.user?.nickname ?? '匿名',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                    const Spacer(),
                    Text('${c.likedCount ?? 0}',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary)),
                    const Icon(Icons.thumb_up_alt_outlined,
                        size: 13, color: AppColors.textSecondary),
                  ],
                ),
                const SizedBox(height: 4),
                Text(c.content ?? '',
                    style: const TextStyle(
                        fontSize: 14, color: AppColors.textPrimary)),
                if ((c.time ?? 0) > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    _fmtTime(c.time!),
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmtTime(int ts) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ts);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
