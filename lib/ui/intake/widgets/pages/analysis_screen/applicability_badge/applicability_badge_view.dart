import 'package:flutter/material.dart';

import 'package:animus/core/intake/dtos/analysis_precedent_classification_level_dto.dart';
import 'package:animus/theme.dart';

class ApplicabilityBadgeView extends StatelessWidget {
  final double percentage;
  final String percentageText;
  final AnalysisPrecedentClassificationLevelDto? classificationLevel;
  final bool showBorder;
  final TextOverflow overflow;
  final int maxLines;

  const ApplicabilityBadgeView({
    required this.percentage,
    required this.percentageText,
    this.classificationLevel,
    this.showBorder = true,
    this.overflow = TextOverflow.visible,
    this.maxLines = 1,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final _ApplicabilityPalette palette = _resolvePalette(tokens);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: palette.backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: showBorder ? Border.all(color: palette.borderColor) : null,
      ),
      child: Text(
        '$percentageText% - ${palette.label}',
        maxLines: maxLines,
        overflow: overflow,
        style: textTheme.labelSmall?.copyWith(
          color: palette.textColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  _ApplicabilityPalette _resolvePalette(AppThemeTokens tokens) {
    if (classificationLevel != null) {
      return _resolvePaletteByClassification(tokens, classificationLevel!);
    }

    return _resolvePaletteByPercentage(tokens);
  }

  _ApplicabilityPalette _resolvePaletteByClassification(
    AppThemeTokens tokens,
    AnalysisPrecedentClassificationLevelDto level,
  ) {
    switch (level) {
      case AnalysisPrecedentClassificationLevelDto.applicable:
        return _ApplicabilityPalette(
          label: 'Aplicavel',
          textColor: tokens.success,
          backgroundColor: tokens.success.withValues(alpha: 0.12),
          borderColor: tokens.success.withValues(alpha: 0.28),
        );
      case AnalysisPrecedentClassificationLevelDto.possiblyApplicable:
        return _ApplicabilityPalette(
          label: 'Possivelmente aplicavel',
          textColor: tokens.warning,
          backgroundColor: tokens.warning.withValues(alpha: 0.12),
          borderColor: tokens.warning.withValues(alpha: 0.28),
        );
      case AnalysisPrecedentClassificationLevelDto.notApplicable:
        return _ApplicabilityPalette(
          label: 'Não aplicável',
          textColor: tokens.danger,
          backgroundColor: tokens.danger.withValues(alpha: 0.12),
          borderColor: tokens.danger.withValues(alpha: 0.28),
        );
    }
  }

  _ApplicabilityPalette _resolvePaletteByPercentage(AppThemeTokens tokens) {
    if (percentage >= 85) {
      return _ApplicabilityPalette(
        label: 'Aplicavel',
        textColor: tokens.success,
        backgroundColor: tokens.success.withValues(alpha: 0.12),
        borderColor: tokens.success.withValues(alpha: 0.28),
      );
    }

    if (percentage >= 70) {
      return _ApplicabilityPalette(
        label: 'Possivelmente aplicavel',
        textColor: tokens.warning,
        backgroundColor: tokens.warning.withValues(alpha: 0.12),
        borderColor: tokens.warning.withValues(alpha: 0.28),
      );
    }

    return _ApplicabilityPalette(
      label: 'Não aplicável',
      textColor: tokens.danger,
      backgroundColor: tokens.danger.withValues(alpha: 0.12),
      borderColor: tokens.danger.withValues(alpha: 0.28),
    );
  }
}

class _ApplicabilityPalette {
  final String label;
  final Color textColor;
  final Color backgroundColor;
  final Color borderColor;

  const _ApplicabilityPalette({
    required this.label,
    required this.textColor,
    required this.backgroundColor,
    required this.borderColor,
  });
}
