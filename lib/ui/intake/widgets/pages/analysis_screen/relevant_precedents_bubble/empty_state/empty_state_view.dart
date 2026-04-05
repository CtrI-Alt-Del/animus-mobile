import 'package:flutter/material.dart';

import 'package:animus/theme.dart';

class EmptyStateView extends StatelessWidget {
  const EmptyStateView({super.key});

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Text(
        'Nenhum precedente relevante foi encontrado para esta peticao.',
        style: textTheme.bodyMedium?.copyWith(
          color: tokens.textSecondary,
          height: 1.35,
        ),
      ),
    );
  }
}
