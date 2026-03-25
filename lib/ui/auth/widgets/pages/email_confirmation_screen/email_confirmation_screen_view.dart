import 'package:flutter/material.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:animus/theme.dart';
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
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

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
                              SizedBox(width: 8),
                              Text(
                                'Animus',
                                style: textTheme.headlineMedium?.copyWith(
                                  color: tokens.accent,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.8,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Inteligencia juridica ao seu lado',
                            textAlign: TextAlign.center,
                            style: textTheme.bodySmall?.copyWith(
                              color: tokens.accent.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 28),
                          Text(
                            'Verifique seu e-mail',
                            textAlign: TextAlign.center,
                            style: textTheme.headlineLarge?.copyWith(
                              color: tokens.textPrimary,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.8,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Enviamos um codigo OTP de 6 digitos para $email. '
                            'Digite o codigo para liberar o acesso ao app.',
                            textAlign: TextAlign.center,
                            style: textTheme.bodySmall?.copyWith(
                              color: tokens.textSecondary,
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
                                    'Codigo enviado para o e-mail cadastrado. Validade de 1 hora.',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: tokens.textPrimary,
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
                            textStyle: textTheme.titleMedium?.copyWith(
                              color: tokens.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                            onCodeChanged: (String code) {
                              presenter.otpControl.value = code;
                              presenter.otpControl.markAsDirty();
                              presenter.otpControl.removeError('server');
                            },
                            onSubmit: (String verificationCode) {
                              presenter.otpControl.value = verificationCode;
                              presenter.verifyOtp(context);
                            },
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Codigo valido por 1 hora. Se ele expirar, voce pode solicitar um novo envio.',
                            textAlign: TextAlign.center,
                            style: textTheme.bodySmall?.copyWith(
                              color: tokens.textMuted,
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
                                style: textTheme.bodySmall?.copyWith(
                                  color: tokens.danger,
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
                                    : () => presenter.verifyOtp(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: tokens.accent,
                                  foregroundColor: tokens.surfacePage,
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
                                  style: textTheme.labelMedium?.copyWith(
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
                                    'Nao recebeu o codigo?',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: tokens.textMuted,
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
                                        fontSize: textTheme.bodySmall?.fontSize,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    resendCountdown > 0
                                        ? 'em ${presenter.resendCountdownLabel}'
                                        : '',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: tokens.textMuted,
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
