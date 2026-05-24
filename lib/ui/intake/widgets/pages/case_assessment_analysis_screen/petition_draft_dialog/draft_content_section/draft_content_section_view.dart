import 'package:flutter/material.dart';

import 'package:animus/theme.dart';

class DraftContentSectionView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;
  final bool emphasize;

  const DraftContentSectionView({
    required this.icon,
    required this.title,
    required this.content,
    this.emphasize = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String normalizedContent = content.trim();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: emphasize ? tokens.surfaceElevated : tokens.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: emphasize
              ? tokens.accent.withValues(alpha: 0.35)
              : tokens.borderSubtle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 18, color: tokens.accent),
              const SizedBox(width: 10),
              Text(
                title,
                style: textTheme.titleMedium?.copyWith(
                  color: tokens.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            normalizedContent.isEmpty
                ? 'Conteúdo não disponibilizado.'
                : normalizedContent,
            style: textTheme.bodyMedium?.copyWith(
              color: tokens.textSecondary,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}
