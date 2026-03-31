import 'package:animus/ui/auth/widgets/pages/sign_in_screen/sign_in_form/sign_in_form_presenter.dart';
import 'package:animus/ui/auth/widgets/pages/sign_in_screen/sign_in_form/sign_in_form_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:signals_flutter/signals_flutter.dart';

class _MockSignInFormPresenter extends Mock implements SignInFormPresenter {}

void main() {
  testWidgets('renderiza campos, erro geral e acoes do formulario', (
    WidgetTester tester,
  ) async {
    final Signal<String?> generalError = signal<String?>('Falha ao entrar');
    final _MockSignInFormPresenter presenter = _createPresenter(
      generalError: generalError,
    );

    await tester.pumpWidget(_createWidget(presenter));
    await tester.pump();

    expect(find.byType(ReactiveTextField<String>), findsNWidgets(2));
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Senha'), findsOneWidget);
    expect(find.text('Esqueceu a senha?'), findsOneWidget);
    expect(find.text('Falha ao entrar'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('Continuar com Google'), findsOneWidget);
    expect(find.text('Nao tem conta? '), findsOneWidget);
    expect(find.text('Criar conta'), findsOneWidget);
  });

  testWidgets('mostra loading e desabilita o CTA principal', (
    WidgetTester tester,
  ) async {
    final _MockSignInFormPresenter presenter = _createPresenter(
      isSubmitting: signal<bool>(true),
      canSubmit: signal<bool>(false),
    );

    await tester.pumpWidget(_createWidget(presenter));
    await tester.pump();

    final ElevatedButton button = tester.widget<ElevatedButton>(
      find.byType(ElevatedButton),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(button.onPressed, isNull);
    verifyNever(() => presenter.submit());
  });

  testWidgets('reflete loading e disabled do CTA Google', (
    WidgetTester tester,
  ) async {
    final _MockSignInFormPresenter presenter = _createPresenter(
      isGoogleSubmitting: signal<bool>(true),
      canTriggerGoogleAuth: signal<bool>(false),
    );

    await tester.pumpWidget(_createWidget(presenter));
    await tester.pump();

    final OutlinedButton googleButton = tester.widget<OutlinedButton>(
      find.byType(OutlinedButton),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(googleButton.onPressed, isNull);
    verifyNever(() => presenter.continueWithGoogle());
  });

  testWidgets('delegates forgot password tap', (WidgetTester tester) async {
    final _MockSignInFormPresenter presenter = _createPresenter();

    await tester.pumpWidget(_createWidget(presenter));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Esqueceu a senha?'));
    await tester.pump();

    verify(() => presenter.goToForgotPassword()).called(1);
  });
  testWidgets(
    'delegates sign up tap, google CTA and password visibility toggle',
    (WidgetTester tester) async {
      final Signal<bool> isPasswordVisible = signal<bool>(false);
      final _MockSignInFormPresenter presenter = _createPresenter(
        isPasswordVisible: isPasswordVisible,
      );
      when(() => presenter.togglePasswordVisibility()).thenAnswer((_) {
        isPasswordVisible.value = !isPasswordVisible.value;
      });

      await tester.pumpWidget(_createWidget(presenter));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.visibility), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off), findsNothing);

      await tester.tap(find.byIcon(Icons.visibility));
      await tester.pump();
      await tester.tap(find.text('Continuar com Google'));
      await tester.pump();

      verify(() => presenter.togglePasswordVisibility()).called(1);
      verify(() => presenter.continueWithGoogle()).called(1);
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
      expect(find.byIcon(Icons.visibility), findsNothing);

      await tester.tap(find.text('Criar conta'));
      await tester.pump();

      verify(() => presenter.goToSignUp()).called(1);
    },
  );
}

Widget _createWidget(_MockSignInFormPresenter presenter) {
  return ProviderScope(
    overrides: [signInFormPresenterProvider.overrideWithValue(presenter)],
    child: const MaterialApp(home: Scaffold(body: SignInFormView())),
  );
}

_MockSignInFormPresenter _createPresenter({
  Signal<String?>? generalError,
  Signal<bool>? isSubmitting,
  Signal<bool>? isGoogleSubmitting,
  Signal<bool>? isPasswordVisible,
  ReadonlySignal<bool>? canSubmit,
  ReadonlySignal<bool>? canTriggerGoogleAuth,
}) {
  final _MockSignInFormPresenter presenter = _MockSignInFormPresenter();
  final FormGroup form = FormGroup(<String, AbstractControl<Object>>{
    'email': FormControl<String>(),
    'password': FormControl<String>(),
  });

  when(() => presenter.form).thenReturn(form);
  when(
    () => presenter.generalError,
  ).thenReturn(generalError ?? signal<String?>(null));
  when(
    () => presenter.isSubmitting,
  ).thenReturn(isSubmitting ?? signal<bool>(false));
  when(
    () => presenter.isGoogleSubmitting,
  ).thenReturn(isGoogleSubmitting ?? signal<bool>(false));
  when(
    () => presenter.isPasswordVisible,
  ).thenReturn(isPasswordVisible ?? signal<bool>(false));
  when(() => presenter.canSubmit).thenReturn(canSubmit ?? signal<bool>(true));
  when(
    () => presenter.canTriggerGoogleAuth,
  ).thenReturn(canTriggerGoogleAuth ?? signal<bool>(true));
  when(() => presenter.emailValidationMessages).thenReturn(
    <String, String Function(Object)>{
      ValidationMessage.required: (_) => 'Informe seu e-mail.',
    },
  );
  when(() => presenter.passwordValidationMessages).thenReturn(
    <String, String Function(Object)>{
      ValidationMessage.required: (_) => 'Informe sua senha.',
    },
  );
  when(() => presenter.submit()).thenAnswer((_) async {});
  when(() => presenter.continueWithGoogle()).thenAnswer((_) async {});
  when(() => presenter.togglePasswordVisibility()).thenReturn(null);
  when(() => presenter.goToSignUp()).thenReturn(null);
  when(() => presenter.goToForgotPassword()).thenReturn(null);
  return presenter;
}
