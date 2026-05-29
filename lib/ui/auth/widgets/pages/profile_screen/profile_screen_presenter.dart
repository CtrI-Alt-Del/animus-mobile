import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:animus/constants/cache_keys.dart';
import 'package:animus/constants/routes.dart';
import 'package:animus/core/auth/dtos/account_dto.dart';
import 'package:animus/core/auth/interfaces/auth_service.dart';
import 'package:animus/core/auth/interfaces/google_auth_driver.dart';
import 'package:animus/core/shared/interfaces/app_version_driver.dart';
import 'package:animus/core/shared/interfaces/cache_driver.dart';
import 'package:animus/core/shared/interfaces/navigation_driver.dart';
import 'package:animus/core/shared/interfaces/push_notification_driver.dart';
import 'package:animus/core/shared/responses/rest_response.dart';
import 'package:animus/drivers/app-version-driver/index.dart';
import 'package:animus/drivers/cache/index.dart';
import 'package:animus/drivers/google-auth-driver/index.dart';
import 'package:animus/drivers/navigation/index.dart';
import 'package:animus/drivers/push-notification-driver/index.dart';
import 'package:animus/rest/services/index.dart';

class ProfileScreenPresenter {
  final AuthService _authService;
  final GoogleAuthDriver _googleAuthDriver;
  final AppVersionDriver _appVersionDriver;
  final CacheDriver _cacheDriver;
  final NavigationDriver _navigationDriver;
  final PushNotificationDriver _pushNotificationDriver;

  final Signal<String> appVersionLabel = signal<String>('Versão indisponível');
  final Signal<bool> isLoadingInitialData = signal<bool>(false);
  final Signal<String?> generalError = signal<String?>(null);
  final Signal<AccountDto?> account = signal<AccountDto?>(null);

  bool _didLoadAppVersion = false;
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
      return 'Nome indisponível';
    }

    return normalizedName;
  });

  late final ReadonlySignal<String> displayEmail = computed(() {
    final String normalizedEmail = account.value?.email.trim() ?? '';
    if (normalizedEmail.isEmpty) {
      return 'E-mail indisponível';
    }

    return normalizedEmail;
  });

  ProfileScreenPresenter({
    required AuthService authService,
    required GoogleAuthDriver googleAuthDriver,
    required AppVersionDriver appVersionDriver,
    required CacheDriver cacheDriver,
    required NavigationDriver navigationDriver,
    required PushNotificationDriver pushNotificationDriver,
  }) : _authService = authService,
       _googleAuthDriver = googleAuthDriver,
       _appVersionDriver = appVersionDriver,
       _cacheDriver = cacheDriver,
       _navigationDriver = navigationDriver,
       _pushNotificationDriver = pushNotificationDriver;

  Future<void> initialize() async {
    await _initializeAppVersionLabel();

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

    final RestResponse<AccountDto> response = await _authService.getAccount();

    if (response.isFailure) {
      generalError.value = _resolveErrorMessage(
        response,
        fallback:
            'Não foi possível carregar o seu perfil agora. Tente novamente.',
      );
      isLoadingInitialData.value = false;
      return;
    }

    account.value = response.body;
    generalError.value = null;
    _didCompleteInitialLoad = true;
    isLoadingInitialData.value = false;
  }

  Future<void> signOut() async {
    try {
      unawaited(_pushNotificationDriver.clearUser().catchError((_) {}));
      await _googleAuthDriver.signOut();
    } catch (_) {}

    _cacheDriver.delete(CacheKeys.accessToken);
    _cacheDriver.delete(CacheKeys.refreshToken);
    _navigationDriver.goTo(Routes.signIn);
  }

  void goToForgotPassword() {
    _navigationDriver.goTo(
      Routes.getForgotPassword(previousRoute: Routes.profile),
    );
  }

  void goToArchivedAnalyses() {
    unawaited(_navigationDriver.pushTo(Routes.archivedAnalyses));
  }

  Future<void> updateDisplayName(String updatedName) async {
    final String normalizedName = updatedName.trim();
    if (normalizedName.isEmpty) {
      return;
    }

    final AccountDto? currentAccount = account.value;
    if (currentAccount == null) {
      return;
    }

    final RestResponse<AccountDto> response = await _authService.updateAccount(
      name: normalizedName,
    );

    if (response.isFailure) {
      return;
    }

    account.value = response.body;
  }

  void dispose() {
    appVersionLabel.dispose();
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

  Future<void> _initializeAppVersionLabel() async {
    if (_didLoadAppVersion) {
      return;
    }

    _didLoadAppVersion = true;

    try {
      final String version = (await _appVersionDriver.getVersion()).trim();
      if (version.isEmpty) {
        return;
      }

      appVersionLabel.value = 'v$version';
    } catch (_) {}
  }
}

final Provider<ProfileScreenPresenter>
profileScreenPresenterProvider = Provider.autoDispose<ProfileScreenPresenter>((
  Ref ref,
) {
  final AuthService authService = ref.watch(authServiceProvider);
  final GoogleAuthDriver googleAuthDriver = ref.watch(googleAuthDriverProvider);
  final AppVersionDriver appVersionDriver = ref.watch(appVersionDriverProvider);
  final CacheDriver cacheDriver = ref.watch(cacheDriverProvider);
  final NavigationDriver navigationDriver = ref.watch(navigationDriverProvider);
  final PushNotificationDriver pushNotificationDriver = ref.watch(
    pushNotificationDriverProvider,
  );

  final ProfileScreenPresenter presenter = ProfileScreenPresenter(
    authService: authService,
    googleAuthDriver: googleAuthDriver,
    appVersionDriver: appVersionDriver,
    cacheDriver: cacheDriver,
    navigationDriver: navigationDriver,
    pushNotificationDriver: pushNotificationDriver,
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
