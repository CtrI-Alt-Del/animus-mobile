import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:animus/constants/routes.dart';
import 'package:animus/core/auth/interfaces/auth_service.dart';
import 'package:animus/core/shared/interfaces/navigation_driver.dart';
import 'package:animus/core/shared/responses/rest_response.dart';
import 'package:animus/drivers/navigation/index.dart';
import 'package:animus/rest/services/index.dart';

class ForgotPasswordScreenPresenter {
  final AuthService _authService;
  final NavigationDriver _navigationDriver;

  final FormGroup form = FormGroup(<String, AbstractControl<Object>>{
    'email': FormControl<String>(
      validators: <Validator<dynamic>>[Validators.required, Validators.email],
    ),
  });

  final Signal<String?> generalError;
  final Signal<bool> isSubmitting = signal<bool>(false);
  final Signal<int> _formVersion = signal<int>(0);

  late final ReadonlySignal<bool> canSubmit = computed(() {
    _formVersion.value;
    return !isSubmitting.value && form.valid;
  });

  late final StreamSubscription<dynamic> _formStatusSubscription;
  late final StreamSubscription<dynamic> _formValueSubscription;

  ForgotPasswordScreenPresenter({
    required AuthService authService,
    required NavigationDriver navigationDriver,
    String? initialErrorCode,
  }) : _authService = authService,
       _navigationDriver = navigationDriver,
       generalError = signal<String?>(_resolveInitialError(initialErrorCode)) {
    _formStatusSubscription = form.statusChanged.listen((dynamic _) {
      _formVersion.value = _formVersion.value + 1;
    });
    _formValueSubscription = form.valueChanges.listen((dynamic _) {
      _formVersion.value = _formVersion.value + 1;
    });
  }

  FormControl<String> get emailControl =>
      form.control('email') as FormControl<String>;

  Future<void> submit() async {
    if (isSubmitting.value) {
      return;
    }

    generalError.value = null;
    form.markAllAsTouched();

    if (form.invalid) {
      return;
    }

    isSubmitting.value = true;

    final String email = (emailControl.value ?? '').trim();
    final RestResponse<void> response = await _authService.forgotPassword(
      email: email,
    );

    if (response.isSuccessful) {
      _navigationDriver.goTo(Routes.getCheckEmail(email: email));
      isSubmitting.value = false;
      return;
    }

    generalError.value = _resolveGeneralError(response);
    isSubmitting.value = false;
  }

  void goToSignIn() {
    _navigationDriver.goTo(Routes.signIn);
  }

  void dispose() {
    _formStatusSubscription.cancel();
    _formValueSubscription.cancel();
    form.dispose();
    generalError.dispose();
    isSubmitting.dispose();
    _formVersion.dispose();
    canSubmit.dispose();
  }

  static String? _resolveInitialError(String? errorCode) {
    if (errorCode == 'invalid_reset_link') {
      return 'O link de redefinicao e invalido ou expirou. Solicite um novo link.';
    }

    return null;
  }

  String _resolveGeneralError(RestResponse<dynamic> response) {
    final String? bodyMessage = response.errorBody?['message'] as String?;
    if (bodyMessage != null && bodyMessage.isNotEmpty) {
      return bodyMessage;
    }

    try {
      return response.errorMessage;
    } catch (_) {
      return 'Nao foi possivel enviar o link agora. Tente novamente.';
    }
  }
}

final forgotPasswordScreenPresenterProvider = Provider.autoDispose
    .family<ForgotPasswordScreenPresenter, String?>((
      Ref ref,
      String? errorCode,
    ) {
      final AuthService authService = ref.watch(authServiceProvider);
      final NavigationDriver navigationDriver = ref.watch(
        navigationDriverProvider,
      );

      final ForgotPasswordScreenPresenter presenter =
          ForgotPasswordScreenPresenter(
            authService: authService,
            navigationDriver: navigationDriver,
            initialErrorCode: errorCode,
          );

      ref.onDispose(presenter.dispose);
      return presenter;
    });
