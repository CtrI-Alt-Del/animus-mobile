import 'package:animus/ui/auth/widgets/components/google_auth_button/google_auth_button_view.dart';
import 'package:animus/ui/auth/widgets/components/or_divider/or_divider_view.dart';
import 'package:animus/ui/auth/widgets/pages/sign_up_screen/sign_up_form/sign_up_form_presenter.dart';
import 'package:animus/ui/auth/widgets/pages/sign_up_screen/sign_up_form/sign_up_form_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:signals_flutter/signals_flutter.dart';

class _MockSignUpFormPresenter extends Mock implements SignUpFormPresenter {}

void main() {
  testWidgets('renderiza campos, divisor compartilhado e cta do google', (
    WidgetTester tester,
  ) async {
    final Signal<String?> generalError = signal<String?>('Falha ao cadastrar');
    final _MockSignUpFormPresenter presenter = _createPresenter(
      generalError: generalError,
    );

    await tester.pumpWidget(_createWidget(presenter));
    await tester.pump();

    expect(find.byType(ReactiveTextField<String>), findsNWidgets(4));
    expect(find.text('Nome completo'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Senha'), findsOneWidget);
    expect(find.text('Confirmar senha'), findsOneWidget);
    expect(find.text('Falha ao cadastrar'), findsOneWidget);
    expect(find.text('Criar Conta'), findsOneWidget);
    expect(find.byType(OrDividerView), findsOneWidget);
    expect(find.text('ou'), findsOneWidget);
    expect(find.byType(GoogleAuthButtonView), findsOneWidget);
    expect(find.text('Continuar com Google'), findsOneWidget);
    expect(find.text('Ja tem conta? '), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });

  testWidgets('reflete loading e disabled do presenter nos dois CTAs', (
    WidgetTester tester,
  ) async {
    final _MockSignUpFormPresenter presenter = _createPresenter(
      isSubmitting: signal<bool>(true),
      isGoogleSubmitting: signal<bool>(true),
      canSubmit: signal<bool>(false),
      canTriggerGoogleAuth: signal<bool>(false),
    );

    await tester.pumpWidget(_createWidget(presenter));
    await tester.pump();

    final ElevatedButton submitButton = tester.widget<ElevatedButton>(
      find.byType(ElevatedButton),
    );
    final OutlinedButton googleButton = tester.widget<OutlinedButton>(
      find.byType(OutlinedButton),
    );

    expect(find.byType(CircularProgressIndicator), findsNWidgets(2));
    expect(submitButton.onPressed, isNull);
    expect(googleButton.onPressed, isNull);
    verifyNever(() => presenter.submit());
    verifyNever(() => presenter.continueWithGoogle());
  });

  testWidgets('delegates google CTA, sign in tap and password toggles', (
    WidgetTester tester,
  ) async {
    final Signal<bool> isPasswordVisible = signal<bool>(false);
    final Signal<bool> isConfirmPasswordVisible = signal<bool>(false);
    final _MockSignUpFormPresenter presenter = _createPresenter(
      isPasswordVisible: isPasswordVisible,
      isConfirmPasswordVisible: isConfirmPasswordVisible,
    );
    when(() => presenter.togglePasswordVisibility()).thenAnswer((_) {
      isPasswordVisible.value = !isPasswordVisible.value;
    });
    when(() => presenter.toggleConfirmPasswordVisibility()).thenAnswer((_) {
      isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;
    });

    await tester.pumpWidget(_createWidget(presenter));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.visibility), findsNWidgets(2));
    expect(find.byIcon(Icons.visibility_off), findsNothing);

    await tester.tap(find.byIcon(Icons.visibility).first);
    await tester.pump();
    await tester.tap(find.byIcon(Icons.visibility).last);
    await tester.pump();
    await tester.tap(find.text('Continuar com Google'));
    await tester.pump();
    await tester.tap(find.text('Entrar'));
    await tester.pump();

    verify(() => presenter.togglePasswordVisibility()).called(1);
    verify(() => presenter.toggleConfirmPasswordVisibility()).called(1);
    verify(() => presenter.continueWithGoogle()).called(1);
    verify(() => presenter.goToSignIn()).called(1);
    expect(find.byIcon(Icons.visibility_off), findsNWidgets(2));
  });
}

Widget _createWidget(_MockSignUpFormPresenter presenter) {
  return ProviderScope(
    overrides: [signUpFormPresenterProvider.overrideWithValue(presenter)],
    child: const MaterialApp(home: Scaffold(body: SignUpFormView())),
  );
}

_MockSignUpFormPresenter _createPresenter({
  Signal<String?>? generalError,
  Signal<bool>? isSubmitting,
  Signal<bool>? isGoogleSubmitting,
  Signal<bool>? isPasswordVisible,
  Signal<bool>? isConfirmPasswordVisible,
  ReadonlySignal<bool>? hasMinLength,
  ReadonlySignal<bool>? hasUppercaseLetter,
  ReadonlySignal<bool>? hasNumber,
  ReadonlySignal<int>? passwordStrengthScore,
  ReadonlySignal<bool>? canSubmit,
  ReadonlySignal<bool>? canTriggerGoogleAuth,
}) {
  final _MockSignUpFormPresenter presenter = _MockSignUpFormPresenter();
  final FormGroup form = FormGroup(<String, AbstractControl<Object>>{
    'name': FormControl<String>(),
    'email': FormControl<String>(),
    'password': FormControl<String>(),
    'confirmPassword': FormControl<String>(),
    'termsAccepted': FormControl<bool>(value: false),
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
  when(
    () => presenter.isConfirmPasswordVisible,
  ).thenReturn(isConfirmPasswordVisible ?? signal<bool>(false));
  when(
    () => presenter.hasMinLength,
  ).thenReturn(hasMinLength ?? signal<bool>(false));
  when(
    () => presenter.hasUppercaseLetter,
  ).thenReturn(hasUppercaseLetter ?? signal<bool>(false));
  when(() => presenter.hasNumber).thenReturn(hasNumber ?? signal<bool>(false));
  when(
    () => presenter.passwordStrengthScore,
  ).thenReturn(passwordStrengthScore ?? signal<int>(0));
  when(() => presenter.canSubmit).thenReturn(canSubmit ?? signal<bool>(true));
  when(
    () => presenter.canTriggerGoogleAuth,
  ).thenReturn(canTriggerGoogleAuth ?? signal<bool>(true));
  when(() => presenter.nameValidationMessages).thenReturn(
    <String, String Function(Object)>{
      ValidationMessage.required: (_) => 'Informe seu nome.',
    },
  );
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
  when(() => presenter.confirmPasswordValidationMessages).thenReturn(
    <String, String Function(Object)>{
      ValidationMessage.required: (_) => 'Confirme sua senha.',
    },
  );
  when(() => presenter.onPasswordChanged(any())).thenReturn(null);
  when(() => presenter.submit()).thenAnswer((_) async {});
  when(() => presenter.continueWithGoogle()).thenAnswer((_) async {});
  when(() => presenter.togglePasswordVisibility()).thenReturn(null);
  when(() => presenter.toggleConfirmPasswordVisibility()).thenReturn(null);
  when(() => presenter.goToSignIn()).thenReturn(null);
  return presenter;
}
