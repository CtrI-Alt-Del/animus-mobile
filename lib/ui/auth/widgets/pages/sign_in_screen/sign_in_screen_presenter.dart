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

class SignInScreenPresenter {
  final AuthService _authService;
  final GoogleAuthDriver _googleAuthDriver;
  final CacheDriver _cacheDriver;
  final NavigationDriver _navigationDriver;

  final FormGroup form = FormGroup(<String, AbstractControl<Object>>{
    'email': FormControl<String>(
      validators: <Validator<dynamic>>[Validators.required, Validators.email],
    ),
    'password': FormControl<String>(
      validators: <Validator<dynamic>>[Validators.required],
    ),
  });

  final Signal<String?> generalError = signal<String?>(null);
  final Signal<bool> isSubmitting = signal<bool>(false);
  final Signal<bool> isGoogleSubmitting = signal<bool>(false);
  final Signal<bool> isPasswordVisible = signal<bool>(false);
  final Signal<int> _formVersion = signal<int>(0);

  late final ReadonlySignal<bool> canSubmit = computed(() {
    _formVersion.value;
    return !isSubmitting.value && !isGoogleSubmitting.value && form.valid;
  });

  late final ReadonlySignal<bool> canTriggerGoogleAuth = computed(
    () => !isSubmitting.value && !isGoogleSubmitting.value,
  );

  late final StreamSubscription<dynamic> _formStatusSubscription;
  late final StreamSubscription<dynamic> _formValueSubscription;

  SignInScreenPresenter({
    required AuthService authService,
    required GoogleAuthDriver googleAuthDriver,
    required CacheDriver cacheDriver,
    required NavigationDriver navigationDriver,
  }) : _authService = authService,
       _googleAuthDriver = googleAuthDriver,
       _cacheDriver = cacheDriver,
       _navigationDriver = navigationDriver {
    _formStatusSubscription = form.statusChanged.listen((dynamic _) {
      _formVersion.value = _formVersion.value + 1;
    });
    _formValueSubscription = form.valueChanges.listen((dynamic _) {
      _formVersion.value = _formVersion.value + 1;
    });
  }

  FormControl<String> get emailControl =>
      form.control('email') as FormControl<String>;

  FormControl<String> get passwordControl =>
      form.control('password') as FormControl<String>;

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void applyStatusCodeError(RestResponse<dynamic> response) {
    if (response.statusCode == 401) {
      generalError.value = 'E-mail ou senha incorretos.';
      return;
    }

    generalError.value = _resolveGeneralError(response);
  }

  Future<void> handleUnverifiedAccount() async {
    final String email = (emailControl.value ?? '').trim();
    try {
      await _authService.resendVerificationEmail(email: email);
    } catch (_) {}
  }

  Future<void> submit() async {
    if (isSubmitting.value || isGoogleSubmitting.value) {
      return;
    }

    generalError.value = null;
    form.markAllAsTouched();

    if (form.invalid) {
      return;
    }

    isSubmitting.value = true;

    final RestResponse<SessionDto> response = await _authService.signIn(
      email: (emailControl.value ?? '').trim(),
      password: passwordControl.value ?? '',
    );

    if (response.isSuccessful) {
      _persistSession(response.body);
      _navigationDriver.goTo(Routes.home);
      isSubmitting.value = false;
      return;
    }

    if (response.statusCode == 403) {
      await handleUnverifiedAccount();
      final String email = (emailControl.value ?? '').trim();
      _navigationDriver.goTo(Routes.getEmailConfirmation(email: email));
      isSubmitting.value = false;
      return;
    }

    applyStatusCodeError(response);
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

  void goToSignUp() {
    _navigationDriver.goTo(Routes.signUp);
  }

  void goToForgotPassword() {
    _navigationDriver.goTo(Routes.forgotPassword);
  }

  void _persistSession(SessionDto session) {
    _cacheDriver.set(CacheKeys.accessToken, session.accessToken.value);
    _cacheDriver.set(CacheKeys.refreshToken, session.refreshToken.value);
  }

  String _resolveGeneralError(RestResponse<dynamic> response) {
    final String? bodyMessage = response.errorBody?['message'] as String?;
    if (bodyMessage != null && bodyMessage.isNotEmpty) {
      return bodyMessage;
    }

    try {
      return response.errorMessage;
    } catch (_) {
      return 'Nao foi possivel entrar agora. Tente novamente.';
    }
  }

  void dispose() {
    _formStatusSubscription.cancel();
    _formValueSubscription.cancel();
    form.dispose();
    generalError.dispose();
    isSubmitting.dispose();
    isGoogleSubmitting.dispose();
    isPasswordVisible.dispose();
    _formVersion.dispose();
    canSubmit.dispose();
    canTriggerGoogleAuth.dispose();
  }
}

final signInScreenPresenterProvider = Provider.autoDispose<
  SignInScreenPresenter
>((Ref ref) {
  final AuthService authService = ref.watch(authServiceProvider);
  final GoogleAuthDriver googleAuthDriver = ref.watch(googleAuthDriverProvider);
  final CacheDriver cacheDriver = ref.watch(cacheDriverProvider);
  final NavigationDriver navigationDriver = ref.watch(navigationDriverProvider);
  final SignInScreenPresenter presenter = SignInScreenPresenter(
    authService: authService,
    googleAuthDriver: googleAuthDriver,
    cacheDriver: cacheDriver,
    navigationDriver: navigationDriver,
  );
  ref.onDispose(presenter.dispose);
  return presenter;
});
