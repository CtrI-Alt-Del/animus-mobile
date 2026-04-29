import 'package:flutter/material.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:animus/theme.dart';
import 'package:animus/ui/auth/widgets/pages/check_email_screen/check_email_screen_presenter.dart';
import 'package:animus/ui/auth/widgets/pages/email_confirmation_screen/message_box/index.dart';

class CheckEmailScreenView extends ConsumerWidget {
  final String email;

  const CheckEmailScreenView({required this.email, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final CheckEmailScreenPresenter presenter = ref.watch(
      checkEmailScreenPresenterProvider(email),
    );
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: tokens.surfacePage,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 402),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                child: ReactiveForm(
                  formGroup: presenter.form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Center(
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: tokens.surfaceCard,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: tokens.accent.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Icon(
                            Icons.mark_email_read_outlined,
                            color: tokens.accent,
                            size: 40,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Verifique seu E-mail',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.fraunces(
                          textStyle: textTheme.titleMedium?.copyWith(
                            color: tokens.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enviamos um codigo OTP de 6 digitos para $email. Digite o codigo para continuar a redefinicao da senha.',
                        textAlign: TextAlign.center,
                        style: textTheme.bodySmall?.copyWith(
                          color: tokens.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      OtpTextField(
                        numberOfFields: 6,
                        fieldWidth: 52,
                        keyboardType: TextInputType.number,
                        borderRadius: BorderRadius.circular(12),
                        borderColor: tokens.borderStrong,
                        focusedBorderColor: tokens.accent,
                        enabledBorderColor: tokens.borderStrong,
                        fillColor: tokens.surfaceCard,
                        filled: true,
                        showFieldAsBox: true,
                        textStyle: const TextStyle(
                          color: Color(0xFFFAFAF9),
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          height: 1,
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
                        'Codigo valido por tempo limitado. Se ele expirar, voce pode solicitar um novo envio.',
                        textAlign: TextAlign.center,
                        style: textTheme.bodySmall?.copyWith(
                          color: tokens.textSecondary,
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
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                      Watch((BuildContext context) {
                        final bool isVerifying = presenter.isVerifying.watch(
                          context,
                        );

                        return SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: isVerifying ? null : presenter.verifyOtp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: tokens.accent,
                              foregroundColor: tokens.surfacePage,
                              disabledBackgroundColor: tokens.borderStrong,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              isVerifying ? 'Validando...' : 'Confirmar codigo',
                              style: textTheme.labelMedium?.copyWith(
                                color: tokens.surfacePage,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                      Watch((BuildContext context) {
                        final bool isResending = presenter.isResending.watch(
                          context,
                        );
                        final int resendCountdown = presenter.resendCountdown
                            .watch(context);
                        final bool canResend =
                            !isResending && resendCountdown == 0;

                        return Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 4,
                          children: <Widget>[
                            Text(
                              'Nao recebeu?',
                              style: textTheme.labelSmall?.copyWith(
                                color: tokens.textMuted,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            TextButton(
                              onPressed: canResend
                                  ? presenter.resendResetOtp
                                  : null,
                              child: Text(
                                isResending ? 'Reenviando...' : 'Reenviar',
                                style: textTheme.labelSmall?.copyWith(
                                  color: canResend
                                      ? tokens.accent
                                      : tokens.textTertiary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (!canResend)
                              Text(
                                'em ${presenter.resendCountdownLabel}',
                                style: textTheme.bodySmall?.copyWith(
                                  color: tokens.textSecondary,
                                ),
                              ),
                          ],
                        );
                      }),
                      const SizedBox(height: 16),
                      Watch((BuildContext context) {
                        final String? feedback = presenter.feedbackMessage
                            .watch(context);

                        if (feedback == null || feedback.isEmpty) {
                          return const SizedBox.shrink();
                        }

                        return MessageBox(
                          message: feedback,
                          color: tokens.accent,
                        );
                      }),
                      const SizedBox(height: 12),
                      Watch((BuildContext context) {
                        final String? error = presenter.generalError.watch(
                          context,
                        );

                        if (error == null || error.isEmpty) {
                          return const SizedBox.shrink();
                        }

                        return MessageBox(message: error, color: tokens.danger);
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
