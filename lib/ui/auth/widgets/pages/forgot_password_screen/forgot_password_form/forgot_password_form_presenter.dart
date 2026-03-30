import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:animus/ui/auth/widgets/pages/forgot_password_screen/forgot_password_screen_presenter.dart';

class ForgotPasswordFormPresenter {
  final ForgotPasswordScreenPresenter _screenPresenter;

  const ForgotPasswordFormPresenter({
    required ForgotPasswordScreenPresenter screenPresenter,
  }) : _screenPresenter = screenPresenter;

  FormGroup get form => _screenPresenter.form;

  Signal<String?> get generalError => _screenPresenter.generalError;

  Signal<bool> get isSubmitting => _screenPresenter.isSubmitting;

  ReadonlySignal<bool> get canSubmit => _screenPresenter.canSubmit;

  Map<String, String Function(Object)> get emailValidationMessages =>
      _emailValidationMessages;

  Future<void> submit() {
    return _screenPresenter.submit();
  }

  void goToSignIn() {
    _screenPresenter.goToSignIn();
  }
}

final Map<String, String Function(Object)> _emailValidationMessages =
    <String, String Function(Object)>{
      ValidationMessage.required: (_) => 'Informe seu e-mail.',
      ValidationMessage.email: (_) => 'Informe um e-mail valido.',
    };

final forgotPasswordFormPresenterProvider = Provider.autoDispose
    .family<ForgotPasswordFormPresenter, String?>((Ref ref, String? errorCode) {
      final ForgotPasswordScreenPresenter screenPresenter = ref.watch(
        forgotPasswordScreenPresenterProvider(errorCode),
      );

      return ForgotPasswordFormPresenter(screenPresenter: screenPresenter);
    });
