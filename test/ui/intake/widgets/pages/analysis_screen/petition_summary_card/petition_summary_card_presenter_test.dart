import 'package:flutter_test/flutter_test.dart';

import 'package:animus/ui/intake/widgets/pages/analysis_screen/petition_summary_card/petition_summary_card_presenter.dart';

import '../../../../../../fakers/intake/petition_summary_dto_faker.dart';

void main() {
  group('PetitionSummaryCardPresenter', () {
    test(
      'should build clipboard summary with placeholders and bullet lists',
      () {
        final PetitionSummaryCardPresenter presenter =
            PetitionSummaryCardPresenter();
        final summary = PetitionSummaryDtoFaker.fake(
          caseSummary: 'Resumo do caso',
          legalIssue: 'Questao juridica principal',
          centralQuestion: 'Pergunta central',
          relevantLaws: const <String>['Art. 5', '  ', 'Art. 7'],
          keyFacts: const <String>[],
          searchTerms: const <String>['termo 1'],
          typeOfAction: 'Mandado de seguranca',
          jurisdictionIssue: '  ',
          standingIssue: null,
          secondaryLegalIssues: const <String>['Tese secundaria'],
          alternativeQuestions: const <String>[],
          requestedRelief: const <String>['Pedido 1'],
          proceduralIssues: const <String>[],
          excludedOrAccessoryTopics: const <String>['Topico acessorio'],
        );

        final String result = presenter.buildSummaryForClipboard(summary);

        expect(result, startsWith('Síntese da Análise'));
        expect(result, contains('Resumo do caso\nResumo do caso'));
        expect(result, contains('Questao de jurisdicao\n-'));
        expect(result, contains('Questao de legitimidade\n-'));
        expect(result, contains('Leis relevantes\n- Art. 5\n- Art. 7'));
        expect(result, contains('Fatos-chave\n-'));
        expect(result, contains('Pedidos\n- Pedido 1'));
        expect(
          result,
          contains('Topicos excluidos ou acessorios\n- Topico acessorio'),
        );
      },
    );
  });
}
