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

class CheckEmailScreenPresenter {
  final AuthService _authService;
  final NavigationDriver _navigationDriver;
  final String email;

  final FormGroup form = FormGroup(<String, AbstractControl<Object>>{
    'otp': FormControl<String>(
      validators: <Validator<dynamic>>[
        Validators.required,
        Validators.number(),
        Validators.minLength(6),
        Validators.maxLength(6),
      ],
    ),
  });

  final Signal<bool> isVerifying = signal<bool>(false);
  final Signal<bool> isResending = signal<bool>(false);
  final Signal<int> resendCountdown = signal<int>(60);
  final Signal<String?> generalError = signal<String?>(null);
  final Signal<String?> feedbackMessage = signal<String?>(null);

  Timer? _resendTimer;

  CheckEmailScreenPresenter({
    required AuthService authService,
    required NavigationDriver navigationDriver,
    required this.email,
  }) : _authService = authService,
       _navigationDriver = navigationDriver {
    _startResendCountdown();
  }

  FormControl<String> get otpControl =>
      form.control('otp') as FormControl<String>;

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

  Future<void> verifyOtp() async {
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

    final RestResponse<String> response = await _authService
        .verifyResetPasswordOtp(
          email: email,
          otp: (otpControl.value ?? '').trim(),
        );

    if (response.isSuccessful) {
      _navigationDriver.goTo(
        Routes.getNewPassword(resetContext: response.body),
      );
      isVerifying.value = false;
      return;
    }

    if (response.statusCode == 400 ||
        response.statusCode == 401 ||
        response.statusCode == 422) {
      final String? serverMessage = response.errorBody?['message'] as String?;
      otpControl.setErrors(<String, Object>{
        'server': serverMessage ?? 'Codigo OTP invalido ou expirado.',
      });
      otpControl.markAsTouched();
    } else {
      generalError.value = _resolveGeneralError(
        response,
        fallback: 'Nao foi possivel validar o codigo agora. Tente novamente.',
      );
    }

    isVerifying.value = false;
  }

  Future<void> resendResetOtp() async {
    if (isResending.value || resendCountdown.value > 0) {
      return;
    }

    generalError.value = null;
    feedbackMessage.value = null;
    isResending.value = true;

    final RestResponse<void> response = await _authService
        .resendResetPasswordOtp(email: email);

    if (response.isSuccessful) {
      feedbackMessage.value = 'Enviamos um novo codigo OTP para $email.';
      _startResendCountdown();
      isResending.value = false;
      return;
    }

    generalError.value = _resolveGeneralError(
      response,
      fallback: 'Nao foi possivel reenviar o codigo agora. Tente novamente.',
    );
    isResending.value = false;
  }

  String get resendCountdownLabel {
    final int totalSeconds = resendCountdown.value;
    final int minutes = totalSeconds ~/ 60;
    final int seconds = totalSeconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void dispose() {
    _resendTimer?.cancel();
    form.dispose();
    isVerifying.dispose();
    isResending.dispose();
    resendCountdown.dispose();
    generalError.dispose();
    feedbackMessage.dispose();
  }

  void _startResendCountdown() {
    _resendTimer?.cancel();
    resendCountdown.value = 60;

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

  String _resolveGeneralError(
    RestResponse<dynamic> response, {
    required String fallback,
  }) {
    final String? bodyMessage = response.errorBody?['message'] as String?;
    if (bodyMessage != null && bodyMessage.isNotEmpty) {
      return bodyMessage;
    }

    try {
      return response.errorMessage;
    } catch (_) {
      return fallback;
    }
  }
}

final checkEmailScreenPresenterProvider = Provider.autoDispose
    .family<CheckEmailScreenPresenter, String>((Ref ref, String email) {
      final AuthService authService = ref.watch(authServiceProvider);
      final NavigationDriver navigationDriver = ref.watch(
        navigationDriverProvider,
      );

      final CheckEmailScreenPresenter presenter = CheckEmailScreenPresenter(
        authService: authService,
        navigationDriver: navigationDriver,
        email: email,
      );

      ref.onDispose(presenter.dispose);
      return presenter;
    });
