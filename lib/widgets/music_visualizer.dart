import 'dart:math';

import 'package:flutter/material.dart';

/// 音乐频谱可视化组件 — 静态随机高度竖条，模拟音频频谱。
class MusicVisualizer extends StatelessWidget {
  final List<Color>? colors;
  final int barCount;
  final double barWidth;
  final double maxHeight;

  const MusicVisualizer({
    super.key,
    this.colors,
    this.barCount = 35,
    this.barWidth = 3.0,
    this.maxHeight = 36.0,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColors =
        colors ??
        [Colors.white24, Colors.white30, Colors.white38, Colors.white54];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: List<Widget>.generate(barCount, (index) {
        final height = Random().nextInt(maxHeight.toInt() - 6).toDouble() + 6;
        return Container(
          width: barWidth,
          height: height,
          decoration: BoxDecoration(
            color: effectiveColors[index % effectiveColors.length],
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}
