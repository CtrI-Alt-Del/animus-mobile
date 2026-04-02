import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:animus/constants/cache_keys.dart';
import 'package:animus/constants/routes.dart';
import 'package:animus/core/auth/dtos/account_dto.dart';
import 'package:animus/core/auth/interfaces/auth_service.dart';
import 'package:animus/core/shared/interfaces/cache_driver.dart';
import 'package:animus/core/shared/interfaces/navigation_driver.dart';
import 'package:animus/core/shared/responses/rest_response.dart';
import 'package:animus/drivers/cache/index.dart';
import 'package:animus/drivers/navigation/index.dart';
import 'package:animus/rest/services/index.dart';

class ProfileScreenPresenter {
  final AuthService _authService;
  final CacheDriver _cacheDriver;
  final NavigationDriver _navigationDriver;

  final Signal<bool> isLoadingInitialData = signal<bool>(false);
  final Signal<String?> generalError = signal<String?>(null);
  final Signal<AccountDto?> account = signal<AccountDto?>(null);

  bool _didCompleteInitialLoad = false;

  late final ReadonlySignal<bool> hasAccount = computed(
    () => account.value != null,
  );

  late final ReadonlySignal<String> displayInitial = computed(() {
    final String normalizedName = account.value?.name.trim() ?? '';
    if (normalizedName.isEmpty) {
      return '?';
    }

    return normalizedName[0].toUpperCase();
  });

  late final ReadonlySignal<String> displayName = computed(() {
    final String normalizedName = account.value?.name.trim() ?? '';
    if (normalizedName.isEmpty) {
      return 'Nome indisponivel';
    }

    return normalizedName;
  });

  late final ReadonlySignal<String> displayEmail = computed(() {
    final String normalizedEmail = account.value?.email.trim() ?? '';
    if (normalizedEmail.isEmpty) {
      return 'E-mail indisponivel';
    }

    return normalizedEmail;
  });

  ProfileScreenPresenter({
    required AuthService authService,
    required CacheDriver cacheDriver,
    required NavigationDriver navigationDriver,
  }) : _authService = authService,
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

    final RestResponse<AccountDto> response = await _authService.fetchAccount();

    if (response.isFailure) {
      generalError.value = _resolveErrorMessage(
        response,
        fallback:
            'Nao foi possivel carregar o seu perfil agora. Tente novamente.',
      );
      isLoadingInitialData.value = false;
      return;
    }

    account.value = response.body;
    generalError.value = null;
    _didCompleteInitialLoad = true;
    isLoadingInitialData.value = false;
  }

  void onDestinationSelected(int index) {
    if (index == 0) {
      _navigationDriver.goTo(Routes.home);
      return;
    }
  }

  void dispose() {
    isLoadingInitialData.dispose();
    generalError.dispose();
    account.dispose();
    hasAccount.dispose();
    displayInitial.dispose();
    displayName.dispose();
    displayEmail.dispose();
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

final Provider<ProfileScreenPresenter> profileScreenPresenterProvider =
    Provider.autoDispose<ProfileScreenPresenter>((Ref ref) {
      final AuthService authService = ref.watch(authServiceProvider);
      final CacheDriver cacheDriver = ref.watch(cacheDriverProvider);
      final NavigationDriver navigationDriver = ref.watch(
        navigationDriverProvider,
      );

      final ProfileScreenPresenter presenter = ProfileScreenPresenter(
        authService: authService,
        cacheDriver: cacheDriver,
        navigationDriver: navigationDriver,
      );

      ref.onDispose(presenter.dispose);
      return presenter;
    });

final Provider<void> profileScreenInitializationProvider =
    Provider.autoDispose<void>((Ref ref) {
      final ProfileScreenPresenter presenter = ref.watch(
        profileScreenPresenterProvider,
      );
      Future<void>.microtask(presenter.initialize);
    });
