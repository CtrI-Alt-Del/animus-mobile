import 'dart:async';

import 'package:animus/constants/cache_keys.dart';
import 'package:animus/constants/routes.dart';
import 'package:animus/core/auth/dtos/session_dto.dart';
import 'package:animus/core/auth/interfaces/auth_service.dart';
import 'package:animus/core/auth/interfaces/google_auth_driver.dart';
import 'package:animus/core/shared/interfaces/cache_driver.dart';
import 'package:animus/core/shared/interfaces/navigation_driver.dart';
import 'package:animus/core/shared/responses/rest_response.dart';
import 'package:animus/ui/auth/widgets/pages/sign_in_screen/sign_in_screen_presenter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

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

  SignInScreenPresenter createPresenter() {
    return SignInScreenPresenter(
      authService: authService,
      googleAuthDriver: googleAuthDriver,
      cacheDriver: cacheDriver,
      navigationDriver: navigationDriver,
    );
  }

  group('submit', () {
    test('persiste tokens e navega para home no sucesso', () async {
      final SignInScreenPresenter presenter = createPresenter();
      addTearDown(presenter.dispose);
      _fillValidForm(presenter);

      when(
        () =>
            authService.signIn(email: 'ada@example.com', password: 'Password1'),
      ).thenAnswer(
        (_) async => RestResponse<SessionDto>(
          statusCode: 200,
          body: SessionDtoFaker.fake(),
        ),
      );

      await presenter.submit();

      verify(
        () => cacheDriver.set(CacheKeys.accessToken, 'access-token'),
      ).called(1);
      verify(
        () => cacheDriver.set(CacheKeys.refreshToken, 'refresh-token'),
      ).called(1);
      verify(() => navigationDriver.goTo(Routes.home)).called(1);
      expect(presenter.generalError.value, isNull);
      expect(presenter.isSubmitting.value, isFalse);
    });

    test('exibe erro generico quando sign in retorna 401', () async {
      final SignInScreenPresenter presenter = createPresenter();
      addTearDown(presenter.dispose);
      _fillValidForm(presenter);

      when(
        () => authService.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer(
        (_) async => RestResponse<SessionDto>(
          statusCode: 401,
          errorMessage: 'backend message should be ignored',
          errorBody: <String, dynamic>{
            'message': 'backend message should be ignored',
          },
        ),
      );

      await presenter.submit();

      expect(presenter.generalError.value, 'E-mail ou senha incorretos.');
      verifyNever(() => cacheDriver.set(any(), any()));
      verifyNever(() => navigationDriver.goTo(any()));
    });

    test(
      'reenvia verificacao e navega para confirmacao quando retorna 403',
      () async {
        final SignInScreenPresenter presenter = createPresenter();
        addTearDown(presenter.dispose);
        _fillValidForm(presenter);

        when(
          () => authService.signIn(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer(
          (_) async => RestResponse<SessionDto>(
            statusCode: 403,
            errorMessage: 'Conta nao verificada',
          ),
        );
        when(
          () => authService.resendVerificationEmail(email: 'ada@example.com'),
        ).thenAnswer((_) async => RestResponse<void>(statusCode: 204));

        await presenter.submit();

        verify(
          () => authService.resendVerificationEmail(email: 'ada@example.com'),
        ).called(1);
        verify(
          () => navigationDriver.goTo(
            Routes.getEmailConfirmation(email: 'ada@example.com'),
          ),
        ).called(1);
        expect(presenter.generalError.value, isNull);
      },
    );

    test(
      'navega para confirmacao mesmo quando reenvio automatico falha',
      () async {
        final SignInScreenPresenter presenter = createPresenter();
        addTearDown(presenter.dispose);
        _fillValidForm(presenter);

        when(
          () => authService.signIn(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer(
          (_) async => RestResponse<SessionDto>(
            statusCode: 403,
            errorMessage: 'Conta nao verificada',
          ),
        );
        when(
          () => authService.resendVerificationEmail(email: 'ada@example.com'),
        ).thenThrow(Exception('network error'));

        await presenter.submit();

        verify(
          () => navigationDriver.goTo(
            Routes.getEmailConfirmation(email: 'ada@example.com'),
          ),
        ).called(1);
        expect(presenter.generalError.value, isNull);
        expect(presenter.isSubmitting.value, isFalse);
      },
    );

    test('nao submete quando formulario e invalido', () async {
      final SignInScreenPresenter presenter = createPresenter();
      addTearDown(presenter.dispose);

      await presenter.submit();

      verifyNever(
        () => authService.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      );
      expect(presenter.form.invalid, isTrue);
      expect(presenter.emailControl.touched, isTrue);
      expect(presenter.passwordControl.touched, isTrue);
    });

    test('ignora submit duplicado enquanto requisicao esta em voo', () async {
      final SignInScreenPresenter presenter = createPresenter();
      addTearDown(presenter.dispose);
      _fillValidForm(presenter);
      final Completer<RestResponse<SessionDto>> completer =
          Completer<RestResponse<SessionDto>>();

      when(
        () => authService.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) => completer.future);

      final Future<void> firstSubmit = presenter.submit();
      final Future<void> secondSubmit = presenter.submit();

      verify(
        () =>
            authService.signIn(email: 'ada@example.com', password: 'Password1'),
      ).called(1);
      expect(presenter.isSubmitting.value, isTrue);

      completer.complete(
        RestResponse<SessionDto>(statusCode: 401, errorMessage: 'ignored'),
      );

      await Future.wait(<Future<void>>[firstSubmit, secondSubmit]);

      expect(presenter.isSubmitting.value, isFalse);
    });
  });

  group('continueWithGoogle', () {
    test('persiste tokens e navega para home no sucesso', () async {
      final SignInScreenPresenter presenter = createPresenter();
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
      final SignInScreenPresenter presenter = createPresenter();
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
      final SignInScreenPresenter presenter = createPresenter();
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
      final SignInScreenPresenter presenter = createPresenter();
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
        final SignInScreenPresenter presenter = createPresenter();
        addTearDown(presenter.dispose);
        _fillValidForm(presenter);
        final Completer<RestResponse<SessionDto>> completer =
            Completer<RestResponse<SessionDto>>();

        when(
          () => authService.signIn(
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
          RestResponse<SessionDto>(statusCode: 401, errorMessage: 'ignored'),
        );
        await submitFuture;
      },
    );
  });

  test('alterna visibilidade da senha', () {
    final SignInScreenPresenter presenter = createPresenter();
    addTearDown(presenter.dispose);

    expect(presenter.isPasswordVisible.value, isFalse);

    presenter.togglePasswordVisibility();
    expect(presenter.isPasswordVisible.value, isTrue);

    presenter.togglePasswordVisibility();
    expect(presenter.isPasswordVisible.value, isFalse);
  });

  test('goToForgotPassword navega para forgot password', () {
    final SignInScreenPresenter presenter = createPresenter();
    addTearDown(presenter.dispose);

    presenter.goToForgotPassword();

    verify(
      () => navigationDriver.goTo(
        Routes.getForgotPassword(previousRoute: Routes.signIn),
      ),
    ).called(1);
  });
}

void _fillValidForm(SignInScreenPresenter presenter) {
  presenter.emailControl.value = 'ada@example.com';
  presenter.passwordControl.value = 'Password1';
}
