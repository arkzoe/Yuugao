import 'package:flutter/material.dart';
import 'squiggly_slider_track_shape.dart';

/// 波纹进度条 — 播放时轨道呈正弦波纹动画，暂停时静止。
///
/// 使用 AnimatedBuilder 局部重建 SliderTheme，避免 setState 导致整棵
/// Widget 树每帧重建。
class SquigglySlider extends StatefulWidget {
  final double value;
  final double min;
  final double max;
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangeEnd;
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? thumbColor;
  final double squiggleAmplitude;
  final double squiggleWavelength;
  final double squiggleSpeed;

  const SquigglySlider({
    super.key,
    required this.value,
    this.min = 0.0,
    this.max = 1.0,
    this.onChanged,
    this.onChangeEnd,
    this.activeColor,
    this.inactiveColor,
    this.thumbColor,
    this.squiggleAmplitude = 0.0,
    this.squiggleWavelength = 10.0,
    this.squiggleSpeed = 1.0,
  });

  @override
  State<SquigglySlider> createState() => _SquigglySliderState();
}

class _SquigglySliderState extends State<SquigglySlider>
    with TickerProviderStateMixin {
  late AnimationController _phaseController;

  @override
  void initState() {
    super.initState();
    _setupController();
  }

  void _setupController() {
    if (widget.squiggleSpeed == 0) {
      _phaseController = AnimationController(vsync: this);
      _phaseController.value = 0.5;
    } else {
      _phaseController = AnimationController(
        duration: Duration(
          milliseconds: (1000.0 / widget.squiggleSpeed).round(),
        ),
        vsync: this,
      )..repeat(min: 0, max: 1);
    }
  }

  @override
  void didUpdateWidget(covariant SquigglySlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.squiggleSpeed != widget.squiggleSpeed) {
      _phaseController.dispose();
      _setupController();
    }
  }

  @override
  void dispose() {
    _phaseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _phaseController,
      builder: (_, child) {
        return SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 8,
            overlayShape:
                const RoundSliderOverlayShape(overlayRadius: 12),
            thumbShape:
                const RoundSliderThumbShape(enabledThumbRadius: 6),
            trackShape: SquigglySliderTrackShape(
              squiggleAmplitude: widget.squiggleAmplitude,
              squiggleWavelength: widget.squiggleWavelength,
              squigglePhaseFactor: widget.squiggleSpeed < 0
                  ? 1 - _phaseController.value
                  : _phaseController.value,
            ),
            activeTrackColor: widget.activeColor,
            inactiveTrackColor: widget.inactiveColor,
            thumbColor: widget.thumbColor,
          ),
          child: child!,
        );
      },
      child: Slider(
        value: widget.value,
        min: widget.min,
        max: widget.max,
        onChanged: widget.onChanged,
        onChangeEnd: widget.onChangeEnd,
      ),
    );
  }
}
