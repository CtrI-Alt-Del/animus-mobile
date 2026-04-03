import 'package:flutter/material.dart';

class RadialGlowView extends StatelessWidget {
  final Size size;
  final double? top;
  final double? right;
  final double? bottom;
  final double? left;
  final Color color;

  const RadialGlowView({
    required this.size,
    required this.color,
    this.top,
    this.right,
    this.bottom,
    this.left,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      right: right,
      bottom: bottom,
      left: left,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: <Color>[color, color.withValues(alpha: 0)],
            ),
          ),
          child: SizedBox(width: size.width, height: size.height),
        ),
      ),
    );
  }
}
