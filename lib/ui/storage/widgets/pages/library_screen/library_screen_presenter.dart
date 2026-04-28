import 'package:animus/core/intake/dtos/analysis_dto.dart';
import 'package:animus/core/library/dtos/folder_dto.dart';
import 'package:animus/core/library/interfaces/library_service.dart';
import 'package:animus/core/shared/interfaces/navigation_driver.dart';
import 'package:animus/core/shared/responses/cursor_pagination_response.dart';
import 'package:animus/core/shared/responses/rest_response.dart';
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
       _navigationDriver = navigationDriver {
    load();
  }

  final Signal<bool> isLoading = signal<bool>(true);
  final Signal<bool> hasError = signal<bool>(false);
  final Signal<List<FolderDto>> folders = signal<List<FolderDto>>([]);
  final Signal<int> unfolderedCount = signal<int>(0);

  Future<void> load() async {
    isLoading.value = true;
    hasError.value = false;

    final List<Future<RestResponse>> futures = [
      _libraryService.listFolders(limit: 50),
      _libraryService.listUnfolderedAnalyses(limit: 50),
    ];

    final List<RestResponse> responses = await Future.wait(futures);

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
  }

  Future<void> retry() async {
    await load();
  }

  Future<void> createFolder(String name) async {
    final response = await _libraryService.createFolder(name: name);

    if (response.isSuccessful) {
      folders.value = [response.body, ...folders.value];
    } else {
      // In a real scenario we could throw an exception or handle it
    }
  }

  void openFolder(String folderId) {
    _navigationDriver.goTo('/library/folder/$folderId');
  }

  void openUnfoldered() {
    _navigationDriver.goTo('/library/unfoldered');
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

      ref.onDispose(() {
        presenter.isLoading.dispose();
        presenter.hasError.dispose();
        presenter.folders.dispose();
        presenter.unfolderedCount.dispose();
      });

      return presenter;
    });
