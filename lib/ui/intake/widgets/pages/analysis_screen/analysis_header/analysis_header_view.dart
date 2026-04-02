import 'package:flutter/material.dart';

import 'package:animus/theme.dart';

class AnalysisHeaderView extends StatelessWidget {
  final VoidCallback? onBack;

  const AnalysisHeaderView({required this.onBack, super.key});

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 52,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            IconButton(
              onPressed: onBack,
              icon: Icon(Icons.arrow_back, color: tokens.textPrimary, size: 22),
            ),
            Text(
              'Nova Análise',
              style: textTheme.titleMedium?.copyWith(
                color: tokens.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            IconButton(
              onPressed: null,
              icon: Icon(Icons.tune, color: tokens.textSecondary, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
