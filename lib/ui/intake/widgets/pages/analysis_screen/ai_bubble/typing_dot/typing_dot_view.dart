import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TypingDotView extends StatelessWidget {
  final Color color;
  final Duration delay;

  const TypingDotView({
    required this.color,
    this.delay = Duration.zero,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        )
        .animate(onPlay: (controller) => controller.repeat())
        .fadeIn(duration: 220.ms, delay: delay)
        .scale(
          begin: const Offset(0.85, 0.85),
          end: const Offset(1.1, 1.1),
          duration: 420.ms,
        )
        .then(delay: 120.ms)
        .fadeOut(duration: 260.ms)
        .scale(
          begin: const Offset(1.1, 1.1),
          end: const Offset(0.85, 0.85),
          duration: 260.ms,
        );
  }
}
