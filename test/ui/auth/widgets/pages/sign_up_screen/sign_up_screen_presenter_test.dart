import 'package:animus/constants/routes.dart';
import 'package:animus/core/auth/interfaces/auth_service.dart';
import 'package:animus/core/shared/responses/rest_response.dart';
import 'package:animus/ui/auth/widgets/pages/sign_up_screen/sign_up_screen_presenter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../fakers/auth/account_dto_faker.dart';

class _MockAuthService extends Mock implements AuthService {}

void main() {
  late _MockAuthService authService;

  setUp(() {
    authService = _MockAuthService();
  });

  group('validacoes', () {
    late SignUpScreenPresenter presenter;

    setUp(() {
      presenter = SignUpScreenPresenter(authService: authService);
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
    testWidgets('navega para confirmacao no sucesso', (
      WidgetTester tester,
    ) async {
      final presenter = SignUpScreenPresenter(authService: authService);
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

      await _pumpSubmitHarness(tester, presenter);
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('email-confirmation:ada@example.com'), findsOneWidget);
      verify(
        () => authService.signUp(
          name: 'Ada Lovelace',
          email: 'ada@example.com',
          password: 'Password1',
        ),
      ).called(1);
    });

    testWidgets('nao submete enquanto termos nao forem aceitos', (
      WidgetTester tester,
    ) async {
      final presenter = SignUpScreenPresenter(authService: authService);
      addTearDown(presenter.dispose);
      _fillValidForm(presenter, acceptTerms: false);

      await _pumpSubmitHarness(tester, presenter);
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      verifyNever(
        () => authService.signUp(
          name: any(named: 'name'),
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      );
      expect(presenter.termsAcceptedControl.valid, isFalse);
      expect(find.text('idle'), findsOneWidget);
    });

    testWidgets('mapeia conflito 409 para erro inline de email', (
      WidgetTester tester,
    ) async {
      final presenter = SignUpScreenPresenter(authService: authService);
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

      await _pumpSubmitHarness(tester, presenter);
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(presenter.emailControl.hasError('server'), isTrue);
      expect(
        presenter.fieldErrorMessage(presenter.emailControl),
        'Este e-mail ja esta em uso.',
      );
      expect(presenter.generalError.value, isNull);
    });

    testWidgets('mapeia 422 para erros reconhecidos de campo', (
      WidgetTester tester,
    ) async {
      final presenter = SignUpScreenPresenter(authService: authService);
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

      await _pumpSubmitHarness(tester, presenter);
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(presenter.emailControl.getError('server'), 'Email invalido');
      expect(presenter.passwordControl.getError('server'), 'Senha fraca');
      expect(presenter.generalError.value, isNull);
    });

    testWidgets('exibe erro geral em falha nao tratada', (
      WidgetTester tester,
    ) async {
      final presenter = SignUpScreenPresenter(authService: authService);
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

      await _pumpSubmitHarness(tester, presenter);
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(presenter.generalError.value, 'Falha inesperada');
      expect(find.text('idle'), findsOneWidget);
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

Future<void> _pumpSubmitHarness(
  WidgetTester tester,
  SignUpScreenPresenter presenter,
) async {
  final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (BuildContext context, GoRouterState state) {
          return Scaffold(
            body: Column(
              children: <Widget>[
                ElevatedButton(
                  onPressed: () => presenter.submit(context),
                  child: const Text('submit'),
                ),
                Text(presenter.isSubmitting.value ? 'submitting' : 'idle'),
              ],
            ),
          );
        },
      ),
      GoRoute(
        path: Routes.emailConfirmation,
        builder: (BuildContext context, GoRouterState state) {
          return Text(
            'email-confirmation:${state.uri.queryParameters['email']}',
          );
        },
      ),
    ],
  );

  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
}
