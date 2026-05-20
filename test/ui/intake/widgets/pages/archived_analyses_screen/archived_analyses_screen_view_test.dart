import 'package:animus/core/intake/dtos/analysis_dto.dart';
import 'package:animus/theme.dart';
import 'package:animus/ui/intake/widgets/pages/archived_analyses_screen/archived_analyses_empty_state/index.dart';
import 'package:animus/ui/intake/widgets/pages/archived_analyses_screen/archived_analyses_error_state/index.dart';
import 'package:animus/ui/intake/widgets/pages/archived_analyses_screen/archived_analyses_loading_state/index.dart';
import 'package:animus/ui/intake/widgets/pages/archived_analyses_screen/archived_analyses_screen_presenter.dart';
import 'package:animus/ui/intake/widgets/pages/archived_analyses_screen/archived_analyses_screen_view.dart';
import 'package:animus/ui/intake/widgets/pages/archived_analyses_screen/archived_analysis_card/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../../fakers/intake/analysis_dto_faker.dart';

class _MockArchivedAnalysesScreenPresenter extends Mock
    implements ArchivedAnalysesScreenPresenter {}

class _FakeAnalysisDto extends Fake implements AnalysisDto {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeAnalysisDto());
  });

  late _MockArchivedAnalysesScreenPresenter presenter;
  late Signal<bool> isLoadingInitialData;
  late Signal<bool> isLoadingMore;
  late Signal<bool> isUnarchiving;
  late Signal<String?> unarchivingId;
  late Signal<String?> generalError;
  late Signal<String?> paginationError;
  late Signal<List<AnalysisDto>> archivedAnalyses;
  late Signal<String?> nextCursor;
  late Signal<String> searchQuery;
  late ReadonlySignal<bool> hasMore;
  late ReadonlySignal<bool> showEmptyState;
  late ReadonlySignal<bool> showSearchEmptyState;

  setUp(() {
    presenter = _MockArchivedAnalysesScreenPresenter();
    isLoadingInitialData = signal<bool>(false);
    isLoadingMore = signal<bool>(false);
    isUnarchiving = signal<bool>(false);
    unarchivingId = signal<String?>(null);
    generalError = signal<String?>(null);
    paginationError = signal<String?>(null);
    archivedAnalyses = signal<List<AnalysisDto>>(const <AnalysisDto>[]);
    nextCursor = signal<String?>(null);
    searchQuery = signal<String>('');
    hasMore = computed(() => (nextCursor.value ?? '').trim().isNotEmpty);
    showEmptyState = computed(
      () =>
          !isLoadingInitialData.value &&
          generalError.value == null &&
          searchQuery.value.trim().isEmpty &&
          archivedAnalyses.value.isEmpty,
    );
    showSearchEmptyState = computed(
      () =>
          !isLoadingInitialData.value &&
          generalError.value == null &&
          searchQuery.value.trim().isNotEmpty &&
          archivedAnalyses.value.isEmpty,
    );

    when(() => presenter.isLoadingInitialData).thenReturn(isLoadingInitialData);
    when(() => presenter.isLoadingMore).thenReturn(isLoadingMore);
    when(() => presenter.isUnarchiving).thenReturn(isUnarchiving);
    when(() => presenter.unarchivingId).thenReturn(unarchivingId);
    when(() => presenter.generalError).thenReturn(generalError);
    when(() => presenter.paginationError).thenReturn(paginationError);
    when(() => presenter.archivedAnalyses).thenReturn(archivedAnalyses);
    when(() => presenter.nextCursor).thenReturn(nextCursor);
    when(() => presenter.searchQuery).thenReturn(searchQuery);
    when(() => presenter.hasMore).thenReturn(hasMore);
    when(() => presenter.showEmptyState).thenReturn(showEmptyState);
    when(() => presenter.showSearchEmptyState).thenReturn(showSearchEmptyState);
    when(() => presenter.formatCreatedAt(any())).thenReturn('18/05/2026');
    when(() => presenter.refresh()).thenAnswer((_) async {});
    when(() => presenter.loadNextPage()).thenAnswer((_) async {});
    when(() => presenter.openAnalysis(any())).thenAnswer((_) async {});
    when(() => presenter.updateSearchQuery(any())).thenReturn(null);
    when(() => presenter.clearSearch()).thenReturn(null);
    when(() => presenter.goBack()).thenReturn(null);
    when(() => presenter.unarchive(any())).thenAnswer((_) async => true);
  });

  tearDown(() {
    isLoadingInitialData.dispose();
    isLoadingMore.dispose();
    isUnarchiving.dispose();
    unarchivingId.dispose();
    generalError.dispose();
    paginationError.dispose();
    archivedAnalyses.dispose();
    nextCursor.dispose();
    searchQuery.dispose();
    hasMore.dispose();
    showEmptyState.dispose();
    showSearchEmptyState.dispose();
  });

  testWidgets('renderiza estado de loading inicial', (
    WidgetTester tester,
  ) async {
    isLoadingInitialData.value = true;

    await tester.pumpWidget(_createWidget(presenter));
    await tester.pump();

    expect(find.byType(ArchivedAnalysesLoadingState), findsOneWidget);
    expect(find.text('Análises arquivadas'), findsOneWidget);
  });

  testWidgets('renderiza estado de erro e dispara refresh', (
    WidgetTester tester,
  ) async {
    generalError.value = 'Falha ao carregar';

    await tester.pumpWidget(_createWidget(presenter));
    await tester.pump();
    clearInteractions(presenter);

    expect(find.byType(ArchivedAnalysesErrorState), findsOneWidget);
    expect(find.text('Falha ao carregar'), findsOneWidget);

    await tester.tap(find.text('Tentar novamente'));
    await tester.pump();

    verify(() => presenter.refresh()).called(1);
  });

  testWidgets('renderiza estado vazio geral', (WidgetTester tester) async {
    await tester.pumpWidget(_createWidget(presenter));
    await tester.pump();

    expect(find.byType(ArchivedAnalysesEmptyState), findsOneWidget);
    expect(
      find.text('Você ainda não tem análises arquivadas.'),
      findsOneWidget,
    );
  });

  testWidgets('renderiza cards com items', (WidgetTester tester) async {
    archivedAnalyses.value = <AnalysisDto>[
      AnalysisDtoFaker.fake(id: 'a-1', name: 'Analise A'),
      AnalysisDtoFaker.fake(id: 'a-2', name: 'Analise B'),
    ];

    await tester.pumpWidget(_createWidget(presenter));
    await tester.pump();

    expect(find.byType(ArchivedAnalysisCard), findsNWidgets(2));
    expect(find.text('Analise A'), findsOneWidget);
    expect(find.text('Analise B'), findsOneWidget);
    expect(find.text('18/05/2026'), findsNWidgets(2));
  });

  testWidgets('aciona openAnalysis ao tocar em um card', (
    WidgetTester tester,
  ) async {
    final AnalysisDto analysis = AnalysisDtoFaker.fake(
      id: 'a-1',
      name: 'Analise A',
    );
    archivedAnalyses.value = <AnalysisDto>[analysis];

    await tester.pumpWidget(_createWidget(presenter));
    await tester.pump();
    clearInteractions(presenter);

    await tester.tap(find.text('Analise A'));
    await tester.pump();

    verify(() => presenter.openAnalysis(any())).called(1);
  });

  testWidgets('renderiza estado vazio especifico para busca sem resultados', (
    WidgetTester tester,
  ) async {
    archivedAnalyses.value = const <AnalysisDto>[];
    searchQuery.value = 'inexistente';

    await tester.pumpWidget(_createWidget(presenter));
    await tester.pump();

    expect(find.byType(ArchivedAnalysesEmptyState), findsOneWidget);
    expect(
      find.text('Nenhuma análise encontrada para "inexistente".'),
      findsOneWidget,
    );
  });

  testWidgets('aciona goBack ao tocar no botao de voltar', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_createWidget(presenter));
    await tester.pump();
    clearInteractions(presenter);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pump();

    verify(() => presenter.goBack()).called(1);
  });
}

Widget _createWidget(_MockArchivedAnalysesScreenPresenter presenter) {
  return ProviderScope(
    overrides: [
      archivedAnalysesScreenPresenterProvider.overrideWithValue(presenter),
      archivedAnalysesScreenInitializationProvider.overrideWithValue(null),
    ],
    child: MaterialApp(
      theme: AppTheme.dark,
      home: const ArchivedAnalysesScreenView(),
    ),
  );
}
