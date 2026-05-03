import 'package:flutter/material.dart';

import 'package:animus/theme.dart';

class RecentAnalysisCardView extends StatelessWidget {
  final String title;
  final String dateLabel;
  final String? statusLabel;
  final VoidCallback onTap;

  const RecentAnalysisCardView({
    required this.title,
    required this.dateLabel,
    this.statusLabel,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

    final BorderRadius borderRadius = BorderRadius.circular(18);
    final BoxDecoration decoration = BoxDecoration(
      color: tokens.surfaceCard,
      borderRadius: borderRadius,
      border: Border.all(color: tokens.borderSubtle),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: decoration,
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: <Widget>[
                        Text(
                          dateLabel,
                          style: textTheme.labelSmall?.copyWith(
                            color: tokens.textMuted,
                          ),
                        ),
                        if (statusLabel != null && statusLabel!.trim().isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: tokens.surfaceElevated,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: tokens.borderSubtle,
                              ),
                            ),
                            child: Text(
                              statusLabel!,
                              style: textTheme.labelSmall?.copyWith(
                                color: tokens.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
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
              Icon(
                Icons.chevron_right,
                color: tokens.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
