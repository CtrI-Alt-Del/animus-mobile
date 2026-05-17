import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:animus/constants/routes.dart';
import 'package:animus/core/intake/dtos/analysis_dto.dart';
import 'package:animus/core/intake/interfaces/intake_service.dart';
import 'package:animus/core/library/dtos/folder_dto.dart';
import 'package:animus/core/library/interfaces/library_service.dart';
import 'package:animus/core/shared/interfaces/navigation_driver.dart';
import 'package:animus/core/shared/responses/cursor_pagination_response.dart';
import 'package:animus/core/shared/responses/rest_response.dart';
import 'package:animus/drivers/navigation/index.dart';
import 'package:animus/rest/services/index.dart';

class LibraryFolderScreenPresenter {
  static const int _pageSize = 10;
  static const int _availableAnalysesLimit = 50;

  final LibraryService _libraryService;
  final IntakeService _intakeService;
  final NavigationDriver _navigationDriver;
  final String folderId;

  final Signal<bool> isLoadingInitialData = signal<bool>(false);
  final Signal<bool> isLoadingMore = signal<bool>(false);
  final Signal<bool> isLoadingAvailableAnalyses = signal<bool>(false);
  final Signal<bool> isAddingAvailableAnalyses = signal<bool>(false);
  final Signal<bool> isMovingAnalyses = signal<bool>(false);
  final Signal<bool> isArchivingAnalyses = signal<bool>(false);
  final Signal<bool> isManagingFolder = signal<bool>(false);
  final Signal<String?> generalError = signal<String?>(null);
  final Signal<FolderDto?> folder = signal<FolderDto?>(null);
  final Signal<List<AnalysisDto>> analyses = signal<List<AnalysisDto>>(
    const <AnalysisDto>[],
  );
  final Signal<List<AnalysisDto>> availableAnalyses = signal<List<AnalysisDto>>(
    const <AnalysisDto>[],
  );
  final Signal<Set<String>> selectedAnalysisIds = signal<Set<String>>(
    const <String>{},
  );
  final Signal<Set<String>> selectedAvailableAnalysisIds = signal<Set<String>>(
    const <String>{},
  );
  final Signal<String?> nextCursor = signal<String?>(null);

  late final ReadonlySignal<bool> hasMore = computed(() {
    final String? cursor = nextCursor.value;
    return cursor != null && cursor.trim().isNotEmpty;
  });

  late final ReadonlySignal<bool> hasSelection = computed(() {
    return selectedAnalysisIds.value.isNotEmpty;
  });

  late final ReadonlySignal<int> selectedCount = computed(() {
    return selectedAnalysisIds.value.length;
  });

  late final ReadonlySignal<bool> showAvailableAnalysisPicker = computed(() {
    return !isLoadingInitialData.value &&
        generalError.value == null &&
        analyses.value.isEmpty &&
        (isLoadingAvailableAnalyses.value ||
            availableAnalyses.value.isNotEmpty);
  });

  late final ReadonlySignal<bool> showEmptyState = computed(() {
    return !isLoadingInitialData.value &&
        generalError.value == null &&
        analyses.value.isEmpty &&
        availableAnalyses.value.isEmpty &&
        !isLoadingAvailableAnalyses.value;
  });

  bool _didInitialize = false;
  bool _isDisposed = false;

  LibraryFolderScreenPresenter({
    required LibraryService libraryService,
    required IntakeService intakeService,
    required NavigationDriver navigationDriver,
    required this.folderId,
  }) : _libraryService = libraryService,
       _intakeService = intakeService,
       _navigationDriver = navigationDriver;

  Future<void> initialize() async {
    if (_didInitialize || isLoadingInitialData.value) {
      return;
    }

    _didInitialize = true;
    await load();
  }

  Future<void> load() async {
    if (_isDisposed || isLoadingInitialData.value) {
      return;
    }

    final String normalizedFolderId = folderId.trim();
    if (normalizedFolderId.isEmpty) {
      generalError.value = 'Pasta invalida.';
      return;
    }

    isLoadingInitialData.value = true;
    generalError.value = null;
    selectedAnalysisIds.value = const <String>{};
    selectedAvailableAnalysisIds.value = const <String>{};

    try {
      final List<RestResponse<dynamic>> responses =
          await Future.wait<RestResponse<dynamic>>(
            <Future<RestResponse<dynamic>>>[
              _libraryService.getFolder(folderId: normalizedFolderId),
              _libraryService.listFolderAnalyses(
                folderId: normalizedFolderId,
                limit: _pageSize,
              ),
            ],
          );

      if (_isDisposed) {
        return;
      }

      final RestResponse<FolderDto> folderResponse =
          responses[0] as RestResponse<FolderDto>;
      final RestResponse<CursorPaginationResponse<AnalysisDto>>
      analysesResponse =
          responses[1] as RestResponse<CursorPaginationResponse<AnalysisDto>>;

      if (folderResponse.isFailure) {
        generalError.value = _resolveErrorMessage(
          folderResponse,
          fallback: 'Nao foi possivel carregar esta pasta agora.',
        );
        isLoadingInitialData.value = false;
        return;
      }

      if (analysesResponse.isFailure) {
        generalError.value = _resolveErrorMessage(
          analysesResponse,
          fallback: 'Nao foi possivel carregar as analises da pasta.',
        );
        isLoadingInitialData.value = false;
        return;
      }

      final CursorPaginationResponse<AnalysisDto> pagination =
          analysesResponse.body;
      folder.value = folderResponse.body;
      analyses.value = List<AnalysisDto>.unmodifiable(pagination.items);
      nextCursor.value = pagination.nextCursor;
      availableAnalyses.value = const <AnalysisDto>[];
      generalError.value = null;
      isLoadingInitialData.value = false;

      if (pagination.items.isEmpty) {
        await loadAvailableAnalysesForEmptyFolder();
      }
    } catch (_) {
      if (_isDisposed) {
        return;
      }

      generalError.value = 'Nao foi possivel carregar esta pasta agora.';
      isLoadingInitialData.value = false;
    }
  }

  Future<void> refresh() async {
    if (isLoadingInitialData.value || isLoadingMore.value) {
      return;
    }

    analyses.value = const <AnalysisDto>[];
    availableAnalyses.value = const <AnalysisDto>[];
    nextCursor.value = null;
    selectedAnalysisIds.value = const <String>{};
    selectedAvailableAnalysisIds.value = const <String>{};
    await load();
  }

  Future<void> loadNextPage() async {
    if (isLoadingInitialData.value || isLoadingMore.value || !hasMore.value) {
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
            'Nao foi possivel carregar mais analises. Role novamente para tentar de novo.',
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
    isLoadingMore.value = false;
  }

  Future<void> loadAvailableAnalysesForEmptyFolder() async {
    if (isLoadingAvailableAnalyses.value) {
      return;
    }

    isLoadingAvailableAnalyses.value = true;
    generalError.value = null;

    final RestResponse<CursorPaginationResponse<AnalysisDto>> response =
        await _intakeService.listAnalyses(
          limit: _availableAnalysesLimit,
          isArchived: false,
        );

    if (_isDisposed) {
      return;
    }

    if (response.isFailure) {
      generalError.value = _resolveErrorMessage(
        response,
        fallback: 'Nao foi possivel carregar analises disponiveis.',
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

        return analysis.folderId != folderId;
      }),
    );
    isLoadingAvailableAnalyses.value = false;
  }

  void toggleAvailableAnalysisSelection(String analysisId) {
    final String normalizedAnalysisId = analysisId.trim();
    if (normalizedAnalysisId.isEmpty) {
      return;
    }

    final Set<String> next = <String>{...selectedAvailableAnalysisIds.value};
    if (!next.add(normalizedAnalysisId)) {
      next.remove(normalizedAnalysisId);
    }

    selectedAvailableAnalysisIds.value = Set<String>.unmodifiable(next);
  }

  void clearAvailableAnalysisSelection() {
    selectedAvailableAnalysisIds.value = const <String>{};
  }

  Future<void> addSelectedAvailableAnalyses() async {
    final List<String> ids = selectedAvailableAnalysisIds.value.toList(
      growable: false,
    );
    if (ids.isEmpty || isAddingAvailableAnalyses.value) {
      return;
    }

    isAddingAvailableAnalyses.value = true;
    generalError.value = null;

    final RestResponse<void> response = await _libraryService
        .moveAnalysesToFolder(analysisIds: ids, folderId: folderId);

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

    final Set<String> selectedIds = ids.toSet();
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
    selectedAvailableAnalysisIds.value = const <String>{};
    isAddingAvailableAnalyses.value = false;
  }

  Future<void> openAnalysis(AnalysisDto analysis) async {
    final String analysisId = (analysis.id ?? '').trim();
    if (analysisId.isEmpty) {
      return;
    }

    if (hasSelection.value) {
      toggleSelection(analysisId);
      return;
    }

    await _navigationDriver.pushTo(
      Routes.getAnalysis(analysisId: analysisId, analysisType: analysis.type),
    );
  }

  void toggleSelection(String analysisId) {
    final String normalizedAnalysisId = analysisId.trim();
    if (normalizedAnalysisId.isEmpty) {
      return;
    }

    final Set<String> next = <String>{...selectedAnalysisIds.value};
    if (!next.add(normalizedAnalysisId)) {
      next.remove(normalizedAnalysisId);
    }

    selectedAnalysisIds.value = Set<String>.unmodifiable(next);
  }

  void clearSelection() {
    selectedAnalysisIds.value = const <String>{};
  }

  Future<void> moveSelectedAnalyses(String? destinationFolderId) async {
    final List<String> ids = selectedAnalysisIds.value.toList(growable: false);
    if (ids.isEmpty || isMovingAnalyses.value) {
      return;
    }

    isMovingAnalyses.value = true;
    generalError.value = null;

    final String? normalizedDestinationId = destinationFolderId?.trim();
    final RestResponse<void> response = await _libraryService
        .moveAnalysesToFolder(
          analysisIds: ids,
          folderId:
              normalizedDestinationId == null || normalizedDestinationId.isEmpty
              ? null
              : normalizedDestinationId,
        );

    if (_isDisposed) {
      return;
    }

    if (response.isFailure) {
      generalError.value = _resolveErrorMessage(
        response,
        fallback: 'Nao foi possivel mover as analises selecionadas.',
      );
      isMovingAnalyses.value = false;
      return;
    }

    _removeAnalyses(ids);
    selectedAnalysisIds.value = const <String>{};
    isMovingAnalyses.value = false;
    await _loadAvailableWhenCurrentListIsEmpty();
  }

  Future<void> archiveSelectedAnalyses() async {
    final List<String> ids = selectedAnalysisIds.value.toList(growable: false);
    if (ids.isEmpty || isArchivingAnalyses.value) {
      return;
    }

    isArchivingAnalyses.value = true;
    generalError.value = null;

    final RestResponse<void> response = await _libraryService.archiveAnalyses(
      analysisIds: ids,
    );

    if (_isDisposed) {
      return;
    }

    if (response.isFailure) {
      generalError.value = _resolveErrorMessage(
        response,
        fallback: 'Nao foi possivel arquivar as analises selecionadas.',
      );
      isArchivingAnalyses.value = false;
      return;
    }

    _removeAnalyses(ids);
    selectedAnalysisIds.value = const <String>{};
    isArchivingAnalyses.value = false;
    await _loadAvailableWhenCurrentListIsEmpty();
  }

  Future<bool> renameFolder(String name) async {
    final String normalizedName = name.trim();
    final String normalizedFolderId = folderId.trim();
    if (normalizedName.isEmpty ||
        normalizedName.length > 50 ||
        normalizedFolderId.isEmpty ||
        isManagingFolder.value) {
      return false;
    }

    isManagingFolder.value = true;

    final RestResponse<FolderDto> response = await _libraryService
        .updateFolderName(folderId: normalizedFolderId, name: normalizedName);

    if (_isDisposed) {
      return false;
    }

    isManagingFolder.value = false;

    if (response.isFailure) {
      return false;
    }

    folder.value = response.body;
    return true;
  }

  Future<bool> archiveFolder() async {
    final String normalizedFolderId = folderId.trim();
    if (normalizedFolderId.isEmpty || isManagingFolder.value) {
      return false;
    }

    isManagingFolder.value = true;

    final RestResponse<FolderDto> response = await _libraryService
        .archiveFolder(folderId: normalizedFolderId);

    if (_isDisposed) {
      return false;
    }

    isManagingFolder.value = false;

    if (response.isFailure) {
      return false;
    }

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
    isLoadingInitialData.dispose();
    isLoadingMore.dispose();
    isLoadingAvailableAnalyses.dispose();
    isAddingAvailableAnalyses.dispose();
    isMovingAnalyses.dispose();
    isArchivingAnalyses.dispose();
    isManagingFolder.dispose();
    generalError.dispose();
    folder.dispose();
    analyses.dispose();
    availableAnalyses.dispose();
    selectedAnalysisIds.dispose();
    selectedAvailableAnalysisIds.dispose();
    nextCursor.dispose();
    hasMore.dispose();
    hasSelection.dispose();
    selectedCount.dispose();
    showAvailableAnalysisPicker.dispose();
    showEmptyState.dispose();
  }

  void _removeAnalyses(List<String> ids) {
    final Set<String> selectedIds = ids.toSet();
    analyses.value = List<AnalysisDto>.unmodifiable(
      analyses.value.where(
        (AnalysisDto analysis) =>
            !selectedIds.contains((analysis.id ?? '').trim()),
      ),
    );
    _updateFolderAnalysisCount(analyses.value.length);
  }

  void _updateFolderAnalysisCount(int analysisCount) {
    final FolderDto? currentFolder = folder.value;
    if (currentFolder == null) {
      return;
    }

    folder.value = FolderDto(
      id: currentFolder.id,
      name: currentFolder.name,
      analysisCount: analysisCount,
      accountId: currentFolder.accountId,
      isArchived: currentFolder.isArchived,
    );
  }

  Future<void> _loadAvailableWhenCurrentListIsEmpty() async {
    if (analyses.value.isNotEmpty || isLoadingAvailableAnalyses.value) {
      return;
    }

    availableAnalyses.value = const <AnalysisDto>[];
    selectedAvailableAnalysisIds.value = const <String>{};
    await loadAvailableAnalysesForEmptyFolder();
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

final libraryFolderScreenPresenterProvider = Provider.autoDispose
    .family<LibraryFolderScreenPresenter, String>((Ref ref, String folderId) {
      final LibraryService libraryService = ref.watch(libraryServiceProvider);
      final IntakeService intakeService = ref.watch(intakeServiceProvider);
      final NavigationDriver navigationDriver = ref.watch(
        navigationDriverProvider,
      );

      final LibraryFolderScreenPresenter presenter =
          LibraryFolderScreenPresenter(
            libraryService: libraryService,
            intakeService: intakeService,
            navigationDriver: navigationDriver,
            folderId: folderId,
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
