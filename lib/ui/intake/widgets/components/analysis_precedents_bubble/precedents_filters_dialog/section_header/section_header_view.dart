import 'package:flutter/material.dart';

class SectionHeaderView extends StatelessWidget {
  final String title;
  final int appliedCount;

  const SectionHeaderView({
    required this.title,
    required this.appliedCount,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            title,
            style: textTheme.labelMedium?.copyWith(
              color: const Color(0xFF6B6B70),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0x14FBE26D),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0x35FBE26D)),
          ),
          child: Text(
            '$appliedCount aplicado${appliedCount == 1 ? '' : 's'}',
            style: textTheme.labelMedium?.copyWith(
              color: const Color(0xFFFAFAF9),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
