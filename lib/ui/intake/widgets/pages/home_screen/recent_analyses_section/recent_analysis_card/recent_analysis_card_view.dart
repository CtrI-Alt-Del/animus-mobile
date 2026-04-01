import 'package:flutter/material.dart';

import 'package:animus/theme.dart';

class RecentAnalysisCardView extends StatelessWidget {
  final String title;
  final String dateLabel;
  final VoidCallback onTap;

  const RecentAnalysisCardView({
    required this.title,
    required this.dateLabel,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: tokens.surfaceCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: tokens.borderSubtle),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      dateLabel,
                      style: textTheme.labelSmall?.copyWith(
                        color: tokens.textMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelMedium?.copyWith(
                        color: tokens.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.chevron_right, color: tokens.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
