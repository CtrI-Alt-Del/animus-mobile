import 'package:animus/core/intake/dtos/analysis_precedent_dto.dart';
import 'package:animus/theme.dart';
import 'package:animus/ui/intake/widgets/pages/analysis_screen/precedent_dialog/precedent_dialog_view.dart';
import 'package:animus/ui/intake/widgets/pages/analysis_screen/relevant_precedents_bubble/relevant_precedents_bubble_presenter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../../fakers/intake/analysis_precedent_dto_faker.dart';

class _MockRelevantPrecedentsBubblePresenter extends Mock
    implements RelevantPrecedentsBubblePresenter {}

void main() {
  late _MockRelevantPrecedentsBubblePresenter presenter;
  late AnalysisPrecedentDto precedent;

  setUpAll(() {
    registerFallbackValue(AnalysisPrecedentDtoFaker.fake());
  });

  Widget createApp() {
    return ProviderScope(
      overrides: [
        relevantPrecedentsBubblePresenterProvider(
          'analysis-123',
        ).overrideWithValue(presenter),
      ],
      child: MaterialApp(
        theme: AppTheme.dark,
        home: Builder(
          builder: (BuildContext context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => PrecedentDialogView(
                          analysisId: 'analysis-123',
                          precedent: precedent,
                        ),
                      ),
                    );
                  },
                  child: const Text('Abrir'),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  setUp(() {
    presenter = _MockRelevantPrecedentsBubblePresenter();
    precedent = AnalysisPrecedentDtoFaker.fake(
      synthesis: 'Síntese detalhada do precedente.',
    );
    when(() => presenter.openPangea(any())).thenAnswer((_) async {});
    when(() => presenter.choosePrecedent(any())).thenReturn(null);
    when(
      () => presenter.confirmPrecedentChoice(),
    ).thenAnswer((_) async => true);
  });

  Future<void> openDialog(WidgetTester tester) async {
    await tester.pumpWidget(createApp());
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('renderiza CTA link e sintese', (WidgetTester tester) async {
    await openDialog(tester);

    expect(find.text('Acessar Pangea'), findsOneWidget);
    expect(find.text('Síntese Explicativa'), findsOneWidget);
    expect(find.text('Síntese detalhada do precedente.'), findsOneWidget);
    expect(find.text('Escolher Precedente'), findsOneWidget);
  });

  testWidgets('fecha apenas quando confirmacao retorna sucesso', (
    WidgetTester tester,
  ) async {
    when(
      () => presenter.confirmPrecedentChoice(),
    ).thenAnswer((_) async => true);

    await openDialog(tester);
    await tester.tap(find.text('Escolher Precedente'));
    await tester.pumpAndSettle();

    verify(() => presenter.choosePrecedent(precedent)).called(1);
    verify(() => presenter.confirmPrecedentChoice()).called(1);
    expect(find.byType(PrecedentDialogView), findsNothing);
    expect(find.text('Abrir'), findsOneWidget);
  });

  testWidgets('mantem dialogo aberto quando confirmacao falha', (
    WidgetTester tester,
  ) async {
    when(
      () => presenter.confirmPrecedentChoice(),
    ).thenAnswer((_) async => false);

    await openDialog(tester);
    await tester.tap(find.text('Escolher Precedente'));
    await tester.pumpAndSettle();

    verify(() => presenter.confirmPrecedentChoice()).called(1);
    expect(find.byType(PrecedentDialogView), findsOneWidget);
    expect(find.text('Escolher Precedente'), findsOneWidget);
  });
}
