import 'package:flutter/material.dart';

import 'package:animus/theme.dart';

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
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            title,
            style: textTheme.labelMedium?.copyWith(
              color: tokens.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: tokens.accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: tokens.accent.withValues(alpha: 0.21)),
          ),
          child: Text(
            '$appliedCount aplicado${appliedCount == 1 ? '' : 's'}',
            style: textTheme.labelMedium?.copyWith(
              color: tokens.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
