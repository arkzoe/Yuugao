import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 正弦波纹滑块轨道形状。
///
/// 绘制一条正弦波曲线作为激活/非激活轨道的边界。
class SquigglySliderTrackShape extends SliderTrackShape
    with BaseSliderTrackShape {
  final double squiggleAmplitude;
  final double squiggleWavelength;
  final double squigglePhaseFactor;

  const SquigglySliderTrackShape({
    this.squiggleAmplitude = 3.0,
    this.squiggleWavelength = 10.0,
    this.squigglePhaseFactor = 0.0,
  });

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isDiscrete = false,
    bool isEnabled = false,
    double additionalActiveTrackHeight = 2,
  }) {
    final trackHeight = sliderTheme.trackHeight ?? 4;
    if (trackHeight <= 0) return;

    final trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );

    final midY = trackRect.top + trackRect.height / 2;
    final activeColor = sliderTheme.activeTrackColor;
    final inactiveColor = sliderTheme.inactiveTrackColor;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = trackHeight
      ..strokeCap = StrokeCap.round;

    // 非激活轨道（thumb 右侧）— 画直线
    if (inactiveColor != null) {
      paint.color = inactiveColor;
      final inactiveStart = textDirection == TextDirection.ltr
          ? thumbCenter.dx
          : trackRect.left;
      final inactiveEnd = textDirection == TextDirection.ltr
          ? trackRect.right
          : thumbCenter.dx;
      if (inactiveEnd - inactiveStart > 0) {
        context.canvas.drawLine(
          Offset(inactiveStart, midY),
          Offset(inactiveEnd, midY),
          paint,
        );
      }
    }

    // 激活轨道（thumb 左侧）— 画波纹，进度靠波纹填充体现
    if (activeColor != null) {
      paint.color = activeColor;
      _drawSquiggle(
        context.canvas,
        paint,
        textDirection == TextDirection.ltr
            ? trackRect.left
            : thumbCenter.dx,
        textDirection == TextDirection.ltr
            ? thumbCenter.dx
            : trackRect.right,
        midY,
      );
    }
  }

  void _drawSquiggle(
    Canvas canvas,
    Paint paint,
    double startX,
    double endX,
    double midY,
  ) {
    if (endX - startX <= 0) return;

    final path = Path();
    path.moveTo(startX, midY);

    final step = 1.0;
    for (double x = startX; x <= endX; x += step) {
      final phase = (x / squiggleWavelength + squigglePhaseFactor) * 2 * math.pi;
      final y = midY + math.sin(phase) * squiggleAmplitude;
      path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);
  }
}
