import 'dart:async';

import 'package:animus/constants/routes.dart';
import 'package:animus/core/auth/interfaces/auth_service.dart';
import 'package:animus/core/shared/interfaces/navigation_driver.dart';
import 'package:animus/core/shared/responses/rest_response.dart';
import 'package:animus/ui/auth/widgets/pages/forgot_password_screen/forgot_password_screen_presenter.dart';
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

  ForgotPasswordScreenPresenter createPresenter({String? initialErrorCode}) {
    return ForgotPasswordScreenPresenter(
      authService: authService,
      navigationDriver: navigationDriver,
      initialErrorCode: initialErrorCode,
    );
  }

  test('inicializa erro quando recebe invalid_reset_link', () {
    final ForgotPasswordScreenPresenter presenter = createPresenter(
      initialErrorCode: 'invalid_reset_link',
    );
    addTearDown(presenter.dispose);

    expect(
      presenter.generalError.value,
      'O link de redefinicao e invalido ou expirou. Solicite um novo link.',
    );
  });

  group('submit', () {
    test('nao submete quando formulario e invalido', () async {
      final ForgotPasswordScreenPresenter presenter = createPresenter();
      addTearDown(presenter.dispose);

      await presenter.submit();

      verifyNever(() => authService.forgotPassword(email: any(named: 'email')));
      expect(presenter.form.invalid, isTrue);
      expect(presenter.emailControl.touched, isTrue);
    });

    test('navega para check email no sucesso', () async {
      final ForgotPasswordScreenPresenter presenter = createPresenter();
      addTearDown(presenter.dispose);
      presenter.emailControl.value = 'ada@example.com';

      when(
        () => authService.forgotPassword(email: 'ada@example.com'),
      ).thenAnswer((_) async => RestResponse<void>(statusCode: 204));

      await presenter.submit();

      verify(
        () => authService.forgotPassword(email: 'ada@example.com'),
      ).called(1);
      verify(
        () => navigationDriver.goTo(
          Routes.getCheckEmail(email: 'ada@example.com'),
        ),
      ).called(1);
      expect(presenter.generalError.value, isNull);
      expect(presenter.isSubmitting.value, isFalse);
    });

    test('exibe erro geral quando forgot password falha', () async {
      final ForgotPasswordScreenPresenter presenter = createPresenter();
      addTearDown(presenter.dispose);
      presenter.emailControl.value = 'ada@example.com';

      when(
        () => authService.forgotPassword(email: 'ada@example.com'),
      ).thenAnswer(
        (_) async => RestResponse<void>(
          statusCode: 500,
          errorMessage: 'Falha ao enviar link',
          errorBody: <String, dynamic>{'message': 'Falha ao enviar link'},
        ),
      );

      await presenter.submit();

      expect(presenter.generalError.value, 'Falha ao enviar link');
      verifyNever(() => navigationDriver.goTo(any()));
      expect(presenter.isSubmitting.value, isFalse);
    });

    test('ignora submit duplicado enquanto requisicao esta em voo', () async {
      final Completer<RestResponse<void>> completer =
          Completer<RestResponse<void>>();
      final ForgotPasswordScreenPresenter presenter = createPresenter();
      addTearDown(presenter.dispose);
      presenter.emailControl.value = 'ada@example.com';

      when(
        () => authService.forgotPassword(email: 'ada@example.com'),
      ).thenAnswer((_) => completer.future);

      final Future<void> firstSubmit = presenter.submit();
      final Future<void> secondSubmit = presenter.submit();

      verify(
        () => authService.forgotPassword(email: 'ada@example.com'),
      ).called(1);
      expect(presenter.isSubmitting.value, isTrue);

      completer.complete(RestResponse<void>(statusCode: 204));
      await Future.wait(<Future<void>>[firstSubmit, secondSubmit]);

      expect(presenter.isSubmitting.value, isFalse);
    });
  });

  test('goToSignIn navega para tela de login', () {
    final ForgotPasswordScreenPresenter presenter = createPresenter();
    addTearDown(presenter.dispose);

    presenter.goToSignIn();

    verify(() => navigationDriver.goTo(Routes.signIn)).called(1);
  });
}
