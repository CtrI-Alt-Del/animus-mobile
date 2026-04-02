import 'dart:async';

import 'package:animus/constants/cache_keys.dart';
import 'package:animus/constants/routes.dart';
import 'package:animus/core/auth/dtos/account_dto.dart';
import 'package:animus/core/auth/dtos/session_dto.dart';
import 'package:animus/core/auth/interfaces/auth_service.dart';
import 'package:animus/core/auth/interfaces/google_auth_driver.dart';
import 'package:animus/core/shared/interfaces/cache_driver.dart';
import 'package:animus/core/shared/interfaces/navigation_driver.dart';
import 'package:animus/core/shared/responses/rest_response.dart';
import 'package:animus/ui/auth/widgets/pages/sign_up_screen/sign_up_screen_presenter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../fakers/auth/account_dto_faker.dart';
import '../../../../../fakers/auth/session_dto_faker.dart';

class _MockAuthService extends Mock implements AuthService {}

class _MockGoogleAuthDriver extends Mock implements GoogleAuthDriver {}

class _MockCacheDriver extends Mock implements CacheDriver {}

class _MockNavigationDriver extends Mock implements NavigationDriver {}

void main() {
  late _MockAuthService authService;
  late _MockGoogleAuthDriver googleAuthDriver;
  late _MockCacheDriver cacheDriver;
  late _MockNavigationDriver navigationDriver;

  setUp(() {
    authService = _MockAuthService();
    googleAuthDriver = _MockGoogleAuthDriver();
    cacheDriver = _MockCacheDriver();
    navigationDriver = _MockNavigationDriver();
    when(() => cacheDriver.set(any(), any())).thenReturn(null);
    when(() => navigationDriver.canGoBack()).thenReturn(false);
    when(() => navigationDriver.goBack()).thenReturn(null);
    when(() => navigationDriver.goTo(any())).thenReturn(null);
  });

  SignUpScreenPresenter createPresenter() {
    return SignUpScreenPresenter(
      authService: authService,
      googleAuthDriver: googleAuthDriver,
      cacheDriver: cacheDriver,
      navigationDriver: navigationDriver,
    );
  }

  group('validacoes', () {
    late SignUpScreenPresenter presenter;

    setUp(() {
      presenter = SignUpScreenPresenter(
        authService: authService,
        googleAuthDriver: googleAuthDriver,
        cacheDriver: cacheDriver,
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
        googleAuthDriver: googleAuthDriver,
        cacheDriver: cacheDriver,
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
            RestResponse(body: AccountDtoFaker.fake(), statusCode: 201),
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
        googleAuthDriver: googleAuthDriver,
        cacheDriver: cacheDriver,
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
        googleAuthDriver: googleAuthDriver,
        cacheDriver: cacheDriver,
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
        googleAuthDriver: googleAuthDriver,
        cacheDriver: cacheDriver,
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
        googleAuthDriver: googleAuthDriver,
        cacheDriver: cacheDriver,
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

    test('ignora submit enquanto auth google esta em voo', () async {
      final SignUpScreenPresenter presenter = createPresenter();
      addTearDown(presenter.dispose);
      _fillValidForm(presenter);
      final Completer<String?> completer = Completer<String?>();

      when(
        () => googleAuthDriver.requestIdToken(),
      ).thenAnswer((_) => completer.future);

      final Future<void> googleFuture = presenter.continueWithGoogle();

      expect(presenter.isGoogleSubmitting.value, isTrue);
      expect(presenter.canSubmit.value, isFalse);
      expect(presenter.canTriggerGoogleAuth.value, isFalse);

      await presenter.submit();

      verifyNever(
        () => authService.signUp(
          name: any(named: 'name'),
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      );

      completer.complete(null);
      await googleFuture;
    });
  });

  group('continueWithGoogle', () {
    test('persiste tokens e navega para home no sucesso', () async {
      final SignUpScreenPresenter presenter = createPresenter();
      addTearDown(presenter.dispose);

      when(
        () => googleAuthDriver.requestIdToken(),
      ).thenAnswer((_) async => 'google-id-token');
      when(
        () => authService.signInWithGoogle(idToken: 'google-id-token'),
      ).thenAnswer(
        (_) async => RestResponse<SessionDto>(
          statusCode: 200,
          body: SessionDtoFaker.fake(),
        ),
      );

      await presenter.continueWithGoogle();

      verify(() => googleAuthDriver.requestIdToken()).called(1);
      verify(
        () => authService.signInWithGoogle(idToken: 'google-id-token'),
      ).called(1);
      verify(
        () => cacheDriver.set(CacheKeys.accessToken, 'access-token'),
      ).called(1);
      verify(
        () => cacheDriver.set(CacheKeys.refreshToken, 'refresh-token'),
      ).called(1);
      verify(() => navigationDriver.goTo(Routes.home)).called(1);
      expect(presenter.generalError.value, isNull);
      expect(presenter.isGoogleSubmitting.value, isFalse);
    });

    test('ignora cancelamento silencioso do usuario', () async {
      final SignUpScreenPresenter presenter = createPresenter();
      addTearDown(presenter.dispose);

      when(
        () => googleAuthDriver.requestIdToken(),
      ).thenAnswer((_) async => null);

      await presenter.continueWithGoogle();

      verify(() => googleAuthDriver.requestIdToken()).called(1);
      verifyNever(
        () => authService.signInWithGoogle(idToken: any(named: 'idToken')),
      );
      verifyNever(() => cacheDriver.set(any(), any()));
      verifyNever(() => navigationDriver.goTo(any()));
      expect(presenter.generalError.value, isNull);
      expect(presenter.isGoogleSubmitting.value, isFalse);
    });

    test('exibe erro generico quando o sdk falha antes da api', () async {
      final SignUpScreenPresenter presenter = createPresenter();
      addTearDown(presenter.dispose);

      when(() => googleAuthDriver.requestIdToken()).thenThrow(Exception('sdk'));

      await presenter.continueWithGoogle();

      verify(() => googleAuthDriver.requestIdToken()).called(1);
      verifyNever(
        () => authService.signInWithGoogle(idToken: any(named: 'idToken')),
      );
      verifyNever(() => navigationDriver.goTo(any()));
      expect(
        presenter.generalError.value,
        'Nao foi possivel continuar com Google agora. Tente novamente.',
      );
      expect(presenter.isGoogleSubmitting.value, isFalse);
    });

    test('exibe erro da api quando sign in com google falha', () async {
      final SignUpScreenPresenter presenter = createPresenter();
      addTearDown(presenter.dispose);

      when(
        () => googleAuthDriver.requestIdToken(),
      ).thenAnswer((_) async => 'google-id-token');
      when(
        () => authService.signInWithGoogle(idToken: 'google-id-token'),
      ).thenAnswer(
        (_) async => RestResponse<SessionDto>(
          statusCode: 500,
          errorMessage: 'Falha no login social.',
          errorBody: <String, dynamic>{'message': 'Falha no login social.'},
        ),
      );

      await presenter.continueWithGoogle();

      verify(
        () => authService.signInWithGoogle(idToken: 'google-id-token'),
      ).called(1);
      verifyNever(() => cacheDriver.set(any(), any()));
      verifyNever(() => navigationDriver.goTo(any()));
      expect(presenter.generalError.value, 'Falha no login social.');
      expect(presenter.isGoogleSubmitting.value, isFalse);
    });

    test(
      'ignora google auth enquanto submit de credenciais esta em voo',
      () async {
        final SignUpScreenPresenter presenter = createPresenter();
        addTearDown(presenter.dispose);
        _fillValidForm(presenter);
        final Completer<RestResponse<AccountDto>> completer =
            Completer<RestResponse<AccountDto>>();

        when(
          () => authService.signUp(
            name: any(named: 'name'),
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) => completer.future);

        final Future<void> submitFuture = presenter.submit();

        expect(presenter.isSubmitting.value, isTrue);
        expect(presenter.canSubmit.value, isFalse);
        expect(presenter.canTriggerGoogleAuth.value, isFalse);

        await presenter.continueWithGoogle();

        verifyNever(() => googleAuthDriver.requestIdToken());
        expect(presenter.isGoogleSubmitting.value, isFalse);

        completer.complete(
          RestResponse<AccountDto>(statusCode: 500, errorMessage: 'ignored'),
        );
        await submitFuture;
      },
    );
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
