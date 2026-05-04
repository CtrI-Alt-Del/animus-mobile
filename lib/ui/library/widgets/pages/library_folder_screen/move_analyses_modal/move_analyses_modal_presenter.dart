import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:animus/core/library/dtos/folder_dto.dart';
import 'package:animus/core/library/interfaces/library_service.dart';
import 'package:animus/core/shared/responses/cursor_pagination_response.dart';
import 'package:animus/core/shared/responses/rest_response.dart';
import 'package:animus/rest/services/index.dart';

class MoveAnalysesModalPresenter {
  final String currentFolderId;
  final LibraryService _libraryService;

  final Signal<bool> isLoading = signal<bool>(false);
  final Signal<String?> generalError = signal<String?>(null);
  final Signal<List<FolderDto>> folders = signal<List<FolderDto>>(
    const <FolderDto>[],
  );
  final Signal<String?> selectedFolderId = signal<String?>(null);
  final Signal<bool> hasSelectedDestination = signal<bool>(false);

  bool _didLoad = false;
  bool _isDisposed = false;

  MoveAnalysesModalPresenter({
    required this.currentFolderId,
    required LibraryService libraryService,
  }) : _libraryService = libraryService;

  Future<void> load() async {
    if (_didLoad || isLoading.value || _isDisposed) {
      return;
    }

    _didLoad = true;
    isLoading.value = true;
    generalError.value = null;

    final List<FolderDto> loadedFolders = <FolderDto>[];
    String? cursor;

    do {
      final RestResponse<CursorPaginationResponse<FolderDto>> response =
          cursor == null
          ? await _libraryService.listFolders(limit: 50)
          : await _libraryService.listFolders(cursor: cursor, limit: 50);

      if (_isDisposed) {
        return;
      }

      if (response.isFailure) {
        generalError.value =
            'Nao foi possivel carregar as pastas de destino agora.';
        isLoading.value = false;
        return;
      }

      loadedFolders.addAll(response.body.items);
      cursor = response.body.nextCursor;
    } while (cursor != null && cursor.trim().isNotEmpty);

    folders.value = List<FolderDto>.unmodifiable(
      loadedFolders.where((FolderDto folder) => folder.id != currentFolderId),
    );
    isLoading.value = false;
  }

  void selectFolder(String? folderId) {
    selectedFolderId.value = folderId;
    hasSelectedDestination.value = true;
  }

  void dispose() {
    _isDisposed = true;
    isLoading.dispose();
    generalError.dispose();
    folders.dispose();
    selectedFolderId.dispose();
    hasSelectedDestination.dispose();
  }
}

final moveAnalysesModalPresenterProvider = Provider.autoDispose
    .family<MoveAnalysesModalPresenter, String>((
      Ref ref,
      String currentFolderId,
    ) {
      final LibraryService libraryService = ref.watch(libraryServiceProvider);
      final MoveAnalysesModalPresenter presenter = MoveAnalysesModalPresenter(
        currentFolderId: currentFolderId,
        libraryService: libraryService,
      );

      ref.onDispose(presenter.dispose);
      return presenter;
    });
