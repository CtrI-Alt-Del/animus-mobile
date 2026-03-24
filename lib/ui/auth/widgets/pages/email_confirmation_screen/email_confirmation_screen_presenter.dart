import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:animus_mobile/core/auth/interfaces/auth_service.dart';
import 'package:animus_mobile/core/shared/responses/rest_response.dart';
import 'package:animus_mobile/rest/services/auth_rest_service.dart';

final emailConfirmationScreenPresenterProvider = Provider.autoDispose
    .family<EmailConfirmationScreenPresenter, String>((Ref ref, String email) {
      final AuthService authService = ref.watch(authServiceProvider);
      return EmailConfirmationScreenPresenter(
        email: email,
        authService: authService,
      );
    });

class EmailConfirmationScreenPresenter {
  final String email;
  final AuthService _authService;

  final Signal<bool> isResending = signal<bool>(false);
  final Signal<String?> generalError = signal<String?>(null);
  final Signal<String?> feedbackMessage = signal<String?>(null);

  EmailConfirmationScreenPresenter({
    required this.email,
    required AuthService authService,
  }) : _authService = authService;

  Future<void> resendVerificationEmail() async {
    if (isResending.value) {
      return;
    }

    generalError.value = null;
    feedbackMessage.value = null;
    isResending.value = true;

    final RestResponse<void> response = await _authService
        .resendVerificationEmail(email: email);

    if (response.isSuccessful) {
      feedbackMessage.value =
          'Enviamos um novo link de confirmacao para $email.';
    } else {
      final String? bodyMessage = response.errorBody?['message'] as String?;
      if (bodyMessage != null && bodyMessage.isNotEmpty) {
        generalError.value = bodyMessage;
      } else {
        try {
          generalError.value = response.errorMessage;
        } catch (_) {
          generalError.value =
              'Nao foi possivel reenviar o e-mail de verificacao.';
        }
      }
    }

    isResending.value = false;
  }
}
