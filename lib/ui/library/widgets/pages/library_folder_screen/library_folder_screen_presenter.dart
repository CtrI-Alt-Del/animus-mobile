import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:animus/constants/routes.dart';
import 'package:animus/core/intake/dtos/analysis_dto.dart';
import 'package:animus/core/library/dtos/folder_dto.dart';
import 'package:animus/core/library/interfaces/library_service.dart';
import 'package:animus/core/shared/interfaces/navigation_driver.dart';
import 'package:animus/core/shared/responses/cursor_pagination_response.dart';
import 'package:animus/core/shared/responses/rest_response.dart';
import 'package:animus/drivers/navigation/index.dart';
import 'package:animus/rest/services/index.dart';

class LibraryFolderScreenPresenter {
  static const int _pageSize = 50;
  static const int _availableAnalysesLimit = 50;

  final String folderId;
  final LibraryService _libraryService;
  final NavigationDriver _navigationDriver;

  final Signal<bool> isLoading = signal<bool>(false);
  final Signal<bool> isLoadingMore = signal<bool>(false);
  final Signal<bool> isLoadingAvailableAnalyses = signal<bool>(false);
  final Signal<bool> isAddingAvailableAnalyses = signal<bool>(false);
  final Signal<bool> isOperating = signal<bool>(false);
  final Signal<String?> generalError = signal<String?>(null);
  final Signal<FolderDto?> folder = signal<FolderDto?>(null);
  final Signal<List<AnalysisDto>> analyses = signal<List<AnalysisDto>>(
    const <AnalysisDto>[],
  );
  final Signal<List<AnalysisDto>> availableAnalyses = signal<List<AnalysisDto>>(
    const <AnalysisDto>[],
  );
  final Signal<Set<String>> selectedAnalysisIds = signal<Set<String>>(
    <String>{},
  );
  final Signal<Set<String>> selectedAvailableAnalysisIds = signal<Set<String>>(
    <String>{},
  );
  final Signal<String?> nextCursor = signal<String?>(null);

  bool _didInitialize = false;
  bool _isDisposed = false;

  late final ReadonlySignal<bool> hasSelection = computed(() {
    return selectedAnalysisIds.value.isNotEmpty;
  });

  late final ReadonlySignal<int> selectedCount = computed(() {
    return selectedAnalysisIds.value.length;
  });

  late final ReadonlySignal<bool> hasMore = computed(() {
    final String? cursor = nextCursor.value;
    return cursor != null && cursor.trim().isNotEmpty;
  });

  late final ReadonlySignal<bool> showAvailableAnalysisPicker = computed(() {
    return !isLoading.value &&
        generalError.value == null &&
        analyses.value.isEmpty &&
        (isLoadingAvailableAnalyses.value ||
            availableAnalyses.value.isNotEmpty);
  });

  late final ReadonlySignal<bool> showEmptyState = computed(() {
    return !isLoading.value &&
        generalError.value == null &&
        analyses.value.isEmpty &&
        availableAnalyses.value.isEmpty &&
        !isLoadingAvailableAnalyses.value;
  });

  LibraryFolderScreenPresenter({
    required this.folderId,
    required LibraryService libraryService,
    required NavigationDriver navigationDriver,
  }) : _libraryService = libraryService,
       _navigationDriver = navigationDriver;

  Future<void> initialize() async {
    if (_didInitialize) {
      return;
    }

    _didInitialize = true;
    await load();
  }

  Future<void> load() async {
    if (_isDisposed || isLoading.value) {
      return;
    }

    isLoading.value = true;
    generalError.value = null;

    final List<Future<RestResponse<dynamic>>> futures =
        <Future<RestResponse<dynamic>>>[
          _libraryService.getFolder(folderId: folderId),
          _libraryService.listFolderAnalyses(
            folderId: folderId,
            limit: _pageSize,
          ),
        ];

    try {
      final List<RestResponse<dynamic>> responses = await Future.wait(futures);
      if (_isDisposed) {
        return;
      }

      final RestResponse<FolderDto> folderResponse =
          responses[0] as RestResponse<FolderDto>;
      final RestResponse<CursorPaginationResponse<AnalysisDto>>
      analysesResponse =
          responses[1] as RestResponse<CursorPaginationResponse<AnalysisDto>>;

      if (folderResponse.isFailure || analysesResponse.isFailure) {
        generalError.value = _resolveLoadErrorMessage(
          folderResponse.isFailure ? folderResponse : analysesResponse,
        );
        isLoading.value = false;
        return;
      }

      folder.value = folderResponse.body;
      analyses.value = List<AnalysisDto>.unmodifiable(
        analysesResponse.body.items,
      );
      nextCursor.value = analysesResponse.body.nextCursor;
      selectedAnalysisIds.value = <String>{};
      selectedAvailableAnalysisIds.value = <String>{};
      availableAnalyses.value = const <AnalysisDto>[];
      generalError.value = null;
      isLoading.value = false;

      if (analysesResponse.body.items.isEmpty) {
        await loadAvailableAnalysesForEmptyFolder();
      }
    } catch (_) {
      if (_isDisposed) {
        return;
      }

      generalError.value =
          'Nao foi possivel carregar esta pasta agora. Tente novamente.';
      isLoading.value = false;
    }
  }

  Future<void> refresh() async {
    if (_isDisposed || isLoading.value || isLoadingMore.value) {
      return;
    }

    selectedAnalysisIds.value = <String>{};
    selectedAvailableAnalysisIds.value = <String>{};
    analyses.value = const <AnalysisDto>[];
    availableAnalyses.value = const <AnalysisDto>[];
    nextCursor.value = null;
    await load();
  }

  Future<void> loadNextPage() async {
    if (_isDisposed ||
        isLoading.value ||
        isLoadingMore.value ||
        !hasMore.value) {
      return;
    }

    final String cursor = (nextCursor.value ?? '').trim();
    if (cursor.isEmpty) {
      return;
    }

    isLoadingMore.value = true;
    generalError.value = null;

    final RestResponse<CursorPaginationResponse<AnalysisDto>> response =
        await _libraryService.listFolderAnalyses(
          folderId: folderId,
          cursor: cursor,
          limit: _pageSize,
        );

    if (_isDisposed) {
      return;
    }

    if (response.isFailure) {
      generalError.value = _resolveErrorMessage(
        response,
        fallback:
            'Nao foi possivel carregar mais analises agora. Role novamente para tentar de novo.',
      );
      isLoadingMore.value = false;
      return;
    }

    final CursorPaginationResponse<AnalysisDto> pagination = response.body;
    analyses.value = List<AnalysisDto>.unmodifiable(<AnalysisDto>[
      ...analyses.value,
      ...pagination.items,
    ]);
    nextCursor.value = pagination.nextCursor;
    generalError.value = null;
    isLoadingMore.value = false;
  }

  Future<void> loadAvailableAnalysesForEmptyFolder() async {
    if (_isDisposed || isLoadingAvailableAnalyses.value) {
      return;
    }

    isLoadingAvailableAnalyses.value = true;
    generalError.value = null;

    final RestResponse<CursorPaginationResponse<AnalysisDto>> response =
        await _libraryService.listUnfolderedAnalyses(
          limit: _availableAnalysesLimit,
        );

    if (_isDisposed) {
      return;
    }

    if (response.isFailure) {
      generalError.value = _resolveErrorMessage(
        response,
        fallback: 'Nao foi possivel carregar analises disponiveis agora.',
      );
      isLoadingAvailableAnalyses.value = false;
      return;
    }

    final Set<String> currentAnalysisIds = analyses.value
        .map((AnalysisDto analysis) => (analysis.id ?? '').trim())
        .where((String id) => id.isNotEmpty)
        .toSet();

    availableAnalyses.value = List<AnalysisDto>.unmodifiable(
      response.body.items.where((AnalysisDto analysis) {
        final String analysisId = (analysis.id ?? '').trim();
        if (analysisId.isEmpty || currentAnalysisIds.contains(analysisId)) {
          return false;
        }

        return analysis.folderId == null || analysis.folderId!.trim().isEmpty;
      }),
    );
    isLoadingAvailableAnalyses.value = false;
  }

  void toggleAvailableAnalysisSelection(String analysisId) {
    final String normalizedAnalysisId = analysisId.trim();
    if (normalizedAnalysisId.isEmpty) {
      return;
    }

    final Set<String> nextSelection = Set<String>.from(
      selectedAvailableAnalysisIds.value,
    );
    if (nextSelection.contains(normalizedAnalysisId)) {
      nextSelection.remove(normalizedAnalysisId);
    } else {
      nextSelection.add(normalizedAnalysisId);
    }

    selectedAvailableAnalysisIds.value = Set<String>.unmodifiable(
      nextSelection,
    );
  }

  void clearAvailableAnalysisSelection() {
    selectedAvailableAnalysisIds.value = <String>{};
  }

  Future<void> addSelectedAvailableAnalyses() async {
    if (_isDisposed || isAddingAvailableAnalyses.value) {
      return;
    }

    final List<String> analysisIds = selectedAvailableAnalysisIds.value.toList(
      growable: false,
    );
    if (analysisIds.isEmpty) {
      return;
    }

    isAddingAvailableAnalyses.value = true;
    generalError.value = null;

    final RestResponse<void> response = await _libraryService
        .moveAnalysesToFolder(analysisIds: analysisIds, folderId: folderId);

    if (_isDisposed) {
      return;
    }

    if (response.isFailure) {
      generalError.value = _resolveErrorMessage(
        response,
        fallback: 'Nao foi possivel adicionar as analises nesta pasta.',
      );
      isAddingAvailableAnalyses.value = false;
      return;
    }

    final Set<String> selectedIds = analysisIds.toSet();
    final List<AnalysisDto> selectedAnalyses = availableAnalyses.value
        .where(
          (AnalysisDto analysis) =>
              selectedIds.contains((analysis.id ?? '').trim()),
        )
        .toList(growable: false);

    analyses.value = List<AnalysisDto>.unmodifiable(<AnalysisDto>[
      ...analyses.value,
      ...selectedAnalyses,
    ]);
    _updateFolderAnalysisCount(analyses.value.length);

    availableAnalyses.value = List<AnalysisDto>.unmodifiable(
      availableAnalyses.value.where(
        (AnalysisDto analysis) =>
            !selectedIds.contains((analysis.id ?? '').trim()),
      ),
    );
    selectedAvailableAnalysisIds.value = <String>{};
    isAddingAvailableAnalyses.value = false;
  }

  Future<void> openAnalysis(AnalysisDto analysis) async {
    final String analysisId = (analysis.id ?? '').trim();
    if (analysisId.isEmpty) {
      return;
    }

    await _navigationDriver.pushTo(Routes.getAnalysis(analysisId: analysisId));
  }

  void toggleSelection(String analysisId) {
    final String normalizedAnalysisId = analysisId.trim();
    if (normalizedAnalysisId.isEmpty) {
      return;
    }

    final Set<String> nextSelection = Set<String>.from(
      selectedAnalysisIds.value,
    );
    if (nextSelection.contains(normalizedAnalysisId)) {
      nextSelection.remove(normalizedAnalysisId);
    } else {
      nextSelection.add(normalizedAnalysisId);
    }

    selectedAnalysisIds.value = nextSelection;
  }

  void clearSelection() {
    selectedAnalysisIds.value = <String>{};
  }

  Future<bool> moveSelectedAnalyses(String? destinationFolderId) async {
    if (isOperating.value) {
      return false;
    }

    final List<String> analysisIds = selectedAnalysisIds.value.toList(
      growable: false,
    );
    if (analysisIds.isEmpty) {
      return false;
    }

    isOperating.value = true;
    generalError.value = null;

    final RestResponse<void> response = await _libraryService
        .moveAnalysesToFolder(
          analysisIds: analysisIds,
          folderId: _normalizeDestinationFolderId(destinationFolderId),
        );

    if (_isDisposed) {
      return false;
    }

    if (response.isFailure) {
      generalError.value = _resolveErrorMessage(
        response,
        fallback:
            'Nao foi possivel mover as analises selecionadas agora. Tente novamente.',
      );
      isOperating.value = false;
      return false;
    }

    _removeAnalysesFromCurrentList(analysisIds);
    clearSelection();
    generalError.value = null;
    isOperating.value = false;
    await _loadAvailableWhenCurrentListIsEmpty();
    return true;
  }

  Future<bool> archiveSelectedAnalyses() async {
    if (isOperating.value) {
      return false;
    }

    final List<String> analysisIds = selectedAnalysisIds.value.toList(
      growable: false,
    );
    if (analysisIds.isEmpty) {
      return false;
    }

    isOperating.value = true;
    generalError.value = null;

    final RestResponse<void> response = await _libraryService.archiveAnalyses(
      analysisIds: analysisIds,
    );

    if (_isDisposed) {
      return false;
    }

    if (response.isFailure) {
      generalError.value = _resolveErrorMessage(
        response,
        fallback:
            'Nao foi possivel arquivar as analises selecionadas agora. Tente novamente.',
      );
      isOperating.value = false;
      return false;
    }

    _removeAnalysesFromCurrentList(analysisIds);
    clearSelection();
    generalError.value = null;
    isOperating.value = false;
    await _loadAvailableWhenCurrentListIsEmpty();
    return true;
  }

  Future<bool> renameFolder(String name) async {
    final FolderDto? currentFolder = folder.value;
    if (currentFolder == null || isOperating.value) {
      return false;
    }

    final String normalizedName = name.trim();
    if (normalizedName.isEmpty || normalizedName.length > 50) {
      generalError.value = 'Informe um nome de pasta valido.';
      return false;
    }

    if (normalizedName == currentFolder.name.trim()) {
      generalError.value = null;
      return true;
    }

    isOperating.value = true;
    generalError.value = null;

    final RestResponse<FolderDto> response = await _libraryService
        .updateFolderName(folderId: folderId, name: normalizedName);

    if (_isDisposed) {
      return false;
    }

    if (response.isFailure) {
      generalError.value = _resolveErrorMessage(
        response,
        fallback: 'Nao foi possivel atualizar o nome da pasta agora.',
      );
      isOperating.value = false;
      return false;
    }

    folder.value = response.body;
    generalError.value = null;
    isOperating.value = false;
    return true;
  }

  Future<bool> archiveFolder() async {
    if (isOperating.value) {
      return false;
    }

    isOperating.value = true;
    generalError.value = null;

    final RestResponse<FolderDto> response = await _libraryService
        .archiveFolder(folderId: folderId);

    if (_isDisposed) {
      return false;
    }

    if (response.isFailure) {
      generalError.value = _resolveErrorMessage(
        response,
        fallback: 'Nao foi possivel arquivar esta pasta agora.',
      );
      isOperating.value = false;
      return false;
    }

    isOperating.value = false;
    _navigationDriver.goTo(Routes.library);
    return true;
  }

  void goBack() {
    if (_navigationDriver.canGoBack()) {
      _navigationDriver.goBack();
      return;
    }

    _navigationDriver.goTo(Routes.library);
  }

  String formatCreatedAt(String value) {
    final DateTime? parsedDate = DateTime.tryParse(value);
    if (parsedDate == null) {
      return 'Data indisponivel';
    }

    final String day = parsedDate.day.toString().padLeft(2, '0');
    final String month = parsedDate.month.toString().padLeft(2, '0');
    final String year = parsedDate.year.toString();
    return '$day/$month/$year';
  }

  void dispose() {
    _isDisposed = true;
    isLoading.dispose();
    isLoadingMore.dispose();
    isLoadingAvailableAnalyses.dispose();
    isAddingAvailableAnalyses.dispose();
    isOperating.dispose();
    generalError.dispose();
    folder.dispose();
    analyses.dispose();
    availableAnalyses.dispose();
    selectedAnalysisIds.dispose();
    selectedAvailableAnalysisIds.dispose();
    nextCursor.dispose();
    hasSelection.dispose();
    selectedCount.dispose();
    hasMore.dispose();
    showAvailableAnalysisPicker.dispose();
    showEmptyState.dispose();
  }

  void _removeAnalysesFromCurrentList(List<String> analysisIds) {
    final Set<String> idsToRemove = analysisIds.toSet();
    final List<AnalysisDto> remainingAnalyses = analyses.value
        .where((AnalysisDto analysis) => !idsToRemove.contains(analysis.id))
        .toList(growable: false);

    analyses.value = List<AnalysisDto>.unmodifiable(remainingAnalyses);

    final FolderDto? currentFolder = folder.value;
    if (currentFolder == null) {
      return;
    }

    final int updatedCount = currentFolder.analysisCount - analysisIds.length;
    folder.value = FolderDto(
      id: currentFolder.id,
      name: currentFolder.name,
      analysisCount: updatedCount < 0 ? 0 : updatedCount,
      accountId: currentFolder.accountId,
      isArchived: currentFolder.isArchived,
    );
  }

  void _updateFolderAnalysisCount(int analysisCount) {
    final FolderDto? currentFolder = folder.value;
    if (currentFolder == null) {
      return;
    }

    folder.value = FolderDto(
      id: currentFolder.id,
      name: currentFolder.name,
      analysisCount: analysisCount < 0 ? 0 : analysisCount,
      accountId: currentFolder.accountId,
      isArchived: currentFolder.isArchived,
    );
  }

  Future<void> _loadAvailableWhenCurrentListIsEmpty() async {
    if (analyses.value.isNotEmpty ||
        hasMore.value ||
        isLoadingAvailableAnalyses.value) {
      return;
    }

    availableAnalyses.value = const <AnalysisDto>[];
    selectedAvailableAnalysisIds.value = <String>{};
    await loadAvailableAnalysesForEmptyFolder();
  }

  String? _normalizeDestinationFolderId(String? destinationFolderId) {
    final String? normalizedFolderId = destinationFolderId?.trim();
    if (normalizedFolderId == null || normalizedFolderId.isEmpty) {
      return null;
    }

    return normalizedFolderId;
  }

  String _resolveLoadErrorMessage(RestResponse<dynamic> response) {
    if (response.statusCode == HttpStatus.notFound ||
        response.statusCode == HttpStatus.forbidden) {
      return 'Nao foi possivel carregar esta pasta.';
    }

    return _resolveErrorMessage(
      response,
      fallback: 'Nao foi possivel carregar esta pasta agora. Tente novamente.',
    );
  }

  String _resolveErrorMessage(
    RestResponse<dynamic> response, {
    required String fallback,
  }) {
    if (response.statusCode == HttpStatus.notFound ||
        response.statusCode == HttpStatus.forbidden) {
      return fallback;
    }

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

final libraryFolderScreenPresenterProvider = Provider.autoDispose
    .family<LibraryFolderScreenPresenter, String>((Ref ref, String folderId) {
      final LibraryService libraryService = ref.watch(libraryServiceProvider);
      final NavigationDriver navigationDriver = ref.watch(
        navigationDriverProvider,
      );

      final LibraryFolderScreenPresenter presenter =
          LibraryFolderScreenPresenter(
            folderId: folderId,
            libraryService: libraryService,
            navigationDriver: navigationDriver,
          );

      ref.onDispose(presenter.dispose);
      return presenter;
    });

final libraryFolderScreenInitializationProvider = Provider.autoDispose
    .family<void, String>((Ref ref, String folderId) {
      final LibraryFolderScreenPresenter presenter = ref.watch(
        libraryFolderScreenPresenterProvider(folderId),
      );
      Future<void>.microtask(presenter.initialize);
    });
