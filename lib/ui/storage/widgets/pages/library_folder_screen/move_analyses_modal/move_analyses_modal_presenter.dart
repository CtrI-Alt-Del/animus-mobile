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

    final RestResponse<CursorPaginationResponse<FolderDto>> response =
        await _libraryService.listFolders(limit: 50);

    if (_isDisposed) {
      return;
    }

    if (response.isFailure) {
      generalError.value =
          'Nao foi possivel carregar as pastas de destino agora.';
      isLoading.value = false;
      return;
    }

    folders.value = List<FolderDto>.unmodifiable(
      response.body.items
          .where((FolderDto folder) => folder.id != currentFolderId)
          .toList(growable: false),
    );
    isLoading.value = false;
  }

  void selectFolder(String? folderId) {
    selectedFolderId.value = folderId;
  }

  void dispose() {
    _isDisposed = true;
    isLoading.dispose();
    generalError.dispose();
    folders.dispose();
    selectedFolderId.dispose();
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
