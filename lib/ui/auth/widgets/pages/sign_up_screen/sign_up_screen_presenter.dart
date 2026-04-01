import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:animus/constants/cache_keys.dart';
import 'package:animus/constants/routes.dart';
import 'package:animus/core/auth/dtos/session_dto.dart';
import 'package:animus/core/auth/interfaces/auth_service.dart';
import 'package:animus/core/auth/interfaces/google_auth_driver.dart';
import 'package:animus/core/shared/interfaces/cache_driver.dart';
import 'package:animus/core/shared/interfaces/navigation_driver.dart';
import 'package:animus/core/shared/responses/rest_response.dart';
import 'package:animus/drivers/cache/index.dart';
import 'package:animus/drivers/google-auth-driver/index.dart';
import 'package:animus/drivers/navigation/index.dart';
import 'package:animus/rest/services/index.dart';

class SignUpScreenPresenter {
  final AuthService _authService;
  final GoogleAuthDriver _googleAuthDriver;
  final CacheDriver _cacheDriver;
  final NavigationDriver _navigationDriver;

  final FormGroup form = FormGroup(
    <String, AbstractControl<Object>>{
      'name': FormControl<String>(validators: [Validators.required]),
      'email': FormControl<String>(
        validators: [Validators.required, Validators.email],
      ),
      'termsAccepted': FormControl<bool>(
        value: false,
        validators: [Validators.requiredTrue],
      ),
      'password': FormControl<String>(
        validators: [
          Validators.required,
          Validators.delegate(_passwordRulesValidator),
        ],
      ),
      'confirmPassword': FormControl<String>(validators: [Validators.required]),
    },
    validators: [Validators.mustMatch('password', 'confirmPassword')],
  );

  final Signal<String?> generalError = signal<String?>(null);
  final Signal<bool> isSubmitting = signal<bool>(false);
  final Signal<bool> isGoogleSubmitting = signal<bool>(false);
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
    int score = 0;
    if (hasMinLength.value) {
      score += 1;
    }
    if (hasUppercaseLetter.value) {
      score += 1;
    }
    if (hasNumber.value) {
      score += 1;
    }
    return score;
  });
  late final ReadonlySignal<bool> canSubmit = computed(() {
    _formVersion.value;
    return !isSubmitting.value && !isGoogleSubmitting.value && form.valid;
  });
  late final ReadonlySignal<bool> canTriggerGoogleAuth = computed(
    () => !isSubmitting.value && !isGoogleSubmitting.value,
  );

  late final StreamSubscription<dynamic> _formStatusSubscription;
  late final StreamSubscription<dynamic> _formValueSubscription;

  SignUpScreenPresenter({
    required AuthService authService,
    required GoogleAuthDriver googleAuthDriver,
    required CacheDriver cacheDriver,
    required NavigationDriver navigationDriver,
  }) : _authService = authService,
       _googleAuthDriver = googleAuthDriver,
       _cacheDriver = cacheDriver,
       _navigationDriver = navigationDriver {
    _passwordValue.value = passwordControl.value ?? '';

    _formStatusSubscription = form.statusChanged.listen((dynamic _) {
      _formVersion.value = _formVersion.value + 1;
    });
    _formValueSubscription = form.valueChanges.listen((dynamic _) {
      _formVersion.value = _formVersion.value + 1;
    });
  }

  FormControl<String> get nameControl =>
      form.control('name') as FormControl<String>;

  FormControl<String> get emailControl =>
      form.control('email') as FormControl<String>;

  FormControl<String> get passwordControl =>
      form.control('password') as FormControl<String>;

  FormControl<bool> get termsAcceptedControl =>
      form.control('termsAccepted') as FormControl<bool>;

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

  String? fieldErrorMessage(FormControl<Object?> control) {
    if (!control.invalid || (!control.touched && !control.dirty)) {
      return null;
    }

    if (control.hasError(ValidationMessage.required)) {
      return 'Campo obrigatorio.';
    }
    if (control.hasError(ValidationMessage.email)) {
      return 'Informe um e-mail valido.';
    }
    if (control.hasError(ValidationMessage.mustMatch)) {
      return 'As senhas precisam ser iguais.';
    }
    if (control.hasError('minLength')) {
      return 'A senha precisa ter no minimo 8 caracteres.';
    }
    if (control.hasError('uppercase')) {
      return 'A senha precisa ter pelo menos 1 letra maiuscula.';
    }
    if (control.hasError('number')) {
      return 'A senha precisa ter pelo menos 1 numero.';
    }
    if (control.hasError('server')) {
      return control.getError('server') as String;
    }

    return 'Campo invalido.';
  }

  void applyServerFieldErrors(RestResponse<dynamic> response) {
    _clearServerErrors();

    if (response.statusCode == 409) {
      emailControl.setErrors(<String, Object>{
        'server': 'Este e-mail ja esta em uso.',
      });
      emailControl.markAsTouched();
      return;
    }

    if (response.statusCode != 422) {
      generalError.value = _resolveGeneralError(response);
      return;
    }

    final Map<String, String> fieldErrors = _extractFieldErrors(response);
    bool hasMappedFieldError = false;

    for (final MapEntry<String, String> fieldError in fieldErrors.entries) {
      final FormControl<String>? control = _controlByName(fieldError.key);
      if (control == null) {
        continue;
      }
      control.setErrors(<String, Object>{'server': fieldError.value});
      control.markAsTouched();
      hasMappedFieldError = true;
    }

    if (!hasMappedFieldError) {
      generalError.value = _resolveGeneralError(response);
    }
  }

  Future<void> submit() async {
    if (isSubmitting.value || isGoogleSubmitting.value) {
      return;
    }

    generalError.value = null;
    _clearServerErrors();
    form.markAllAsTouched();

    if (form.invalid) {
      return;
    }

    isSubmitting.value = true;

    final RestResponse<dynamic> response = await _authService.signUp(
      name: (nameControl.value ?? '').trim(),
      email: (emailControl.value ?? '').trim(),
      password: passwordControl.value ?? '',
    );

    if (response.isSuccessful) {
      final String email = (emailControl.value ?? '').trim();
      _navigationDriver.goTo(Routes.getEmailConfirmation(email: email));
      isSubmitting.value = false;
      return;
    }

    applyServerFieldErrors(response);
    isSubmitting.value = false;
  }

  Future<void> continueWithGoogle() async {
    if (isSubmitting.value || isGoogleSubmitting.value) {
      return;
    }

    generalError.value = null;
    isGoogleSubmitting.value = true;

    try {
      final String? idToken = await _googleAuthDriver.requestIdToken();
      if (idToken == null) {
        isGoogleSubmitting.value = false;
        return;
      }

      final RestResponse<SessionDto> response = await _authService
          .signInWithGoogle(idToken: idToken);

      if (response.isSuccessful) {
        _persistSession(response.body);
        _navigationDriver.goTo(Routes.home);
        isGoogleSubmitting.value = false;
        return;
      }

      generalError.value = _resolveGeneralError(response);
    } catch (_) {
      generalError.value =
          'Nao foi possivel continuar com Google agora. Tente novamente.';
    }

    isGoogleSubmitting.value = false;
  }

  void goToSignIn() {
    _navigationDriver.goTo(Routes.signIn);
  }

  void _persistSession(SessionDto session) {
    _cacheDriver.set(CacheKeys.accessToken, session.accessToken.value);
    _cacheDriver.set(CacheKeys.refreshToken, session.refreshToken.value);
  }

  void dispose() {
    _formStatusSubscription.cancel();
    _formValueSubscription.cancel();
    form.dispose();
    generalError.dispose();
    isSubmitting.dispose();
    isGoogleSubmitting.dispose();
    isPasswordVisible.dispose();
    isConfirmPasswordVisible.dispose();
    _passwordValue.dispose();
    _formVersion.dispose();
    hasMinLength.dispose();
    hasUppercaseLetter.dispose();
    hasNumber.dispose();
    passwordStrengthScore.dispose();
    canSubmit.dispose();
    canTriggerGoogleAuth.dispose();
  }

  void _clearServerErrors() {
    for (final FormControl<String> control in <FormControl<String>>[
      nameControl,
      emailControl,
      passwordControl,
      confirmPasswordControl,
    ]) {
      control.removeError('server');
    }
  }

  FormControl<String>? _controlByName(String key) {
    switch (key) {
      case 'name':
        return nameControl;
      case 'email':
        return emailControl;
      case 'password':
        return passwordControl;
      default:
        return null;
    }
  }

  String _resolveGeneralError(RestResponse<dynamic> response) {
    final String? bodyMessage = response.errorBody?['message'] as String?;
    if (bodyMessage != null && bodyMessage.isNotEmpty) {
      return bodyMessage;
    }

    try {
      return response.errorMessage;
    } catch (_) {
      return 'Nao foi possivel concluir o cadastro. Tente novamente.';
    }
  }

  Map<String, String> _extractFieldErrors(RestResponse<dynamic> response) {
    final Map<String, String> mapped = <String, String>{};
    final Map<String, dynamic>? errorBody = response.errorBody;

    if (errorBody == null) {
      return mapped;
    }

    final dynamic detail = errorBody['detail'];
    if (detail is List<dynamic>) {
      for (final dynamic item in detail) {
        if (item is! Map<String, dynamic>) {
          continue;
        }
        final dynamic message = item['msg'];
        final dynamic loc = item['loc'];

        if (message is! String || loc is! List<dynamic>) {
          continue;
        }

        final String? field = _extractFieldFromLoc(loc);
        if (field == null) {
          continue;
        }

        mapped[field] = message;
      }
      return mapped;
    }

    for (final String key in <String>['name', 'email', 'password']) {
      final dynamic value = errorBody[key];
      if (value is String && value.isNotEmpty) {
        mapped[key] = value;
      } else if (value is List<dynamic> && value.isNotEmpty) {
        final String first = value.first.toString();
        if (first.isNotEmpty) {
          mapped[key] = first;
        }
      }
    }

    return mapped;
  }

  String? _extractFieldFromLoc(List<dynamic> loc) {
    for (final dynamic token in loc.reversed) {
      if (token is String &&
          (token == 'name' || token == 'email' || token == 'password')) {
        return token;
      }
    }
    return null;
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

final signUpScreenPresenterProvider = Provider.autoDispose<
  SignUpScreenPresenter
>((Ref ref) {
  final AuthService authService = ref.watch(authServiceProvider);
  final GoogleAuthDriver googleAuthDriver = ref.watch(googleAuthDriverProvider);
  final CacheDriver cacheDriver = ref.watch(cacheDriverProvider);
  final NavigationDriver navigationDriver = ref.watch(navigationDriverProvider);
  final SignUpScreenPresenter presenter = SignUpScreenPresenter(
    authService: authService,
    googleAuthDriver: googleAuthDriver,
    cacheDriver: cacheDriver,
    navigationDriver: navigationDriver,
  );
  ref.onDispose(presenter.dispose);
  return presenter;
});
