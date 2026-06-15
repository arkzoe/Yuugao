import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yuugao/CloudMusic/yuugao.dart';
import 'package:yuugao/providers/player_provider.dart';
import 'package:yuugao/providers/settings_provider.dart';

class LyricLine {
  final Duration time;
  final String text;
  const LyricLine(this.time, this.text);
}

/// 歌词面板：解析 LRC、随播放进度高亮并自动滚动。
class LyricPanel extends ConsumerStatefulWidget {
  const LyricPanel({super.key});

  @override
  ConsumerState<LyricPanel> createState() => _LyricPanelState();
}

class _LyricPanelState extends ConsumerState<LyricPanel> {
  final ScrollController _scroll = ScrollController();
  List<LyricLine> _lines = [];
  int _currentSongId = -1;
  int _activeIndex = 0;
  bool _loading = false;
  int _loadGen = 0; // 代次守卫，防快速切歌时旧结果覆盖新结果
  static const double _lineHeight = 44;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadFor(int songId) async {
    if (songId == _currentSongId) return;
    _currentSongId = songId;
    final gen = ++_loadGen;
    setState(() {
      _loading = true;
      _lines = [];
    });
    try {
      final res = await MusicManager().songLyricCached(id: songId.toString());
      if (gen != _loadGen || !mounted) return;
      _lines = _parse(res?.lrc?.lyric ?? '');
    } catch (_) {
      if (gen != _loadGen || !mounted) return;
      _lines = [];
    }
    if (!mounted) return;
    if (gen == _loadGen) setState(() => _loading = false);
  }

  List<LyricLine> _parse(String raw) {
    if (raw.trim().isEmpty) return [];
    final reg = RegExp(r'\[(\d{1,2}):(\d{1,2})(?:[.:](\d{1,3}))?\]');
    final lines = <LyricLine>[];
    for (final line in raw.split('\n')) {
      final matches = reg.allMatches(line);
      if (matches.isEmpty) continue;
      final text = line.replaceAll(reg, '').trim();
      if (text.isEmpty) continue;
      for (final m in matches) {
        final min = int.parse(m.group(1)!);
        final sec = int.parse(m.group(2)!);
        final msRaw = m.group(3);
        var ms = 0;
        if (msRaw != null) {
          ms = msRaw.length == 2
              ? int.parse(msRaw) * 10
              : (msRaw.length == 1 ? int.parse(msRaw) * 100 : int.parse(msRaw));
        }
        lines.add(
          LyricLine(
            Duration(minutes: min, seconds: sec, milliseconds: ms),
            text,
          ),
        );
      }
    }
    lines.sort((a, b) => a.time.compareTo(b.time));
    return lines;
  }

  void _syncActive(Duration pos) {
    if (_lines.isEmpty) return;
    var idx = 0;
    for (var i = 0; i < _lines.length; i++) {
      if (_lines[i].time <= pos) {
        idx = i;
      } else {
        break;
      }
    }
    if (idx != _activeIndex && mounted) {
      setState(() => _activeIndex = idx);
      if (_scroll.hasClients) {
        final target =
            (idx * _lineHeight) - (_scroll.position.viewportDimension / 2);
        _scroll.animateTo(
          target.clamp(0.0, _scroll.position.maxScrollExtent),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(currentColorsProvider);
    final songId = ref.watch(playerProvider.select((s) => s.current?.id));
    // 歌曲切换时加载歌词（listen 仅响应变化，不触发初始值）
    ref.listen(playerProvider.select((s) => s.current?.id), (prev, next) {
      if (next != null && next != prev) _loadFor(next);
    });
    // 首次挂载或 songId 为初始值时触发加载（_loadFor 内部 _currentSongId 守卫防重复）
    if (songId != null) _loadFor(songId);
    // 监听进度同步高亮
    ref.listen(playerProvider.select((s) => s.position), (_, pos) {
      _syncActive(pos);
    });

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_lines.isEmpty) {
      return Center(
        child: Text('纯音乐，请欣赏', style: TextStyle(color: colors.textSecondary)),
      );
    }

    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      itemCount: _lines.length,
      itemBuilder: (context, i) {
        final active = i == _activeIndex;
        return Container(
          height: _lineHeight,
          alignment: Alignment.center,
          child: Text(
            _lines[i].text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: active ? 16 : 14,
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
              color: active ? colors.primary : colors.textSecondary,
            ),
          ),
        );
      },
    );
  }
}
