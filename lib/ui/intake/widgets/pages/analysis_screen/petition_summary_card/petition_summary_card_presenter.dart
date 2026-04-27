import 'package:flutter/services.dart';

import 'package:animus/core/intake/dtos/petition_summary_dto.dart';

class PetitionSummaryCardPresenter {
  Future<bool> copySummaryToClipboard(PetitionSummaryDto summary) async {
    final String summaryText = buildSummaryForClipboard(summary);

    await Clipboard.setData(ClipboardData(text: summaryText));
    return true;
  }

  String buildSummaryForClipboard(PetitionSummaryDto summary) {
    String buildText(String title, String? content) {
      final String normalizedContent = (content ?? '').trim();
      return '$title\n${normalizedContent.isEmpty ? '-' : normalizedContent}';
    }

    String buildList(String title, List<String> items) {
      final List<String> normalizedItems = items
          .map((String item) => item.trim())
          .where((String item) => item.isNotEmpty)
          .toList();
      final String content =
          normalizedItems.isEmpty
              ? '-'
              : normalizedItems.map((String item) => '- $item').join('\n');
      return '$title\n$content';
    }

    return <String>[
      'Síntese da Análise',
      '',
      buildText('Resumo do caso', summary.caseSummary),
      '',
      buildText('Questao juridica', summary.legalIssue),
      '',
      buildText('Pergunta central', summary.centralQuestion),
      '',
      buildText('Tipo de acao', summary.typeOfAction),
      '',
      buildText('Questao de jurisdicao', summary.jurisdictionIssue),
      '',
      buildText('Questao de legitimidade', summary.standingIssue),
      '',
      buildList('Leis relevantes', summary.relevantLaws),
      '',
      buildList('Fatos-chave', summary.keyFacts),
      '',
      buildList('Termos de busca', summary.searchTerms),
      '',
      buildList('Teses juridicas secundarias', summary.secondaryLegalIssues),
      '',
      buildList('Perguntas alternativas', summary.alternativeQuestions),
      '',
      buildList('Pedidos', summary.requestedRelief),
      '',
      buildList('Questoes processuais', summary.proceduralIssues),
      '',
      buildList(
        'Topicos excluidos ou acessorios',
        summary.excludedOrAccessoryTopics,
      ),
    ].join('\n');
  }
}
