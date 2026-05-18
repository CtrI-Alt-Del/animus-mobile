import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:animus/constants/routes.dart';
import 'package:animus/core/intake/dtos/analysis_dto.dart';
import 'package:animus/core/intake/dtos/analysis_status_dto.dart';
import 'package:animus/core/intake/dtos/analysis_type_dto.dart';
import 'package:animus/core/library/dtos/folder_dto.dart';
import 'package:animus/core/library/interfaces/library_service.dart';
import 'package:animus/core/shared/interfaces/navigation_driver.dart';
import 'package:animus/core/shared/responses/cursor_pagination_response.dart';
import 'package:animus/core/shared/responses/rest_response.dart';
import 'package:animus/ui/library/widgets/screens/library_folder_screen/library_folder_screen_presenter.dart';

class _MockLibraryService extends Mock implements LibraryService {}

class _MockNavigationDriver extends Mock implements NavigationDriver {}

void main() {
  late _MockLibraryService libraryService;
  late _MockNavigationDriver navigationDriver;

  setUp(() {
    libraryService = _MockLibraryService();
    navigationDriver = _MockNavigationDriver();

    when(() => navigationDriver.pushTo(any())).thenAnswer((_) async {});
    when(() => navigationDriver.goTo(any())).thenReturn(null);
    when(() => navigationDriver.goBack()).thenReturn(null);
    when(() => navigationDriver.canGoBack()).thenReturn(false);
  });

  LibraryFolderScreenPresenter createPresenter() {
    return LibraryFolderScreenPresenter(
      folderId: 'folder-1',
      libraryService: libraryService,
      navigationDriver: navigationDriver,
    );
  }

  FolderDto createFolder({String name = 'Trabalhista', int count = 2}) {
    return FolderDto(
      id: 'folder-1',
      name: name,
      analysisCount: count,
      accountId: 'account-1',
    );
  }

  AnalysisDto createAnalysis({
    required String id,
    String name = 'Analise trabalhista',
    String? folderId = 'folder-1',
  }) {
    return AnalysisDto(
      id: id,
      name: name,
      accountId: 'account-1',
      type: AnalysisTypeDto.firstInstance,
      status: AnalysisStatusDto.precedentChosen,
      summary: '',
      createdAt: '2026-05-03T10:00:00Z',
      folderId: folderId,
    );
  }

  CursorPaginationResponse<AnalysisDto> createPagination({
    required List<AnalysisDto> items,
    String? nextCursor,
  }) {
    return CursorPaginationResponse<AnalysisDto>(
      items: items,
      nextCursor: nextCursor,
    );
  }

  group('initialize/load', () {
    test('carrega metadados da pasta e primeira pagina de analises', () async {
      final LibraryFolderScreenPresenter presenter = createPresenter();
      final AnalysisDto analysis = createAnalysis(id: 'analysis-1');
      addTearDown(presenter.dispose);

      when(
        () => libraryService.getFolder(folderId: 'folder-1'),
      ).thenAnswer((_) async => RestResponse<FolderDto>(body: createFolder()));
      when(
        () =>
            libraryService.listFolderAnalyses(folderId: 'folder-1', limit: 50),
      ).thenAnswer(
        (_) async => RestResponse<CursorPaginationResponse<AnalysisDto>>(
          body: createPagination(
            items: <AnalysisDto>[analysis],
            nextCursor: 'cursor-2',
          ),
        ),
      );

      await presenter.initialize();

      expect(presenter.isLoading.value, isFalse);
      expect(presenter.generalError.value, isNull);
      expect(presenter.folder.value?.name, 'Trabalhista');
      expect(presenter.analyses.value, hasLength(1));
      expect(presenter.nextCursor.value, 'cursor-2');
      expect(presenter.hasMore.value, isTrue);
      expect(presenter.showEmptyState.value, isFalse);
    });

    test('exibe erro recuperavel quando a carga inicial falha', () async {
      final LibraryFolderScreenPresenter presenter = createPresenter();
      addTearDown(presenter.dispose);

      when(() => libraryService.getFolder(folderId: 'folder-1')).thenAnswer(
        (_) async => RestResponse<FolderDto>(
          statusCode: 404,
          errorMessage: 'folder not found',
        ),
      );
      when(
        () =>
            libraryService.listFolderAnalyses(folderId: 'folder-1', limit: 50),
      ).thenAnswer(
        (_) async => RestResponse<CursorPaginationResponse<AnalysisDto>>(
          body: createPagination(items: <AnalysisDto>[]),
        ),
      );

      await presenter.initialize();

      expect(presenter.isLoading.value, isFalse);
      expect(
        presenter.generalError.value,
        'Nao foi possivel carregar esta pasta.',
      );
      expect(presenter.folder.value, isNull);
      expect(presenter.analyses.value, isEmpty);
    });

    test(
      'carrega apenas analises sem pasta quando a pasta esta vazia',
      () async {
        final LibraryFolderScreenPresenter presenter = createPresenter();
        final AnalysisDto unfolderedAnalysis = createAnalysis(
          id: 'analysis-1',
          folderId: null,
        );
        addTearDown(presenter.dispose);

        when(() => libraryService.getFolder(folderId: 'folder-1')).thenAnswer(
          (_) async => RestResponse<FolderDto>(body: createFolder()),
        );
        when(
          () => libraryService.listFolderAnalyses(
            folderId: 'folder-1',
            limit: 50,
          ),
        ).thenAnswer(
          (_) async => RestResponse<CursorPaginationResponse<AnalysisDto>>(
            body: createPagination(items: <AnalysisDto>[]),
          ),
        );
        when(() => libraryService.listUnfolderedAnalyses(limit: 50)).thenAnswer(
          (_) async => RestResponse<CursorPaginationResponse<AnalysisDto>>(
            body: createPagination(
              items: <AnalysisDto>[
                unfolderedAnalysis,
                createAnalysis(id: 'analysis-2'),
              ],
            ),
          ),
        );

        await presenter.initialize();

        expect(presenter.availableAnalyses.value, <AnalysisDto>[
          unfolderedAnalysis,
        ]);
        expect(presenter.showAvailableAnalysisPicker.value, isTrue);
        verify(
          () => libraryService.listUnfolderedAnalyses(limit: 50),
        ).called(1);
      },
    );
  });

  group('pagination', () {
    test('adiciona proxima pagina quando ha nextCursor', () async {
      final LibraryFolderScreenPresenter presenter = createPresenter();
      addTearDown(presenter.dispose);

      when(
        () => libraryService.getFolder(folderId: 'folder-1'),
      ).thenAnswer((_) async => RestResponse<FolderDto>(body: createFolder()));
      when(
        () =>
            libraryService.listFolderAnalyses(folderId: 'folder-1', limit: 50),
      ).thenAnswer(
        (_) async => RestResponse<CursorPaginationResponse<AnalysisDto>>(
          body: createPagination(
            items: <AnalysisDto>[createAnalysis(id: 'analysis-1')],
            nextCursor: 'cursor-2',
          ),
        ),
      );
      when(
        () => libraryService.listFolderAnalyses(
          folderId: 'folder-1',
          cursor: 'cursor-2',
          limit: 50,
        ),
      ).thenAnswer(
        (_) async => RestResponse<CursorPaginationResponse<AnalysisDto>>(
          body: createPagination(
            items: <AnalysisDto>[createAnalysis(id: 'analysis-2')],
          ),
        ),
      );

      await presenter.initialize();
      await presenter.loadNextPage();

      expect(
        presenter.analyses.value.map((AnalysisDto analysis) => analysis.id),
        <String?>['analysis-1', 'analysis-2'],
      );
      expect(presenter.hasMore.value, isFalse);
    });
  });

  group('selection and batch operations', () {
    test(
      'moveSelectedAnalyses remove itens em sucesso e limpa selecao',
      () async {
        final LibraryFolderScreenPresenter presenter = createPresenter();
        addTearDown(presenter.dispose);

        presenter.folder.value = createFolder(count: 2);
        presenter.analyses.value = <AnalysisDto>[
          createAnalysis(id: 'analysis-1'),
          createAnalysis(id: 'analysis-2'),
        ];
        presenter.toggleSelection('analysis-1');

        when(
          () => libraryService.moveAnalysesToFolder(
            analysisIds: <String>['analysis-1'],
            folderId: null,
          ),
        ).thenAnswer((_) async => RestResponse<void>());

        final bool moved = await presenter.moveSelectedAnalyses(null);

        expect(moved, isTrue);
        expect(presenter.selectedAnalysisIds.value, isEmpty);
        expect(presenter.analyses.value.single.id, 'analysis-2');
        expect(presenter.folder.value?.analysisCount, 1);
      },
    );

    test('archiveSelectedAnalyses preserva selecao em erro', () async {
      final LibraryFolderScreenPresenter presenter = createPresenter();
      addTearDown(presenter.dispose);

      presenter.analyses.value = <AnalysisDto>[
        createAnalysis(id: 'analysis-1'),
      ];
      presenter.toggleSelection('analysis-1');

      when(
        () =>
            libraryService.archiveAnalyses(analysisIds: <String>['analysis-1']),
      ).thenAnswer(
        (_) async => RestResponse<void>(
          statusCode: 500,
          errorMessage: 'Falha ao arquivar',
        ),
      );

      final bool archived = await presenter.archiveSelectedAnalyses();

      expect(archived, isFalse);
      expect(presenter.selectedAnalysisIds.value, <String>{'analysis-1'});
      expect(presenter.analyses.value, hasLength(1));
      expect(presenter.generalError.value, 'Falha ao arquivar');
    });
  });

  group('folder management and navigation', () {
    test('renameFolder atualiza metadados em sucesso', () async {
      final LibraryFolderScreenPresenter presenter = createPresenter();
      addTearDown(presenter.dispose);

      presenter.folder.value = createFolder();
      when(
        () => libraryService.updateFolderName(
          folderId: 'folder-1',
          name: 'Civel',
        ),
      ).thenAnswer(
        (_) async => RestResponse<FolderDto>(body: createFolder(name: 'Civel')),
      );

      final bool renamed = await presenter.renameFolder('Civel');

      expect(renamed, isTrue);
      expect(presenter.folder.value?.name, 'Civel');
    });

    test('archiveFolder navega para biblioteca em sucesso', () async {
      final LibraryFolderScreenPresenter presenter = createPresenter();
      addTearDown(presenter.dispose);

      when(
        () => libraryService.archiveFolder(folderId: 'folder-1'),
      ).thenAnswer((_) async => RestResponse<FolderDto>(body: createFolder()));

      final bool archived = await presenter.archiveFolder();

      expect(archived, isTrue);
      verify(() => navigationDriver.goTo(Routes.library)).called(1);
    });

    test('openAnalysis ignora analise sem id e navega com id valido', () async {
      final LibraryFolderScreenPresenter presenter = createPresenter();
      addTearDown(presenter.dispose);

      await presenter.openAnalysis(createAnalysis(id: ''));
      await presenter.openAnalysis(createAnalysis(id: 'analysis-1'));

      verify(
        () => navigationDriver.pushTo(
          Routes.getAnalysis(analysisId: 'analysis-1'),
        ),
      ).called(1);
    });

    test('goBack usa fallback para biblioteca quando nao pode voltar', () {
      final LibraryFolderScreenPresenter presenter = createPresenter();
      addTearDown(presenter.dispose);

      presenter.goBack();

      verify(() => navigationDriver.goTo(Routes.library)).called(1);
    });
  });

  group('formatCreatedAt', () {
    test('formata data ISO ou retorna fallback', () {
      final LibraryFolderScreenPresenter presenter = createPresenter();
      addTearDown(presenter.dispose);

      expect(presenter.formatCreatedAt('2026-05-03T10:00:00Z'), '03/05/2026');
      expect(presenter.formatCreatedAt('invalida'), 'Data indisponivel');
    });
  });
}
