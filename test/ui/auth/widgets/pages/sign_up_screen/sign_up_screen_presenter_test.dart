import 'package:animus/constants/routes.dart';
import 'package:animus/core/auth/interfaces/auth_service.dart';
import 'package:animus/core/shared/interfaces/navigation_driver.dart';
import 'package:animus/core/shared/responses/rest_response.dart';
import 'package:animus/ui/auth/widgets/pages/sign_up_screen/sign_up_screen_presenter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../fakers/auth/account_dto_faker.dart';

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

  group('validacoes', () {
    late SignUpScreenPresenter presenter;

    setUp(() {
      presenter = SignUpScreenPresenter(
        authService: authService,
        navigationDriver: navigationDriver,
      );
    });

    tearDown(() {
      presenter.dispose();
    });

    test('valida regras de senha e confirmacao', () {
      presenter.passwordControl.value = 'short';
      presenter.onPasswordChanged('short');
      presenter.confirmPasswordControl.value = 'different';
      presenter.form.markAllAsTouched();
      presenter.form.updateValueAndValidity();

      expect(
        presenter.fieldErrorMessage(presenter.passwordControl),
        'A senha precisa ter no minimo 8 caracteres.',
      );
      expect(presenter.hasMinLength.value, isFalse);
      expect(presenter.hasUppercaseLetter.value, isFalse);
      expect(presenter.hasNumber.value, isFalse);
      expect(presenter.passwordStrengthScore.value, 0);
      expect(
        presenter.fieldErrorMessage(presenter.confirmPasswordControl),
        'As senhas precisam ser iguais.',
      );
      expect(presenter.termsAcceptedControl.valid, isFalse);

      presenter.passwordControl.value = 'password1';
      presenter.onPasswordChanged('password1');
      presenter.passwordControl.markAsTouched();
      presenter.passwordControl.updateValueAndValidity();
      expect(
        presenter.fieldErrorMessage(presenter.passwordControl),
        'A senha precisa ter pelo menos 1 letra maiuscula.',
      );

      presenter.passwordControl.value = 'Password';
      presenter.onPasswordChanged('Password');
      presenter.passwordControl.markAsTouched();
      presenter.passwordControl.updateValueAndValidity();
      expect(
        presenter.fieldErrorMessage(presenter.passwordControl),
        'A senha precisa ter pelo menos 1 numero.',
      );
    });
  });

  group('submit', () {
    test('navega para confirmacao no sucesso', () async {
      final presenter = SignUpScreenPresenter(
        authService: authService,
        navigationDriver: navigationDriver,
      );
      addTearDown(presenter.dispose);
      _fillValidForm(presenter);

      when(
        () => authService.signUp(
          name: 'Ada Lovelace',
          email: 'ada@example.com',
          password: 'Password1',
        ),
      ).thenAnswer(
        (_) async =>
            RestResponse(body: AccountDtoFaker.make(), statusCode: 201),
      );

      await presenter.submit();

      verify(
        () => navigationDriver.goTo(
          Routes.getEmailConfirmation(email: 'ada@example.com'),
        ),
      ).called(1);
      verify(
        () => authService.signUp(
          name: 'Ada Lovelace',
          email: 'ada@example.com',
          password: 'Password1',
        ),
      ).called(1);
    });

    test('nao submete enquanto termos nao forem aceitos', () async {
      final presenter = SignUpScreenPresenter(
        authService: authService,
        navigationDriver: navigationDriver,
      );
      addTearDown(presenter.dispose);
      _fillValidForm(presenter, acceptTerms: false);

      await presenter.submit();

      verifyNever(
        () => authService.signUp(
          name: any(named: 'name'),
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      );
      expect(presenter.termsAcceptedControl.valid, isFalse);
    });

    test('mapeia conflito 409 para erro inline de email', () async {
      final presenter = SignUpScreenPresenter(
        authService: authService,
        navigationDriver: navigationDriver,
      );
      addTearDown(presenter.dispose);
      _fillValidForm(presenter);

      when(
        () => authService.signUp(
          name: any(named: 'name'),
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer(
        (_) async => RestResponse(
          statusCode: 409,
          errorMessage: 'E-mail ja cadastrado',
          errorBody: <String, dynamic>{'message': 'E-mail ja cadastrado'},
        ),
      );

      await presenter.submit();

      expect(presenter.emailControl.hasError('server'), isTrue);
      expect(
        presenter.fieldErrorMessage(presenter.emailControl),
        'Este e-mail ja esta em uso.',
      );
      expect(presenter.generalError.value, isNull);
    });

    test('mapeia 422 para erros reconhecidos de campo', () async {
      final presenter = SignUpScreenPresenter(
        authService: authService,
        navigationDriver: navigationDriver,
      );
      addTearDown(presenter.dispose);
      _fillValidForm(presenter);

      when(
        () => authService.signUp(
          name: any(named: 'name'),
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer(
        (_) async => RestResponse(
          statusCode: 422,
          errorMessage: 'Erro de validacao',
          errorBody: <String, dynamic>{
            'detail': <Map<String, dynamic>>[
              <String, dynamic>{
                'loc': <String>['body', 'email'],
                'msg': 'Email invalido',
              },
              <String, dynamic>{
                'loc': <String>['body', 'password'],
                'msg': 'Senha fraca',
              },
            ],
          },
        ),
      );

      await presenter.submit();

      expect(presenter.emailControl.getError('server'), 'Email invalido');
      expect(presenter.passwordControl.getError('server'), 'Senha fraca');
      expect(presenter.generalError.value, isNull);
    });

    test('exibe erro geral em falha nao tratada', () async {
      final presenter = SignUpScreenPresenter(
        authService: authService,
        navigationDriver: navigationDriver,
      );
      addTearDown(presenter.dispose);
      _fillValidForm(presenter);

      when(
        () => authService.signUp(
          name: any(named: 'name'),
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer(
        (_) async => RestResponse(
          statusCode: 500,
          errorMessage: 'Falha inesperada',
          errorBody: <String, dynamic>{'message': 'Falha inesperada'},
        ),
      );

      await presenter.submit();

      expect(presenter.generalError.value, 'Falha inesperada');
    });
  });
}

void _fillValidForm(
  SignUpScreenPresenter presenter, {
  bool acceptTerms = true,
}) {
  presenter.nameControl.value = 'Ada Lovelace';
  presenter.emailControl.value = 'ada@example.com';
  presenter.passwordControl.value = 'Password1';
  presenter.confirmPasswordControl.value = 'Password1';
  presenter.termsAcceptedControl.value = acceptTerms;
  presenter.onPasswordChanged('Password1');
}
