import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:animus/core/library/dtos/folder_dto.dart';
import 'package:animus/core/library/interfaces/library_service.dart';
import 'package:animus/core/shared/responses/cursor_pagination_response.dart';
import 'package:animus/core/shared/responses/rest_response.dart';
import 'package:animus/rest/services/index.dart';
import 'package:animus/ui/library/widgets/screens/library_folder_screen/archive_selected_analyses_dialog/archive_selected_analyses_dialog_view.dart';
import 'package:animus/ui/library/widgets/screens/library_folder_screen/folder_settings_modal/folder_settings_modal_presenter.dart';
import 'package:animus/ui/library/widgets/screens/library_folder_screen/move_analyses_modal/move_analyses_modal_presenter.dart';
import 'package:animus/ui/library/widgets/screens/library_folder_screen/move_analyses_modal/move_analyses_modal_view.dart';

class _MockLibraryService extends Mock implements LibraryService {}

void main() {
  FolderDto createFolder(String id, String name) {
    return FolderDto(
      id: id,
      name: name,
      analysisCount: 2,
      accountId: 'account-1',
    );
  }

  group('MoveAnalysesModalPresenter', () {
    late _MockLibraryService libraryService;

    setUp(() {
      libraryService = _MockLibraryService();
    });

    test('load pagina destinos excluindo a pasta atual', () async {
      final MoveAnalysesModalPresenter presenter = MoveAnalysesModalPresenter(
        currentFolderId: 'folder-1',
        libraryService: libraryService,
      );
      addTearDown(presenter.dispose);

      when(() => libraryService.listFolders(limit: 50)).thenAnswer(
        (_) async => RestResponse<CursorPaginationResponse<FolderDto>>(
          body: CursorPaginationResponse<FolderDto>(
            items: <FolderDto>[
              createFolder('folder-1', 'Atual'),
              createFolder('folder-2', 'Destino'),
            ],
            nextCursor: 'cursor-2',
          ),
        ),
      );
      when(
        () => libraryService.listFolders(cursor: 'cursor-2', limit: 50),
      ).thenAnswer(
        (_) async => RestResponse<CursorPaginationResponse<FolderDto>>(
          body: CursorPaginationResponse<FolderDto>(
            items: <FolderDto>[createFolder('folder-3', 'Destino 2')],
          ),
        ),
      );

      await presenter.load();

      expect(presenter.isLoading.value, isFalse);
      expect(presenter.generalError.value, isNull);
      expect(
        presenter.folders.value.map((FolderDto folder) => folder.id),
        <String>['folder-2', 'folder-3'],
      );
    });

    test('selectFolder marca selecao explicita de pasta ou Sem pasta', () {
      final MoveAnalysesModalPresenter presenter = MoveAnalysesModalPresenter(
        currentFolderId: 'folder-1',
        libraryService: libraryService,
      );
      addTearDown(presenter.dispose);

      expect(presenter.hasSelectedDestination.value, isFalse);

      presenter.selectFolder('folder-2');
      expect(presenter.selectedFolderId.value, 'folder-2');
      expect(presenter.hasSelectedDestination.value, isTrue);

      presenter.selectFolder(null);
      expect(presenter.selectedFolderId.value, isNull);
      expect(presenter.hasSelectedDestination.value, isTrue);
    });

    test('load mantem erro quando destinos falham', () async {
      final MoveAnalysesModalPresenter presenter = MoveAnalysesModalPresenter(
        currentFolderId: 'folder-1',
        libraryService: libraryService,
      );
      addTearDown(presenter.dispose);

      when(() => libraryService.listFolders(limit: 50)).thenAnswer(
        (_) async => RestResponse<CursorPaginationResponse<FolderDto>>(
          statusCode: 500,
          errorMessage: 'Erro remoto',
        ),
      );

      await presenter.load();

      expect(presenter.isLoading.value, isFalse);
      expect(presenter.generalError.value, isNotNull);
      expect(presenter.folders.value, isEmpty);
      expect(presenter.hasSelectedDestination.value, isFalse);
    });
  });

  group('MoveAnalysesModalView', () {
    late _MockLibraryService libraryService;

    setUp(() {
      libraryService = _MockLibraryService();
    });

    Future<void> pumpModal(
      WidgetTester tester, {
      required Future<bool> Function(String? folderId) onMove,
      bool showUnfolderedDestination = true,
    }) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [libraryServiceProvider.overrideWithValue(libraryService)],
          child: MaterialApp(
            home: Scaffold(
              body: MoveAnalysesModalView(
                currentFolderId: 'folder-1',
                selectedCount: 1,
                showUnfolderedDestination: showUnfolderedDestination,
                onMove: onMove,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
    }

    testWidgets('mantem mover desabilitado ate destino explicito', (
      WidgetTester tester,
    ) async {
      String? movedFolderId;

      when(() => libraryService.listFolders(limit: 50)).thenAnswer(
        (_) async => RestResponse<CursorPaginationResponse<FolderDto>>(
          body: CursorPaginationResponse<FolderDto>(
            items: <FolderDto>[createFolder('folder-2', 'Destino')],
          ),
        ),
      );

      await pumpModal(
        tester,
        onMove: (String? folderId) async {
          movedFolderId = folderId;
          return true;
        },
      );

      FilledButton moveButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Mover'),
      );
      expect(moveButton.onPressed, isNull);

      await tester.tap(find.text('Sem pasta'));
      await tester.pump();

      moveButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Mover'),
      );
      expect(moveButton.onPressed, isNotNull);

      await tester.tap(find.widgetWithText(FilledButton, 'Mover'));
      await tester.pump();

      expect(movedFolderId, isNull);
    });

    testWidgets('oculta Sem pasta quando origem ja e Sem pasta', (
      WidgetTester tester,
    ) async {
      String? movedFolderId;

      when(() => libraryService.listFolders(limit: 50)).thenAnswer(
        (_) async => RestResponse<CursorPaginationResponse<FolderDto>>(
          body: CursorPaginationResponse<FolderDto>(
            items: <FolderDto>[createFolder('folder-2', 'Destino')],
          ),
        ),
      );

      await pumpModal(
        tester,
        showUnfolderedDestination: false,
        onMove: (String? folderId) async {
          movedFolderId = folderId;
          return true;
        },
      );

      expect(find.text('Sem pasta'), findsNothing);

      await tester.tap(find.text('Destino'));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Mover'));
      await tester.pump();

      expect(movedFolderId, 'folder-2');
    });

    testWidgets('bloqueia mover quando carregar destinos falha', (
      WidgetTester tester,
    ) async {
      when(() => libraryService.listFolders(limit: 50)).thenAnswer(
        (_) async => RestResponse<CursorPaginationResponse<FolderDto>>(
          statusCode: 500,
          errorMessage: 'Erro remoto',
        ),
      );

      await pumpModal(tester, onMove: (_) async => true);

      expect(
        find.text('Não foi possível carregar as pastas de destino agora.'),
        findsOneWidget,
      );
      expect(find.text('Sem pasta'), findsNothing);

      final FilledButton moveButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Mover'),
      );
      expect(moveButton.onPressed, isNull);
    });

    testWidgets('destino customizado expoe semantica de selecao', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantics = tester.ensureSemantics();

      when(() => libraryService.listFolders(limit: 50)).thenAnswer(
        (_) async => RestResponse<CursorPaginationResponse<FolderDto>>(
          body: CursorPaginationResponse<FolderDto>(
            items: <FolderDto>[createFolder('folder-2', 'Destino')],
          ),
        ),
      );

      await pumpModal(tester, onMove: (_) async => true);
      await tester.tap(find.text('Destino'));
      await tester.pump();

      expect(
        tester.getSemantics(find.bySemanticsLabel('Destino, 2 análises')),
        matchesSemantics(
          label: 'Destino, 2 análises',
          value: 'Selecionado',
          hint: 'Toque para selecionar este destino',
          isButton: true,
          isSelected: true,
          hasSelectedState: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      semantics.dispose();
    });
  });

  group('ArchiveSelectedAnalysesDialogView', () {
    Future<void> pumpDialog(WidgetTester tester, int selectedCount) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ArchiveSelectedAnalysesDialogView(
              selectedCount: selectedCount,
            ),
          ),
        ),
      );
    }

    testWidgets('usa copy singular para uma analise selecionada', (
      WidgetTester tester,
    ) async {
      await pumpDialog(tester, 1);

      expect(
        find.text(
          '1 análise será arquivada. Ela não será excluída permanentemente.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('usa copy plural para multiplas analises selecionadas', (
      WidgetTester tester,
    ) async {
      await pumpDialog(tester, 2);

      expect(
        find.text(
          '2 análises serão arquivadas. Elas não serão excluídas permanentemente.',
        ),
        findsOneWidget,
      );
    });
  });

  group('FolderSettingsModalPresenter', () {
    test('submitRename valida nome vazio antes de chamar callback', () async {
      bool wasCalled = false;
      final FolderSettingsModalPresenter presenter =
          FolderSettingsModalPresenter(
            initialName: 'Trabalhista',
            onRename: (_) async {
              wasCalled = true;
              return true;
            },
            onArchiveFolder: () async => true,
          );
      addTearDown(presenter.dispose);

      presenter.setName('   ');
      final bool renamed = await presenter.submitRename();

      expect(renamed, isFalse);
      expect(wasCalled, isFalse);
      expect(presenter.nameError.value, isNotNull);
    });

    test('submitRename retorna sucesso quando callback conclui', () async {
      String? submittedName;
      final FolderSettingsModalPresenter presenter =
          FolderSettingsModalPresenter(
            initialName: 'Trabalhista',
            onRename: (String name) async {
              submittedName = name;
              return true;
            },
            onArchiveFolder: () async => true,
          );
      addTearDown(presenter.dispose);

      presenter.setName(' Civel ');
      final bool renamed = await presenter.submitRename();

      expect(renamed, isTrue);
      expect(submittedName, 'Civel');
      expect(presenter.generalError.value, isNull);
    });

    test(
      'submitArchiveFolder mantem erro recuperavel quando callback falha',
      () async {
        final FolderSettingsModalPresenter presenter =
            FolderSettingsModalPresenter(
              initialName: 'Trabalhista',
              onRename: (_) async => true,
              onArchiveFolder: () async => false,
            );
        addTearDown(presenter.dispose);

        final bool archived = await presenter.submitArchiveFolder();

        expect(archived, isFalse);
        expect(presenter.isArchivingFolder.value, isFalse);
        expect(presenter.generalError.value, isNotNull);
      },
    );
  });
}
