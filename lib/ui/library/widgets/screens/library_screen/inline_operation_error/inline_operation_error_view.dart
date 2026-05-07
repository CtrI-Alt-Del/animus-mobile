import 'package:animus/theme.dart';
import 'package:flutter/material.dart';

class InlineOperationErrorView extends StatelessWidget {
  final String message;

  const InlineOperationErrorView({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tokens.danger.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tokens.danger.withValues(alpha: 0.22)),
      ),
      child: Text(
        message,
        style: textTheme.bodySmall?.copyWith(
          color: tokens.textPrimary,
          height: 1.35,
        ),
      ),
    );
  }
}
