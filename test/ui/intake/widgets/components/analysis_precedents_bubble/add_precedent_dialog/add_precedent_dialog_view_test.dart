import 'package:animus/core/intake/interfaces/intake_service.dart';
import 'package:animus/rest/services/index.dart';
import 'package:animus/theme.dart';
import 'package:animus/ui/intake/widgets/components/analysis_precedents_bubble/add_precedent_dialog/add_precedent_dialog_presenter.dart';
import 'package:animus/ui/intake/widgets/components/analysis_precedents_bubble/add_precedent_dialog/add_precedent_dialog_view.dart';
import 'package:animus/ui/intake/widgets/components/analysis_precedents_bubble/analysis_precedents_bubble_presenter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../../fakers/intake/analysis_precedent_dto_faker.dart';

class _MockIntakeService extends Mock implements IntakeService {}

class _MockAnalysisPrecedentsBubblePresenter extends Mock
    implements AnalysisPrecedentsBubblePresenter {}

void main() {
  late _MockIntakeService intakeService;
  late _MockAnalysisPrecedentsBubblePresenter bubblePresenter;
  late AddPrecedentDialogPresenter presenter;

  setUp(() {
    intakeService = _MockIntakeService();
    bubblePresenter = _MockAnalysisPrecedentsBubblePresenter();
    when(() => bubblePresenter.reloadPrecedents()).thenAnswer((_) async {});
    presenter = AddPrecedentDialogPresenter(
      intakeService: intakeService,
      bubblePresenter: bubblePresenter,
      analysisId: 'analysis-1',
    );
  });

  tearDown(() {
    presenter.dispose();
  });

  Widget createWidget() {
    return ProviderScope(
      overrides: [
        intakeServiceProvider.overrideWithValue(intakeService),
        analysisPrecedentsBubblePresenterProvider(
          'analysis-1',
        ).overrideWithValue(bubblePresenter),
        addPrecedentDialogPresenterProvider(
          'analysis-1',
        ).overrideWithValue(presenter),
      ],
      child: MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(
          body: AddPrecedentDialogView(analysisId: 'analysis-1'),
        ),
      ),
    );
  }

  testWidgets('should render basic form and primary actions', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createWidget());

    expect(find.text('Adicionar precedente'), findsOneWidget);
    expect(find.text('Tribunal'), findsOneWidget);
    expect(find.text('Espécie'), findsOneWidget);
    expect(find.text('Número'), findsOneWidget);
    expect(find.text('Buscar precedente'), findsOneWidget);
    expect(find.text('Cancelar'), findsOneWidget);
    expect(find.text('Adicionar'), findsOneWidget);
  });

  testWidgets('should render preview card when presenter has preview', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    presenter.previewPrecedent.value = PrecedentDtoFaker.fake(
      enunciation: 'E' * 140,
      thesis: 'T' * 140,
    );

    await tester.pumpWidget(createWidget());
    await tester.pump();

    expect(find.text('Status'), findsOneWidget);
    expect(find.text('Enunciado'), findsOneWidget);
    expect(find.text('Tese'), findsOneWidget);
    expect(find.text('Mostrar mais'), findsNWidgets(2));

    await tester.ensureVisible(find.text('Mostrar mais').first);
    await tester.tap(find.text('Mostrar mais').first);
    await tester.pump();

    expect(find.text('Mostrar menos'), findsOneWidget);
  });

  testWidgets('should show preview error from presenter', (
    WidgetTester tester,
  ) async {
    presenter.generalError.value = 'Precedente não encontrado.';

    await tester.pumpWidget(createWidget());
    await tester.pump();

    expect(find.text('Precedente não encontrado.'), findsOneWidget);
  });
}
