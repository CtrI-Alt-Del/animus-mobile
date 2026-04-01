import 'package:flutter/material.dart';

import 'package:animus/core/intake/dtos/petition_summary_dto.dart';
import 'package:animus/theme.dart';
import 'package:animus/ui/intake/widgets/pages/analysis_screen/petition_summary_card/summary_list_section/index.dart';
import 'package:animus/ui/intake/widgets/pages/analysis_screen/petition_summary_card/summary_section/index.dart';

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
            SummarySection(
              title: 'Resumo do caso',
              content: summary.caseSummary,
            ),
            SummarySection(
              title: 'Questao juridica',
              content: summary.legalIssue,
            ),
            SummarySection(
              title: 'Pergunta central',
              content: summary.centralQuestion,
            ),
            SummaryListSection(
              title: 'Leis relevantes',
              items: summary.relevantLaws,
            ),
            SummaryListSection(title: 'Fatos-chave', items: summary.keyFacts),
            SummaryListSection(
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
