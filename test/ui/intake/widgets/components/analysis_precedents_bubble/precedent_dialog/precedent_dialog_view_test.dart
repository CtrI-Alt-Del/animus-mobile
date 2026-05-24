import 'package:animus/core/intake/interfaces/intake_service.dart';
import 'package:animus/core/intake/dtos/analysis_precedent_dto.dart';
import 'package:animus/core/intake/dtos/analysis_status_dto.dart';
import 'package:animus/core/shared/responses/rest_response.dart';
import 'package:animus/theme.dart';
import 'package:animus/ui/intake/widgets/components/analysis_precedents_bubble/analysis_precedents_bubble_presenter.dart';
import 'package:animus/ui/intake/widgets/components/analysis_precedents_bubble/precedent_dialog/precedent_dialog_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../../fakers/intake/analysis_precedent_dto_faker.dart';

class _MockIntakeService extends Mock implements IntakeService {}

void main() {
  late _MockIntakeService intakeService;
  late AnalysisPrecedentsBubblePresenter presenter;
  late AnalysisPrecedentDto precedent;

  setUpAll(() {
    registerFallbackValue(PrecedentIdentifierDtoFaker.fake());
  });

  setUp(() {
    intakeService = _MockIntakeService();
    presenter = AnalysisPrecedentsBubblePresenter(
      intakeService: intakeService,
      analysisId: 'analysis-123',
    );
    precedent = AnalysisPrecedentDtoFaker.fake(
      synthesis: 'Síntese detalhada do precedente.',
    );
    presenter.precedents.value = <AnalysisPrecedentDto>[precedent];
  });

  tearDown(() {
    presenter.dispose();
  });

  Widget createApp() {
    return ProviderScope(
      overrides: [
        analysisPrecedentsBubblePresenterProvider(
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
                        builder: (_) => AnalysisPrecedentDialogView(
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

  Future<void> openDialog(WidgetTester tester) async {
    await tester.pumpWidget(createApp());
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('should render chosen badge for manually added precedent', (
    WidgetTester tester,
  ) async {
    precedent = AnalysisPrecedentDtoFaker.fake(
      isChosen: true,
      isManuallyAdded: true,
      synthesis: 'Síntese detalhada do precedente.',
    );
    presenter.precedents.value = <AnalysisPrecedentDto>[precedent];

    await openDialog(tester);

    expect(find.text('Acessar Pangea'), findsOneWidget);
    expect(find.text('Trecho em Destaque'), findsOneWidget);
    expect(find.text('Justificativa (Síntese)'), findsOneWidget);
    expect(find.text('Manualmente adicionado'), findsOneWidget);
    expect(find.text('Desescolher precedente'), findsOneWidget);
  });

  testWidgets('should focus and close dialog when choosing succeeds', (
    WidgetTester tester,
  ) async {
    when(
      () => intakeService.chooseAnalysisPrecedent(
        analysisId: 'analysis-123',
        identifier: precedent.precedent.identifier,
      ),
    ).thenAnswer(
      (_) async => RestResponse(
        statusCode: 200,
        body: AnalysisStatusDto.precedentChosen,
      ),
    );

    await openDialog(tester);
    await tester.tap(find.text('Escolher Precedente'));
    await tester.pumpAndSettle();

    expect(
      presenter.focusedPrecedent.value?.precedent.identifier.number,
      precedent.precedent.identifier.number,
    );
    expect(find.byType(AnalysisPrecedentDialogView), findsNothing);
  });

  testWidgets('should keep dialog open when choosing fails', (
    WidgetTester tester,
  ) async {
    when(
      () => intakeService.chooseAnalysisPrecedent(
        analysisId: 'analysis-123',
        identifier: precedent.precedent.identifier,
      ),
    ).thenAnswer(
      (_) async => RestResponse(statusCode: 500, errorMessage: 'Falha'),
    );

    await openDialog(tester);
    await tester.tap(find.text('Escolher Precedente'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(find.byType(AnalysisPrecedentDialogView), findsOneWidget);
    expect(find.text('Escolher Precedente'), findsOneWidget);
  });

  testWidgets('should unchoose chosen precedent and close only on success', (
    WidgetTester tester,
  ) async {
    precedent = AnalysisPrecedentDtoFaker.fake(isChosen: true);
    presenter.precedents.value = <AnalysisPrecedentDto>[precedent];
    presenter.focusPrecedent(precedent);
    when(
      () => intakeService.unchooseAnalysisPrecedent(
        analysisId: 'analysis-123',
        identifier: precedent.precedent.identifier,
      ),
    ).thenAnswer(
      (_) async => RestResponse(
        statusCode: 200,
        body: AnalysisStatusDto.waitingPrecedentChoice,
      ),
    );

    await openDialog(tester);
    await tester.tap(find.text('Desescolher precedente'));
    await tester.pumpAndSettle();

    expect(presenter.precedents.value.single.isChosen, isFalse);
    expect(find.byType(AnalysisPrecedentDialogView), findsNothing);
  });
}
