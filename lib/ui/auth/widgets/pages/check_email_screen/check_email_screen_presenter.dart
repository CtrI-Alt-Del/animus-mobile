import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:animus/core/auth/interfaces/auth_service.dart';
import 'package:animus/core/shared/responses/rest_response.dart';
import 'package:animus/rest/services/index.dart';

class CheckEmailScreenPresenter {
  final AuthService _authService;
  final String email;

  final Signal<bool> isResending = signal<bool>(false);
  final Signal<int> resendCountdown = signal<int>(60);
  final Signal<String?> generalError = signal<String?>(null);
  final Signal<String?> feedbackMessage = signal<String?>(null);

  Timer? _resendTimer;

  CheckEmailScreenPresenter({
    required AuthService authService,
    required this.email,
  }) : _authService = authService {
    _startResendCountdown();
  }

  Future<void> resend() async {
    if (isResending.value || resendCountdown.value > 0) {
      return;
    }

    generalError.value = null;
    feedbackMessage.value = null;
    isResending.value = true;

    final RestResponse<void> response = await _authService.forgotPassword(
      email: email,
    );

    if (response.isSuccessful) {
      feedbackMessage.value = 'Enviamos um novo link para $email.';
      _startResendCountdown();
      isResending.value = false;
      return;
    }

    generalError.value = _resolveGeneralError(response);
    isResending.value = false;
  }

  String get resendCountdownLabel =>
      '00:${resendCountdown.value.toString().padLeft(2, '0')}';

  void dispose() {
    _resendTimer?.cancel();
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

  String _resolveGeneralError(RestResponse<dynamic> response) {
    final String? bodyMessage = response.errorBody?['message'] as String?;
    if (bodyMessage != null && bodyMessage.isNotEmpty) {
      return bodyMessage;
    }

    try {
      return response.errorMessage;
    } catch (_) {
      return 'Nao foi possivel reenviar o link agora. Tente novamente.';
    }
  }
}

final checkEmailScreenPresenterProvider = Provider.autoDispose
    .family<CheckEmailScreenPresenter, String>((Ref ref, String email) {
      final AuthService authService = ref.watch(authServiceProvider);

      final CheckEmailScreenPresenter presenter = CheckEmailScreenPresenter(
        authService: authService,
        email: email,
      );

      ref.onDispose(presenter.dispose);
      return presenter;
    });
