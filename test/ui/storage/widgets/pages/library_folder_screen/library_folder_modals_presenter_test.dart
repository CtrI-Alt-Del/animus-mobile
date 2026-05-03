import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:animus/core/library/dtos/folder_dto.dart';
import 'package:animus/core/library/interfaces/library_service.dart';
import 'package:animus/core/shared/responses/cursor_pagination_response.dart';
import 'package:animus/core/shared/responses/rest_response.dart';
import 'package:animus/ui/storage/widgets/pages/library_folder_screen/folder_settings_modal/folder_settings_modal_presenter.dart';
import 'package:animus/ui/storage/widgets/pages/library_folder_screen/move_analyses_modal/move_analyses_modal_presenter.dart';

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

    test('load lista destinos excluindo a pasta atual', () async {
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
          ),
        ),
      );

      await presenter.load();

      expect(presenter.isLoading.value, isFalse);
      expect(presenter.generalError.value, isNull);
      expect(presenter.folders.value, hasLength(1));
      expect(presenter.folders.value.single.id, 'folder-2');
    });

    test('selectFolder permite selecionar pasta ou Sem pasta', () {
      final MoveAnalysesModalPresenter presenter = MoveAnalysesModalPresenter(
        currentFolderId: 'folder-1',
        libraryService: libraryService,
      );
      addTearDown(presenter.dispose);

      presenter.selectFolder('folder-2');
      expect(presenter.selectedFolderId.value, 'folder-2');

      presenter.selectFolder(null);
      expect(presenter.selectedFolderId.value, isNull);
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
