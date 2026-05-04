import 'dart:async';

import 'package:animus/core/intake/dtos/analysis_dto.dart';
import 'package:animus/core/intake/dtos/analysis_status_dto.dart';
import 'package:animus/core/library/dtos/folder_dto.dart';
import 'package:animus/core/library/interfaces/library_service.dart';
import 'package:animus/core/shared/interfaces/navigation_driver.dart';
import 'package:animus/core/shared/responses/cursor_pagination_response.dart';
import 'package:animus/core/shared/responses/rest_response.dart';
import 'package:animus/constants/routes.dart';
import 'package:animus/ui/library/widgets/pages/library_screen/library_screen_presenter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockLibraryService extends Mock implements LibraryService {}

class _MockNavigationDriver extends Mock implements NavigationDriver {}

void main() {
  late _MockLibraryService libraryService;
  late _MockNavigationDriver navigationDriver;

  setUp(() {
    libraryService = _MockLibraryService();
    navigationDriver = _MockNavigationDriver();

    when(() => navigationDriver.pushTo(any())).thenAnswer((_) async {});
  });

  FolderDto createFolder({
    String? id = 'folder-1',
    String name = 'Contratos',
    int analysisCount = 0,
  }) {
    return FolderDto(
      id: id,
      name: name,
      analysisCount: analysisCount,
      accountId: 'account-1',
    );
  }

  AnalysisDto createAnalysis({String id = 'analysis-1'}) {
    return AnalysisDto(
      id: id,
      name: 'Analise',
      accountId: 'account-1',
      status: AnalysisStatusDto.waitingPetition,
      summary: '',
      createdAt: '2026-04-28T10:00:00Z',
    );
  }

  CursorPaginationResponse<T> createPagination<T>(List<T> items) {
    return CursorPaginationResponse<T>(items: items);
  }

  LibraryScreenPresenter createPresenter() {
    return LibraryScreenPresenter(
      libraryService: libraryService,
      navigationDriver: navigationDriver,
    );
  }

  void stubLibraryLoad({
    List<FolderDto> folders = const <FolderDto>[],
    List<AnalysisDto> unfolderedAnalyses = const <AnalysisDto>[],
  }) {
    when(() => libraryService.listFolders(limit: 50)).thenAnswer(
      (_) async => RestResponse<CursorPaginationResponse<FolderDto>>(
        statusCode: 200,
        body: createPagination<FolderDto>(folders),
      ),
    );
    when(() => libraryService.listUnfolderedAnalyses(limit: 50)).thenAnswer(
      (_) async => RestResponse<CursorPaginationResponse<AnalysisDto>>(
        statusCode: 200,
        body: createPagination<AnalysisDto>(unfolderedAnalyses),
      ),
    );
  }

  group('initialize', () {
    test('carrega pastas e quantidade de analises sem pasta', () async {
      final LibraryScreenPresenter presenter = createPresenter();
      final FolderDto folder = createFolder();
      addTearDown(presenter.dispose);

      when(() => libraryService.listFolders(limit: 50)).thenAnswer(
        (_) async => RestResponse<CursorPaginationResponse<FolderDto>>(
          statusCode: 200,
          body: createPagination(<FolderDto>[folder]),
        ),
      );
      when(() => libraryService.listUnfolderedAnalyses(limit: 50)).thenAnswer(
        (_) async => RestResponse<CursorPaginationResponse<AnalysisDto>>(
          statusCode: 200,
          body: createPagination(<AnalysisDto>[
            createAnalysis(id: 'analysis-1'),
            createAnalysis(id: 'analysis-2'),
          ]),
        ),
      );

      await presenter.initialize();

      expect(presenter.isLoading.value, isFalse);
      expect(presenter.hasError.value, isFalse);
      expect(presenter.folders.value, <FolderDto>[folder]);
      expect(presenter.unfolderedCount.value, 2);
    });

    test('marca erro quando uma das requisicoes falha', () async {
      final LibraryScreenPresenter presenter = createPresenter();
      addTearDown(presenter.dispose);

      when(() => libraryService.listFolders(limit: 50)).thenAnswer(
        (_) async => RestResponse<CursorPaginationResponse<FolderDto>>(
          statusCode: 500,
          errorMessage: 'falha',
        ),
      );
      when(() => libraryService.listUnfolderedAnalyses(limit: 50)).thenAnswer(
        (_) async => RestResponse<CursorPaginationResponse<AnalysisDto>>(
          statusCode: 200,
          body: createPagination(<AnalysisDto>[]),
        ),
      );

      await presenter.initialize();

      expect(presenter.isLoading.value, isFalse);
      expect(presenter.hasError.value, isTrue);
      expect(presenter.folders.value, isEmpty);
    });

    test('nao atualiza signals depois do dispose', () async {
      final LibraryScreenPresenter presenter = createPresenter();
      final foldersCompleter =
          Completer<RestResponse<CursorPaginationResponse<FolderDto>>>();
      final analysesCompleter =
          Completer<RestResponse<CursorPaginationResponse<AnalysisDto>>>();

      when(
        () => libraryService.listFolders(limit: 50),
      ).thenAnswer((_) => foldersCompleter.future);
      when(
        () => libraryService.listUnfolderedAnalyses(limit: 50),
      ).thenAnswer((_) => analysesCompleter.future);

      final Future<void> load = presenter.initialize();
      presenter.dispose();

      foldersCompleter.complete(
        RestResponse<CursorPaginationResponse<FolderDto>>(
          statusCode: 200,
          body: createPagination(<FolderDto>[createFolder()]),
        ),
      );
      analysesCompleter.complete(
        RestResponse<CursorPaginationResponse<AnalysisDto>>(
          statusCode: 200,
          body: createPagination(<AnalysisDto>[]),
        ),
      );

      await expectLater(load, completes);
    });
  });

  group('createFolder', () {
    test('adiciona a pasta no inicio quando cria com sucesso', () async {
      final LibraryScreenPresenter presenter = createPresenter();
      final FolderDto existingFolder = createFolder(
        id: 'folder-1',
        name: 'Existente',
      );
      final FolderDto createdFolder = createFolder(
        id: 'folder-2',
        name: 'Nova',
      );
      addTearDown(presenter.dispose);
      presenter.folders.value = <FolderDto>[existingFolder];

      when(() => libraryService.createFolder(name: 'Nova')).thenAnswer(
        (_) async =>
            RestResponse<FolderDto>(statusCode: 201, body: createdFolder),
      );

      await presenter.createFolder('Nova');

      expect(
        presenter.folders.value.map((FolderDto folder) => folder.id),
        <String?>['folder-2', 'folder-1'],
      );
    });

    test('lanca excecao e preserva lista quando criacao falha', () async {
      final LibraryScreenPresenter presenter = createPresenter();
      final FolderDto existingFolder = createFolder();
      addTearDown(presenter.dispose);
      presenter.folders.value = <FolderDto>[existingFolder];

      when(() => libraryService.createFolder(name: 'Nova')).thenAnswer(
        (_) async =>
            RestResponse<FolderDto>(statusCode: 500, errorMessage: 'falha'),
      );

      await expectLater(presenter.createFolder('Nova'), throwsException);
      expect(presenter.folders.value, <FolderDto>[existingFolder]);
    });
  });

  group('unfoldered selection actions', () {
    test(
      'openAnalysis alterna selecao quando ja existe selecao ativa',
      () async {
        final LibraryScreenPresenter presenter = createPresenter();
        addTearDown(presenter.dispose);
        presenter.selectedUnfolderedAnalysisIds.value = <String>{'analysis-1'};

        await presenter.openAnalysis(createAnalysis(id: 'analysis-2'));

        expect(presenter.selectedUnfolderedAnalysisIds.value, <String>{
          'analysis-1',
          'analysis-2',
        });
        verifyNever(() => navigationDriver.pushTo(any()));
      },
    );

    test(
      'moveSelectedUnfolderedAnalyses move para pasta e atualiza listas',
      () async {
        final LibraryScreenPresenter presenter = createPresenter();
        final AnalysisDto selectedAnalysis = createAnalysis(id: 'analysis-1');
        final AnalysisDto remainingAnalysis = createAnalysis(id: 'analysis-2');
        final FolderDto destinationFolder = createFolder(
          id: 'folder-1',
          analysisCount: 2,
        );
        addTearDown(presenter.dispose);
        presenter.unfolderedAnalyses.value = <AnalysisDto>[
          selectedAnalysis,
          remainingAnalysis,
        ];
        presenter.unfolderedCount.value = 2;
        presenter.folders.value = <FolderDto>[destinationFolder];
        presenter.selectedUnfolderedAnalysisIds.value = <String>{'analysis-1'};

        when(
          () => libraryService.moveAnalysesToFolder(
            analysisIds: <String>['analysis-1'],
            folderId: 'folder-1',
          ),
        ).thenAnswer((_) async => RestResponse<void>(statusCode: 204));

        final bool moved = await presenter.moveSelectedUnfolderedAnalyses(
          'folder-1',
        );

        expect(moved, isTrue);
        expect(presenter.unfolderedAnalyses.value, <AnalysisDto>[
          remainingAnalysis,
        ]);
        expect(presenter.unfolderedCount.value, 1);
        expect(presenter.folders.value.single.analysisCount, 3);
        expect(presenter.selectedUnfolderedAnalysisIds.value, isEmpty);
      },
    );

    test('moveSelectedUnfolderedAnalyses preserva selecao em falha', () async {
      final LibraryScreenPresenter presenter = createPresenter();
      final AnalysisDto selectedAnalysis = createAnalysis(id: 'analysis-1');
      addTearDown(presenter.dispose);
      presenter.unfolderedAnalyses.value = <AnalysisDto>[selectedAnalysis];
      presenter.selectedUnfolderedAnalysisIds.value = <String>{'analysis-1'};

      when(
        () => libraryService.moveAnalysesToFolder(
          analysisIds: <String>['analysis-1'],
          folderId: 'folder-1',
        ),
      ).thenAnswer(
        (_) async =>
            RestResponse<void>(statusCode: 500, errorMessage: 'Falha remota'),
      );

      final bool moved = await presenter.moveSelectedUnfolderedAnalyses(
        'folder-1',
      );

      expect(moved, isFalse);
      expect(presenter.unfolderedAnalyses.value, <AnalysisDto>[
        selectedAnalysis,
      ]);
      expect(presenter.selectedUnfolderedAnalysisIds.value, <String>{
        'analysis-1',
      });
      expect(presenter.operationError.value, 'Falha remota');
    });

    test(
      'archiveSelectedUnfolderedAnalyses arquiva e remove da lista',
      () async {
        final LibraryScreenPresenter presenter = createPresenter();
        final AnalysisDto selectedAnalysis = createAnalysis(id: 'analysis-1');
        final AnalysisDto remainingAnalysis = createAnalysis(id: 'analysis-2');
        addTearDown(presenter.dispose);
        presenter.unfolderedAnalyses.value = <AnalysisDto>[
          selectedAnalysis,
          remainingAnalysis,
        ];
        presenter.unfolderedCount.value = 2;
        presenter.selectedUnfolderedAnalysisIds.value = <String>{'analysis-1'};

        when(
          () => libraryService.archiveAnalyses(
            analysisIds: <String>['analysis-1'],
          ),
        ).thenAnswer((_) async => RestResponse<void>(statusCode: 204));

        final bool archived = await presenter
            .archiveSelectedUnfolderedAnalyses();

        expect(archived, isTrue);
        expect(presenter.unfolderedAnalyses.value, <AnalysisDto>[
          remainingAnalysis,
        ]);
        expect(presenter.unfolderedCount.value, 1);
        expect(presenter.selectedUnfolderedAnalysisIds.value, isEmpty);
      },
    );
  });

  group('navigation', () {
    test(
      'openFolder empurra a rota correta da pasta e recarrega ao voltar',
      () async {
        final LibraryScreenPresenter presenter = createPresenter();
        final FolderDto refreshedFolder = createFolder(analysisCount: 3);
        addTearDown(presenter.dispose);
        stubLibraryLoad(folders: <FolderDto>[refreshedFolder]);

        await presenter.openFolder('folder/123');

        verify(
          () => navigationDriver.pushTo(
            Routes.getLibraryFolder(folderId: 'folder/123'),
          ),
        ).called(1);
        verify(() => libraryService.listFolders(limit: 50)).called(1);
        verify(
          () => libraryService.listUnfolderedAnalyses(limit: 50),
        ).called(1);
        expect(presenter.folders.value, <FolderDto>[refreshedFolder]);
      },
    );

    test(
      'openUnfoldered empurra a rota de sem pasta e recarrega ao voltar',
      () async {
        final LibraryScreenPresenter presenter = createPresenter();
        final AnalysisDto refreshedAnalysis = createAnalysis();
        addTearDown(presenter.dispose);
        stubLibraryLoad(unfolderedAnalyses: <AnalysisDto>[refreshedAnalysis]);

        await presenter.openUnfoldered();

        verify(
          () => navigationDriver.pushTo(Routes.libraryUnfoldered),
        ).called(1);
        verify(() => libraryService.listFolders(limit: 50)).called(1);
        verify(
          () => libraryService.listUnfolderedAnalyses(limit: 50),
        ).called(1);
        expect(presenter.unfolderedCount.value, 1);
      },
    );
  });
}
