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
  final Signal<List<AnalysisDto>> unfolderedAnalyses =
      signal<List<AnalysisDto>>(<AnalysisDto>[]);
  final Signal<int> unfolderedCount = signal<int>(0);
  final Signal<int> selectedTabIndex = signal<int>(0);

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
      unfolderedAnalyses.value = analysesResponse.body.items;
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

  Future<void> openAnalysis(AnalysisDto analysis) async {
    final String analysisId = (analysis.id ?? '').trim();
    if (analysisId.isEmpty) {
      return;
    }

    await _navigationDriver.pushTo(Routes.getAnalysis(analysisId: analysisId));
  }

  void selectTab(int index) {
    if (index < 0 || index > 1) {
      return;
    }
    selectedTabIndex.value = index;
  }

  String formatRelativeDate(String value) {
    final DateTime? parsedDate = DateTime.tryParse(value);
    if (parsedDate == null) {
      return '';
    }

    final Duration diff = DateTime.now().difference(parsedDate.toLocal());

    if (diff.inSeconds < 60) {
      return 'agora';
    }
    if (diff.inMinutes < 60) {
      final int minutes = diff.inMinutes;
      return 'há $minutes ${minutes == 1 ? 'minuto' : 'minutos'}';
    }
    if (diff.inHours < 24) {
      final int hours = diff.inHours;
      return 'há $hours ${hours == 1 ? 'hora' : 'horas'}';
    }
    if (diff.inDays < 7) {
      final int days = diff.inDays;
      return 'há $days ${days == 1 ? 'dia' : 'dias'}';
    }
    if (diff.inDays < 30) {
      final int weeks = (diff.inDays / 7).floor();
      return 'há $weeks ${weeks == 1 ? 'semana' : 'semanas'}';
    }
    if (diff.inDays < 365) {
      final int months = (diff.inDays / 30).floor();
      return 'há $months ${months == 1 ? 'mês' : 'meses'}';
    }
    final int years = (diff.inDays / 365).floor();
    return 'há $years ${years == 1 ? 'ano' : 'anos'}';
  }

  void dispose() {
    _isDisposed = true;
    isLoading.dispose();
    hasError.dispose();
    folders.dispose();
    unfolderedAnalyses.dispose();
    unfolderedCount.dispose();
    selectedTabIndex.dispose();
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
