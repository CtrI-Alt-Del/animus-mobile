import 'package:flutter/material.dart';

import 'package:animus/theme.dart';

class GenerateJudgmentDraftCardView extends StatelessWidget {
  const GenerateJudgmentDraftCardView({super.key});

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: tokens.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tokens.borderSubtle),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(tokens.accent),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Gerando minuta de sentença',
                style: textTheme.titleSmall?.copyWith(
                  color: tokens.accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: tokens.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: tokens.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'A minuta esta sendo estruturada com base no resumo do caso e nos precedentes selecionados.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: tokens.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Isso pode levar alguns instantes.',
                  style: textTheme.bodySmall?.copyWith(color: tokens.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
