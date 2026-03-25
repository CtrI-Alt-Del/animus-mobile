import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:animus/ui/auth/widgets/pages/sign_up_screen/sign_up_screen_presenter.dart';

class SignUpFormPresenter {
  final SignUpScreenPresenter _screenPresenter;

  const SignUpFormPresenter({required SignUpScreenPresenter screenPresenter})
    : _screenPresenter = screenPresenter;

  FormGroup get form => _screenPresenter.form;

  Signal<String?> get generalError => _screenPresenter.generalError;

  Signal<bool> get isSubmitting => _screenPresenter.isSubmitting;

  Signal<bool> get isPasswordVisible => _screenPresenter.isPasswordVisible;

  Signal<bool> get isConfirmPasswordVisible =>
      _screenPresenter.isConfirmPasswordVisible;

  ReadonlySignal<bool> get hasMinLength => _screenPresenter.hasMinLength;

  ReadonlySignal<bool> get hasUppercaseLetter =>
      _screenPresenter.hasUppercaseLetter;

  ReadonlySignal<bool> get hasNumber => _screenPresenter.hasNumber;

  ReadonlySignal<int> get passwordStrengthScore =>
      _screenPresenter.passwordStrengthScore;

  ReadonlySignal<bool> get canSubmit => _screenPresenter.canSubmit;

  Map<String, String Function(Object)> get nameValidationMessages =>
      _nameValidationMessages;

  Map<String, String Function(Object)> get emailValidationMessages =>
      _emailValidationMessages;

  Map<String, String Function(Object)> get passwordValidationMessages =>
      _passwordValidationMessages;

  Map<String, String Function(Object)> get confirmPasswordValidationMessages =>
      _confirmPasswordValidationMessages;

  void onPasswordChanged(String? value) {
    _screenPresenter.onPasswordChanged(value);
  }

  void togglePasswordVisibility() {
    _screenPresenter.togglePasswordVisibility();
  }

  void toggleConfirmPasswordVisibility() {
    _screenPresenter.toggleConfirmPasswordVisibility();
  }

  Future<void> submit(BuildContext context) {
    return _screenPresenter.submit(context);
  }
}

final Map<String, String Function(Object)> _nameValidationMessages =
    <String, String Function(Object)>{
      ValidationMessage.required: (_) => 'Informe seu nome.',
      'server': (Object error) => error.toString(),
    };

final Map<String, String Function(Object)> _emailValidationMessages =
    <String, String Function(Object)>{
      ValidationMessage.required: (_) => 'Informe seu e-mail.',
      ValidationMessage.email: (_) => 'Informe um e-mail valido.',
      'server': (Object error) => error.toString(),
    };

final Map<String, String Function(Object)> _passwordValidationMessages =
    <String, String Function(Object)>{
      ValidationMessage.required: (_) => 'Informe sua senha.',
      'minLength': (_) => 'A senha precisa ter no minimo 8 caracteres.',
      'uppercase': (_) => 'A senha precisa ter pelo menos 1 letra maiuscula.',
      'number': (_) => 'A senha precisa ter pelo menos 1 numero.',
      'server': (Object error) => error.toString(),
    };

final Map<String, String Function(Object)> _confirmPasswordValidationMessages =
    <String, String Function(Object)>{
      ValidationMessage.required: (_) => 'Confirme sua senha.',
      ValidationMessage.mustMatch: (_) => 'As senhas precisam ser iguais.',
      'server': (Object error) => error.toString(),
    };

final signUpFormPresenterProvider = Provider.autoDispose<SignUpFormPresenter>((
  Ref ref,
) {
  final SignUpScreenPresenter screenPresenter = ref.watch(
    signUpScreenPresenterProvider,
  );

  return SignUpFormPresenter(screenPresenter: screenPresenter);
});
