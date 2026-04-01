import 'package:flutter/material.dart';

class TypingDotView extends StatelessWidget {
  final Color color;

  const TypingDotView({required this.color, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
