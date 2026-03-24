import 'package:flutter/material.dart';

class RuleItemView extends StatelessWidget {
  final String label;
  final bool isMet;
  final Color successColor;

  const RuleItemView({
    required this.label,
    required this.isMet,
    required this.successColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(
          isMet ? Icons.check : Icons.circle_outlined,
          size: 11,
          color: isMet ? successColor : const Color(0xFF6A708D),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF6A708D), fontSize: 11),
        ),
      ],
    );
  }
}
