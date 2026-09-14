import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  static const int _dotCount = 3;
  static const Duration _totalDuration = Duration(milliseconds: 1400);

  // Khoảng lệch pha giữa các dot (0.0 – 1.0)
  static const double _phaseStep = 0.15;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _totalDuration)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Tính giá trị sine chỉ lấy phần đi lên (0 → 1 → 0)
  /// rồi áp thêm easing power để chuyển động nhanh lên, rơi nhẹ xuống
  double _wave(double t, int index) {
    final double phase = (t - index * _phaseStep) % 1.0;
    final double sine = math.sin(phase * 2 * math.pi);
    final double upOnly = (sine + 1) / 2; // 0..1
    return math.pow(upOnly, 1.5).toDouble(); // easing nhẹ
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          builder: (context, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, (1 - value) * 10),
              child: child,
            ),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(18),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (_, __) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: List.generate(_dotCount, (i) {
                    final double wave = _wave(_controller.value, i);
                    final double offset = -wave * 7.0;  // lên tối đa 7px
                    final double scale  = 1.0 + wave * 0.22;
                    final double opacity = 0.5 + wave * 0.35;

                    return Padding(
                      padding: EdgeInsets.only(left: i == 0 ? 0 : 5),
                      child: Transform.translate(
                        offset: Offset(0, offset),
                        child: Transform.scale(
                          scale: scale,
                          child: Opacity(
                            opacity: opacity,
                            child: Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: AppColors.textSecondary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}