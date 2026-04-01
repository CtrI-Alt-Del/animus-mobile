import 'package:flutter/material.dart';

import 'package:animus/theme.dart';

class RecentAnalysesEmptyStateView extends StatelessWidget {
  final VoidCallback onCreateFirstAnalysis;

  const RecentAnalysesEmptyStateView({
    required this.onCreateFirstAnalysis,
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
            Icon(Icons.history_toggle_off, color: tokens.textMuted, size: 40),
            const SizedBox(height: 12),
            Text(
              'Nenhuma analise ainda. Que tal comecar agora?',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(color: tokens.textMuted),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onCreateFirstAnalysis,
              icon: const Icon(Icons.add),
              label: const Text('Iniciar primeira analise'),
            ),
          ],
        ),
      ),
    );
  }
}
