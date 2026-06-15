import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yuugao/providers/player_provider.dart';
import 'package:yuugao/providers/settings_provider.dart';

/// 进度条 + 当前/总时长。拖动时本地预览，松手后 seek。
class PlayerProgressBar extends ConsumerStatefulWidget {
  const PlayerProgressBar({super.key});

  @override
  ConsumerState<PlayerProgressBar> createState() => _PlayerProgressBarState();
}

class _PlayerProgressBarState extends ConsumerState<PlayerProgressBar> {
  double? _dragValue;

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(currentColorsProvider);
    // 仅监听需要的字段，避免 buffering/isFmMode 等无关状态变化引发重建
    final totalMs =
        ref.watch(playerProvider.select((s) => s.duration.inMilliseconds));
    final posMs =
        ref.watch(playerProvider.select((s) => s.position.inMilliseconds));
    final total = totalMs.toDouble();
    final pos = posMs.toDouble().clamp(0.0, total <= 0 ? 0.0 : total);
    final value = _dragValue ?? pos;

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          ),
          child: Slider(
            min: 0,
            max: total <= 0 ? 1 : total,
            value: total <= 0 ? 0 : value,
            onChanged: total <= 0
                ? null
                : (v) => setState(() => _dragValue = v),
            onChangeEnd: (v) {
              ref
                  .read(playerProvider.notifier)
                  .seek(Duration(milliseconds: v.toInt()));
              setState(() => _dragValue = null);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_fmt(Duration(milliseconds: value.toInt())),
                  style: TextStyle(
                      fontSize: 11, color: colors.textSecondary)),
              Text(_fmt(Duration(milliseconds: totalMs)),
                  style: TextStyle(
                      fontSize: 11, color: colors.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}
