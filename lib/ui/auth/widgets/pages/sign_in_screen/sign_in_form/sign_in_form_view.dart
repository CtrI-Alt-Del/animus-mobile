import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:animus/theme.dart';
import 'package:animus/ui/auth/widgets/pages/sign_in_screen/sign_in_form/forgot_password_hint/index.dart';
import 'package:animus/ui/auth/widgets/pages/sign_in_screen/sign_in_form/general_error_alert/index.dart';
import 'package:animus/ui/auth/widgets/pages/sign_in_screen/sign_in_form/google_sign_in_button/index.dart';
import 'package:animus/ui/auth/widgets/pages/sign_in_screen/sign_in_form/or_divider/index.dart';
import 'package:animus/ui/auth/widgets/pages/sign_in_screen/sign_in_form/sign_in_submit_button/index.dart';
import 'package:animus/ui/auth/widgets/pages/sign_in_screen/sign_in_form/sign_up_hint/index.dart';

import 'sign_in_form_presenter.dart';

class SignInFormView extends ConsumerWidget {
  const SignInFormView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SignInFormPresenter presenter = ref.watch(
      signInFormPresenterProvider,
    );
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return ReactiveForm(
      formGroup: presenter.form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ReactiveTextField<String>(
            formControlName: 'email',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            style: textTheme.labelMedium?.copyWith(color: tokens.textPrimary),
            decoration: _buildInputDecoration(
              context: context,
              hintText: 'Email',
              icon: Icons.mail_outline,
            ),
            validationMessages: presenter.emailValidationMessages,
          ),
          const SizedBox(height: 12),
          Watch((BuildContext context) {
            final bool isVisible = presenter.isPasswordVisible.watch(context);
            return ReactiveTextField<String>(
              formControlName: 'password',
              textInputAction: TextInputAction.done,
              obscureText: !isVisible,
              style: textTheme.labelMedium?.copyWith(color: tokens.textPrimary),
              onSubmitted: (_) => presenter.submit(),
              decoration: _buildInputDecoration(
                context: context,
                hintText: 'Senha',
                icon: Icons.lock_outline,
                suffixIcon: IconButton(
                  icon: Icon(
                    isVisible ? Icons.visibility_off : Icons.visibility,
                    color: tokens.accent,
                  ),
                  onPressed: presenter.togglePasswordVisibility,
                ),
              ),
              validationMessages: presenter.passwordValidationMessages,
            );
          }),
          const SizedBox(height: 8),
          const ForgotPasswordHint(),
          const SizedBox(height: 12),
          Watch((BuildContext context) {
            final String? error = presenter.generalError.watch(context);
            return GeneralErrorAlert(message: error);
          }),
          Watch((BuildContext context) {
            final bool isSubmitting = presenter.isSubmitting.watch(context);
            final bool canSubmit = presenter.canSubmit.watch(context);
            return SignInSubmitButton(
              isSubmitting: isSubmitting,
              enabled: canSubmit,
              onPressed: presenter.submit,
            );
          }),
          const SizedBox(height: 12),
          const OrDivider(),
          const SizedBox(height: 12),
          const GoogleSignInButton(enabled: false),
          const SizedBox(height: 12),
          SignUpHint(onTap: presenter.goToSignUp),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required BuildContext context,
    required String hintText,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return InputDecoration(
      hintText: hintText,
      hintStyle: textTheme.bodySmall?.copyWith(color: tokens.textSecondary),
      filled: true,
      fillColor: tokens.surfaceElevated,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      prefixIcon: Icon(icon, color: tokens.accent, size: 18),
      suffixIcon: suffixIcon,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: tokens.accent.withValues(alpha: 0.21)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: tokens.accent.withValues(alpha: 0.5),
          width: 1.2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: tokens.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: tokens.danger, width: 1.2),
      ),
    );
  }
}
