import 'package:flutter/material.dart';

import 'package:animus/core/intake/dtos/analysis_precedent_applicability_level_dto.dart';
import 'package:animus/theme.dart';
import 'package:animus/ui/intake/widgets/pages/first_instance_analysis_screen/applicability_badge/index.dart';

class PrecedentListItemView extends StatelessWidget {
  final String title;
  final double similarityScore;
  final AnalysisPrecedentApplicabilityLevelDto applicabilityLevel;
  final bool isChosen;
  final VoidCallback? onTap;

  const PrecedentListItemView({
    required this.title,
    required this.similarityScore,
    required this.applicabilityLevel,
    required this.isChosen,
    this.onTap,
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: <Widget>[
              if (isChosen)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Container(
                    width: 6,
                    height: 56,
                    decoration: BoxDecoration(
                      color: tokens.successDark,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    ApplicabilityBadge(
                      classificationLevel: applicabilityLevel,
                      showScore: false,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      title,
                      style: textTheme.bodyMedium?.copyWith(
                        color: tokens.textPrimary,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                    if (isChosen) ...<Widget>[
                      const SizedBox(height: 8),
                      Row(
                        children: <Widget>[
                          Icon(
                            Icons.check_circle_outline,
                            size: 16,
                            color: tokens.successDark,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Escolhido',
                            style: textTheme.labelSmall?.copyWith(
                              color: tokens.successDark,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(Icons.chevron_right, size: 20, color: tokens.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}
