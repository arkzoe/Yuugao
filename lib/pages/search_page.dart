import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yuugao/CloudMusic/yuugao.dart';
import 'package:yuugao/models/song.dart';
import 'package:yuugao/providers/settings_provider.dart';
import 'package:yuugao/widgets/mini_player_bar.dart';
import 'package:yuugao/widgets/song_tile.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _controller = TextEditingController();
  List<Song> _results = [];
  bool _loading = false;
  bool _searched = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final kw = _controller.text.trim();
    if (kw.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _searched = true;
    });
    try {
      final res = await BujuanMusicManager().search(keywords: kw, limit: 50);
      _results = (res?.result?.songs ?? [])
          .map((s) => Song.fromSearchItem(s))
          .toList();
    } catch (_) {
      _results = [];
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(currentColorsProvider);
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _search(),
          decoration: InputDecoration(
            hintText: '搜索歌曲',
            border: InputBorder.none,
            hintStyle: TextStyle(color: colors.textSecondary),
          ),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: _search),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildBody()),
            const MiniPlayerBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    final colors = ref.watch(currentColorsProvider);
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (!_searched) {
      return Center(
        child: Text('输入关键词搜索',
            style: TextStyle(color: colors.textSecondary)),
      );
    }
    if (_results.isEmpty) {
      return Center(
        child: Text('没有找到结果',
            style: TextStyle(color: colors.textSecondary)),
      );
    }
    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (context, i) =>
          SongTile(song: _results[i], queue: _results, index: i),
    );
  }
}
