import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:animus/theme.dart';
import 'package:animus/ui/auth/widgets/pages/sign_up_screen/password_strength_indicator/index.dart';
import 'package:animus/ui/auth/widgets/pages/sign_up_screen/sign_up_form/general_error_alert/index.dart';
import 'package:animus/ui/auth/widgets/pages/sign_up_screen/sign_up_form/input_decoration/index.dart';
import 'package:animus/ui/auth/widgets/pages/sign_up_screen/sign_up_form/sign_in_hint/index.dart';
import 'package:animus/ui/auth/widgets/pages/sign_up_screen/sign_up_form/sign_up_submit_button/index.dart';
import 'package:animus/ui/auth/widgets/pages/sign_up_screen/sign_up_form/terms_label/index.dart';

import 'sign_up_form_presenter.dart';

class SignUpFormView extends ConsumerWidget {
  const SignUpFormView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SignUpFormPresenter presenter = ref.watch(
      signUpFormPresenterProvider,
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
            formControlName: 'name',
            textInputAction: TextInputAction.next,
            style: textTheme.labelMedium?.copyWith(color: tokens.textPrimary),
            decoration: SignUpInputDecoration.build(
              context: context,
              hintText: 'Nome completo',
              icon: Icons.person_outline,
            ),
            validationMessages: presenter.nameValidationMessages,
          ),
          const SizedBox(height: 12),
          ReactiveTextField<String>(
            formControlName: 'email',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            style: textTheme.labelMedium?.copyWith(color: tokens.textPrimary),
            decoration: SignUpInputDecoration.build(
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
              textInputAction: TextInputAction.next,
              obscureText: !isVisible,
              style: textTheme.labelMedium?.copyWith(color: tokens.textPrimary),
              onChanged: (FormControl<String> control) {
                presenter.onPasswordChanged(control.value);
              },
              decoration: SignUpInputDecoration.build(
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
          Watch((BuildContext context) {
            return PasswordStrengthIndicator(
              score: presenter.passwordStrengthScore.watch(context),
              hasMinLength: presenter.hasMinLength.watch(context),
              hasUppercaseLetter: presenter.hasUppercaseLetter.watch(context),
              hasNumber: presenter.hasNumber.watch(context),
            );
          }),
          const SizedBox(height: 8),
          Watch((BuildContext context) {
            final bool isVisible = presenter.isConfirmPasswordVisible.watch(
              context,
            );
            return ReactiveTextField<String>(
              formControlName: 'confirmPassword',
              textInputAction: TextInputAction.done,
              obscureText: !isVisible,
              style: textTheme.labelMedium?.copyWith(color: tokens.textPrimary),
              onSubmitted: (_) => presenter.submit(context),
              decoration: SignUpInputDecoration.build(
                context: context,
                hintText: 'Confirmar senha',
                icon: Icons.lock_outline,
                suffixIcon: IconButton(
                  icon: Icon(
                    isVisible ? Icons.visibility_off : Icons.visibility,
                    color: tokens.accent,
                  ),
                  onPressed: presenter.toggleConfirmPasswordVisibility,
                ),
              ),
              validationMessages: presenter.confirmPasswordValidationMessages,
            );
          }),
          const SizedBox(height: 12),
          const TermsLabel(),
          const SizedBox(height: 12),
          Watch((BuildContext context) {
            final String? error = presenter.generalError.watch(context);
            return GeneralErrorAlert(message: error);
          }),
          const SizedBox(height: 6),
          Watch((BuildContext context) {
            final bool isSubmitting = presenter.isSubmitting.watch(context);
            final bool canSubmit = presenter.canSubmit.watch(context);

            return SignUpSubmitButton(
              isSubmitting: isSubmitting,
              enabled: canSubmit,
              onPressed: () => presenter.submit(context),
            );
          }),
          const SizedBox(height: 14),
          const SignInHint(),
        ],
      ),
    );
  }
}
