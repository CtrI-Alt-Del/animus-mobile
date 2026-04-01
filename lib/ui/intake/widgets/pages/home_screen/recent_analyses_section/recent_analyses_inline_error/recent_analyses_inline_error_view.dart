import 'package:flutter/material.dart';

import 'package:animus/theme.dart';

class RecentAnalysesInlineErrorView extends StatelessWidget {
  final String message;

  const RecentAnalysesInlineErrorView({
    required this.message,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: tokens.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.danger.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.info_outline, color: tokens.danger, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: textTheme.bodySmall?.copyWith(color: tokens.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
