import 'package:animus/core/intake/dtos/analysis_precedent_dto.dart';
import 'package:animus/core/intake/dtos/analysis_status_dto.dart';
import 'package:animus/theme.dart';
import 'package:animus/ui/intake/widgets/pages/analysis_screen/relevant_precedents_bubble/relevant_precedents_bubble_presenter.dart';
import 'package:animus/ui/intake/widgets/pages/analysis_screen/relevant_precedents_bubble/relevant_precedents_bubble_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../../../fakers/intake/analysis_precedent_dto_faker.dart';

class _MockRelevantPrecedentsBubblePresenter extends Mock
    implements RelevantPrecedentsBubblePresenter {}

void main() {
  late _MockRelevantPrecedentsBubblePresenter presenter;
  late Signal<List<AnalysisPrecedentDto>> precedents;
  late Signal<bool> isLoading;
  late Signal<String?> generalError;
  late ReadonlySignal<int> totalCount;
  late ReadonlySignal<String> loadingMessage;
  late ReadonlySignal<bool> showEmptyState;

  setUpAll(() {
    registerFallbackValue(AnalysisStatusDto.searchingPrecedents);
  });

  Widget createWidget({ValueChanged<AnalysisPrecedentDto>? onPrecedentTap}) {
    return ProviderScope(
      overrides: [
        relevantPrecedentsBubblePresenterProvider(
          'analysis-123',
        ).overrideWithValue(presenter),
      ],
      child: MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: RelevantPrecedentsBubbleView(
            analysisId: 'analysis-123',
            analysisStatus: AnalysisStatusDto.searchingPrecedents,
            onPrecedentTap: onPrecedentTap,
          ),
        ),
      ),
    );
  }

  setUp(() {
    presenter = _MockRelevantPrecedentsBubblePresenter();
    precedents = signal<List<AnalysisPrecedentDto>>(<AnalysisPrecedentDto>[]);
    isLoading = signal<bool>(false);
    generalError = signal<String?>(null);
    totalCount = computed(() => precedents.value.length);
    loadingMessage = computed(
      () => 'Buscando precedentes relevantes na base nacional.',
    );
    showEmptyState = computed(
      () =>
          !isLoading.value &&
          generalError.value == null &&
          precedents.value.isEmpty,
    );

    when(() => presenter.precedents).thenReturn(precedents);
    when(() => presenter.isLoading).thenReturn(isLoading);
    when(() => presenter.generalError).thenReturn(generalError);
    when(() => presenter.totalCount).thenReturn(totalCount);
    when(() => presenter.loadingMessage).thenReturn(loadingMessage);
    when(() => presenter.showEmptyState).thenReturn(showEmptyState);
    when(() => presenter.syncAnalysisStatus(any())).thenReturn(null);
    when(() => presenter.retry()).thenAnswer((_) async {});
  });

  tearDown(() {
    precedents.dispose();
    isLoading.dispose();
    generalError.dispose();
    totalCount.dispose();
    loadingMessage.dispose();
    showEmptyState.dispose();
  });

  testWidgets('renderiza estado de loading', (WidgetTester tester) async {
    isLoading.value = true;

    await tester.pumpWidget(createWidget());

    expect(find.text('Precedentes Relevantes'), findsOneWidget);
    expect(
      find.text('Buscando precedentes relevantes na base nacional.'),
      findsOneWidget,
    );
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('renderiza estado de erro e delega retry', (
    WidgetTester tester,
  ) async {
    generalError.value = 'Falha ao carregar precedentes.';

    await tester.pumpWidget(createWidget());

    expect(find.text('Falha ao carregar precedentes.'), findsOneWidget);
    expect(find.text('Tentar novamente'), findsOneWidget);

    await tester.tap(find.text('Tentar novamente'));
    await tester.pump();

    verify(() => presenter.retry()).called(1);
  });

  testWidgets('renderiza estado vazio', (WidgetTester tester) async {
    await tester.pumpWidget(createWidget());

    expect(
      find.text(
        'Nenhum precedente relevante foi encontrado para esta peticao.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('renderiza content state e delega tap e refazer busca', (
    WidgetTester tester,
  ) async {
    final tapped = <AnalysisPrecedentDto>[];
    final first = AnalysisPrecedentDtoFaker.fake(
      precedent: PrecedentDtoFaker.fake(
        identifier: PrecedentIdentifierDtoFaker.fake(number: 123),
      ),
    );
    final second = AnalysisPrecedentDtoFaker.fake(
      precedent: PrecedentDtoFaker.fake(
        identifier: PrecedentIdentifierDtoFaker.fake(number: 456),
      ),
    );
    precedents.value = <AnalysisPrecedentDto>[first, second];

    await tester.pumpWidget(createWidget(onPrecedentTap: tapped.add));

    expect(find.text('TRT7 NT 123'), findsOneWidget);
    expect(find.text('TRT7 NT 456'), findsOneWidget);
    expect(find.text('Refazer busca'), findsOneWidget);

    await tester.tap(find.text('TRT7 NT 123'));
    await tester.pump();

    expect(tapped, <AnalysisPrecedentDto>[first]);

    await tester.tap(find.text('Refazer busca'));
    await tester.pump();

    verify(() => presenter.retry()).called(1);
  });
}
