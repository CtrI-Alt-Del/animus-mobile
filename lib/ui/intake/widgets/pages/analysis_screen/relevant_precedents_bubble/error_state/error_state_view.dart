import 'package:flutter/material.dart';

import 'package:animus/theme.dart';

class ErrorStateView extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const ErrorStateView({
    required this.message,
    required this.onRetry,
    super.key,
  });

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
              color: tokens.danger,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () {
                onRetry();
              },
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Tentar novamente'),
            ),
          ),
        ],
      ),
    );
  }
}
