import 'package:animus/core/auth/interfaces/auth_service.dart';
import 'package:animus/core/auth/interfaces/google_auth_driver.dart';
import 'package:animus/core/shared/interfaces/cache_driver.dart';
import 'package:animus/core/shared/responses/rest_response.dart';
import 'package:animus/drivers/cache/index.dart';
import 'package:animus/drivers/google-auth-driver/index.dart';
import 'package:animus/rest/services/index.dart';
import 'package:animus/ui/auth/widgets/pages/sign_up_screen/sign_up_screen_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthService extends Mock implements AuthService {}

class _MockGoogleAuthDriver extends Mock implements GoogleAuthDriver {}

class _MockCacheDriver extends Mock implements CacheDriver {}

void main() {
  testWidgets(
    'renderiza a tela com providers sobrescritos sem depender de env',
    (WidgetTester tester) async {
      final _MockAuthService authService = _MockAuthService();
      final _MockGoogleAuthDriver googleAuthDriver = _MockGoogleAuthDriver();
      final _MockCacheDriver cacheDriver = _MockCacheDriver();
      when(
        () => authService.signUp(
          name: any(named: 'name'),
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer(
        (_) async => RestResponse(statusCode: 500, errorMessage: 'unused'),
      );
      when(
        () => authService.verifyEmail(
          email: any(named: 'email'),
          otp: any(named: 'otp'),
        ),
      ).thenAnswer(
        (_) async => RestResponse(statusCode: 500, errorMessage: 'unused'),
      );
      when(
        () => authService.resendVerificationEmail(email: any(named: 'email')),
      ).thenAnswer(
        (_) async =>
            RestResponse<void>(statusCode: 500, errorMessage: 'unused'),
      );
      when(() => cacheDriver.set(any(), any())).thenReturn(null);
      when(
        () => googleAuthDriver.requestIdToken(),
      ).thenAnswer((_) async => null);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(authService),
            googleAuthDriverProvider.overrideWithValue(googleAuthDriver),
            cacheDriverProvider.overrideWithValue(cacheDriver),
          ],
          child: const MaterialApp(home: SignUpScreenView()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Animus'), findsOneWidget);
      expect(find.text('Criar Conta'), findsNWidgets(2));
      expect(find.text('Nome completo'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Senha'), findsOneWidget);
      expect(find.text('Confirmar senha'), findsOneWidget);
      expect(
        find.widgetWithText(ElevatedButton, 'Criar Conta'),
        findsOneWidget,
      );
    },
  );
}
