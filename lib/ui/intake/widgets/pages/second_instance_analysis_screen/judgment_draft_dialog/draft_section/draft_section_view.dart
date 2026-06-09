import 'package:flutter/material.dart';

import 'package:animus/theme.dart';

class DraftSectionView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;
  final String emptyText;
  final bool emphasize;
  final Color? accentColor;
  final Widget? editableContent;

  const DraftSectionView({
    required this.icon,
    required this.title,
    required this.content,
    required this.emptyText,
    this.emphasize = false,
    this.accentColor,
    this.editableContent,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String normalizedContent = content.trim();
    final Color highlight = accentColor ?? tokens.accent;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: emphasize ? tokens.surfaceElevated : tokens.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: emphasize
              ? highlight.withValues(alpha: 0.35)
              : tokens.borderSubtle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 18, color: highlight),
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
          if (editableContent != null)
            editableContent!
          else
            Text(
              normalizedContent.isEmpty ? emptyText : normalizedContent,
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
