import 'package:animus/constants/cache_keys.dart';
import 'package:animus/constants/routes.dart';
import 'package:animus/core/auth/interfaces/auth_service.dart';
import 'package:animus/core/shared/interfaces/cache_driver.dart';
import 'package:animus/core/shared/interfaces/navigation_driver.dart';
import 'package:animus/core/shared/responses/rest_response.dart';
import 'package:animus/ui/auth/widgets/pages/email_confirmation_screen/email_confirmation_screen_presenter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../fakers/auth/session_dto_faker.dart';

class _MockAuthService extends Mock implements AuthService {}

class _MockNavigationDriver extends Mock implements NavigationDriver {}

class _InMemoryCacheDriver implements CacheDriver {
  final Map<String, String> values = <String, String>{};

  @override
  void delete(String key) {
    values.remove(key);
  }

  @override
  String? get(String key) {
    return values[key];
  }

  @override
  void set(String key, String value) {
    values[key] = value;
  }
}

void main() {
  late _MockAuthService authService;
  late _MockNavigationDriver navigationDriver;
  late _InMemoryCacheDriver cacheDriver;

  setUp(() {
    authService = _MockAuthService();
    navigationDriver = _MockNavigationDriver();
    cacheDriver = _InMemoryCacheDriver();

    when(() => navigationDriver.canGoBack()).thenReturn(false);
    when(() => navigationDriver.goBack()).thenReturn(null);
    when(() => navigationDriver.goTo(any())).thenReturn(null);
  });

  test('verifyOtp persiste tokens e navega para home no sucesso', () async {
    final presenter = EmailConfirmationScreenPresenter(
      email: 'ada@example.com',
      authService: authService,
      cacheDriver: cacheDriver,
      navigationDriver: navigationDriver,
    );
    addTearDown(presenter.dispose);
    presenter.otpControl.value = '123456';

    when(
      () => authService.verifyEmail(email: 'ada@example.com', otp: '123456'),
    ).thenAnswer(
      (_) async => RestResponse(
        statusCode: 200,
        body: SessionDtoFaker.fake(
          accessTokenValue: 'access-token',
          refreshTokenValue: 'refresh-token',
        ),
      ),
    );

    await presenter.verifyOtp();

    expect(cacheDriver.get(CacheKeys.accessToken), 'access-token');
    expect(cacheDriver.get(CacheKeys.refreshToken), 'refresh-token');
    verify(() => navigationDriver.goTo(Routes.home)).called(1);
  });

  test('verifyOtp mapeia erro de otp para feedback inline', () async {
    final presenter = EmailConfirmationScreenPresenter(
      email: 'ada@example.com',
      authService: authService,
      cacheDriver: cacheDriver,
      navigationDriver: navigationDriver,
    );
    addTearDown(presenter.dispose);
    presenter.otpControl.value = '123456';

    when(
      () => authService.verifyEmail(
        email: any(named: 'email'),
        otp: any(named: 'otp'),
      ),
    ).thenAnswer(
      (_) async => RestResponse(
        statusCode: 422,
        errorMessage: 'Codigo invalido',
        errorBody: <String, dynamic>{'message': 'Codigo invalido'},
      ),
    );

    await presenter.verifyOtp();

    expect(presenter.otpControl.getError('server'), 'Codigo invalido');
    expect(presenter.otpErrorMessage(), 'Codigo invalido');
    expect(presenter.generalError.value, isNull);
  });

  test(
    'resendVerificationEmail exibe feedback ao reenviar com sucesso',
    () async {
      final presenter = EmailConfirmationScreenPresenter(
        email: 'ada@example.com',
        authService: authService,
        cacheDriver: cacheDriver,
        navigationDriver: navigationDriver,
      );
      addTearDown(presenter.dispose);

      when(
        () => authService.resendVerificationEmail(email: 'ada@example.com'),
      ).thenAnswer((_) async => RestResponse<void>(statusCode: 204));

      await presenter.resendVerificationEmail();

      expect(
        presenter.feedbackMessage.value,
        'Enviamos um novo codigo OTP para ada@example.com.',
      );
      expect(presenter.generalError.value, isNull);
      expect(presenter.resendCountdown.value, 30);
    },
  );

  test(
    'resendVerificationEmail exibe erro geral quando o reenvio falha',
    () async {
      final presenter = EmailConfirmationScreenPresenter(
        email: 'ada@example.com',
        authService: authService,
        cacheDriver: cacheDriver,
        navigationDriver: navigationDriver,
      );
      addTearDown(presenter.dispose);

      when(
        () => authService.resendVerificationEmail(email: 'ada@example.com'),
      ).thenAnswer(
        (_) async => RestResponse<void>(
          statusCode: 500,
          errorMessage: 'Falha ao reenviar',
          errorBody: <String, dynamic>{'message': 'Falha ao reenviar'},
        ),
      );

      await presenter.resendVerificationEmail();

      expect(presenter.generalError.value, 'Falha ao reenviar');
      expect(presenter.feedbackMessage.value, isNull);
    },
  );
}
