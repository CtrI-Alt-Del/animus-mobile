import 'package:flutter/material.dart';

import 'package:animus/theme.dart';

class LoadingStateView extends StatelessWidget {
  final String message;

  const LoadingStateView({required this.message, super.key});

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            message,
            style: textTheme.bodyMedium?.copyWith(
              color: tokens.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(minHeight: 4, color: tokens.accent),
          ),
        ],
      ),
    );
  }
}
