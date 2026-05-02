import 'dart:async';

import 'package:animus/core/intake/dtos/analysis_dto.dart';
import 'package:animus/core/intake/dtos/analysis_status_dto.dart';
import 'package:animus/core/library/dtos/folder_dto.dart';
import 'package:animus/core/library/interfaces/library_service.dart';
import 'package:animus/core/shared/interfaces/navigation_driver.dart';
import 'package:animus/core/shared/responses/cursor_pagination_response.dart';
import 'package:animus/core/shared/responses/rest_response.dart';
import 'package:animus/constants/routes.dart';
import 'package:animus/ui/storage/widgets/pages/library_screen/library_screen_presenter.dart';
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

  FolderDto createFolder({String? id = 'folder-1', String name = 'Contratos'}) {
    return FolderDto(
      id: id,
      name: name,
      analysisCount: 0,
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

  group('navigation', () {
    test('openFolder empurra a rota correta da pasta', () async {
      final LibraryScreenPresenter presenter = createPresenter();
      addTearDown(presenter.dispose);

      await presenter.openFolder('folder/123');

      verify(
        () => navigationDriver.pushTo(
          Routes.getLibraryFolder(folderId: 'folder/123'),
        ),
      ).called(1);
    });

    test('openUnfoldered empurra a rota de sem pasta', () async {
      final LibraryScreenPresenter presenter = createPresenter();
      addTearDown(presenter.dispose);

      await presenter.openUnfoldered();

      verify(() => navigationDriver.pushTo(Routes.libraryUnfoldered)).called(1);
    });
  });
}
