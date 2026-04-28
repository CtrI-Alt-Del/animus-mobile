import 'package:animus/core/intake/dtos/analysis_dto.dart';
import 'package:animus/core/library/dtos/folder_dto.dart';
import 'package:animus/core/library/interfaces/library_service.dart';
import 'package:animus/core/shared/interfaces/navigation_driver.dart';
import 'package:animus/core/shared/responses/cursor_pagination_response.dart';
import 'package:animus/core/shared/responses/rest_response.dart';
import 'package:animus/constants/routes.dart';
import 'package:animus/drivers/navigation/index.dart';
import 'package:animus/rest/services/index.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signals_flutter/signals_flutter.dart';

class LibraryScreenPresenter {
  final LibraryService _libraryService;
  final NavigationDriver _navigationDriver;

  LibraryScreenPresenter({
    required LibraryService libraryService,
    required NavigationDriver navigationDriver,
  }) : _libraryService = libraryService,
       _navigationDriver = navigationDriver;

  final Signal<bool> isLoading = signal<bool>(true);
  final Signal<bool> hasError = signal<bool>(false);
  final Signal<List<FolderDto>> folders = signal<List<FolderDto>>([]);
  final Signal<int> unfolderedCount = signal<int>(0);

  bool _isDisposed = false;
  bool _didInitialize = false;

  Future<void> initialize() async {
    if (_didInitialize) {
      return;
    }

    _didInitialize = true;
    await load();
  }

  Future<void> load() async {
    if (_isDisposed) {
      return;
    }

    isLoading.value = true;
    hasError.value = false;

    try {
      final List<Future<RestResponse>> futures = [
        _libraryService.listFolders(limit: 50),
        _libraryService.listUnfolderedAnalyses(limit: 50),
      ];

      final List<RestResponse> responses = await Future.wait(futures);

      if (_isDisposed) {
        return;
      }

      final foldersResponse =
          responses[0] as RestResponse<CursorPaginationResponse<FolderDto>>;
      final analysesResponse =
          responses[1] as RestResponse<CursorPaginationResponse<AnalysisDto>>;

      if (foldersResponse.isFailure || analysesResponse.isFailure) {
        isLoading.value = false;
        hasError.value = true;
        return;
      }

      folders.value = foldersResponse.body.items;
      unfolderedCount.value = analysesResponse.body.items.length;
      isLoading.value = false;
    } catch (_) {
      if (_isDisposed) {
        return;
      }

      isLoading.value = false;
      hasError.value = true;
    }
  }

  Future<void> retry() async {
    await load();
  }

  Future<void> createFolder(String name) async {
    if (_isDisposed) {
      return;
    }

    hasError.value = false;
    final response = await _libraryService.createFolder(name: name);

    if (_isDisposed) {
      return;
    }

    if (response.isSuccessful) {
      folders.value = [response.body, ...folders.value];
      return;
    }

    throw Exception('Nao foi possivel criar a pasta.');
  }

  Future<void> openFolder(String folderId) async {
    await _navigationDriver.pushTo(Routes.getLibraryFolder(folderId: folderId));
  }

  Future<void> openUnfoldered() async {
    await _navigationDriver.pushTo(Routes.libraryUnfoldered);
  }

  void dispose() {
    _isDisposed = true;
    isLoading.dispose();
    hasError.dispose();
    folders.dispose();
    unfolderedCount.dispose();
  }
}

final Provider<LibraryScreenPresenter> libraryScreenPresenterProvider =
    Provider.autoDispose<LibraryScreenPresenter>((Ref ref) {
      final LibraryService libraryService = ref.watch(libraryServiceProvider);
      final NavigationDriver navigationDriver = ref.watch(
        navigationDriverProvider,
      );

      final presenter = LibraryScreenPresenter(
        libraryService: libraryService,
        navigationDriver: navigationDriver,
      );

      ref.onDispose(presenter.dispose);
      return presenter;
    });

final Provider<void> libraryScreenInitializationProvider =
    Provider.autoDispose<void>((Ref ref) {
      final LibraryScreenPresenter presenter = ref.watch(
        libraryScreenPresenterProvider,
      );
      Future<void>.microtask(presenter.initialize);
    });
