import 'package:flutter/material.dart';

import 'package:animus/core/intake/dtos/analysis_type_dto.dart';
import 'package:animus/theme.dart';
import 'package:animus/ui/intake/widgets/pages/home_screen/recent_analyses_section/analysis_type_badge/index.dart';
import 'package:animus/ui/intake/widgets/pages/home_screen/recent_analyses_section/processing_analysis_card/processing_status_pill/index.dart';
import 'package:animus/ui/intake/widgets/pages/home_screen/recent_analyses_section/recent_analysis_card/processing_spinner/index.dart';

class ProcessingAnalysisCardView extends StatelessWidget {
  final String title;
  final String dateLabel;
  final AnalysisTypeDto type;
  final String? statusLabel;
  final VoidCallback onTap;

  const ProcessingAnalysisCardView({
    required this.title,
    required this.dateLabel,
    required this.type,
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

    final bool hasStatus =
        statusLabel != null && statusLabel!.trim().isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Ink(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                tokens.accent.withValues(alpha: 0.14),
                tokens.primaryGradient.colors.first.withValues(alpha: 0.08),
                tokens.surfaceCard.withValues(alpha: 0.92),
              ],
            ),
            border: Border.all(color: tokens.accent.withValues(alpha: 0.32)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        ProcessingSpinner(color: tokens.accent),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.titleSmall?.copyWith(
                              color: tokens.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: <Widget>[
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 13,
                              color: tokens.textMuted,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              dateLabel,
                              style: textTheme.labelSmall?.copyWith(
                                color: tokens.textMuted,
                              ),
                            ),
                          ],
                        ),
                        AnalysisTypeBadge(type: type),
                      ],
                    ),
                    if (hasStatus) ...<Widget>[
                      const SizedBox(height: 8),
                      ProcessingStatusPill(label: statusLabel!),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: tokens.textMuted, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
