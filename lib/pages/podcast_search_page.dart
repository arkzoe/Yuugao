import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yuugao/CloudMusic/api/podcast/entity/user_dj_entity.dart';
import 'package:yuugao/CloudMusic/yuugao.dart';
import 'package:yuugao/pages/podcast_detail_page.dart';
import 'package:yuugao/providers/settings_provider.dart';
import 'package:yuugao/providers/user_provider.dart';
import 'package:yuugao/widgets/cover_image.dart';
import 'package:yuugao/widgets/mini_player_bar.dart';

/// 用户订阅的播客列表页。
class PodcastSearchPage extends ConsumerStatefulWidget {
  const PodcastSearchPage({super.key});

  @override
  ConsumerState<PodcastSearchPage> createState() => _PodcastSearchPageState();
}

class _PodcastSearchPageState extends ConsumerState<PodcastSearchPage> {
  List<UserDjRadio> _podcasts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    final uid = ref.read(userProvider).uid;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final res = await MusicManager().userDj(uid: uid);
      if (!mounted) return;
      setState(() {
        _podcasts = res?.djRadios ?? [];
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _openDetail(UserDjRadio item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PodcastDetailPage(
          voiceListId: item.id ?? 0,
          title: item.name ?? '',
          coverUrl: item.picUrl ?? '',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(currentColorsProvider);

    return Scaffold(
      appBar: AppBar(title: Text('播客', style: TextStyle(color: colors.textPrimary))),
      body: Column(
        children: [
          Expanded(child: _buildBody(colors)),
          const MiniPlayerBar(),
        ],
      ),
    );
  }

  Widget _buildBody(ThemeColors colors) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_podcasts.isEmpty) {
      return Center(
        child: Text('暂无订阅的播客',
            style: TextStyle(color: colors.textSecondary, fontSize: 14)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _podcasts.length,
      itemBuilder: (context, index) {
        final item = _podcasts[index];
        final meta = [
          item.category ?? '',
          '${item.programCount ?? 0}期',
          if (item.subCount != null && item.subCount! > 0)
            '${_fmt(item.subCount!)}订阅',
        ].where((s) => s.isNotEmpty).join(' · ');

        return InkWell(
          onTap: () => _openDetail(item),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                CoverImage(url: item.picUrl ?? '', size: 64, radius: 8),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: colors.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12, color: colors.textSecondary),
                      ),
                      if (item.dj?.nickname != null &&
                          item.dj!.nickname!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(item.dj!.nickname!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 12, color: colors.textSecondary)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _fmt(int n) {
    if (n >= 10000) return '${(n / 10000).toStringAsFixed(1)}万';
    return n.toString();
  }
}
