import 'package:flutter/material.dart';

import 'package:animus/theme.dart';

class GeneralErrorAlertView extends StatelessWidget {
  final String? message;

  const GeneralErrorAlertView({required this.message, super.key});

  @override
  Widget build(BuildContext context) {
    if (message == null || message!.isEmpty) {
      return const SizedBox.shrink();
    }

    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final Color error = Theme.of(context).colorScheme.error;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: error.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: error),
        ),
        child: Text(
          message!,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: tokens.white.withValues(alpha: 0.9),
          ),
        ),
      ),
    );
  }
}
