import 'package:flutter/material.dart';

import 'package:animus/core/intake/dtos/analysis_precedent_dto.dart';
import 'package:animus/theme.dart';
import 'package:animus/ui/intake/widgets/pages/analysis_screen/applicability_badge/index.dart';

class ChosenPrecedentSummaryView extends StatelessWidget {
  final AnalysisPrecedentDto selectedPrecedent;

  const ChosenPrecedentSummaryView({
    required this.selectedPrecedent,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

    final String title =
        '${selectedPrecedent.precedent.identifier.court.value} ${selectedPrecedent.precedent.identifier.kind.value} ${selectedPrecedent.precedent.identifier.number}';
    final String status = _formatPrecedentStatus(
      selectedPrecedent.precedent.status,
    );
    final String synthesis = selectedPrecedent.synthesis.trim();
    final String synthesisText = synthesis.isEmpty
        ? 'A sintese explicativa ainda nao esta disponivel para este precedente.'
        : synthesis;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Precedente escolhido',
            style: textTheme.titleSmall?.copyWith(
              color: tokens.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: tokens.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: tokens.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(Icons.balance, color: tokens.accent, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: textTheme.bodyMedium?.copyWith(
                          color: tokens.textPrimary,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ApplicabilityBadge(
                    percentage: selectedPrecedent.similarityScore,
                    percentageText: _formatSimilarityScore(
                      selectedPrecedent.similarityScore,
                    ),
                    classificationLevel: selectedPrecedent.applicabilityLevel,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: tokens.surfaceCard,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: tokens.borderSubtle),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        Icons.gavel_outlined,
                        size: 16,
                        color: tokens.accent,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          status,
                          style: textTheme.labelMedium?.copyWith(
                            color: tokens.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Sintese Explicativa',
            style: textTheme.titleSmall?.copyWith(
              fontFamily: 'Fraunces',
              fontSize: 18,
              color: tokens.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            synthesisText,
            style: textTheme.bodyMedium?.copyWith(
              color: tokens.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  String _formatPrecedentStatus(String value) {
    final String normalized = value.trim();
    if (normalized.isEmpty) {
      return 'Transito em Julgado';
    }

    final String sanitized = normalized.replaceAll('_', ' ').toLowerCase();
    final List<String> parts = sanitized
        .split(RegExp(r'\s+'))
        .where((String part) => part.isNotEmpty)
        .toList();

    return parts
        .map((String part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  String _formatSimilarityScore(double value) {
    return value.clamp(0, 100).toStringAsFixed(1);
  }
}
