import 'package:flutter/material.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:animus/theme.dart';
import 'package:animus/ui/auth/widgets/pages/email_confirmation_screen/email_confirmation_screen_presenter.dart';
import 'package:animus/ui/intake/widgets/components/message_box/index.dart';

class EmailConfirmationScreenView extends ConsumerWidget {
  final String email;

  const EmailConfirmationScreenView({required this.email, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final EmailConfirmationScreenPresenter presenter = ref.watch(
      emailConfirmationScreenPresenterProvider(email),
    );
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;

    return Scaffold(
      backgroundColor: tokens.surfacePage,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Container(height: 2, color: tokens.accent),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 402),
                    child: ReactiveForm(
                      formGroup: presenter.form,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Icon(
                                Icons.balance,
                                color: tokens.accent,
                                size: 28,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Animus',
                                style: TextStyle(
                                  color: tokens.accent,
                                  fontSize: 38,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.8,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Inteligência jurídica ao seu lado',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: tokens.accent.withValues(alpha: 0.6),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 28),
                          Text(
                            'Verifique seu e-mail',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: tokens.textPrimary,
                              fontSize: 36,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.8,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Enviamos um código OTP de 6 dígitos para $email. '
                            'Digite o código para liberar o acesso ao app.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: tokens.textSecondary,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: tokens.surfaceElevated,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: tokens.accent.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              children: <Widget>[
                                Icon(
                                  Icons.mark_email_read_outlined,
                                  color: tokens.accent,
                                  size: 18,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Código enviado para o e-mail cadastrado. Validade de 1 hora.',
                                    style: TextStyle(
                                      color: tokens.textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          OtpTextField(
                            numberOfFields: 6,
                            fieldWidth: 52,
                            borderRadius: BorderRadius.circular(12),
                            borderColor: tokens.borderSubtle,
                            focusedBorderColor: tokens.accent,
                            enabledBorderColor: tokens.borderSubtle,
                            fillColor: tokens.surfaceElevated,
                            filled: true,
                            showFieldAsBox: true,
                            textStyle: TextStyle(
                              color: tokens.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                            onCodeChanged: (String code) {
                              presenter.otpControl.value = code;
                              presenter.otpControl.markAsDirty();
                              presenter.otpControl.removeError('server');
                            },
                            onSubmit: (String verificationCode) {
                              presenter.otpControl.value = verificationCode;
                              presenter.verifyOtp();
                            },
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Código válido por 1 hora. Se ele expirar, você pode solicitar um novo envio.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: tokens.textMuted,
                              fontSize: 13,
                            ),
                          ),
                          Watch((BuildContext context) {
                            final String? error = presenter.otpErrorMessage();
                            if (error == null) {
                              return const SizedBox(height: 10);
                            }

                            return Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Text(
                                error,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: tokens.danger,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }),
                          Watch((BuildContext context) {
                            final String? feedback = presenter.feedbackMessage
                                .watch(context);
                            if (feedback == null || feedback.isEmpty) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: MessageBox(
                                message: feedback,
                                color: tokens.accent,
                              ),
                            );
                          }),
                          Watch((BuildContext context) {
                            final String? error = presenter.generalError.watch(
                              context,
                            );
                            if (error == null || error.isEmpty) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: MessageBox(
                                message: error,
                                color: tokens.danger,
                              ),
                            );
                          }),
                          const SizedBox(height: 20),
                          Watch((BuildContext context) {
                            final bool isVerifying = presenter.isVerifying
                                .watch(context);
                            return SizedBox(
                              height: 52,
                              child: ElevatedButton(
                                onPressed: isVerifying
                                    ? null
                                    : presenter.verifyOtp,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: tokens.accent,
                                  foregroundColor: tokens.onAccent,
                                  disabledBackgroundColor: tokens.accent
                                      .withValues(alpha: 0.6),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  isVerifying
                                      ? 'Validando...'
                                      : 'Confirmar e-mail',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 14),
                          Center(
                            child: Watch((BuildContext context) {
                              final bool isResending = presenter.isResending
                                  .watch(context);
                              final int resendCountdown = presenter
                                  .resendCountdown
                                  .watch(context);
                              final bool resendBlocked =
                                  isResending || resendCountdown > 0;
                              return Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 4,
                                children: <Widget>[
                                  Text(
                                    'Não recebeu o código?',
                                    style: TextStyle(
                                      color: tokens.textMuted,
                                      fontSize: 13,
                                    ),
                                  ),
                                  InkWell(
                                    onTap: resendBlocked
                                        ? null
                                        : presenter.resendVerificationEmail,
                                    child: Text(
                                      isResending
                                          ? 'Reenviando...'
                                          : 'Reenviar',
                                      style: TextStyle(
                                        color: resendBlocked
                                            ? tokens.textSecondary
                                            : tokens.accent,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    resendCountdown > 0
                                        ? 'em ${presenter.resendCountdownLabel}'
                                        : '',
                                    style: TextStyle(
                                      color: tokens.textMuted,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
