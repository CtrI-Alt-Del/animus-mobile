import 'package:animus/constants/cache_keys.dart';
import 'package:animus/constants/routes.dart';
import 'package:animus/core/auth/interfaces/auth_service.dart';
import 'package:animus/core/shared/interfaces/cache_driver.dart';
import 'package:animus/core/shared/responses/rest_response.dart';
import 'package:animus/drivers/cache-driver/shared_preferences_cache_driver.dart';
import 'package:animus/ui/auth/widgets/pages/email_confirmation_screen/email_confirmation_screen_presenter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../fakers/auth/session_dto_faker.dart';

class _MockAuthService extends Mock implements AuthService {}

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
  late _InMemoryCacheDriver cacheDriver;
  late CacheDriverFactory cacheDriverFactory;

  setUp(() {
    authService = _MockAuthService();
    cacheDriver = _InMemoryCacheDriver();
    cacheDriverFactory = () async => cacheDriver;
  });

  group('verifyOtp', () {
    testWidgets('persiste tokens e navega para home no sucesso', (
      WidgetTester tester,
    ) async {
      final presenter = EmailConfirmationScreenPresenter(
        email: 'ada@example.com',
        authService: authService,
        cacheDriverFactory: cacheDriverFactory,
      );
      addTearDown(presenter.dispose);
      presenter.otpControl.value = '123456';

      when(
        () => authService.verifyEmail(email: 'ada@example.com', otp: '123456'),
      ).thenAnswer(
        (_) async => RestResponse(
          statusCode: 200,
          body: SessionDtoFaker.make(
            accessTokenValue: 'access-token',
            refreshTokenValue: 'refresh-token',
          ),
        ),
      );

      await _pumpVerifyHarness(tester, presenter);
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(cacheDriver.get(CacheKeys.accessToken), 'access-token');
      expect(cacheDriver.get(CacheKeys.refreshToken), 'refresh-token');
      expect(find.text('home'), findsOneWidget);
    });

    testWidgets('mapeia erro de otp para feedback inline', (
      WidgetTester tester,
    ) async {
      final presenter = EmailConfirmationScreenPresenter(
        email: 'ada@example.com',
        authService: authService,
        cacheDriverFactory: cacheDriverFactory,
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

      await _pumpVerifyHarness(tester, presenter);
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(presenter.otpControl.getError('server'), 'Codigo invalido');
      expect(presenter.otpErrorMessage(), 'Codigo invalido');
      expect(presenter.generalError.value, isNull);
    });
  });

  group('resendVerificationEmail', () {
    test('exibe feedback ao reenviar com sucesso', () async {
      final presenter = EmailConfirmationScreenPresenter(
        email: 'ada@example.com',
        authService: authService,
        cacheDriverFactory: cacheDriverFactory,
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
    });

    test('exibe erro geral quando o reenvio falha', () async {
      final presenter = EmailConfirmationScreenPresenter(
        email: 'ada@example.com',
        authService: authService,
        cacheDriverFactory: cacheDriverFactory,
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
    });
  });
}

Future<void> _pumpVerifyHarness(
  WidgetTester tester,
  EmailConfirmationScreenPresenter presenter,
) async {
  final GoRouter router = GoRouter(
    initialLocation: '/verify',
    routes: <RouteBase>[
      GoRoute(
        path: '/verify',
        builder: (BuildContext context, GoRouterState state) {
          return Scaffold(
            body: ElevatedButton(
              onPressed: () => presenter.verifyOtp(context),
              child: const Text('verify'),
            ),
          );
        },
      ),
      GoRoute(
        path: Routes.home,
        builder: (BuildContext context, GoRouterState state) {
          return const Text('home');
        },
      ),
    ],
  );

  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
}
