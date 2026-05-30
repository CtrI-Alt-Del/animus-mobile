import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:animus/constants/routes.dart';
import 'package:animus/core/intake/dtos/analysis_dto.dart';
import 'package:animus/core/intake/interfaces/intake_service.dart';
import 'package:animus/core/shared/interfaces/navigation_driver.dart';
import 'package:animus/core/shared/responses/cursor_pagination_response.dart';
import 'package:animus/core/shared/responses/rest_response.dart';
import 'package:animus/drivers/navigation/index.dart';
import 'package:animus/rest/services/index.dart';
import 'package:animus/ui/intake/providers/analyses_feed_refresh_provider.dart';

class ArchivedAnalysesScreenPresenter {
  static const int _pageSize = 10;
  static const Duration _defaultSearchDebounce = Duration(milliseconds: 300);

  final IntakeService _intakeService;
  final NavigationDriver _navigationDriver;
  final VoidCallback _onAnalysesChanged;
  final Duration _searchDebounce;

  Timer? _searchDebounceTimer;
  int _activeSearchToken = 0;

  final Signal<bool> isLoadingInitialData = signal<bool>(false);
  final Signal<bool> isLoadingMore = signal<bool>(false);
  final Signal<bool> isUnarchiving = signal<bool>(false);
  final Signal<String?> unarchivingId = signal<String?>(null);
  final Signal<String?> generalError = signal<String?>(null);
  final Signal<String?> paginationError = signal<String?>(null);
  final Signal<List<AnalysisDto>> archivedAnalyses = signal<List<AnalysisDto>>(
    const <AnalysisDto>[],
  );
  final Signal<String?> nextCursor = signal<String?>(null);
  final Signal<String> searchQuery = signal<String>('');

  bool _didCompleteInitialLoad = false;

  late final ReadonlySignal<bool> hasMore = computed(() {
    final String? cursor = nextCursor.value;
    return cursor != null && cursor.trim().isNotEmpty;
  });

  late final ReadonlySignal<bool> showEmptyState = computed(() {
    return !isLoadingInitialData.value &&
        generalError.value == null &&
        searchQuery.value.trim().isEmpty &&
        archivedAnalyses.value.isEmpty;
  });

  late final ReadonlySignal<bool> showSearchEmptyState = computed(() {
    return !isLoadingInitialData.value &&
        generalError.value == null &&
        searchQuery.value.trim().isNotEmpty &&
        archivedAnalyses.value.isEmpty;
  });

  ArchivedAnalysesScreenPresenter({
    required IntakeService intakeService,
    required NavigationDriver navigationDriver,
    required VoidCallback onAnalysesChanged,
    Duration? searchDebounce,
  }) : _intakeService = intakeService,
       _navigationDriver = navigationDriver,
       _onAnalysesChanged = onAnalysesChanged,
       _searchDebounce = searchDebounce ?? _defaultSearchDebounce;

  Future<void> initialize() async {
    if (isLoadingInitialData.value || _didCompleteInitialLoad) {
      return;
    }
    await _fetchFirstPage();
  }

  Future<void> loadNextPage() async {
    if (isLoadingInitialData.value || isLoadingMore.value) {
      return;
    }

    final String cursor = (nextCursor.value ?? '').trim();
    if (cursor.isEmpty) {
      return;
    }

    final int token = ++_activeSearchToken;
    isLoadingMore.value = true;
    paginationError.value = null;

    final RestResponse<CursorPaginationResponse<AnalysisDto>> response =
        await _intakeService.listAnalyses(
          cursor: cursor,
          limit: _pageSize,
          isArchived: true,
          search: searchQuery.value.trim(),
        );

    if (token != _activeSearchToken) {
      return;
    }

    if (response.isFailure) {
      paginationError.value = _resolveErrorMessage(
        response,
        fallback:
            'Não foi possível carregar mais análises arquivadas agora. Role para tentar novamente.',
      );
      isLoadingMore.value = false;
      return;
    }

    final CursorPaginationResponse<AnalysisDto> pagination = response.body;
    final Set<String> existingIds = <String>{
      for (final AnalysisDto current in archivedAnalyses.value)
        (current.id ?? '').trim(),
    };
    final List<AnalysisDto> deduped = <AnalysisDto>[
      ...archivedAnalyses.value,
      for (final AnalysisDto item in pagination.items)
        if (!existingIds.contains((item.id ?? '').trim())) item,
    ];
    archivedAnalyses.value = List<AnalysisDto>.unmodifiable(deduped);
    nextCursor.value = pagination.nextCursor;
    paginationError.value = null;
    isLoadingMore.value = false;
  }

  Future<void> refresh() async {
    if (isLoadingInitialData.value || isLoadingMore.value) {
      return;
    }
    _searchDebounceTimer?.cancel();
    _didCompleteInitialLoad = false;
    await _fetchFirstPage();
  }

  void updateSearchQuery(String value) {
    if (searchQuery.value == value) {
      return;
    }
    searchQuery.value = value;
    _scheduleSearchFetch();
  }

  void clearSearch() {
    if (searchQuery.value.isEmpty) {
      return;
    }
    searchQuery.value = '';
    _scheduleSearchFetch();
  }

  void _scheduleSearchFetch() {
    _searchDebounceTimer?.cancel();
    if (_searchDebounce == Duration.zero) {
      unawaited(_fetchFirstPage());
      return;
    }
    _searchDebounceTimer = Timer(_searchDebounce, () {
      unawaited(_fetchFirstPage());
    });
  }

  Future<void> _fetchFirstPage() async {
    final int token = ++_activeSearchToken;
    isLoadingInitialData.value = true;
    generalError.value = null;
    paginationError.value = null;

    final RestResponse<CursorPaginationResponse<AnalysisDto>> response =
        await _intakeService.listAnalyses(
          limit: _pageSize,
          isArchived: true,
          search: searchQuery.value.trim(),
        );

    if (token != _activeSearchToken) {
      return;
    }

    if (response.isFailure) {
      generalError.value = _resolveErrorMessage(
        response,
        fallback:
            'Não foi possível carregar as análises arquivadas agora. Tente novamente.',
      );
      archivedAnalyses.value = const <AnalysisDto>[];
      nextCursor.value = null;
      isLoadingInitialData.value = false;
      return;
    }

    final CursorPaginationResponse<AnalysisDto> pagination = response.body;
    archivedAnalyses.value = List<AnalysisDto>.unmodifiable(pagination.items);
    nextCursor.value = pagination.nextCursor;
    generalError.value = null;
    _didCompleteInitialLoad = true;
    isLoadingInitialData.value = false;
  }

  Future<bool> unarchive(AnalysisDto analysis) async {
    if (isUnarchiving.value) {
      return false;
    }

    final String analysisId = (analysis.id ?? '').trim();
    if (analysisId.isEmpty) {
      return false;
    }

    isUnarchiving.value = true;
    unarchivingId.value = analysisId;

    final RestResponse<AnalysisDto> response = await _intakeService
        .unarchiveAnalysis(analysisId: analysisId);

    if (response.isFailure) {
      isUnarchiving.value = false;
      unarchivingId.value = null;
      return false;
    }

    archivedAnalyses.value = List<AnalysisDto>.unmodifiable(
      archivedAnalyses.value.where(
        (AnalysisDto current) => (current.id ?? '').trim() != analysisId,
      ),
    );
    _onAnalysesChanged();

    isUnarchiving.value = false;
    unarchivingId.value = null;
    return true;
  }

  Future<void> openAnalysis(AnalysisDto analysis) async {
    final String analysisId = (analysis.id ?? '').trim();
    if (analysisId.isEmpty) {
      return;
    }

    await _navigationDriver.pushTo(
      Routes.getAnalysis(analysisId: analysisId, analysisType: analysis.type),
    );
  }

  void goBack() {
    if (_navigationDriver.canGoBack()) {
      _navigationDriver.goBack();
      return;
    }

    _navigationDriver.goTo(Routes.profile);
  }

  String formatCreatedAt(String value) {
    final DateTime? parsedDate = DateTime.tryParse(value);
    if (parsedDate == null) {
      return 'Data indisponível';
    }

    final String day = parsedDate.day.toString().padLeft(2, '0');
    final String month = parsedDate.month.toString().padLeft(2, '0');
    final String year = parsedDate.year.toString();
    return '$day/$month/$year';
  }

  void dispose() {
    _searchDebounceTimer?.cancel();
    isLoadingInitialData.dispose();
    isLoadingMore.dispose();
    isUnarchiving.dispose();
    unarchivingId.dispose();
    generalError.dispose();
    paginationError.dispose();
    archivedAnalyses.dispose();
    nextCursor.dispose();
    searchQuery.dispose();
    hasMore.dispose();
    showEmptyState.dispose();
    showSearchEmptyState.dispose();
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

final Provider<ArchivedAnalysesScreenPresenter>
archivedAnalysesScreenPresenterProvider =
    Provider.autoDispose<ArchivedAnalysesScreenPresenter>((Ref ref) {
      final IntakeService intakeService = ref.watch(intakeServiceProvider);
      final NavigationDriver navigationDriver = ref.watch(
        navigationDriverProvider,
      );

      final ArchivedAnalysesScreenPresenter presenter =
          ArchivedAnalysesScreenPresenter(
            intakeService: intakeService,
            navigationDriver: navigationDriver,
            onAnalysesChanged: () {
              ref.read(analysesFeedRefreshNotifierProvider).notifyChanged();
            },
          );

      ref.onDispose(presenter.dispose);
      return presenter;
    });

final Provider<void> archivedAnalysesScreenInitializationProvider =
    Provider.autoDispose<void>((Ref ref) {
      final ArchivedAnalysesScreenPresenter presenter = ref.watch(
        archivedAnalysesScreenPresenterProvider,
      );
      Future<void>.microtask(presenter.initialize);
    });
