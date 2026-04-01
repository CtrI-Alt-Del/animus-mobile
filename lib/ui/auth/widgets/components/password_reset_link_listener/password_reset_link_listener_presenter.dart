import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:animus/constants/routes.dart';
import 'package:animus/core/auth/interfaces/auth_service.dart';
import 'package:animus/core/auth/interfaces/password_reset_link_driver.dart';
import 'package:animus/core/shared/interfaces/navigation_driver.dart';
import 'package:animus/core/shared/responses/rest_response.dart';
import 'package:animus/drivers/navigation/index.dart';
import 'package:animus/drivers/password-reset-link-driver/index.dart';
import 'package:animus/rest/services/index.dart';

class PasswordResetLinkListenerPresenter {
  final PasswordResetLinkDriver _passwordResetLinkDriver;
  final AuthService _authService;
  final NavigationDriver _navigationDriver;

  final Signal<bool> isHandlingToken = signal<bool>(false);

  StreamSubscription<String>? _subscription;

  PasswordResetLinkListenerPresenter({
    required PasswordResetLinkDriver passwordResetLinkDriver,
    required AuthService authService,
    required NavigationDriver navigationDriver,
  }) : _passwordResetLinkDriver = passwordResetLinkDriver,
       _authService = authService,
       _navigationDriver = navigationDriver;

  void start() {
    _subscription ??= _passwordResetLinkDriver.watchResetTokens().listen(
      handleToken,
      onError: (Object error, StackTrace stackTrace) {
        _navigationDriver.goTo(
          Routes.getForgotPassword(errorCode: 'invalid_reset_link'),
        );
      },
    );
  }

  Future<void> handleToken(String token) async {
    if (isHandlingToken.value) {
      return;
    }

    isHandlingToken.value = true;

    try {
      final RestResponse<String> response = await _authService.verifyResetToken(
        token: token,
      );

      if (response.isSuccessful) {
        _navigationDriver.goTo(Routes.getNewPassword(accountId: response.body));
        return;
      }

      _navigationDriver.goTo(
        Routes.getForgotPassword(errorCode: 'invalid_reset_link'),
      );
    } catch (_) {
      _navigationDriver.goTo(
        Routes.getForgotPassword(errorCode: 'invalid_reset_link'),
      );
    } finally {
      isHandlingToken.value = false;
    }
  }

  void dispose() {
    _subscription?.cancel();
    isHandlingToken.dispose();
  }
}

final Provider<PasswordResetLinkListenerPresenter>
passwordResetLinkListenerPresenterProvider =
    Provider<PasswordResetLinkListenerPresenter>((Ref ref) {
      final PasswordResetLinkDriver passwordResetLinkDriver = ref.watch(
        passwordResetLinkDriverProvider,
      );
      final AuthService authService = ref.watch(authServiceProvider);
      final NavigationDriver navigationDriver = ref.watch(
        navigationDriverProvider,
      );

      final PasswordResetLinkListenerPresenter presenter =
          PasswordResetLinkListenerPresenter(
            passwordResetLinkDriver: passwordResetLinkDriver,
            authService: authService,
            navigationDriver: navigationDriver,
          );

      ref.onDispose(presenter.dispose);
      return presenter;
    });
