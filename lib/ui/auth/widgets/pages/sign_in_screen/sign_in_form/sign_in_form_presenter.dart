import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:animus/ui/auth/widgets/pages/sign_in_screen/sign_in_screen_presenter.dart';

class SignInFormPresenter {
  final SignInScreenPresenter _screenPresenter;

  const SignInFormPresenter({required SignInScreenPresenter screenPresenter})
    : _screenPresenter = screenPresenter;

  FormGroup get form => _screenPresenter.form;

  Signal<String?> get generalError => _screenPresenter.generalError;

  Signal<bool> get isSubmitting => _screenPresenter.isSubmitting;

  Signal<bool> get isPasswordVisible => _screenPresenter.isPasswordVisible;

  ReadonlySignal<bool> get canSubmit => _screenPresenter.canSubmit;

  Map<String, String Function(Object)> get emailValidationMessages =>
      _emailValidationMessages;

  Map<String, String Function(Object)> get passwordValidationMessages =>
      _passwordValidationMessages;

  void togglePasswordVisibility() {
    _screenPresenter.togglePasswordVisibility();
  }

  Future<void> submit() {
    return _screenPresenter.submit();
  }

  void goToSignUp() {
    _screenPresenter.goToSignUp();
  }
}

final Map<String, String Function(Object)> _emailValidationMessages =
    <String, String Function(Object)>{
      ValidationMessage.required: (_) => 'Informe seu e-mail.',
      ValidationMessage.email: (_) => 'Informe um e-mail valido.',
    };

final Map<String, String Function(Object)> _passwordValidationMessages =
    <String, String Function(Object)>{
      ValidationMessage.required: (_) => 'Informe sua senha.',
      'minLength': (_) => 'A senha precisa ter no minimo 8 caracteres.',
      'uppercase': (_) => 'A senha precisa ter pelo menos 1 letra maiuscula.',
      'number': (_) => 'A senha precisa ter pelo menos 1 numero.',
      'server': (Object error) => error.toString(),
    };

final signInFormPresenterProvider = Provider.autoDispose<SignInFormPresenter>((
  Ref ref,
) {
  final SignInScreenPresenter screenPresenter = ref.watch(
    signInScreenPresenterProvider,
  );

  return SignInFormPresenter(screenPresenter: screenPresenter);
});
