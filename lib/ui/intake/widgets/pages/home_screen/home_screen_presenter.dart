import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:animus/constants/cache_keys.dart';
import 'package:animus/constants/routes.dart';
import 'package:animus/core/auth/dtos/account_dto.dart';
import 'package:animus/core/auth/interfaces/auth_service.dart';
import 'package:animus/core/intake/dtos/analysis_dto.dart';
import 'package:animus/core/intake/dtos/analysis_type_dto.dart';
import 'package:animus/core/intake/interfaces/intake_service.dart';
import 'package:animus/core/shared/interfaces/cache_driver.dart';
import 'package:animus/core/shared/interfaces/navigation_driver.dart';
import 'package:animus/core/shared/interfaces/push_notification_driver.dart';
import 'package:animus/core/shared/responses/cursor_pagination_response.dart';
import 'package:animus/core/shared/responses/rest_response.dart';
import 'package:animus/drivers/cache/index.dart';
import 'package:animus/drivers/navigation/index.dart';
import 'package:animus/drivers/push-notification-driver/index.dart';
import 'package:animus/rest/services/index.dart';

class HomeScreenPresenter {
  static const int _pageSize = 10;
  static const Duration _processingPollingInterval = Duration(seconds: 5);

  final AuthService _authService;
  final IntakeService _intakeService;
  final CacheDriver _cacheDriver;
  final NavigationDriver _navigationDriver;
  final PushNotificationDriver _pushNotificationDriver;

  final Signal<bool> isLoadingInitialData = signal<bool>(false);
  final Signal<bool> isLoadingMore = signal<bool>(false);
  final Signal<bool> isCreatingAnalysis = signal<bool>(false);
  final Signal<String?> generalError = signal<String?>(null);
  final Signal<String?> firstName = signal<String?>(null);
  final Signal<List<AnalysisDto>> recentAnalyses = signal<List<AnalysisDto>>(
    const <AnalysisDto>[],
  );
  final Signal<String?> nextCursor = signal<String?>(null);
  List<AnalysisDto> _processingAnalyses = const <AnalysisDto>[];
  Timer? _processingPollingTimer;
  bool _isPollingProcessing = false;

  bool _didCompleteInitialLoad = false;

  late final ReadonlySignal<String> greeting = computed(() {
    final String salutation = _resolveGreeting(DateTime.now().hour);
    final String normalizedFirstName = firstName.value?.trim() ?? '';

    if (normalizedFirstName.isEmpty) {
      return salutation;
    }

    return '$salutation, $normalizedFirstName';
  });

  late final ReadonlySignal<bool> hasMore = computed(() {
    final String? cursor = nextCursor.value;
    return cursor != null && cursor.trim().isNotEmpty;
  });

  late final ReadonlySignal<bool> showEmptyState = computed(() {
    return !isLoadingInitialData.value &&
        generalError.value == null &&
        recentAnalyses.value.isEmpty;
  });

  HomeScreenPresenter({
    required AuthService authService,
    required IntakeService intakeService,
    required CacheDriver cacheDriver,
    required NavigationDriver navigationDriver,
    required PushNotificationDriver pushNotificationDriver,
  }) : _authService = authService,
       _intakeService = intakeService,
       _cacheDriver = cacheDriver,
       _navigationDriver = navigationDriver,
       _pushNotificationDriver = pushNotificationDriver;

  Future<void> initialize() async {
    if (isLoadingInitialData.value || _didCompleteInitialLoad) {
      return;
    }

    final String token = (_cacheDriver.get(CacheKeys.accessToken) ?? '').trim();
    if (token.isEmpty) {
      _navigationDriver.goTo(Routes.signIn);
      return;
    }

    isLoadingInitialData.value = true;
    generalError.value = null;

    final RestResponse<AccountDto> accountResponse = await _authService
        .getAccount();

    if (accountResponse.isFailure) {
      generalError.value = _resolveErrorMessage(
        accountResponse,
        fallback:
            'Não foi possivel carregar a sua conta agora. Tente novamente.',
      );
      isLoadingInitialData.value = false;
      return;
    }

    final AccountDto account = accountResponse.body;
    firstName.value = _extractFirstName(account);
    _syncPushNotificationUser(account);
    _requestPushNotificationPermissionOnce();

    final RestResponse<List<AnalysisDto>> processingAnalysesResponse =
        await _intakeService.listProcessingAnalyses();
    if (processingAnalysesResponse.isSuccessful) {
      _processingAnalyses = List<AnalysisDto>.unmodifiable(
        processingAnalysesResponse.body,
      );
    } else {
      _processingAnalyses = const <AnalysisDto>[];
    }

    final RestResponse<CursorPaginationResponse<AnalysisDto>> analysesResponse =
        await _intakeService.listAnalyses(limit: _pageSize, isArchived: false);

    if (analysesResponse.isFailure) {
      generalError.value = _resolveErrorMessage(
        analysesResponse,
        fallback:
            'Não foi possivel carregar as analises agora. Tente novamente.',
      );
      isLoadingInitialData.value = false;
      return;
    }

    final CursorPaginationResponse<AnalysisDto> pagination =
        analysesResponse.body;
    recentAnalyses.value = List<AnalysisDto>.unmodifiable(
      _mergeProcessingAnalyses(pagination.items),
    );
    nextCursor.value = pagination.nextCursor;
    generalError.value = null;
    _didCompleteInitialLoad = true;
    _startProcessingPolling();
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
    generalError.value = null;

    final RestResponse<CursorPaginationResponse<AnalysisDto>> response =
        await _intakeService.listAnalyses(
          cursor: cursor,
          limit: _pageSize,
          isArchived: false,
        );

    if (response.isFailure) {
      generalError.value = _resolveErrorMessage(
        response,
        fallback:
            'Não foi possivel carregar mais analises agora. Role novamente para tentar de novo.',
      );
      isLoadingMore.value = false;
      return;
    }

    final CursorPaginationResponse<AnalysisDto> pagination = response.body;
    recentAnalyses.value = List<AnalysisDto>.unmodifiable(
      _mergeProcessingAnalyses(<AnalysisDto>[
        ...recentAnalyses.value,
        ...pagination.items,
      ]),
    );
    nextCursor.value = pagination.nextCursor;
    generalError.value = null;
    isLoadingMore.value = false;
  }

  Future<void> createAnalysis() async {
    if (isCreatingAnalysis.value) {
      return;
    }

    isCreatingAnalysis.value = true;
    generalError.value = null;

    final RestResponse<AnalysisDto> response = await _intakeService
        .createAnalysis(type: AnalysisTypeDto.firstInstance);

    if (response.isFailure) {
      generalError.value = _resolveErrorMessage(
        response,
        fallback: 'Não foi possivel iniciar uma nova analise agora.',
      );
      isCreatingAnalysis.value = false;
      return;
    }

    final String analysisId = (response.body.id ?? '').trim();
    if (analysisId.isEmpty) {
      generalError.value = 'Não foi possivel abrir a analise criada.';
      isCreatingAnalysis.value = false;
      return;
    }

    isCreatingAnalysis.value = false;
    await _navigationDriver.pushTo(
      Routes.getFirstInstanceAnalysis(analysisId: analysisId),
    );
    await refresh();
  }

  Future<void> refresh() async {
    if (isLoadingInitialData.value || isLoadingMore.value) {
      return;
    }

    _didCompleteInitialLoad = false;
    _processingAnalyses = const <AnalysisDto>[];
    recentAnalyses.value = const <AnalysisDto>[];
    nextCursor.value = null;
    await initialize();
  }

  Future<void> openAnalysis(AnalysisDto analysis) async {
    final String analysisId = (analysis.id ?? '').trim();
    if (analysisId.isEmpty) {
      return;
    }

    switch (analysis.type) {
      case AnalysisTypeDto.firstInstance:
        await _navigationDriver.pushTo(
          Routes.getFirstInstanceAnalysis(analysisId: analysisId),
        );
        break;
      case AnalysisTypeDto.secondInstance:
        await _navigationDriver.pushTo(
          Routes.getSecondInstanceAnalysis(analysisId: analysisId),
        );
        break;
      case AnalysisTypeDto.caseAssessment:
        await _navigationDriver.pushTo(
          Routes.getSecondInstanceAnalysis(analysisId: analysisId),
        );
    }

    await refresh();
  }

  void openProfile() {
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
    _stopProcessingPolling();
    isLoadingInitialData.dispose();
    isLoadingMore.dispose();
    isCreatingAnalysis.dispose();
    generalError.dispose();
    firstName.dispose();
    recentAnalyses.dispose();
    nextCursor.dispose();
    greeting.dispose();
    hasMore.dispose();
    showEmptyState.dispose();
  }

  void _startProcessingPolling() {
    if (_processingPollingTimer != null) {
      return;
    }

    _processingPollingTimer = Timer.periodic(_processingPollingInterval, (_) {
      unawaited(_pollProcessingAnalyses());
    });
  }

  void _stopProcessingPolling() {
    _processingPollingTimer?.cancel();
    _processingPollingTimer = null;
  }

  Future<void> _pollProcessingAnalyses() async {
    if (_isPollingProcessing ||
        isLoadingInitialData.value ||
        isLoadingMore.value) {
      return;
    }

    _isPollingProcessing = true;

    try {
      final Set<String> previousProcessingIds = _processingAnalyses
          .map((AnalysisDto analysis) => (analysis.id ?? '').trim())
          .where((String id) => id.isNotEmpty)
          .toSet();

      final RestResponse<List<AnalysisDto>> response = await _intakeService
          .listProcessingAnalyses();
      if (response.isFailure) {
        return;
      }

      _processingAnalyses = List<AnalysisDto>.unmodifiable(response.body);

      final Set<String> currentProcessingIds = _processingAnalyses
          .map((AnalysisDto analysis) => (analysis.id ?? '').trim())
          .where((String id) => id.isNotEmpty)
          .toSet();

      final bool hasCompletedAnalyses = previousProcessingIds.any(
        (String id) => !currentProcessingIds.contains(id),
      );

      if (hasCompletedAnalyses) {
        await _refreshRecentAnalysesPage();
        return;
      }

      recentAnalyses.value = List<AnalysisDto>.unmodifiable(
        _mergeProcessingAnalyses(recentAnalyses.value),
      );
    } finally {
      _isPollingProcessing = false;
    }
  }

  Future<void> _refreshRecentAnalysesPage() async {
    final RestResponse<CursorPaginationResponse<AnalysisDto>> response =
        await _intakeService.listAnalyses(limit: _pageSize, isArchived: false);

    if (response.isFailure) {
      recentAnalyses.value = List<AnalysisDto>.unmodifiable(
        _mergeProcessingAnalyses(recentAnalyses.value),
      );
      return;
    }

    final CursorPaginationResponse<AnalysisDto> pagination = response.body;
    recentAnalyses.value = List<AnalysisDto>.unmodifiable(
      _mergeProcessingAnalyses(pagination.items),
    );
    nextCursor.value = pagination.nextCursor;
  }

  String _extractFirstName(AccountDto account) {
    final String normalizedName = account.name.trim();
    if (normalizedName.isEmpty) {
      return '';
    }

    return normalizedName.split(RegExp(r'\s+')).first;
  }

  void _syncPushNotificationUser(AccountDto account) {
    final String accountId = (account.id ?? '').trim();
    if (accountId.isEmpty) {
      return;
    }

    unawaited(
      _pushNotificationDriver.identifyUser(accountId).catchError((_) {}),
    );
  }

  void _requestPushNotificationPermissionOnce() {
    unawaited(
      _pushNotificationDriver
          .requestPermission(fallbackToSettings: false)
          .catchError((_) => false),
    );
  }

  String _resolveGreeting(int hour) {
    if (hour < 12) {
      return 'Bom dia';
    }

    if (hour < 18) {
      return 'Boa tarde';
    }

    return 'Boa noite';
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

  List<AnalysisDto> _mergeProcessingAnalyses(List<AnalysisDto> analyses) {
    if (_processingAnalyses.isEmpty) {
      return analyses;
    }

    final Set<String> addedIds = <String>{};
    final List<AnalysisDto> merged = <AnalysisDto>[];

    for (final AnalysisDto processing in _processingAnalyses) {
      final String processingId = (processing.id ?? '').trim();
      if (processingId.isEmpty || addedIds.contains(processingId)) {
        continue;
      }

      merged.add(processing);
      addedIds.add(processingId);
    }

    for (final AnalysisDto analysis in analyses) {
      final String analysisId = (analysis.id ?? '').trim();
      if (analysisId.isNotEmpty && addedIds.contains(analysisId)) {
        continue;
      }

      merged.add(analysis);
      if (analysisId.isNotEmpty) {
        addedIds.add(analysisId);
      }
    }

    return merged;
  }
}

final Provider<HomeScreenPresenter> homeScreenPresenterProvider =
    Provider.autoDispose<HomeScreenPresenter>((Ref ref) {
      final AuthService authService = ref.watch(authServiceProvider);
      final IntakeService intakeService = ref.watch(intakeServiceProvider);
      final CacheDriver cacheDriver = ref.watch(cacheDriverProvider);
      final NavigationDriver navigationDriver = ref.watch(
        navigationDriverProvider,
      );
      final PushNotificationDriver pushNotificationDriver = ref.watch(
        pushNotificationDriverProvider,
      );

      final HomeScreenPresenter presenter = HomeScreenPresenter(
        authService: authService,
        intakeService: intakeService,
        cacheDriver: cacheDriver,
        navigationDriver: navigationDriver,
        pushNotificationDriver: pushNotificationDriver,
      );

      ref.onDispose(presenter.dispose);
      return presenter;
    });

final Provider<void> homeScreenInitializationProvider =
    Provider.autoDispose<void>((Ref ref) {
      final HomeScreenPresenter presenter = ref.watch(
        homeScreenPresenterProvider,
      );
      Future<void>.microtask(presenter.initialize);
    });
