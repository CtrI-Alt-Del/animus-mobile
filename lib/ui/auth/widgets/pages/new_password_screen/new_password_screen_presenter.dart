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

class NewPasswordScreenPresenter {
  final AuthService _authService;
  final NavigationDriver _navigationDriver;
  final String resetContext;

  final FormGroup form = FormGroup(
    <String, AbstractControl<Object>>{
      'newPassword': FormControl<String>(
        validators: <Validator<dynamic>>[
          Validators.required,
          Validators.delegate(_passwordRulesValidator),
        ],
      ),
      'confirmPassword': FormControl<String>(
        validators: <Validator<dynamic>>[Validators.required],
      ),
    },
    validators: <Validator<dynamic>>[
      Validators.mustMatch('newPassword', 'confirmPassword'),
    ],
  );

  final Signal<String?> generalError = signal<String?>(null);
  final Signal<bool> isSubmitting = signal<bool>(false);
  final Signal<bool> isPasswordVisible = signal<bool>(false);
  final Signal<bool> isConfirmPasswordVisible = signal<bool>(false);
  final Signal<String> _passwordValue = signal<String>('');
  final Signal<int> _formVersion = signal<int>(0);

  late final ReadonlySignal<bool> hasMinLength = computed(
    () => _passwordValue.value.length >= 8,
  );
  late final ReadonlySignal<bool> hasUppercaseLetter = computed(
    () => RegExp(r'[A-Z]').hasMatch(_passwordValue.value),
  );
  late final ReadonlySignal<bool> hasNumber = computed(
    () => RegExp(r'\d').hasMatch(_passwordValue.value),
  );
  late final ReadonlySignal<int> passwordStrengthScore = computed(() {
    if (!hasMinLength.value) {
      return 0;
    }
    if (!hasUppercaseLetter.value) {
      return 1;
    }
    if (!hasNumber.value) {
      return 2;
    }
    return 3;
  });
  late final ReadonlySignal<bool> canSubmit = computed(() {
    _formVersion.value;
    return !isSubmitting.value && form.valid;
  });

  late final StreamSubscription<dynamic> _formStatusSubscription;
  late final StreamSubscription<dynamic> _formValueSubscription;

  NewPasswordScreenPresenter({
    required AuthService authService,
    required NavigationDriver navigationDriver,
    required this.resetContext,
  }) : _authService = authService,
       _navigationDriver = navigationDriver {
    _formStatusSubscription = form.statusChanged.listen((dynamic _) {
      _formVersion.value = _formVersion.value + 1;
    });
    _formValueSubscription = form.valueChanges.listen((dynamic _) {
      _formVersion.value = _formVersion.value + 1;
    });
  }

  FormControl<String> get newPasswordControl =>
      form.control('newPassword') as FormControl<String>;

  FormControl<String> get confirmPasswordControl =>
      form.control('confirmPassword') as FormControl<String>;

  void onPasswordChanged(String? value) {
    _passwordValue.value = value ?? '';
    confirmPasswordControl.updateValueAndValidity();
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;
  }

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

    final RestResponse<void> response = await _authService.resetPassword(
      resetContext: resetContext,
      newPassword: newPasswordControl.value ?? '',
    );

    if (response.isSuccessful) {
      _navigationDriver.goTo(Routes.signIn);
      isSubmitting.value = false;
      return;
    }

    generalError.value = _resolveGeneralError(response);
    isSubmitting.value = false;
  }

  void goBackOrGoToSignIn() {
    if (_navigationDriver.canGoBack()) {
      _navigationDriver.goBack();
      return;
    }

    _navigationDriver.goTo(Routes.signIn);
  }

  void dispose() {
    _formStatusSubscription.cancel();
    _formValueSubscription.cancel();
    form.dispose();
    generalError.dispose();
    isSubmitting.dispose();
    isPasswordVisible.dispose();
    isConfirmPasswordVisible.dispose();
    _passwordValue.dispose();
    _formVersion.dispose();
    hasMinLength.dispose();
    hasUppercaseLetter.dispose();
    hasNumber.dispose();
    passwordStrengthScore.dispose();
    canSubmit.dispose();
  }

  String _resolveGeneralError(RestResponse<dynamic> response) {
    final String? bodyMessage = response.errorBody?['message'] as String?;
    if (bodyMessage != null && bodyMessage.isNotEmpty) {
      return bodyMessage;
    }

    try {
      return response.errorMessage;
    } catch (_) {
      return 'Nao foi possivel redefinir a senha agora. Tente novamente.';
    }
  }

  static Map<String, dynamic>? _passwordRulesValidator(
    AbstractControl<dynamic> control,
  ) {
    final String value = (control.value as String?) ?? '';

    if (value.isEmpty) {
      return null;
    }

    final Map<String, dynamic> errors = <String, dynamic>{};

    if (value.length < 8) {
      errors['minLength'] = true;
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      errors['uppercase'] = true;
    }
    if (!RegExp(r'\d').hasMatch(value)) {
      errors['number'] = true;
    }

    if (errors.isEmpty) {
      return null;
    }

    return errors;
  }
}

final newPasswordScreenPresenterProvider = Provider.autoDispose
    .family<NewPasswordScreenPresenter, String>((Ref ref, String resetContext) {
      final AuthService authService = ref.watch(authServiceProvider);
      final NavigationDriver navigationDriver = ref.watch(
        navigationDriverProvider,
      );

      final NewPasswordScreenPresenter presenter = NewPasswordScreenPresenter(
        authService: authService,
        navigationDriver: navigationDriver,
        resetContext: resetContext,
      );

      ref.onDispose(presenter.dispose);
      return presenter;
    });
