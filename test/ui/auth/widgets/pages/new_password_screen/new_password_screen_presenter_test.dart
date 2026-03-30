import 'dart:async';

import 'package:animus/constants/routes.dart';
import 'package:animus/core/auth/interfaces/auth_service.dart';
import 'package:animus/core/shared/interfaces/navigation_driver.dart';
import 'package:animus/core/shared/responses/rest_response.dart';
import 'package:animus/ui/auth/widgets/pages/new_password_screen/new_password_screen_presenter.dart';
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

  NewPasswordScreenPresenter createPresenter() {
    return NewPasswordScreenPresenter(
      authService: authService,
      navigationDriver: navigationDriver,
      accountId: 'account-1',
    );
  }

  test('atualiza regras e score da senha conforme valor digitado', () {
    final NewPasswordScreenPresenter presenter = createPresenter();
    addTearDown(presenter.dispose);

    presenter.newPasswordControl.value = 'short';
    presenter.onPasswordChanged('short');

    expect(presenter.hasMinLength.value, isFalse);
    expect(presenter.hasUppercaseLetter.value, isFalse);
    expect(presenter.hasNumber.value, isFalse);
    expect(presenter.passwordStrengthScore.value, 0);

    presenter.newPasswordControl.value = 'password1';
    presenter.onPasswordChanged('password1');
    expect(presenter.hasMinLength.value, isTrue);
    expect(presenter.hasUppercaseLetter.value, isFalse);
    expect(presenter.hasNumber.value, isTrue);
    expect(presenter.passwordStrengthScore.value, 1);

    presenter.newPasswordControl.value = 'Password';
    presenter.onPasswordChanged('Password');
    expect(presenter.hasMinLength.value, isTrue);
    expect(presenter.hasUppercaseLetter.value, isTrue);
    expect(presenter.hasNumber.value, isFalse);
    expect(presenter.passwordStrengthScore.value, 2);

    presenter.newPasswordControl.value = 'Password1';
    presenter.onPasswordChanged('Password1');
    expect(presenter.hasMinLength.value, isTrue);
    expect(presenter.hasUppercaseLetter.value, isTrue);
    expect(presenter.hasNumber.value, isTrue);
    expect(presenter.passwordStrengthScore.value, 3);
  });

  test('alterna visibilidade dos campos de senha', () {
    final NewPasswordScreenPresenter presenter = createPresenter();
    addTearDown(presenter.dispose);

    expect(presenter.isPasswordVisible.value, isFalse);
    expect(presenter.isConfirmPasswordVisible.value, isFalse);

    presenter.togglePasswordVisibility();
    presenter.toggleConfirmPasswordVisibility();

    expect(presenter.isPasswordVisible.value, isTrue);
    expect(presenter.isConfirmPasswordVisible.value, isTrue);
  });

  group('submit', () {
    test('nao submete quando formulario e invalido', () async {
      final NewPasswordScreenPresenter presenter = createPresenter();
      addTearDown(presenter.dispose);

      await presenter.submit();

      verifyNever(
        () => authService.resetPassword(
          accountId: any(named: 'accountId'),
          newPassword: any(named: 'newPassword'),
        ),
      );
      expect(presenter.form.invalid, isTrue);
      expect(presenter.newPasswordControl.touched, isTrue);
      expect(presenter.confirmPasswordControl.touched, isTrue);
    });

    test('envia payload correto e navega para sign in no sucesso', () async {
      final NewPasswordScreenPresenter presenter = createPresenter();
      addTearDown(presenter.dispose);
      _fillValidForm(presenter);

      when(
        () => authService.resetPassword(
          accountId: 'account-1',
          newPassword: 'Password1',
        ),
      ).thenAnswer((_) async => RestResponse<void>(statusCode: 204));

      await presenter.submit();

      verify(
        () => authService.resetPassword(
          accountId: 'account-1',
          newPassword: 'Password1',
        ),
      ).called(1);
      verify(() => navigationDriver.goTo(Routes.signIn)).called(1);
      expect(presenter.generalError.value, isNull);
      expect(presenter.isSubmitting.value, isFalse);
    });

    test('exibe erro geral quando reset falha', () async {
      final NewPasswordScreenPresenter presenter = createPresenter();
      addTearDown(presenter.dispose);
      _fillValidForm(presenter);

      when(
        () => authService.resetPassword(
          accountId: 'account-1',
          newPassword: 'Password1',
        ),
      ).thenAnswer(
        (_) async => RestResponse<void>(
          statusCode: 422,
          errorMessage: 'Senha invalida',
          errorBody: <String, dynamic>{'message': 'Senha invalida'},
        ),
      );

      await presenter.submit();

      expect(presenter.generalError.value, 'Senha invalida');
      verifyNever(() => navigationDriver.goTo(any()));
      expect(presenter.isSubmitting.value, isFalse);
    });

    test('ignora submit duplicado enquanto requisicao esta em voo', () async {
      final Completer<RestResponse<void>> completer =
          Completer<RestResponse<void>>();
      final NewPasswordScreenPresenter presenter = createPresenter();
      addTearDown(presenter.dispose);
      _fillValidForm(presenter);

      when(
        () => authService.resetPassword(
          accountId: 'account-1',
          newPassword: 'Password1',
        ),
      ).thenAnswer((_) => completer.future);

      final Future<void> firstSubmit = presenter.submit();
      final Future<void> secondSubmit = presenter.submit();

      verify(
        () => authService.resetPassword(
          accountId: 'account-1',
          newPassword: 'Password1',
        ),
      ).called(1);
      expect(presenter.isSubmitting.value, isTrue);

      completer.complete(RestResponse<void>(statusCode: 204));
      await Future.wait(<Future<void>>[firstSubmit, secondSubmit]);

      expect(presenter.isSubmitting.value, isFalse);
    });
  });

  test('goToSignIn navega para tela de login', () {
    final NewPasswordScreenPresenter presenter = createPresenter();
    addTearDown(presenter.dispose);

    presenter.goToSignIn();

    verify(() => navigationDriver.goTo(Routes.signIn)).called(1);
  });
}

void _fillValidForm(NewPasswordScreenPresenter presenter) {
  presenter.newPasswordControl.value = 'Password1';
  presenter.confirmPasswordControl.value = 'Password1';
  presenter.onPasswordChanged('Password1');
}
