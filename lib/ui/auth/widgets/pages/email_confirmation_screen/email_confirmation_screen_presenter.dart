import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:animus/constants/routes.dart';
import 'package:animus/constants/cache_keys.dart';
import 'package:animus/core/auth/dtos/session_dto.dart';
import 'package:animus/core/auth/interfaces/auth_service.dart';
import 'package:animus/core/shared/interfaces/cache_driver.dart';
import 'package:animus/core/shared/responses/rest_response.dart';
import 'package:animus/drivers/cache-driver/shared_preferences_cache_driver.dart';
import 'package:animus/rest/services/index.dart';

class EmailConfirmationScreenPresenter {
  final String email;
  final AuthService _authService;
  final CacheDriverFactory _cacheDriverFactory;
  Timer? _resendTimer;

  final FormGroup form = FormGroup(<String, AbstractControl<Object>>{
    'otp': FormControl<String>(
      validators: [
        Validators.required,
        Validators.number(),
        Validators.minLength(6),
        Validators.maxLength(6),
      ],
    ),
  });

  final Signal<bool> isResending = signal<bool>(false);
  final Signal<bool> isVerifying = signal<bool>(false);
  final Signal<int> resendCountdown = signal<int>(0);
  final Signal<String?> generalError = signal<String?>(null);
  final Signal<String?> feedbackMessage = signal<String?>(null);

  EmailConfirmationScreenPresenter({
    required this.email,
    required AuthService authService,
    required CacheDriverFactory cacheDriverFactory,
  }) : _authService = authService,
       _cacheDriverFactory = cacheDriverFactory;

  FormControl<String> get otpControl =>
      form.control('otp') as FormControl<String>;

  Map<String, ValidationMessageFunction> get otpValidationMessages =>
      <String, ValidationMessageFunction>{
        ValidationMessage.required: (_) => 'Informe o codigo OTP.',
        ValidationMessage.number: (_) =>
            'O codigo OTP deve conter apenas numeros.',
        ValidationMessage.minLength: (_) => 'O codigo OTP deve ter 6 digitos.',
        ValidationMessage.maxLength: (_) => 'O codigo OTP deve ter 6 digitos.',
        'server': (Object error) => error.toString(),
      };

  String? otpErrorMessage() {
    if (!otpControl.invalid || (!otpControl.touched && !otpControl.dirty)) {
      return null;
    }

    if (otpControl.hasError('server')) {
      return '${otpControl.getError('server')}';
    }
    if (otpControl.hasError(ValidationMessage.required)) {
      return 'Informe o codigo OTP.';
    }
    if (otpControl.hasError(ValidationMessage.number)) {
      return 'O codigo OTP deve conter apenas numeros.';
    }
    if (otpControl.hasError(ValidationMessage.minLength) ||
        otpControl.hasError(ValidationMessage.maxLength)) {
      return 'O codigo OTP deve ter 6 digitos.';
    }

    return 'Codigo OTP invalido ou expirado.';
  }

  Future<void> verifyOtp(BuildContext context) async {
    if (isVerifying.value) {
      return;
    }

    generalError.value = null;
    feedbackMessage.value = null;
    otpControl.removeError('server');
    form.markAllAsTouched();

    if (form.invalid) {
      return;
    }

    isVerifying.value = true;

    final RestResponse<SessionDto> response = await _authService.verifyEmail(
      email: email,
      otp: (otpControl.value ?? '').trim(),
    );

    if (response.isSuccessful) {
      final CacheDriver cacheDriver = await _cacheDriverFactory();
      await cacheDriver.set(
        CacheKeys.accessToken,
        response.body.accessToken.value,
      );
      await cacheDriver.set(
        CacheKeys.refreshToken,
        response.body.refreshToken.value,
      );
      if (context.mounted) {
        context.go(Routes.home);
      }
      isVerifying.value = false;
      return;
    }

    if (response.statusCode == 400 || response.statusCode == 422) {
      final String? serverMessage = response.errorBody?['message'] as String?;
      otpControl.setErrors(<String, Object>{
        'server': serverMessage ?? 'Codigo OTP invalido ou expirado.',
      });
      otpControl.markAsTouched();
    } else {
      generalError.value = _resolveErrorMessage(response);
    }

    isVerifying.value = false;
  }

  Future<void> resendVerificationEmail() async {
    if (isResending.value || resendCountdown.value > 0) {
      return;
    }

    generalError.value = null;
    feedbackMessage.value = null;
    isResending.value = true;

    final RestResponse<void> response = await _authService
        .resendVerificationEmail(email: email);

    if (response.isSuccessful) {
      feedbackMessage.value = 'Enviamos um novo codigo OTP para $email.';
      _startResendCountdown();
    } else {
      generalError.value = _resolveErrorMessage(response);
    }

    isResending.value = false;
  }

  String _resolveErrorMessage(RestResponse<dynamic> response) {
    final String? bodyMessage = response.errorBody?['message'] as String?;
    if (bodyMessage != null && bodyMessage.isNotEmpty) {
      return bodyMessage;
    }

    try {
      return response.errorMessage;
    } catch (_) {
      return 'Nao foi possivel confirmar o e-mail agora. Tente novamente.';
    }
  }

  String get resendCountdownLabel =>
      '00:${resendCountdown.value.toString().padLeft(2, '0')}';

  void _startResendCountdown() {
    _resendTimer?.cancel();
    resendCountdown.value = 30;

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      final int next = resendCountdown.value - 1;
      if (next <= 0) {
        resendCountdown.value = 0;
        timer.cancel();
        return;
      }

      resendCountdown.value = next;
    });
  }

  void dispose() {
    _resendTimer?.cancel();
    form.dispose();
    isResending.dispose();
    isVerifying.dispose();
    resendCountdown.dispose();
    generalError.dispose();
    feedbackMessage.dispose();
  }
}

final emailConfirmationScreenPresenterProvider = Provider.autoDispose
    .family<EmailConfirmationScreenPresenter, String>((Ref ref, String email) {
      final AuthService authService = ref.watch(authServiceProvider);
      final CacheDriverFactory cacheDriverFactory = ref.watch(
        cacheDriverFactoryProvider,
      );
      final EmailConfirmationScreenPresenter presenter =
          EmailConfirmationScreenPresenter(
            email: email,
            authService: authService,
            cacheDriverFactory: cacheDriverFactory,
          );
      ref.onDispose(presenter.dispose);
      return presenter;
    });
