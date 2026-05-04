import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:animus/core/library/dtos/folder_dto.dart';
import 'package:animus/core/library/interfaces/library_service.dart';
import 'package:animus/core/shared/responses/cursor_pagination_response.dart';
import 'package:animus/core/shared/responses/rest_response.dart';
import 'package:animus/rest/services/index.dart';

class FolderDestinationPickerPresenter {
  static const int _foldersLimit = 50;

  final LibraryService _libraryService;
  final String currentFolderId;

  final Signal<bool> isLoading = signal<bool>(false);
  final Signal<String?> errorMessage = signal<String?>(null);
  final Signal<List<FolderDto>> folders = signal<List<FolderDto>>(
    const <FolderDto>[],
  );

  bool _didLoad = false;
  bool _isDisposed = false;

  FolderDestinationPickerPresenter({
    required LibraryService libraryService,
    required this.currentFolderId,
  }) : _libraryService = libraryService;

  Future<void> load() async {
    if (_didLoad || isLoading.value) {
      return;
    }

    _didLoad = true;
    isLoading.value = true;
    errorMessage.value = null;

    final RestResponse<CursorPaginationResponse<FolderDto>> response =
        await _libraryService.listFolders(limit: _foldersLimit);

    if (_isDisposed) {
      return;
    }

    if (response.isFailure) {
      errorMessage.value = _resolveErrorMessage(
        response,
        fallback: 'Nao foi possivel carregar as pastas.',
      );
      isLoading.value = false;
      return;
    }

    final String normalizedCurrentFolderId = currentFolderId.trim();
    folders.value = List<FolderDto>.unmodifiable(
      response.body.items.where((FolderDto folder) {
        final String id = (folder.id ?? '').trim();
        return id.isNotEmpty && id != normalizedCurrentFolderId;
      }),
    );
    isLoading.value = false;
  }

  Future<void> retry() async {
    _didLoad = false;
    await load();
  }

  void dispose() {
    _isDisposed = true;
    isLoading.dispose();
    errorMessage.dispose();
    folders.dispose();
  }

  String _resolveErrorMessage(
    RestResponse<dynamic> response, {
    required String fallback,
  }) {
    final dynamic bodyMessageDynamic = response.errorBody?['message'];
    final String? bodyMessage = bodyMessageDynamic is String
        ? bodyMessageDynamic
        : null;
    if (bodyMessage != null && bodyMessage.trim().isNotEmpty) {
      return bodyMessage;
    }

    try {
      final String message = response.errorMessage;
      if (message.trim().isNotEmpty && !_isTechnicalTransportMessage(message)) {
        return message;
      }
    } catch (_) {}

    return fallback;
  }

  bool _isTechnicalTransportMessage(String message) {
    return message.contains('RequestOptions.validateStatus') ||
        message.contains('This exception was thrown because the response') ||
        message.contains('developer.mozilla.org/en-US/docs/Web/HTTP/Status') ||
        message.contains('status code of ${HttpStatus.notFound}');
  }
}

final folderDestinationPickerPresenterProvider = Provider.autoDispose
    .family<FolderDestinationPickerPresenter, String>((
      Ref ref,
      String currentFolderId,
    ) {
      final LibraryService libraryService = ref.watch(libraryServiceProvider);
      final FolderDestinationPickerPresenter presenter =
          FolderDestinationPickerPresenter(
            libraryService: libraryService,
            currentFolderId: currentFolderId,
          );

      ref.onDispose(presenter.dispose);
      return presenter;
    });
