import 'package:flutter/material.dart';

import 'package:animus/core/intake/dtos/analysis_precedent_applicability_level_dto.dart';
import 'package:animus/theme.dart';
import 'package:animus/ui/intake/widgets/pages/first_instance_analysis_screen/applicability_badge/applicability_palette/index.dart';

class ApplicabilityBadgeView extends StatelessWidget {
  final AnalysisPrecedentApplicabilityLevelDto? classificationLevel;
  final bool showScore;
  final bool showBorder;
  final TextOverflow overflow;
  final int maxLines;

  const ApplicabilityBadgeView({
    this.classificationLevel,
    this.showScore = true,
    this.showBorder = true,
    this.overflow = TextOverflow.visible,
    this.maxLines = 1,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final ApplicabilityPaletteData palette = _resolvePalette(tokens);

    return ApplicabilityPalette(
      label: palette.label,
      textColor: palette.textColor,
      backgroundColor: palette.backgroundColor,
      borderColor: palette.borderColor,
      showBorder: showBorder,
      overflow: overflow,
      maxLines: maxLines,
    );
  }

  ApplicabilityPaletteData _resolvePalette(AppThemeTokens tokens) {
    if (classificationLevel != null) {
      return _resolvePaletteByClassification(tokens, classificationLevel!);
    }

    return ApplicabilityPaletteData(
      label: 'Aplicabilidade',
      textColor: tokens.textSecondary,
      backgroundColor: tokens.surfaceElevated,
      borderColor: tokens.borderSubtle,
    );
  }

  ApplicabilityPaletteData _resolvePaletteByClassification(
    AppThemeTokens tokens,
    AnalysisPrecedentApplicabilityLevelDto level,
  ) {
    switch (level) {
      case AnalysisPrecedentApplicabilityLevelDto.applicable:
        return ApplicabilityPaletteData(
          label: 'Aplicável',
          textColor: tokens.success,
          backgroundColor: tokens.success.withValues(alpha: 0.12),
          borderColor: tokens.success.withValues(alpha: 0.28),
        );
      case AnalysisPrecedentApplicabilityLevelDto.possiblyApplicable:
        return ApplicabilityPaletteData(
          label: 'Possivelmente aplicável',
          textColor: tokens.warning,
          backgroundColor: tokens.warning.withValues(alpha: 0.12),
          borderColor: tokens.warning.withValues(alpha: 0.28),
        );
      case AnalysisPrecedentApplicabilityLevelDto.notApplicable:
        return ApplicabilityPaletteData(
          label: 'Não aplicável',
          textColor: tokens.danger,
          backgroundColor: tokens.danger.withValues(alpha: 0.12),
          borderColor: tokens.danger.withValues(alpha: 0.28),
        );
    }
  }
}
