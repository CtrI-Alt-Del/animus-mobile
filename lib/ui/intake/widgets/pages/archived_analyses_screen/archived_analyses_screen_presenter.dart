import 'dart:io';

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

class ArchivedAnalysesScreenPresenter {
  static const int _pageSize = 10;

  final IntakeService _intakeService;
  final NavigationDriver _navigationDriver;

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

  late final ReadonlySignal<List<AnalysisDto>> filteredAnalyses = computed(() {
    final String query = searchQuery.value.trim().toLowerCase();
    final List<AnalysisDto> source = archivedAnalyses.value;
    if (query.isEmpty) {
      return source;
    }

    return source
        .where(
          (AnalysisDto analysis) => analysis.name.toLowerCase().contains(query),
        )
        .toList(growable: false);
  });

  late final ReadonlySignal<bool> showEmptyState = computed(() {
    return !isLoadingInitialData.value &&
        generalError.value == null &&
        archivedAnalyses.value.isEmpty;
  });

  late final ReadonlySignal<bool> showSearchEmptyState = computed(() {
    return searchQuery.value.trim().isNotEmpty &&
        filteredAnalyses.value.isEmpty &&
        archivedAnalyses.value.isNotEmpty;
  });

  ArchivedAnalysesScreenPresenter({
    required IntakeService intakeService,
    required NavigationDriver navigationDriver,
  }) : _intakeService = intakeService,
       _navigationDriver = navigationDriver;

  Future<void> initialize() async {
    if (isLoadingInitialData.value || _didCompleteInitialLoad) {
      return;
    }

    isLoadingInitialData.value = true;
    generalError.value = null;
    paginationError.value = null;

    final RestResponse<CursorPaginationResponse<AnalysisDto>> response =
        await _intakeService.listAnalyses(limit: _pageSize, isArchived: true);

    if (response.isFailure) {
      generalError.value = _resolveErrorMessage(
        response,
        fallback:
            'Nao foi possivel carregar as analises arquivadas agora. Tente novamente.',
      );
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

  Future<void> loadNextPage() async {
    if (isLoadingInitialData.value || isLoadingMore.value) {
      return;
    }

    final String cursor = (nextCursor.value ?? '').trim();
    if (cursor.isEmpty) {
      return;
    }

    isLoadingMore.value = true;
    paginationError.value = null;

    final RestResponse<CursorPaginationResponse<AnalysisDto>> response =
        await _intakeService.listAnalyses(
          cursor: cursor,
          limit: _pageSize,
          isArchived: true,
        );

    if (response.isFailure) {
      paginationError.value = _resolveErrorMessage(
        response,
        fallback:
            'Nao foi possivel carregar mais analises arquivadas agora. Role para tentar novamente.',
      );
      isLoadingMore.value = false;
      return;
    }

    final CursorPaginationResponse<AnalysisDto> pagination = response.body;
    archivedAnalyses.value = List<AnalysisDto>.unmodifiable(<AnalysisDto>[
      ...archivedAnalyses.value,
      ...pagination.items,
    ]);
    nextCursor.value = pagination.nextCursor;
    paginationError.value = null;
    isLoadingMore.value = false;
  }

  Future<void> refresh() async {
    if (isLoadingInitialData.value || isLoadingMore.value) {
      return;
    }

    _didCompleteInitialLoad = false;
    archivedAnalyses.value = const <AnalysisDto>[];
    nextCursor.value = null;
    generalError.value = null;
    paginationError.value = null;
    await initialize();
  }

  void updateSearchQuery(String value) {
    searchQuery.value = value;
  }

  void clearSearch() {
    if (searchQuery.value.isEmpty) {
      return;
    }
    searchQuery.value = '';
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
      return 'Data indisponivel';
    }

    final String day = parsedDate.day.toString().padLeft(2, '0');
    final String month = parsedDate.month.toString().padLeft(2, '0');
    final String year = parsedDate.year.toString();
    return '$day/$month/$year';
  }

  void dispose() {
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
    filteredAnalyses.dispose();
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
