import 'package:animus/core/intake/dtos/analysis_dto.dart';
import 'package:animus/core/intake/dtos/analysis_type_dto.dart';
import 'package:animus/theme.dart';
import 'package:animus/ui/intake/widgets/pages/home_screen/home_screen_presenter.dart';
import 'package:animus/ui/intake/widgets/pages/home_screen/home_screen_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../../fakers/intake/analysis_dto_faker.dart';

class _MockHomeScreenPresenter extends Mock implements HomeScreenPresenter {}

void main() {
  late _MockHomeScreenPresenter presenter;

  setUpAll(() {
    registerFallbackValue(AnalysisDtoFaker.fake());
    registerFallbackValue(AnalysisTypeDto.firstInstance);
  });

  setUp(() {
    presenter = _MockHomeScreenPresenter();
    when(() => presenter.initialize()).thenAnswer((_) async {});
    when(() => presenter.loadNextPage()).thenAnswer((_) async {});
    when(
      () => presenter.createAnalysis(type: any(named: 'type')),
    ).thenAnswer((_) async {});
    when(() => presenter.refresh()).thenAnswer((_) async {});
    when(() => presenter.openAnalysis(any())).thenAnswer((_) async {});
    when(() => presenter.dispose()).thenReturn(null);
    when(() => presenter.formatCreatedAt(any())).thenReturn('31/03/2026');
    when(() => presenter.isLoadingInitialData).thenReturn(signal<bool>(false));
    when(() => presenter.isLoadingMore).thenReturn(signal<bool>(false));
    when(() => presenter.isCreatingAnalysis).thenReturn(signal<bool>(false));
    when(() => presenter.generalError).thenReturn(signal<String?>(null));
    when(() => presenter.firstName).thenReturn(signal<String?>('Ada'));
    when(() => presenter.recentAnalyses).thenReturn(
      signal<List<AnalysisDto>>(<AnalysisDto>[
        AnalysisDtoFaker.fake(name: 'Analise 1'),
      ]),
    );
    when(() => presenter.nextCursor).thenReturn(signal<String?>(null));
    when(() => presenter.greeting).thenReturn(signal<String>('Bom dia, Ada'));
    when(() => presenter.hasMore).thenReturn(signal<bool>(false));
    when(() => presenter.showEmptyState).thenReturn(signal<bool>(false));
  });

  testWidgets(
    'renderiza a estrutura principal e abre o dialog de criar analise ao tocar no FAB',
    (WidgetTester tester) async {
      await tester.pumpWidget(_createWidget(presenter));
      await tester.pump();

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.text('Bom dia, Ada'), findsOneWidget);
      expect(find.text('Seu resumo juridico de hoje'), findsOneWidget);
      expect(find.text('Recentes'), findsOneWidget);
      expect(find.text('Analise 1'), findsOneWidget);
      expect(find.text('HOME'), findsNothing);
      expect(find.text('BIBLIOTECA'), findsNothing);
      expect(find.text('PERFIL'), findsNothing);

      clearInteractions(presenter);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(find.text('Nova análise'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);
      expect(find.text('Criar'), findsOneWidget);

      verifyNever(() => presenter.createAnalysis(type: any(named: 'type')));
    },
  );

  testWidgets(
    'ao confirmar o dialog, delega createAnalysis com o tipo selecionado',
    (WidgetTester tester) async {
      await tester.pumpWidget(_createWidget(presenter));
      await tester.pump();

      clearInteractions(presenter);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Criar'));
      await tester.pumpAndSettle();

      verify(
        () => presenter.createAnalysis(type: AnalysisTypeDto.firstInstance),
      ).called(1);
    },
  );

  testWidgets('ao cancelar o dialog, nao chama createAnalysis', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_createWidget(presenter));
    await tester.pump();

    clearInteractions(presenter);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    verifyNever(() => presenter.createAnalysis(type: any(named: 'type')));
  });

  testWidgets('ao tocar no card, delega abertura da analise', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_createWidget(presenter));
    await tester.pump();

    clearInteractions(presenter);

    await tester.tap(find.text('Analise 1'));
    await tester.pump();

    verify(() => presenter.openAnalysis(any())).called(1);
  });

  testWidgets('mostra erro inicial e delega retry para initialize', (
    WidgetTester tester,
  ) async {
    when(
      () => presenter.recentAnalyses,
    ).thenReturn(signal<List<AnalysisDto>>(const <AnalysisDto>[]));
    when(
      () => presenter.generalError,
    ).thenReturn(signal<String?>('Falha ao carregar home'));
    when(() => presenter.showEmptyState).thenReturn(signal<bool>(false));

    await tester.pumpWidget(_createWidget(presenter));
    await tester.pump();
    clearInteractions(presenter);

    expect(find.text('Falha ao carregar home'), findsOneWidget);
    expect(find.text('Tentar novamente'), findsOneWidget);

    await tester.tap(find.text('Tentar novamente'));
    await tester.pump();

    verify(() => presenter.initialize()).called(1);
  });
}

Widget _createWidget(_MockHomeScreenPresenter presenter) {
  return ProviderScope(
    overrides: [homeScreenPresenterProvider.overrideWithValue(presenter)],
    child: MaterialApp(theme: AppTheme.dark, home: const HomeScreenView()),
  );
}
