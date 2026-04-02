import 'package:flutter/material.dart';

import 'package:animus/theme.dart';

class DotGridBackgroundView extends StatelessWidget {
  const DotGridBackgroundView({super.key});

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;

    return IgnorePointer(
      child: CustomPaint(
        painter: _DotGridPainter(dotColor: tokens.textTertiary),
        size: Size.infinite,
      ),
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
