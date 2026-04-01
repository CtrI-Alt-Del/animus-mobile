import 'package:flutter/material.dart';

import 'package:animus/theme.dart';

class RecentAnalysesErrorStateView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const RecentAnalysesErrorStateView({
    required this.message,
    required this.onRetry,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.error_outline, color: tokens.danger, size: 36),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(color: tokens.textMuted),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}
