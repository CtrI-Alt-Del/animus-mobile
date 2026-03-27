import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:animus/theme.dart';
import 'package:animus/ui/auth/widgets/pages/email_confirmation_screen/message_box/index.dart';
import 'package:animus/ui/auth/widgets/pages/new_password_screen/new_password_form/password_rule_row/index.dart';
import 'package:animus/ui/auth/widgets/pages/new_password_screen/new_password_form/reset_password_submit_button/index.dart';
import 'package:animus/ui/auth/widgets/pages/sign_up_screen/sign_up_form/input_decoration/index.dart';

import 'new_password_form_presenter.dart';

class NewPasswordFormView extends ConsumerWidget {
  final String accountId;

  const NewPasswordFormView({required this.accountId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final NewPasswordFormPresenter presenter = ref.watch(
      newPasswordFormPresenterProvider(accountId),
    );
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return ReactiveForm(
      formGroup: presenter.form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Watch((BuildContext context) {
            final bool isVisible = presenter.isPasswordVisible.watch(context);

            return ReactiveTextField<String>(
              formControlName: 'newPassword',
              textInputAction: TextInputAction.next,
              obscureText: !isVisible,
              style: textTheme.labelMedium?.copyWith(color: tokens.textPrimary),
              onChanged: (FormControl<String> control) {
                presenter.onPasswordChanged(control.value);
              },
              decoration: SignUpInputDecoration.build(
                context: context,
                hintText: 'Nova Senha',
                icon: Icons.lock_outline,
                suffixIcon: IconButton(
                  onPressed: presenter.togglePasswordVisibility,
                  icon: Icon(
                    isVisible ? Icons.visibility_off : Icons.visibility,
                    color: tokens.accent,
                  ),
                ),
              ),
              validationMessages: presenter.newPasswordValidationMessages,
            );
          }),
          const SizedBox(height: 12),
          Watch((BuildContext context) {
            final int score = presenter.passwordStrengthScore.watch(context);

            return Row(
              children: List<Widget>.generate(3, (int index) {
                final bool isActive = index < score;
                final Color color = !isActive
                    ? tokens.borderSubtle
                    : score == 3
                    ? tokens.warning
                    : tokens.success;

                return Expanded(
                  child: Container(
                    height: 6,
                    margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: color,
                    ),
                  ),
                );
              }),
            );
          }),
          const SizedBox(height: 12),
          Watch((BuildContext context) {
            final bool hasMinLength = presenter.hasMinLength.watch(context);
            final bool hasUppercaseLetter = presenter.hasUppercaseLetter.watch(
              context,
            );
            final bool hasNumber = presenter.hasNumber.watch(context);

            return Column(
              children: <Widget>[
                PasswordRuleRow(label: '8 caracteres', isMet: hasMinLength),
                const SizedBox(height: 8),
                PasswordRuleRow(
                  label: 'Letra maiuscula',
                  isMet: hasUppercaseLetter,
                ),
                const SizedBox(height: 8),
                PasswordRuleRow(label: 'Numero', isMet: hasNumber),
              ],
            );
          }),
          const SizedBox(height: 12),
          Watch((BuildContext context) {
            final bool isVisible = presenter.isConfirmPasswordVisible.watch(
              context,
            );

            return ReactiveTextField<String>(
              formControlName: 'confirmPassword',
              textInputAction: TextInputAction.done,
              obscureText: !isVisible,
              style: textTheme.labelMedium?.copyWith(color: tokens.textPrimary),
              onSubmitted: (_) => presenter.submit(),
              decoration: SignUpInputDecoration.build(
                context: context,
                hintText: 'Confirmar Senha',
                icon: Icons.lock_outline,
                suffixIcon: IconButton(
                  onPressed: presenter.toggleConfirmPasswordVisibility,
                  icon: Icon(
                    isVisible ? Icons.visibility_off : Icons.visibility,
                    color: tokens.accent,
                  ),
                ),
              ),
              validationMessages: presenter.confirmPasswordValidationMessages,
            );
          }),
          const SizedBox(height: 12),
          Watch((BuildContext context) {
            final String? error = presenter.generalError.watch(context);

            if (error == null || error.isEmpty) {
              return const SizedBox.shrink();
            }

            return MessageBox(message: error, color: tokens.danger);
          }),
          const SizedBox(height: 12),
          Watch((BuildContext context) {
            final bool isSubmitting = presenter.isSubmitting.watch(context);
            final bool canSubmit = presenter.canSubmit.watch(context);

            return ResetPasswordSubmitButton(
              isSubmitting: isSubmitting,
              enabled: canSubmit,
              onPressed: presenter.submit,
            );
          }),
        ],
      ),
    );
  }
}
