import 'package:flutter/material.dart';

class DotGridPainterView extends StatelessWidget {
  final Color dotColor;

  const DotGridPainterView({required this.dotColor, super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DotGridPainter(dotColor: dotColor),
      size: Size.infinite,
    );
  }
}

class _DotGridPainter extends CustomPainter {
  final Color dotColor;

  const _DotGridPainter({required this.dotColor});

  @override
  void paint(Canvas canvas, Size size) {
    const double spacing = 28;
    const double radius = 1.1;

    final Paint paint = Paint()
      ..color = dotColor.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    for (double y = 0; y <= size.height; y += spacing) {
      for (double x = 0; x <= size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotGridPainter oldDelegate) {
    return oldDelegate.dotColor != dotColor;
  }
}
