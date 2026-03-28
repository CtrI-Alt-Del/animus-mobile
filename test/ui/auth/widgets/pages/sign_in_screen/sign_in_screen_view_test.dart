import 'package:animus/ui/auth/widgets/pages/sign_in_screen/sign_in_form/sign_in_form_presenter.dart';
import 'package:animus/ui/auth/widgets/pages/sign_in_screen/sign_in_form/sign_in_form_view.dart';
import 'package:animus/ui/auth/widgets/pages/sign_in_screen/sign_in_screen_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:signals_flutter/signals_flutter.dart';

class _MockSignInFormPresenter extends Mock implements SignInFormPresenter {}

void main() {
  testWidgets('renderiza a estrutura principal da tela de login', (
    WidgetTester tester,
  ) async {
    final _MockSignInFormPresenter presenter = _createPresenter();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [signInFormPresenterProvider.overrideWithValue(presenter)],
        child: const MaterialApp(home: SignInScreenView()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(SafeArea), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(find.text('Animus'), findsOneWidget);
    expect(find.text('Entrar'), findsNWidgets(2));
    expect(find.text('Entre com seus dados'), findsOneWidget);
    expect(find.byType(SignInFormView), findsOneWidget);
  });
}

_MockSignInFormPresenter _createPresenter() {
  final _MockSignInFormPresenter presenter = _MockSignInFormPresenter();
  final FormGroup form = FormGroup(<String, AbstractControl<Object>>{
    'email': FormControl<String>(),
    'password': FormControl<String>(),
  });
  when(() => presenter.form).thenReturn(form);
  when(() => presenter.generalError).thenReturn(signal<String?>(null));
  when(() => presenter.isSubmitting).thenReturn(signal<bool>(false));
  when(() => presenter.isGoogleSubmitting).thenReturn(signal<bool>(false));
  when(() => presenter.isPasswordVisible).thenReturn(signal<bool>(false));
  when(() => presenter.canSubmit).thenReturn(signal<bool>(true));
  when(() => presenter.canTriggerGoogleAuth).thenReturn(signal<bool>(true));
  when(
    () => presenter.emailValidationMessages,
  ).thenReturn(<String, String Function(Object)>{});
  when(
    () => presenter.passwordValidationMessages,
  ).thenReturn(<String, String Function(Object)>{});
  when(() => presenter.submit()).thenAnswer((_) async {});
  when(() => presenter.continueWithGoogle()).thenAnswer((_) async {});
  when(() => presenter.togglePasswordVisibility()).thenReturn(null);
  when(() => presenter.goToSignUp()).thenReturn(null);
  return presenter;
}
