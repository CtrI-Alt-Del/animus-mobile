import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:animus/ui/auth/widgets/pages/new_password_screen/new_password_screen_presenter.dart';

class NewPasswordFormPresenter {
  final NewPasswordScreenPresenter _screenPresenter;

  const NewPasswordFormPresenter({
    required NewPasswordScreenPresenter screenPresenter,
  }) : _screenPresenter = screenPresenter;

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

  Map<String, String Function(Object)> get newPasswordValidationMessages =>
      _newPasswordValidationMessages;

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

  Future<void> submit() {
    return _screenPresenter.submit();
  }

  void goToSignIn() {
    _screenPresenter.goToSignIn();
  }
}

final Map<String, String Function(Object)> _newPasswordValidationMessages =
    <String, String Function(Object)>{
      ValidationMessage.required: (_) => 'Informe a nova senha.',
      'minLength': (_) => 'A senha precisa ter no minimo 8 caracteres.',
      'uppercase': (_) => 'A senha precisa ter pelo menos 1 letra maiuscula.',
      'number': (_) => 'A senha precisa ter pelo menos 1 numero.',
    };

final Map<String, String Function(Object)> _confirmPasswordValidationMessages =
    <String, String Function(Object)>{
      ValidationMessage.required: (_) => 'Confirme a nova senha.',
      ValidationMessage.mustMatch: (_) => 'As senhas precisam ser iguais.',
    };

final newPasswordFormPresenterProvider = Provider.autoDispose
    .family<NewPasswordFormPresenter, String>((Ref ref, String accountId) {
      final NewPasswordScreenPresenter screenPresenter = ref.watch(
        newPasswordScreenPresenterProvider(accountId),
      );

      return NewPasswordFormPresenter(screenPresenter: screenPresenter);
    });
