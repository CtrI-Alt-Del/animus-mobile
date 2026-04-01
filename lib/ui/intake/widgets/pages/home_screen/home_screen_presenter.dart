import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:animus/constants/cache_keys.dart';
import 'package:animus/constants/routes.dart';
import 'package:animus/core/auth/dtos/account_dto.dart';
import 'package:animus/core/auth/interfaces/auth_service.dart';
import 'package:animus/core/intake/dtos/analysis_dto.dart';
import 'package:animus/core/intake/interfaces/intake_service.dart';
import 'package:animus/core/shared/interfaces/cache_driver.dart';
import 'package:animus/core/shared/interfaces/navigation_driver.dart';
import 'package:animus/core/shared/responses/cursor_pagination_response.dart';
import 'package:animus/core/shared/responses/rest_response.dart';
import 'package:animus/drivers/cache/index.dart';
import 'package:animus/drivers/navigation/index.dart';
import 'package:animus/rest/services/index.dart';

class HomeScreenPresenter {
  static const int _pageSize = 10;

  final AuthService _authService;
  final IntakeService _intakeService;
  final CacheDriver _cacheDriver;
  final NavigationDriver _navigationDriver;

  final Signal<bool> isLoadingInitialData = signal<bool>(false);
  final Signal<bool> isLoadingMore = signal<bool>(false);
  final Signal<bool> isCreatingAnalysis = signal<bool>(false);
  final Signal<String?> generalError = signal<String?>(null);
  final Signal<String?> firstName = signal<String?>(null);
  final Signal<List<AnalysisDto>> recentAnalyses = signal<List<AnalysisDto>>(
    const <AnalysisDto>[],
  );
  final Signal<String?> nextCursor = signal<String?>(null);

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
  }) : _authService = authService,
       _intakeService = intakeService,
       _cacheDriver = cacheDriver,
       _navigationDriver = navigationDriver;

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

    final RestResponse<AccountDto> accountResponse =
        await _authService.fetchAccount();

    if (accountResponse.isFailure) {
      generalError.value = _resolveErrorMessage(
        accountResponse,
        fallback:
            'Nao foi possivel carregar a sua conta agora. Tente novamente.',
      );
      isLoadingInitialData.value = false;
      return;
    }

    firstName.value = _extractFirstName(accountResponse.body);

    final RestResponse<CursorPaginationResponse<AnalysisDto>> analysesResponse =
        await _intakeService.listAnalyses(limit: _pageSize, isArchived: false);

    if (analysesResponse.isFailure) {
      generalError.value = _resolveErrorMessage(
        analysesResponse,
        fallback:
            'Nao foi possivel carregar as analises agora. Tente novamente.',
      );
      isLoadingInitialData.value = false;
      return;
    }

    final CursorPaginationResponse<AnalysisDto> pagination =
        analysesResponse.body;
    recentAnalyses.value = List<AnalysisDto>.unmodifiable(pagination.items);
    nextCursor.value = pagination.nextCursor;
    generalError.value = null;
    _didCompleteInitialLoad = true;
    isLoadingInitialData.value = false;
  }

  Future<void> loadNextPage() async {
    if (isLoadingInitialData.value || isLoadingMore.value || !hasMore.value) {
      return;
    }

    isLoadingMore.value = true;
    generalError.value = null;

    final RestResponse<CursorPaginationResponse<AnalysisDto>> response =
        await _intakeService.listAnalyses(
          cursor: nextCursor.value,
          limit: _pageSize,
          isArchived: false,
        );

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
    recentAnalyses.value = List<AnalysisDto>.unmodifiable(<AnalysisDto>[
      ...recentAnalyses.value,
      ...pagination.items,
    ]);
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

    final RestResponse<AnalysisDto> response =
        await _intakeService.createAnalysis();

    if (response.isFailure) {
      generalError.value = _resolveErrorMessage(
        response,
        fallback: 'Nao foi possivel iniciar uma nova analise agora.',
      );
      isCreatingAnalysis.value = false;
      return;
    }

    final String analysisId = (response.body.id ?? '').trim();
    if (analysisId.isEmpty) {
      generalError.value = 'Nao foi possivel abrir a analise criada.';
      isCreatingAnalysis.value = false;
      return;
    }

    isCreatingAnalysis.value = false;
    _navigationDriver.goTo(Routes.getAnalysis(id: analysisId));
  }

  void openAnalysis(AnalysisDto analysis) {
    final String analysisId = (analysis.id ?? '').trim();
    if (analysisId.isEmpty) {
      return;
    }

    _navigationDriver.goTo(Routes.getAnalysis(id: analysisId));
  }

  void onDestinationSelected(int index) {
    if (index == 0) {
      return;
    }
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
    isCreatingAnalysis.dispose();
    generalError.dispose();
    firstName.dispose();
    recentAnalyses.dispose();
    nextCursor.dispose();
    greeting.dispose();
    hasMore.dispose();
    showEmptyState.dispose();
  }

  String _extractFirstName(AccountDto account) {
    final String normalizedName = account.name.trim();
    if (normalizedName.isEmpty) {
      return '';
    }

    return normalizedName.split(RegExp(r'\s+')).first;
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
    final String? bodyMessage = response.errorBody?['message'] as String?;
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

final Provider<HomeScreenPresenter> homeScreenPresenterProvider =
    Provider.autoDispose<HomeScreenPresenter>((Ref ref) {
      final AuthService authService = ref.watch(authServiceProvider);
      final IntakeService intakeService = ref.watch(intakeServiceProvider);
      final CacheDriver cacheDriver = ref.watch(cacheDriverProvider);
      final NavigationDriver navigationDriver = ref.watch(
        navigationDriverProvider,
      );

      final HomeScreenPresenter presenter = HomeScreenPresenter(
        authService: authService,
        intakeService: intakeService,
        cacheDriver: cacheDriver,
        navigationDriver: navigationDriver,
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
