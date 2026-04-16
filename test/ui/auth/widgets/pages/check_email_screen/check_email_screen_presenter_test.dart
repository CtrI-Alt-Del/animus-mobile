import 'dart:async';

import 'package:animus/core/auth/interfaces/auth_service.dart';
import 'package:animus/core/shared/interfaces/navigation_driver.dart';
import 'package:animus/core/shared/responses/rest_response.dart';
import 'package:animus/ui/auth/widgets/pages/check_email_screen/check_email_screen_presenter.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthService extends Mock implements AuthService {}

class _MockNavigationDriver extends Mock implements NavigationDriver {}

void main() {
  late _MockAuthService authService;
  late _MockNavigationDriver navigationDriver;

  setUp(() {
    authService = _MockAuthService();
    navigationDriver = _MockNavigationDriver();

    when(() => navigationDriver.canGoBack()).thenReturn(false);
    when(() => navigationDriver.goBack()).thenReturn(null);
    when(() => navigationDriver.goTo(any())).thenReturn(null);
  });

  test('inicia countdown em 60 segundos e formata label em mm:ss', () {
    fakeAsync((FakeAsync async) {
      final CheckEmailScreenPresenter presenter = CheckEmailScreenPresenter(
        authService: authService,
        navigationDriver: navigationDriver,
        email: 'ada@example.com',
      );

      expect(presenter.resendCountdown.value, 60);
      expect(presenter.resendCountdownLabel, '01:00');

      async.elapse(const Duration(seconds: 1));

      expect(presenter.resendCountdown.value, 59);
      expect(presenter.resendCountdownLabel, '00:59');

      presenter.dispose();
    });
  });

  test('nao reenvia enquanto countdown ainda estiver ativo', () async {
    final CheckEmailScreenPresenter presenter = CheckEmailScreenPresenter(
      authService: authService,
      navigationDriver: navigationDriver,
      email: 'ada@example.com',
    );
    addTearDown(presenter.dispose);

    await presenter.resendResetOtp();

    verifyNever(
      () => authService.resendResetPasswordOtp(email: any(named: 'email')),
    );
  });

  test(
    'reenvia link, exibe feedback e reinicia countdown no sucesso',
    () async {
      final CheckEmailScreenPresenter presenter = CheckEmailScreenPresenter(
        authService: authService,
        navigationDriver: navigationDriver,
        email: 'ada@example.com',
      );
      addTearDown(presenter.dispose);
      presenter.resendCountdown.value = 0;

      when(
        () => authService.resendResetPasswordOtp(email: 'ada@example.com'),
      ).thenAnswer((_) async => RestResponse<void>(statusCode: 204));

      await presenter.resendResetOtp();

      verify(
        () => authService.resendResetPasswordOtp(email: 'ada@example.com'),
      ).called(1);
      expect(
        presenter.feedbackMessage.value,
        'Enviamos um novo codigo OTP para ada@example.com.',
      );
      expect(presenter.generalError.value, isNull);
      expect(presenter.resendCountdown.value, 60);
      expect(presenter.isResending.value, isFalse);
    },
  );

  test('exibe erro geral quando reenvio falha', () async {
    final CheckEmailScreenPresenter presenter = CheckEmailScreenPresenter(
      authService: authService,
      navigationDriver: navigationDriver,
      email: 'ada@example.com',
    );
    addTearDown(presenter.dispose);
    presenter.resendCountdown.value = 0;

    when(
      () => authService.resendResetPasswordOtp(email: 'ada@example.com'),
    ).thenAnswer(
      (_) async => RestResponse<void>(
        statusCode: 500,
        errorMessage: 'Falha ao reenviar',
        errorBody: <String, dynamic>{'message': 'Falha ao reenviar'},
      ),
    );

    await presenter.resendResetOtp();

    expect(presenter.generalError.value, 'Falha ao reenviar');
    expect(presenter.feedbackMessage.value, isNull);
    expect(presenter.isResending.value, isFalse);
  });

  test('ignora reenvio duplicado enquanto requisicao esta em voo', () async {
    final Completer<RestResponse<void>> completer =
        Completer<RestResponse<void>>();
    final CheckEmailScreenPresenter presenter = CheckEmailScreenPresenter(
      authService: authService,
      navigationDriver: navigationDriver,
      email: 'ada@example.com',
    );
    addTearDown(presenter.dispose);
    presenter.resendCountdown.value = 0;

    when(
      () => authService.resendResetPasswordOtp(email: 'ada@example.com'),
    ).thenAnswer((_) => completer.future);

    final Future<void> firstResend = presenter.resendResetOtp();
    final Future<void> secondResend = presenter.resendResetOtp();

    verify(
      () => authService.resendResetPasswordOtp(email: 'ada@example.com'),
    ).called(1);
    expect(presenter.isResending.value, isTrue);

    completer.complete(RestResponse<void>(statusCode: 204));
    await Future.wait(<Future<void>>[firstResend, secondResend]);

    expect(presenter.isResending.value, isFalse);
  });
}
