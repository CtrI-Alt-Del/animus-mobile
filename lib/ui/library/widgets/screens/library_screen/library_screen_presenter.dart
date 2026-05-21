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
  final Signal<bool> isOperatingOnUnfolderedAnalyses = signal<bool>(false);
  final Signal<String?> operationError = signal<String?>(null);
  final Signal<List<FolderDto>> folders = signal<List<FolderDto>>([]);
  final Signal<List<AnalysisDto>> unfolderedAnalyses =
      signal<List<AnalysisDto>>(<AnalysisDto>[]);
  final Signal<int> unfolderedCount = signal<int>(0);
  final Signal<int> selectedTabIndex = signal<int>(0);
  final Signal<Set<String>> selectedUnfolderedAnalysisIds = signal<Set<String>>(
    const <String>{},
  );

  late final ReadonlySignal<bool> hasUnfolderedSelection = computed(() {
    return selectedUnfolderedAnalysisIds.value.isNotEmpty;
  });

  late final ReadonlySignal<int> selectedUnfolderedCount = computed(() {
    return selectedUnfolderedAnalysisIds.value.length;
  });

  bool _isDisposed = false;
  bool _didInitialize = false;

  Future<void> initialize() async {
    if (_didInitialize) {
      return;
    }

    _didInitialize = true;
    await load();
  }

  Future<void> load({bool showLoading = true}) async {
    if (_isDisposed) {
      return;
    }

    if (showLoading) {
      isLoading.value = true;
    }
    hasError.value = false;
    operationError.value = null;

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
      selectedUnfolderedAnalysisIds.value = const <String>{};
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

    throw Exception('Não foi possivel criar a pasta.');
  }

  Future<void> openFolder(String folderId) async {
    await _navigationDriver.pushTo(Routes.getLibraryFolder(folderId: folderId));
    await _refreshAfterChildRoute();
  }

  Future<void> openUnfoldered() async {
    await _navigationDriver.pushTo(Routes.libraryUnfoldered);
    await _refreshAfterChildRoute();
  }

  Future<void> openAnalysis(AnalysisDto analysis) async {
    final String analysisId = (analysis.id ?? '').trim();
    if (analysisId.isEmpty) {
      return;
    }

    if (hasUnfolderedSelection.value) {
      toggleUnfolderedSelection(analysisId);
      return;
    }

    await _navigationDriver.pushTo(
      Routes.getAnalysis(analysisId: analysisId, analysisType: analysis.type),
    );
  }

  void toggleUnfolderedSelection(String analysisId) {
    final String normalizedAnalysisId = analysisId.trim();
    if (normalizedAnalysisId.isEmpty) {
      return;
    }

    final Set<String> nextSelection = Set<String>.from(
      selectedUnfolderedAnalysisIds.value,
    );
    if (nextSelection.contains(normalizedAnalysisId)) {
      nextSelection.remove(normalizedAnalysisId);
    } else {
      nextSelection.add(normalizedAnalysisId);
    }

    selectedUnfolderedAnalysisIds.value = Set<String>.unmodifiable(
      nextSelection,
    );
  }

  void clearUnfolderedSelection() {
    selectedUnfolderedAnalysisIds.value = const <String>{};
  }

  Future<bool> moveSelectedUnfolderedAnalyses(
    String? destinationFolderId,
  ) async {
    if (isOperatingOnUnfolderedAnalyses.value) {
      return false;
    }

    final String normalizedDestinationFolderId = (destinationFolderId ?? '')
        .trim();
    final List<String> analysisIds = selectedUnfolderedAnalysisIds.value.toList(
      growable: false,
    );
    if (analysisIds.isEmpty || normalizedDestinationFolderId.isEmpty) {
      return false;
    }

    isOperatingOnUnfolderedAnalyses.value = true;
    operationError.value = null;

    final RestResponse<void> response = await _libraryService
        .moveAnalysesToFolder(
          analysisIds: analysisIds,
          folderId: normalizedDestinationFolderId,
        );

    if (_isDisposed) {
      return false;
    }

    if (response.isFailure) {
      operationError.value = _resolveOperationErrorMessage(
        response,
        fallback:
            'Não foi possivel mover as analises selecionadas agora. Tente novamente.',
      );
      isOperatingOnUnfolderedAnalyses.value = false;
      return false;
    }

    _removeUnfolderedAnalyses(analysisIds);
    _incrementFolderAnalysisCount(
      normalizedDestinationFolderId,
      analysisIds.length,
    );
    selectedUnfolderedAnalysisIds.value = const <String>{};
    operationError.value = null;
    isOperatingOnUnfolderedAnalyses.value = false;
    return true;
  }

  Future<bool> archiveSelectedUnfolderedAnalyses() async {
    if (isOperatingOnUnfolderedAnalyses.value) {
      return false;
    }

    final List<String> analysisIds = selectedUnfolderedAnalysisIds.value.toList(
      growable: false,
    );
    if (analysisIds.isEmpty) {
      return false;
    }

    isOperatingOnUnfolderedAnalyses.value = true;
    operationError.value = null;

    final RestResponse<void> response = await _libraryService.archiveAnalyses(
      analysisIds: analysisIds,
    );

    if (_isDisposed) {
      return false;
    }

    if (response.isFailure) {
      operationError.value = _resolveOperationErrorMessage(
        response,
        fallback:
            'Não foi possivel arquivar as analises selecionadas agora. Tente novamente.',
      );
      isOperatingOnUnfolderedAnalyses.value = false;
      return false;
    }

    _removeUnfolderedAnalyses(analysisIds);
    selectedUnfolderedAnalysisIds.value = const <String>{};
    operationError.value = null;
    isOperatingOnUnfolderedAnalyses.value = false;
    return true;
  }

  void selectTab(int index) {
    if (index < 0 || index > 1) {
      return;
    }
    selectedTabIndex.value = index;
    if (index != 0) {
      clearUnfolderedSelection();
    }
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
    isOperatingOnUnfolderedAnalyses.dispose();
    operationError.dispose();
    folders.dispose();
    unfolderedAnalyses.dispose();
    unfolderedCount.dispose();
    selectedTabIndex.dispose();
    selectedUnfolderedAnalysisIds.dispose();
    hasUnfolderedSelection.dispose();
    selectedUnfolderedCount.dispose();
  }

  void _removeUnfolderedAnalyses(List<String> analysisIds) {
    final Set<String> idsToRemove = analysisIds.toSet();
    unfolderedAnalyses.value = List<AnalysisDto>.unmodifiable(
      unfolderedAnalyses.value.where(
        (AnalysisDto analysis) =>
            !idsToRemove.contains((analysis.id ?? '').trim()),
      ),
    );
    unfolderedCount.value = unfolderedAnalyses.value.length;
  }

  void _incrementFolderAnalysisCount(String folderId, int increment) {
    folders.value = List<FolderDto>.unmodifiable(
      folders.value.map((FolderDto folder) {
        if (folder.id != folderId) {
          return folder;
        }

        return FolderDto(
          id: folder.id,
          name: folder.name,
          analysisCount: folder.analysisCount + increment,
          accountId: folder.accountId,
          isArchived: folder.isArchived,
        );
      }),
    );
  }

  String _resolveOperationErrorMessage(
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
      if (message.trim().isNotEmpty &&
          !message.contains('RequestOptions.validateStatus') &&
          !message.contains('developer.mozilla.org/en-US/docs/Web/HTTP')) {
        return message;
      }
    } catch (_) {}

    return fallback;
  }

  Future<void> _refreshAfterChildRoute() async {
    if (_isDisposed) {
      return;
    }

    final bool hasRenderedData =
        folders.value.isNotEmpty || unfolderedCount.value > 0;
    await load(showLoading: !hasRenderedData);
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
