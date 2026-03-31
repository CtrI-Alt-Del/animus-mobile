import 'package:flutter/material.dart';

import 'package:animus/core/intake/dtos/petition_summary_dto.dart';
import 'package:animus/theme.dart';

class PetitionSummaryCardView extends StatelessWidget {
  final PetitionSummaryDto summary;

  const PetitionSummaryCardView({required this.summary, super.key});

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Resumo da Analise',
              style: textTheme.titleMedium?.copyWith(
                color: tokens.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            _SummarySection(
              title: 'Resumo do caso',
              content: summary.caseSummary,
            ),
            _SummarySection(
              title: 'Questao juridica',
              content: summary.legalIssue,
            ),
            _SummarySection(
              title: 'Pergunta central',
              content: summary.centralQuestion,
            ),
            _SummaryListSection(
              title: 'Leis relevantes',
              items: summary.relevantLaws,
            ),
            _SummaryListSection(title: 'Fatos-chave', items: summary.keyFacts),
            _SummaryListSection(
              title: 'Termos de busca',
              items: summary.searchTerms,
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummarySection extends StatelessWidget {
  final String title;
  final String content;

  const _SummarySection({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: textTheme.labelLarge?.copyWith(
              color: tokens.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: textTheme.bodyMedium?.copyWith(
              color: tokens.textSecondary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryListSection extends StatelessWidget {
  final String title;
  final List<String> items;
  final bool isLast;

  const _SummaryListSection({
    required this.title,
    required this.items,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: textTheme.labelLarge?.copyWith(
              color: tokens.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          ...items.map(
            (String item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: tokens.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: textTheme.bodyMedium?.copyWith(
                        color: tokens.textSecondary,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
