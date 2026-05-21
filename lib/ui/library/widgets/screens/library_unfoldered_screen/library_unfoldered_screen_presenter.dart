import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:animus/constants/routes.dart';
import 'package:animus/core/intake/dtos/analysis_dto.dart';
import 'package:animus/core/library/interfaces/library_service.dart';
import 'package:animus/core/shared/interfaces/navigation_driver.dart';
import 'package:animus/core/shared/responses/cursor_pagination_response.dart';
import 'package:animus/core/shared/responses/rest_response.dart';
import 'package:animus/drivers/navigation/index.dart';
import 'package:animus/rest/services/index.dart';

class LibraryUnfolderedScreenPresenter {
  static const int _pageSize = 10;

  final LibraryService _libraryService;
  final NavigationDriver _navigationDriver;

  final Signal<bool> isLoadingInitialData = signal<bool>(false);
  final Signal<bool> isLoadingMore = signal<bool>(false);
  final Signal<bool> isMovingAnalyses = signal<bool>(false);
  final Signal<bool> isArchivingAnalyses = signal<bool>(false);
  final Signal<String?> generalError = signal<String?>(null);
  final Signal<List<AnalysisDto>> analyses = signal<List<AnalysisDto>>(
    const <AnalysisDto>[],
  );
  final Signal<Set<String>> selectedAnalysisIds = signal<Set<String>>(
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

  bool _didInitialize = false;
  bool _isDisposed = false;

  LibraryUnfolderedScreenPresenter({
    required LibraryService libraryService,
    required NavigationDriver navigationDriver,
  }) : _libraryService = libraryService,
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

    isLoadingInitialData.value = true;
    generalError.value = null;
    selectedAnalysisIds.value = const <String>{};

    final RestResponse<CursorPaginationResponse<AnalysisDto>> response =
        await _libraryService.listUnfolderedAnalyses(limit: _pageSize);

    if (_isDisposed) {
      return;
    }

    if (response.isFailure) {
      generalError.value = _resolveErrorMessage(
        response,
        fallback: 'Não foi possivel carregar as analises sem pasta.',
      );
      isLoadingInitialData.value = false;
      return;
    }

    final CursorPaginationResponse<AnalysisDto> pagination = response.body;
    analyses.value = List<AnalysisDto>.unmodifiable(
      pagination.items.where(_isUnfoldered),
    );
    nextCursor.value = pagination.nextCursor;
    isLoadingInitialData.value = false;
  }

  Future<void> refresh() async {
    if (isLoadingInitialData.value || isLoadingMore.value) {
      return;
    }

    analyses.value = const <AnalysisDto>[];
    nextCursor.value = null;
    selectedAnalysisIds.value = const <String>{};
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
        await _libraryService.listUnfolderedAnalyses(
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
            'Não foi possivel carregar mais analises. Role novamente para tentar de novo.',
      );
      isLoadingMore.value = false;
      return;
    }

    final CursorPaginationResponse<AnalysisDto> pagination = response.body;
    analyses.value = List<AnalysisDto>.unmodifiable(<AnalysisDto>[
      ...analyses.value,
      ...pagination.items.where(_isUnfoldered),
    ]);
    nextCursor.value = pagination.nextCursor;
    isLoadingMore.value = false;
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
    final String normalizedDestinationId = (destinationFolderId ?? '').trim();
    if (ids.isEmpty ||
        normalizedDestinationId.isEmpty ||
        isMovingAnalyses.value) {
      return;
    }

    isMovingAnalyses.value = true;
    generalError.value = null;

    final RestResponse<void> response = await _libraryService
        .moveAnalysesToFolder(
          analysisIds: ids,
          folderId: normalizedDestinationId,
        );

    if (_isDisposed) {
      return;
    }

    if (response.isFailure) {
      generalError.value = _resolveErrorMessage(
        response,
        fallback: 'Não foi possivel mover as analises selecionadas.',
      );
      isMovingAnalyses.value = false;
      return;
    }

    _removeAnalyses(ids);
    selectedAnalysisIds.value = const <String>{};
    isMovingAnalyses.value = false;
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
        fallback: 'Não foi possivel arquivar as analises selecionadas.',
      );
      isArchivingAnalyses.value = false;
      return;
    }

    _removeAnalyses(ids);
    selectedAnalysisIds.value = const <String>{};
    isArchivingAnalyses.value = false;
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
    isMovingAnalyses.dispose();
    isArchivingAnalyses.dispose();
    generalError.dispose();
    analyses.dispose();
    selectedAnalysisIds.dispose();
    nextCursor.dispose();
    hasMore.dispose();
    hasSelection.dispose();
    selectedCount.dispose();
  }

  void _removeAnalyses(List<String> ids) {
    final Set<String> selectedIds = ids.toSet();
    analyses.value = List<AnalysisDto>.unmodifiable(
      analyses.value.where(
        (AnalysisDto analysis) =>
            !selectedIds.contains((analysis.id ?? '').trim()),
      ),
    );
  }

  bool _isUnfoldered(AnalysisDto analysis) {
    return (analysis.folderId ?? '').trim().isEmpty;
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

final Provider<LibraryUnfolderedScreenPresenter>
libraryUnfolderedScreenPresenterProvider =
    Provider.autoDispose<LibraryUnfolderedScreenPresenter>((Ref ref) {
      final LibraryService libraryService = ref.watch(libraryServiceProvider);
      final NavigationDriver navigationDriver = ref.watch(
        navigationDriverProvider,
      );

      final LibraryUnfolderedScreenPresenter presenter =
          LibraryUnfolderedScreenPresenter(
            libraryService: libraryService,
            navigationDriver: navigationDriver,
          );

      ref.onDispose(presenter.dispose);
      return presenter;
    });

final Provider<void> libraryUnfolderedScreenInitializationProvider =
    Provider.autoDispose<void>((Ref ref) {
      final LibraryUnfolderedScreenPresenter presenter = ref.watch(
        libraryUnfolderedScreenPresenterProvider,
      );
      Future<void>.microtask(presenter.initialize);
    });
