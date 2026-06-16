import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yuugao/providers/player_provider.dart';
import 'package:yuugao/providers/player_theme_provider.dart';
import 'package:yuugao/providers/settings_provider.dart';

/// 频谱条进度条 — 竖条上下伸缩模拟频谱跳动，同时作为进度指示器。
///
/// 已播放部分亮色跳动，未播放部分暗色微动。点击/拖动 seek。
class PlayerProgressBar extends ConsumerStatefulWidget {
  const PlayerProgressBar({super.key});

  @override
  ConsumerState<PlayerProgressBar> createState() => _PlayerProgressBarState();
}

class _PlayerProgressBarState extends ConsumerState<PlayerProgressBar>
    with TickerProviderStateMixin {
  double? _dragValue;
  static const int _barCount = 40;
  static const double _maxH = 44.0;
  static const double _minH = 6.0;

  late AnimationController _animCtrl;
  late List<double> _heights;

  final _rand = Random();

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void initState() {
    super.initState();
    _heights = List.generate(_barCount, (i) => _randomH(i));
    _animCtrl = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    )..addListener(_onTick);
    // 延迟启动，等 ref 就绪后根据播放状态决定
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final playing =
            ref.read(playerProvider.select((s) => s.isPlaying));
        if (playing) _animCtrl.repeat();
      }
    });
  }

  @override
  void dispose() {
    _animCtrl.removeListener(_onTick);
    _animCtrl.dispose();
    super.dispose();
  }

  void _onTick() {
    // 每帧随机更新几根条的高度（不是全部更新，避免过度闪烁）
    for (var i = 0; i < _barCount; i++) {
      if (_rand.nextDouble() < 0.25) {
        // 25% 概率更新
        _heights[i] = _randomH(i);
      }
    }
    if (mounted) setState(() {});
  }

  double _randomH(int seed) {
    final r = Random(seed * 7 + 13 + _rand.nextInt(9999));
    return (_minH + r.nextDouble() * (_maxH - _minH));
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(currentColorsProvider);
    final playerColors = ref.watch(playerThemeProvider);
    final totalMs =
        ref.watch(playerProvider.select((s) => s.duration.inMilliseconds));
    final posMs =
        ref.watch(playerProvider.select((s) => s.position.inMilliseconds));
    final total = totalMs.toDouble();
    final pos = posMs.toDouble().clamp(0.0, total <= 0 ? 0.0 : total);
    final value = _dragValue ?? pos;
    final fraction = total <= 0 ? 0.0 : (value / total).clamp(0.0, 1.0);
    final activeBars = (fraction * _barCount).round();

    // 用 ref.listen 响应播放/暂停切换，避免在 build 中操作 controller
    ref.listen(playerProvider.select((s) => s.isPlaying), (prev, next) {
      if (next && !_animCtrl.isAnimating) {
        _animCtrl.repeat();
      } else if (!next && _animCtrl.isAnimating) {
        _animCtrl.stop();
      }
    });

    return Column(
      children: [
        // ── 频谱进度条 ──
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragUpdate: (d) {
            final box = context.findRenderObject() as RenderBox;
            final w = box.size.width;
            if (w > 0 && total > 0) {
              setState(() =>
                  _dragValue = (d.localPosition.dx / w).clamp(0.0, 1.0) * total);
            }
          },
          onHorizontalDragEnd: (_) {
            if (_dragValue != null && total > 0) {
              ref
                  .read(playerProvider.notifier)
                  .seek(Duration(milliseconds: _dragValue!.toInt()));
            }
            setState(() => _dragValue = null);
          },
          onTapDown: (d) {
            final box = context.findRenderObject() as RenderBox;
            final w = box.size.width;
            if (w > 0 && total > 0) {
              final t = (d.localPosition.dx / w).clamp(0.0, 1.0) * total;
              ref
                  .read(playerProvider.notifier)
                  .seek(Duration(milliseconds: t.toInt()));
            }
          },
          child: SizedBox(
            height: _maxH,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: List<Widget>.generate(_barCount, (index) {
                final active = index < activeBars;
                final h = _heights[index];
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  width: 2.5,
                  height: h,
                  decoration: BoxDecoration(
                    color: active
                        ? playerColors.accent.withValues(
                            alpha: 0.3 + (h / _maxH) * 0.7)
                        : playerColors.accent.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            ),
          ),
        ),

        // ── 时间标签 ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_fmt(Duration(milliseconds: value.toInt())),
                  style:
                      TextStyle(fontSize: 11, color: colors.textSecondary)),
              Text(_fmt(Duration(milliseconds: totalMs)),
                  style:
                      TextStyle(fontSize: 11, color: colors.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}
