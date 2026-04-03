import 'package:flutter/material.dart';

import 'package:animus/theme.dart';

class SummarySectionView extends StatelessWidget {
  final String title;
  final String content;

  const SummarySectionView({
    required this.title,
    required this.content,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: textTheme.labelLarge?.copyWith(
              color: tokens.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: textTheme.bodyMedium?.copyWith(
              color: tokens.textSecondary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
