import 'package:animus/core/intake/dtos/analysis_type_dto.dart';
import 'package:animus/ui/intake/widgets/pages/home_screen/create_analysis_type_dialog/create_analysis_type_dialog_presenter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CreateAnalysisTypeDialogPresenter', () {
    test('inicializa selectedType com firstInstance por padrao', () {
      final CreateAnalysisTypeDialogPresenter presenter =
          CreateAnalysisTypeDialogPresenter();
      addTearDown(presenter.dispose);

      expect(presenter.selectedType.value, AnalysisTypeDto.firstInstance);
      expect(presenter.selected, AnalysisTypeDto.firstInstance);
    });

    test('inicializa selectedType com o initialType fornecido', () {
      final CreateAnalysisTypeDialogPresenter presenter =
          CreateAnalysisTypeDialogPresenter(
            initialType: AnalysisTypeDto.secondInstance,
          );
      addTearDown(presenter.dispose);

      expect(presenter.selectedType.value, AnalysisTypeDto.secondInstance);
    });

    test(
      'expoe a ordem visual fixa com caseAssessment, firstInstance e secondInstance',
      () {
        expect(
          CreateAnalysisTypeDialogPresenter.orderedTypes,
          <AnalysisTypeDto>[
            AnalysisTypeDto.caseAssessment,
            AnalysisTypeDto.firstInstance,
            AnalysisTypeDto.secondInstance,
          ],
        );
      },
    );

    test('selectType atualiza o tipo selecionado', () {
      final CreateAnalysisTypeDialogPresenter presenter =
          CreateAnalysisTypeDialogPresenter();
      addTearDown(presenter.dispose);

      presenter.selectType(AnalysisTypeDto.caseAssessment);
      expect(presenter.selected, AnalysisTypeDto.caseAssessment);

      presenter.selectType(AnalysisTypeDto.secondInstance);
      expect(presenter.selected, AnalysisTypeDto.secondInstance);
    });

    test('selectType com o mesmo tipo nao reemite', () {
      final CreateAnalysisTypeDialogPresenter presenter =
          CreateAnalysisTypeDialogPresenter();
      addTearDown(presenter.dispose);

      int notifications = 0;
      final void Function() unsubscribe = presenter.selectedType.subscribe((_) {
        notifications += 1;
      });
      addTearDown(unsubscribe);

      // O subscribe inicial dispara uma vez com o valor atual.
      expect(notifications, 1);

      presenter.selectType(AnalysisTypeDto.firstInstance);
      expect(notifications, 1, reason: 'mesmo tipo nao gera novo evento');

      presenter.selectType(AnalysisTypeDto.caseAssessment);
      expect(notifications, 2);
    });

    test('isSelected reflete corretamente o tipo atual', () {
      final CreateAnalysisTypeDialogPresenter presenter =
          CreateAnalysisTypeDialogPresenter(
            initialType: AnalysisTypeDto.firstInstance,
          );
      addTearDown(presenter.dispose);

      expect(presenter.isSelected(AnalysisTypeDto.firstInstance), isTrue);
      expect(presenter.isSelected(AnalysisTypeDto.caseAssessment), isFalse);
      expect(presenter.isSelected(AnalysisTypeDto.secondInstance), isFalse);

      presenter.selectType(AnalysisTypeDto.secondInstance);
      expect(presenter.isSelected(AnalysisTypeDto.secondInstance), isTrue);
      expect(presenter.isSelected(AnalysisTypeDto.firstInstance), isFalse);
    });

    test('titleFor retorna o titulo PT-BR para cada tipo', () {
      final CreateAnalysisTypeDialogPresenter presenter =
          CreateAnalysisTypeDialogPresenter();
      addTearDown(presenter.dispose);

      expect(
        presenter.titleFor(AnalysisTypeDto.caseAssessment),
        'Avaliacao de caso',
      );
      expect(
        presenter.titleFor(AnalysisTypeDto.firstInstance),
        'Primeira instancia',
      );
      expect(
        presenter.titleFor(AnalysisTypeDto.secondInstance),
        'Segunda instancia',
      );
    });

    test('descriptionFor retorna a descricao PT-BR para cada tipo', () {
      final CreateAnalysisTypeDialogPresenter presenter =
          CreateAnalysisTypeDialogPresenter();
      addTearDown(presenter.dispose);

      expect(
        presenter.descriptionFor(AnalysisTypeDto.caseAssessment),
        'Diagnostico inicial do caso',
      );
      expect(
        presenter.descriptionFor(AnalysisTypeDto.firstInstance),
        'Resposta a peticao inicial',
      );
      expect(
        presenter.descriptionFor(AnalysisTypeDto.secondInstance),
        'Revisao de decisao em grau de recurso',
      );
    });

    test('iconFor retorna icones Material distintos para cada tipo', () {
      final CreateAnalysisTypeDialogPresenter presenter =
          CreateAnalysisTypeDialogPresenter();
      addTearDown(presenter.dispose);

      final IconData caseAssessmentIcon = presenter.iconFor(
        AnalysisTypeDto.caseAssessment,
      );
      final IconData firstInstanceIcon = presenter.iconFor(
        AnalysisTypeDto.firstInstance,
      );
      final IconData secondInstanceIcon = presenter.iconFor(
        AnalysisTypeDto.secondInstance,
      );

      expect(caseAssessmentIcon, Icons.fact_check_outlined);
      expect(firstInstanceIcon, Icons.gavel_outlined);
      expect(secondInstanceIcon, Icons.account_balance_outlined);
    });
  });
}
