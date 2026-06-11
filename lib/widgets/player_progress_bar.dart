import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yuugao/providers/player_provider.dart';
import 'package:yuugao/theme.dart';

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
    final state = ref.watch(playerProvider);
    final total = state.duration.inMilliseconds.toDouble();
    final pos = state.position.inMilliseconds
        .toDouble()
        .clamp(0.0, total <= 0 ? 0.0 : total);
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
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary)),
              Text(_fmt(state.duration),
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}
