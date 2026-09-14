import 'package:flutter/material.dart';

/// Pure Vector Painter for Thread App Logo
/// Infinite resolution, 100% crisp, zero raster blur on any display.
class ThreadVectorLogoPainter extends CustomPainter {
  const ThreadVectorLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 100.0;

    // 1. Vibrant Coral Gradient Blob
    final blobPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFF7A5C), // Coral
          Color(0xFFF0603F), // Coral Deep
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final path = Path();
    path.moveTo(96.74 * s, 50 * s);
    path.cubicTo(96.94 * s, 54.16 * s, 97.77 * s, 58.46 * s, 97.25 * s, 62.66 * s);
    path.cubicTo(96.73 * s, 66.86 * s, 95.56 * s, 71.36 * s, 93.62 * s, 75.18 * s);
    path.cubicTo(91.68 * s, 79.01 * s, 88.74 * s, 82.64 * s, 85.61 * s, 85.61 * s);
    path.cubicTo(82.48 * s, 88.58 * s, 78.7 * s, 91.25 * s, 74.82 * s, 92.99 * s);
    path.cubicTo(70.94 * s, 94.72 * s, 66.47 * s, 95.39 * s, 62.33 * s, 96.02 * s);
    path.cubicTo(58.19 * s, 96.64 * s, 54.16 * s, 96.53 * s, 50 * s, 96.74 * s);
    path.cubicTo(45.84 * s, 96.94 * s, 41.49 * s, 97.85 * s, 37.34 * s, 97.25 * s);
    path.cubicTo(33.19 * s, 96.65 * s, 28.85 * s, 95.14 * s, 25.09 * s, 93.14 * s);
    path.cubicTo(21.33 * s, 91.14 * s, 17.76 * s, 88.3 * s, 14.77 * s, 85.23 * s);
    path.cubicTo(11.78 * s, 82.16 * s, 9.06 * s, 78.52 * s, 7.17 * s, 74.73 * s);
    path.cubicTo(5.28 * s, 70.94 * s, 4.19 * s, 66.59 * s, 3.45 * s, 62.47 * s);
    path.cubicTo(2.71 * s, 58.35 * s, 2.9 * s, 54.2 * s, 2.72 * s, 50 * s);
    path.cubicTo(2.54 * s, 45.8 * s, 1.84 * s, 41.48 * s, 2.4 * s, 37.25 * s);
    path.cubicTo(2.96 * s, 33.02 * s, 4.14 * s, 28.52 * s, 6.07 * s, 24.64 * s);
    path.cubicTo(8 * s, 20.77 * s, 10.86 * s, 17.02 * s, 14 * s, 14 * s);
    path.cubicTo(17.14 * s, 10.98 * s, 20.99 * s, 8.3 * s, 24.91 * s, 6.54 * s);
    path.cubicTo(28.83 * s, 4.78 * s, 33.35 * s, 4.09 * s, 37.53 * s, 3.45 * s);
    path.cubicTo(41.71 * s, 2.81 * s, 45.8 * s, 2.9 * s, 50 * s, 2.72 * s);
    path.cubicTo(54.2 * s, 2.54 * s, 58.6 * s, 1.71 * s, 62.75 * s, 2.4 * s);
    path.cubicTo(66.9 * s, 3.09 * s, 71.16 * s, 4.8 * s, 74.91 * s, 6.86 * s);
    path.cubicTo(78.66 * s, 8.92 * s, 82.24 * s, 11.7 * s, 85.23 * s, 14.77 * s);
    path.cubicTo(88.22 * s, 17.84 * s, 91.03 * s, 21.45 * s, 92.83 * s, 25.27 * s);
    path.cubicTo(94.63 * s, 29.09 * s, 95.37 * s, 33.55 * s, 96.02 * s, 37.67 * s);
    path.cubicTo(96.67 * s, 41.79 * s, 96.53 * s, 45.84 * s, 96.74 * s, 50 * s);
    path.close();
    canvas.drawPath(path, blobPaint);

    // 2. White Thread Connecting Curve
    final threadStroke = Paint()
      ..color = Colors.white
      ..strokeWidth = 4.8 * s
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    final threadPath = Path();
    threadPath.moveTo(32.4 * s, 29.0 * s);
    threadPath.cubicTo(
      33.8 * s, 38.2 * s,
      39.5 * s, 44.6 * s,
      44.7 * s, 51.2 * s,
    );
    threadPath.cubicTo(
      49.8 * s, 57.8 * s,
      52.6 * s, 63.5 * s,
      55.4 * s, 71.7 * s,
    );
    canvas.drawPath(threadPath, threadStroke);

    // 3. Thread Circular Nodes
    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.drawCircle(Offset(32.4 * s, 29.0 * s), 4.3 * s, dotPaint);
    canvas.drawCircle(Offset(44.7 * s, 51.2 * s), 4.0 * s, dotPaint);
    canvas.drawCircle(Offset(55.4 * s, 71.7 * s), 4.4 * s, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
