import 'package:flutter/material.dart';

import 'package:animus/core/intake/dtos/case_summary_dto.dart';
import 'package:animus/theme.dart';
import 'package:animus/ui/intake/widgets/components/case_summary_card/case_summary_card_presenter.dart';
import 'package:animus/ui/intake/widgets/components/case_summary_card/summary_list_section/index.dart';
import 'package:animus/ui/intake/widgets/components/case_summary_card/summary_section/index.dart';

class CaseSummaryCardView extends StatefulWidget {
  final CaseSummaryDto summary;

  const CaseSummaryCardView({required this.summary, super.key});

  @override
  State<CaseSummaryCardView> createState() => _CaseSummaryCardViewState();
}

class _CaseSummaryCardViewState extends State<CaseSummaryCardView> {
  static const String _emptyValue = '-';

  bool _isExpanded = false;
  final CaseSummaryCardPresenter _presenter = CaseSummaryCardPresenter();

  List<String> _buildListItems(List<String> items) {
    final List<String> normalizedItems = items
        .map((String item) => item.trim())
        .where((String item) => item.isNotEmpty)
        .toList();

    return normalizedItems.isEmpty
        ? const <String>[_emptyValue]
        : normalizedItems;
  }

  String _buildText(String? value) {
    final String normalizedValue = (value ?? '').trim();
    return normalizedValue.isEmpty ? _emptyValue : normalizedValue;
  }

  Future<void> _copySummaryToClipboard() async {
    await _presenter.copySummaryToClipboard(widget.summary);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Síntese copiada para a área de transferência.'),
      ),
    );
  }

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
              'Síntese da Análise',
              style: textTheme.bodyMedium?.copyWith(
                color: tokens.accent,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            AnimatedSize(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder:
                    (Widget child, Animation<double> animation) =>
                        FadeTransition(opacity: animation, child: child),
                child: _isExpanded
                    ? Column(
                        key: const ValueKey<String>('expanded-summary'),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          SummarySection(
                            title: 'Resumo do caso',
                            content: _buildText(widget.summary.caseSummary),
                          ),
                          SummarySection(
                            title: 'Questao juridica',
                            content: _buildText(widget.summary.legalIssue),
                          ),
                          SummarySection(
                            title: 'Pergunta central',
                            content: _buildText(widget.summary.centralQuestion),
                          ),
                          SummarySection(
                            title: 'Tipo de acao',
                            content: _buildText(widget.summary.typeOfAction),
                          ),
                          SummarySection(
                            title: 'Questao de jurisdicao',
                            content: _buildText(
                              widget.summary.jurisdictionIssue,
                            ),
                          ),
                          SummarySection(
                            title: 'Questao de legitimidade',
                            content: _buildText(widget.summary.standingIssue),
                          ),
                          SummaryListSection(
                            title: 'Leis relevantes',
                            items: _buildListItems(widget.summary.relevantLaws),
                          ),
                          SummaryListSection(
                            title: 'Fatos-chave',
                            items: _buildListItems(widget.summary.keyFacts),
                          ),
                          SummaryListSection(
                            title: 'Termos de busca',
                            items: _buildListItems(widget.summary.searchTerms),
                          ),
                          SummaryListSection(
                            title: 'Teses juridicas secundarias',
                            items: _buildListItems(
                              widget.summary.secondaryLegalIssues,
                            ),
                          ),
                          SummaryListSection(
                            title: 'Perguntas alternativas',
                            items: _buildListItems(
                              widget.summary.alternativeQuestions,
                            ),
                          ),
                          SummaryListSection(
                            title: 'Pedidos',
                            items: _buildListItems(
                              widget.summary.requestedRelief,
                            ),
                          ),
                          SummaryListSection(
                            title: 'Questoes processuais',
                            items: _buildListItems(
                              widget.summary.proceduralIssues,
                            ),
                          ),
                          SummaryListSection(
                            title: 'Topicos excluidos ou acessorios',
                            items: _buildListItems(
                              widget.summary.excludedOrAccessoryTopics,
                            ),
                            isLast: true,
                          ),
                        ],
                      )
                    : Container(
                        key: const ValueKey<String>('collapsed-summary'),
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: tokens.surfaceElevated,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: tokens.borderSubtle),
                        ),
                        child: Text(
                          _buildText(widget.summary.caseSummary),
                          maxLines: 8,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodyMedium?.copyWith(
                            color: tokens.textSecondary,
                            height: 1.45,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: <Widget>[
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
                    style: textTheme.bodySmall?.copyWith(
                      color: tokens.textMuted,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 24),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: _copySummaryToClipboard,
                  icon: Icon(
                    Icons.copy_rounded,
                    size: 16,
                    color: tokens.textMuted,
                  ),
                  label: Text(
                    'Copiar',
                    style: textTheme.bodySmall?.copyWith(
                      color: tokens.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
