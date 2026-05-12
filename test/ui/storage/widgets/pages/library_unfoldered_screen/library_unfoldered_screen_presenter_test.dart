import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:animus/constants/routes.dart';
import 'package:animus/core/intake/dtos/analysis_dto.dart';
import 'package:animus/core/intake/dtos/analysis_status_dto.dart';
import 'package:animus/core/intake/dtos/analysis_type_dto.dart';
import 'package:animus/core/library/interfaces/library_service.dart';
import 'package:animus/core/shared/interfaces/navigation_driver.dart';
import 'package:animus/core/shared/responses/cursor_pagination_response.dart';
import 'package:animus/core/shared/responses/rest_response.dart';
import 'package:animus/ui/library/widgets/screens/library_unfoldered_screen/library_unfoldered_screen_presenter.dart';

class _MockLibraryService extends Mock implements LibraryService {}

class _MockNavigationDriver extends Mock implements NavigationDriver {}

void main() {
  late _MockLibraryService libraryService;
  late _MockNavigationDriver navigationDriver;

  setUp(() {
    libraryService = _MockLibraryService();
    navigationDriver = _MockNavigationDriver();

    when(() => navigationDriver.pushTo(any())).thenAnswer((_) async {});
    when(() => navigationDriver.canGoBack()).thenReturn(true);
    when(() => navigationDriver.goBack()).thenReturn(null);
    when(() => navigationDriver.goTo(any())).thenReturn(null);
  });

  AnalysisDto createAnalysis({String id = 'analysis-1', String? folderId}) {
    return AnalysisDto(
      id: id,
      name: 'Analise',
      accountId: 'account-1',
      type: AnalysisTypeDto.firstInstance,
      status: AnalysisStatusDto.waitingPetition,
      summary: '',
      createdAt: '2026-04-28T10:00:00Z',
      folderId: folderId,
    );
  }

  CursorPaginationResponse<T> createPagination<T>(
    List<T> items, {
    String? nextCursor,
  }) {
    return CursorPaginationResponse<T>(items: items, nextCursor: nextCursor);
  }

  LibraryUnfolderedScreenPresenter createPresenter() {
    return LibraryUnfolderedScreenPresenter(
      libraryService: libraryService,
      navigationDriver: navigationDriver,
    );
  }

  group('initialize', () {
    test('carrega somente analises sem pasta', () async {
      final LibraryUnfolderedScreenPresenter presenter = createPresenter();
      final AnalysisDto unfolderedAnalysis = createAnalysis(id: 'analysis-1');
      final AnalysisDto folderedAnalysis = createAnalysis(
        id: 'analysis-2',
        folderId: 'folder-1',
      );
      addTearDown(presenter.dispose);

      when(() => libraryService.listUnfolderedAnalyses(limit: 10)).thenAnswer(
        (_) async => RestResponse<CursorPaginationResponse<AnalysisDto>>(
          statusCode: 200,
          body: createPagination<AnalysisDto>(<AnalysisDto>[
            unfolderedAnalysis,
            folderedAnalysis,
          ]),
        ),
      );

      await presenter.initialize();

      expect(presenter.isLoadingInitialData.value, isFalse);
      expect(presenter.generalError.value, isNull);
      expect(presenter.analyses.value, <AnalysisDto>[unfolderedAnalysis]);
    });

    test('marca erro quando listagem falha', () async {
      final LibraryUnfolderedScreenPresenter presenter = createPresenter();
      addTearDown(presenter.dispose);

      when(() => libraryService.listUnfolderedAnalyses(limit: 10)).thenAnswer(
        (_) async => RestResponse<CursorPaginationResponse<AnalysisDto>>(
          statusCode: 500,
          errorMessage: 'falha',
        ),
      );

      await presenter.initialize();

      expect(presenter.isLoadingInitialData.value, isFalse);
      expect(presenter.generalError.value, 'falha');
      expect(presenter.analyses.value, isEmpty);
    });

    test('nao atualiza signals depois do dispose', () async {
      final LibraryUnfolderedScreenPresenter presenter = createPresenter();
      final Completer<RestResponse<CursorPaginationResponse<AnalysisDto>>>
      completer =
          Completer<RestResponse<CursorPaginationResponse<AnalysisDto>>>();

      when(
        () => libraryService.listUnfolderedAnalyses(limit: 10),
      ).thenAnswer((_) => completer.future);

      final Future<void> load = presenter.initialize();
      presenter.dispose();

      completer.complete(
        RestResponse<CursorPaginationResponse<AnalysisDto>>(
          statusCode: 200,
          body: createPagination<AnalysisDto>(<AnalysisDto>[createAnalysis()]),
        ),
      );

      await expectLater(load, completes);
    });
  });

  group('pagination', () {
    test('loadNextPage acumula analises sem pasta', () async {
      final LibraryUnfolderedScreenPresenter presenter = createPresenter();
      final AnalysisDto firstAnalysis = createAnalysis(id: 'analysis-1');
      final AnalysisDto secondAnalysis = createAnalysis(id: 'analysis-2');
      addTearDown(presenter.dispose);

      presenter.analyses.value = <AnalysisDto>[firstAnalysis];
      presenter.nextCursor.value = 'cursor-1';

      when(
        () => libraryService.listUnfolderedAnalyses(
          cursor: 'cursor-1',
          limit: 10,
        ),
      ).thenAnswer(
        (_) async => RestResponse<CursorPaginationResponse<AnalysisDto>>(
          statusCode: 200,
          body: createPagination<AnalysisDto>(<AnalysisDto>[secondAnalysis]),
        ),
      );

      await presenter.loadNextPage();

      expect(presenter.analyses.value, <AnalysisDto>[
        firstAnalysis,
        secondAnalysis,
      ]);
      expect(presenter.isLoadingMore.value, isFalse);
    });
  });

  group('selection actions', () {
    test('moveSelectedAnalyses move para pasta e remove da lista', () async {
      final LibraryUnfolderedScreenPresenter presenter = createPresenter();
      final AnalysisDto firstAnalysis = createAnalysis(id: 'analysis-1');
      final AnalysisDto secondAnalysis = createAnalysis(id: 'analysis-2');
      addTearDown(presenter.dispose);
      presenter.analyses.value = <AnalysisDto>[firstAnalysis, secondAnalysis];
      presenter.selectedAnalysisIds.value = <String>{'analysis-1'};

      when(
        () => libraryService.moveAnalysesToFolder(
          analysisIds: any(named: 'analysisIds'),
          folderId: 'folder-1',
        ),
      ).thenAnswer((_) async => RestResponse<void>(statusCode: 204));

      await presenter.moveSelectedAnalyses('folder-1');

      expect(presenter.analyses.value, <AnalysisDto>[secondAnalysis]);
      expect(presenter.selectedAnalysisIds.value, isEmpty);
    });

    test('archiveSelectedAnalyses arquiva e remove da lista', () async {
      final LibraryUnfolderedScreenPresenter presenter = createPresenter();
      final AnalysisDto firstAnalysis = createAnalysis(id: 'analysis-1');
      final AnalysisDto secondAnalysis = createAnalysis(id: 'analysis-2');
      addTearDown(presenter.dispose);
      presenter.analyses.value = <AnalysisDto>[firstAnalysis, secondAnalysis];
      presenter.selectedAnalysisIds.value = <String>{'analysis-2'};

      when(
        () => libraryService.archiveAnalyses(
          analysisIds: any(named: 'analysisIds'),
        ),
      ).thenAnswer((_) async => RestResponse<void>(statusCode: 204));

      await presenter.archiveSelectedAnalyses();

      expect(presenter.analyses.value, <AnalysisDto>[firstAnalysis]);
      expect(presenter.selectedAnalysisIds.value, isEmpty);
    });
  });

  group('navigation', () {
    test('openAnalysis navega para a analise', () async {
      final LibraryUnfolderedScreenPresenter presenter = createPresenter();
      addTearDown(presenter.dispose);

      await presenter.openAnalysis(createAnalysis(id: 'analysis/123'));

      verify(
        () => navigationDriver.pushTo(
          Routes.getAnalysis(analysisId: 'analysis/123'),
        ),
      ).called(1);
    });

    test('goBack volta quando a pilha permite', () {
      final LibraryUnfolderedScreenPresenter presenter = createPresenter();
      addTearDown(presenter.dispose);

      presenter.goBack();

      verify(() => navigationDriver.goBack()).called(1);
    });
  });
}
