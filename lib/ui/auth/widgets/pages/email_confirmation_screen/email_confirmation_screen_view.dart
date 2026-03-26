import 'package:flutter/material.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:animus/ui/auth/widgets/pages/email_confirmation_screen/email_confirmation_screen_presenter.dart';
import 'package:animus/ui/auth/widgets/pages/email_confirmation_screen/message_box/index.dart';

class EmailConfirmationScreenView extends ConsumerWidget {
  final String email;

  const EmailConfirmationScreenView({required this.email, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final EmailConfirmationScreenPresenter presenter = ref.watch(
      emailConfirmationScreenPresenterProvider(email),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0E),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Container(height: 2, color: const Color(0xFFFBE26D)),
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
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Icon(
                                Icons.balance,
                                color: Color(0xFFFBE26D),
                                size: 28,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Animus',
                                style: TextStyle(
                                  color: Color(0xFFFBE26D),
                                  fontSize: 38,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.8,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Inteligencia juridica ao seu lado',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0x99FBE26D),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 28),
                          const Text(
                            'Verifique seu e-mail',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFFFAFAF9),
                              fontSize: 36,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.8,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Enviamos um codigo OTP de 6 digitos para $email. '
                            'Digite o codigo para liberar o acesso ao app.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF6B6B70),
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
                              color: const Color(0xFF1A1A1E),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0x33FBE26D),
                              ),
                            ),
                            child: const Row(
                              children: <Widget>[
                                Icon(
                                  Icons.mark_email_read_outlined,
                                  color: Color(0xFFFBE26D),
                                  size: 18,
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Codigo enviado para o e-mail cadastrado. Validade de 1 hora.',
                                    style: TextStyle(
                                      color: Color(0xFFFAFAF9),
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
                            borderColor: const Color(0xFF2A2A2E),
                            focusedBorderColor: const Color(0xFFFBE26D),
                            enabledBorderColor: const Color(0xFF2A2A2E),
                            fillColor: const Color(0xFF1A1A1E),
                            filled: true,
                            showFieldAsBox: true,
                            textStyle: const TextStyle(
                              color: Color(0xFFFAFAF9),
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
                          const Text(
                            'Codigo valido por 1 hora. Se ele expirar, voce pode solicitar um novo envio.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF8E8E93),
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
                                style: const TextStyle(
                                  color: Color(0xFFEF4444),
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
                                color: const Color(0xFFFBE26D),
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
                                color: const Color(0xFFEF4444),
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
                                  backgroundColor: const Color(0xFFFBE26D),
                                  foregroundColor: const Color(0xFF0B0B0E),
                                  disabledBackgroundColor: const Color(
                                    0xFFFBE26D,
                                  ).withValues(alpha: 0.6),
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
                                  const Text(
                                    'Nao recebeu o codigo?',
                                    style: TextStyle(
                                      color: Color(0xFF8E8E93),
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
                                            ? const Color(0xFF6B6B70)
                                            : const Color(0xFFFBE26D),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    resendCountdown > 0
                                        ? 'em ${presenter.resendCountdownLabel}'
                                        : '',
                                    style: const TextStyle(
                                      color: Color(0xFF8E8E93),
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
