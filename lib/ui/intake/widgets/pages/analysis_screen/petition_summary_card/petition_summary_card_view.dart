import 'package:flutter/material.dart';

import 'package:animus/core/intake/dtos/petition_summary_dto.dart';
import 'package:animus/theme.dart';
import 'package:animus/ui/intake/widgets/pages/analysis_screen/petition_summary_card/summary_list_section/index.dart';
import 'package:animus/ui/intake/widgets/pages/analysis_screen/petition_summary_card/summary_section/index.dart';

class PetitionSummaryCardView extends StatefulWidget {
  final PetitionSummaryDto summary;

  const PetitionSummaryCardView({required this.summary, super.key});

  @override
  State<PetitionSummaryCardView> createState() =>
      _PetitionSummaryCardViewState();
}

class _PetitionSummaryCardViewState extends State<PetitionSummaryCardView> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: tokens.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tokens.borderSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Resumo da Analise',
              style: textTheme.bodyMedium?.copyWith(
                color: tokens.accent,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            if (_isExpanded) ...<Widget>[
              SummarySection(
                title: 'Resumo do caso',
                content: widget.summary.caseSummary,
              ),
              SummarySection(
                title: 'Questao juridica',
                content: widget.summary.legalIssue,
              ),
              SummarySection(
                title: 'Pergunta central',
                content: widget.summary.centralQuestion,
              ),
              SummaryListSection(
                title: 'Leis relevantes',
                items: widget.summary.relevantLaws,
              ),
              SummaryListSection(
                title: 'Fatos-chave',
                items: widget.summary.keyFacts,
              ),
              SummaryListSection(
                title: 'Termos de busca',
                items: widget.summary.searchTerms,
                isLast: true,
              ),
            ] else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: tokens.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: tokens.borderSubtle),
                ),
                child: Text(
                  widget.summary.caseSummary,
                  maxLines: 8,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(
                    color: tokens.textSecondary,
                    height: 1.45,
                  ),
                ),
              ),
            const SizedBox(height: 2),
            TextButton(
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 24),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                alignment: Alignment.centerLeft,
              ),
              onPressed: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              child: Text(
                _isExpanded ? 'Mostrar menos' : 'Mostrar mais',
                style: textTheme.bodySmall?.copyWith(color: tokens.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
