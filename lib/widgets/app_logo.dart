import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'thread_vector_logo.dart';

/// Pure Vector Thread Logo for Threads Redesign
/// Uses GPU-accelerated vector rendering for razor-sharp fidelity at any resolution.
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 48,
    this.isTilted = false,
    this.hasShadow = true,
  });

  final double size;
  final bool isTilted;
  final bool hasShadow;

  @override
  Widget build(BuildContext context) {
    Widget logo = SizedBox(
      width: size,
      height: size,
      child: const CustomPaint(
        painter: ThreadVectorLogoPainter(),
      ),
    );

    if (hasShadow) {
      logo = Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0x38F87146),
              blurRadius: size * 0.28,
              spreadRadius: -size * 0.04,
              offset: Offset(0, size * 0.1),
            ),
          ],
        ),
        child: logo,
      );
    }

    if (isTilted) {
      return Transform.rotate(
        angle: -4 * (math.pi / 180),
        child: logo,
      );
    }

    return logo;
  }
}