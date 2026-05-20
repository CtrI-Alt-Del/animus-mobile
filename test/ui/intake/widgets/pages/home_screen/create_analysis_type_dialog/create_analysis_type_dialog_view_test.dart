import 'package:animus/core/intake/dtos/analysis_type_dto.dart';
import 'package:animus/theme.dart';
import 'package:animus/ui/intake/widgets/pages/home_screen/create_analysis_type_dialog/create_analysis_type_dialog_view.dart';
import 'package:animus/ui/intake/widgets/pages/home_screen/create_analysis_type_dialog/create_analysis_type_option/create_analysis_type_option_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renderiza titulo, subtitulo, tres opcoes e botoes do dialog', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _createHost(builder: () => const CreateAnalysisTypeDialogView()),
    );

    await tester.tap(find.text('Abrir dialog'));
    await tester.pumpAndSettle();

    expect(find.text('Nova análise'), findsOneWidget);
    expect(find.text('Escolha o tipo da análise.'), findsOneWidget);

    expect(find.text('Avaliação de caso'), findsOneWidget);
    expect(find.text('Primeira instância'), findsOneWidget);
    expect(find.text('Segunda instância'), findsOneWidget);

    expect(find.byType(CreateAnalysisTypeOptionView), findsNWidgets(3));

    expect(find.text('Cancelar'), findsOneWidget);
    expect(find.text('Criar'), findsOneWidget);
  });

  testWidgets(
    'pre-seleciona firstInstance por padrao e marca o indicador correspondente',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        _createHost(builder: () => const CreateAnalysisTypeDialogView()),
      );

      await tester.tap(find.text('Abrir dialog'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
      expect(find.byIcon(Icons.radio_button_unchecked), findsNWidgets(2));

      final CreateAnalysisTypeOptionView firstInstanceOption = tester
          .widget<CreateAnalysisTypeOptionView>(
            find.ancestor(
              of: find.text('Primeira instância'),
              matching: find.byType(CreateAnalysisTypeOptionView),
            ),
          );
      expect(firstInstanceOption.isSelected, isTrue);
    },
  );

  testWidgets('respeita initialType ao pre-selecionar uma opcao diferente', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _createHost(
        builder: () => const CreateAnalysisTypeDialogView(
          initialType: AnalysisTypeDto.secondInstance,
        ),
      ),
    );

    await tester.tap(find.text('Abrir dialog'));
    await tester.pumpAndSettle();

    final CreateAnalysisTypeOptionView secondInstanceOption = tester
        .widget<CreateAnalysisTypeOptionView>(
          find.ancestor(
            of: find.text('Segunda instância'),
            matching: find.byType(CreateAnalysisTypeOptionView),
          ),
        );
    expect(secondInstanceOption.isSelected, isTrue);
  });

  testWidgets('tocar em outra opcao move a selecao para o novo tipo', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _createHost(builder: () => const CreateAnalysisTypeDialogView()),
    );

    await tester.tap(find.text('Abrir dialog'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Avaliação de caso'));
    await tester.pumpAndSettle();

    final CreateAnalysisTypeOptionView caseAssessmentOption = tester
        .widget<CreateAnalysisTypeOptionView>(
          find.ancestor(
            of: find.text('Avaliação de caso'),
            matching: find.byType(CreateAnalysisTypeOptionView),
          ),
        );
    expect(caseAssessmentOption.isSelected, isTrue);

    final CreateAnalysisTypeOptionView firstInstanceOption = tester
        .widget<CreateAnalysisTypeOptionView>(
          find.ancestor(
            of: find.text('Primeira instância'),
            matching: find.byType(CreateAnalysisTypeOptionView),
          ),
        );
    expect(firstInstanceOption.isSelected, isFalse);
  });

  testWidgets('Cancelar fecha o dialog retornando null', (
    WidgetTester tester,
  ) async {
    AnalysisTypeDto? result;
    bool resolved = false;

    await tester.pumpWidget(
      _createHost(
        builder: () => const CreateAnalysisTypeDialogView(),
        onResolved: (AnalysisTypeDto? value) {
          result = value;
          resolved = true;
        },
      ),
    );

    await tester.tap(find.text('Abrir dialog'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(resolved, isTrue);
    expect(result, isNull);
  });

  testWidgets('Criar fecha o dialog retornando o tipo selecionado', (
    WidgetTester tester,
  ) async {
    AnalysisTypeDto? result;
    bool resolved = false;

    await tester.pumpWidget(
      _createHost(
        builder: () => const CreateAnalysisTypeDialogView(),
        onResolved: (AnalysisTypeDto? value) {
          result = value;
          resolved = true;
        },
      ),
    );

    await tester.tap(find.text('Abrir dialog'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Segunda instância'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Criar'));
    await tester.pumpAndSettle();

    expect(resolved, isTrue);
    expect(result, AnalysisTypeDto.secondInstance);
  });

  testWidgets('Criar mantem firstInstance quando nenhuma opcao foi trocada', (
    WidgetTester tester,
  ) async {
    AnalysisTypeDto? result;

    await tester.pumpWidget(
      _createHost(
        builder: () => const CreateAnalysisTypeDialogView(),
        onResolved: (AnalysisTypeDto? value) => result = value,
      ),
    );

    await tester.tap(find.text('Abrir dialog'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Criar'));
    await tester.pumpAndSettle();

    expect(result, AnalysisTypeDto.firstInstance);
  });
}

Widget _createHost({
  required CreateAnalysisTypeDialogView Function() builder,
  void Function(AnalysisTypeDto? result)? onResolved,
}) {
  return MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(
      body: Builder(
        builder: (BuildContext context) {
          return Center(
            child: ElevatedButton(
              onPressed: () async {
                final AnalysisTypeDto? value =
                    await showDialog<AnalysisTypeDto>(
                      context: context,
                      builder: (_) => builder(),
                    );
                onResolved?.call(value);
              },
              child: const Text('Abrir dialog'),
            ),
          );
        },
      ),
    ),
  );
}
