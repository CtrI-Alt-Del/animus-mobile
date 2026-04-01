import 'dart:async';

import 'package:animus/constants/routes.dart';
import 'package:animus/core/auth/interfaces/auth_service.dart';
import 'package:animus/core/auth/interfaces/password_reset_link_driver.dart';
import 'package:animus/core/shared/interfaces/navigation_driver.dart';
import 'package:animus/core/shared/responses/rest_response.dart';
import 'package:animus/ui/auth/widgets/components/password_reset_link_listener/password_reset_link_listener_presenter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthService extends Mock implements AuthService {}

class _MockPasswordResetLinkDriver extends Mock
    implements PasswordResetLinkDriver {}

class _MockNavigationDriver extends Mock implements NavigationDriver {}

void main() {
  late _MockAuthService authService;
  late _MockPasswordResetLinkDriver passwordResetLinkDriver;
  late _MockNavigationDriver navigationDriver;

  setUp(() {
    authService = _MockAuthService();
    passwordResetLinkDriver = _MockPasswordResetLinkDriver();
    navigationDriver = _MockNavigationDriver();

    when(() => navigationDriver.canGoBack()).thenReturn(false);
    when(() => navigationDriver.goBack()).thenReturn(null);
    when(() => navigationDriver.goTo(any())).thenReturn(null);
  });

  test('start escuta tokens e navega para nova senha no sucesso', () async {
    final StreamController<String> controller = StreamController<String>();
    final PasswordResetLinkListenerPresenter presenter =
        PasswordResetLinkListenerPresenter(
          passwordResetLinkDriver: passwordResetLinkDriver,
          authService: authService,
          navigationDriver: navigationDriver,
        );
    addTearDown(() async {
      presenter.dispose();
      await controller.close();
    });

    when(
      () => passwordResetLinkDriver.watchResetTokens(),
    ).thenAnswer((_) => controller.stream);
    when(() => authService.verifyResetToken(token: 'token-123')).thenAnswer(
      (_) async => RestResponse<String>(statusCode: 200, body: 'account-1'),
    );

    presenter.start();
    controller.add('token-123');
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    verify(() => authService.verifyResetToken(token: 'token-123')).called(1);
    verify(
      () =>
          navigationDriver.goTo(Routes.getNewPassword(accountId: 'account-1')),
    ).called(1);
  });

  test('start navega para forgot password quando stream falha', () async {
    final StreamController<String> controller = StreamController<String>();
    final PasswordResetLinkListenerPresenter presenter =
        PasswordResetLinkListenerPresenter(
          passwordResetLinkDriver: passwordResetLinkDriver,
          authService: authService,
          navigationDriver: navigationDriver,
        );
    addTearDown(() async {
      presenter.dispose();
      await controller.close();
    });

    when(
      () => passwordResetLinkDriver.watchResetTokens(),
    ).thenAnswer((_) => controller.stream);

    presenter.start();
    controller.addError(Exception('invalid link'));
    await Future<void>.delayed(Duration.zero);

    verify(
      () => navigationDriver.goTo(
        Routes.getForgotPassword(errorCode: 'invalid_reset_link'),
      ),
    ).called(1);
  });

  test(
    'handleToken navega para forgot password quando validacao falha',
    () async {
      final PasswordResetLinkListenerPresenter presenter =
          PasswordResetLinkListenerPresenter(
            passwordResetLinkDriver: passwordResetLinkDriver,
            authService: authService,
            navigationDriver: navigationDriver,
          );
      addTearDown(presenter.dispose);

      when(() => authService.verifyResetToken(token: 'token-123')).thenAnswer(
        (_) async => RestResponse<String>(
          statusCode: 410,
          errorMessage: 'Link expirado',
        ),
      );

      await presenter.handleToken('token-123');

      verify(
        () => navigationDriver.goTo(
          Routes.getForgotPassword(errorCode: 'invalid_reset_link'),
        ),
      ).called(1);
      expect(presenter.isHandlingToken.value, isFalse);
    },
  );

  test(
    'handleToken ignora chamadas concorrentes enquanto token esta em voo',
    () async {
      final Completer<RestResponse<String>> completer =
          Completer<RestResponse<String>>();
      final PasswordResetLinkListenerPresenter presenter =
          PasswordResetLinkListenerPresenter(
            passwordResetLinkDriver: passwordResetLinkDriver,
            authService: authService,
            navigationDriver: navigationDriver,
          );
      addTearDown(presenter.dispose);

      when(
        () => authService.verifyResetToken(token: 'token-123'),
      ).thenAnswer((_) => completer.future);

      final Future<void> firstCall = presenter.handleToken('token-123');
      final Future<void> secondCall = presenter.handleToken('token-456');

      verify(() => authService.verifyResetToken(token: 'token-123')).called(1);
      verifyNever(() => authService.verifyResetToken(token: 'token-456'));
      expect(presenter.isHandlingToken.value, isTrue);

      completer.complete(
        RestResponse<String>(statusCode: 200, body: 'account-1'),
      );

      await Future.wait(<Future<void>>[firstCall, secondCall]);

      expect(presenter.isHandlingToken.value, isFalse);
    },
  );
}
