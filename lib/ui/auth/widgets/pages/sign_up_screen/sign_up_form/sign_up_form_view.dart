import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:animus_mobile/ui/auth/widgets/pages/sign_up_screen/password_strength_indicator/index.dart';
import 'package:animus_mobile/ui/auth/widgets/pages/sign_up_screen/sign_up_form/general_error_alert/index.dart';
import 'package:animus_mobile/ui/auth/widgets/pages/sign_up_screen/sign_up_form/sign_up_submit_button/index.dart';

import 'sign_up_form_presenter.dart';

class SignUpFormView extends ConsumerWidget {
  const SignUpFormView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SignUpFormPresenter presenter = ref.watch(
      signUpFormPresenterProvider,
    );

    return ReactiveForm(
      formGroup: presenter.form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ReactiveTextField<String>(
            formControlName: 'name',
            textInputAction: TextInputAction.next,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration(
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
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration(
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
              style: const TextStyle(color: Colors.white),
              onChanged: (FormControl<String> control) {
                presenter.onPasswordChanged(control.value);
              },
              decoration: _inputDecoration(
                hintText: 'Senha',
                icon: Icons.lock_outline,
                suffixIcon: IconButton(
                  icon: Icon(
                    isVisible ? Icons.visibility_off : Icons.visibility,
                    color: const Color(0xFF666A85),
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
              style: const TextStyle(color: Colors.white),
              onSubmitted: (_) => presenter.submit(context),
              decoration: _inputDecoration(
                hintText: 'Confirmar senha',
                icon: Icons.lock_outline,
                suffixIcon: IconButton(
                  icon: Icon(
                    isVisible ? Icons.visibility_off : Icons.visibility,
                    color: const Color(0xFF666A85),
                  ),
                  onPressed: presenter.toggleConfirmPasswordVisibility,
                ),
              ),
              validationMessages: presenter.confirmPasswordValidationMessages,
            );
          }),
          const SizedBox(height: 12),
          const _TermsLabel(),
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
          const _SignInHint(),
        ],
      ),
    );
  }
}

InputDecoration _inputDecoration({
  required String hintText,
  required IconData icon,
  Widget? suffixIcon,
}) {
  const Color borderColor = Color(0xFF24283A);
  return InputDecoration(
    hintText: hintText,
    hintStyle: const TextStyle(color: Color(0xFF666A85), fontSize: 14),
    filled: true,
    fillColor: const Color(0xFF0F1220),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
    prefixIcon: Icon(icon, color: const Color(0xFF666A85), size: 18),
    suffixIcon: suffixIcon,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: borderColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFF6268FF), width: 1.1),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFE55454)),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFE55454), width: 1.1),
    ),
  );
}

class _TermsLabel extends StatelessWidget {
  const _TermsLabel();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          height: 14,
          width: 14,
          decoration: BoxDecoration(
            color: const Color(0xFF6268FF),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Icon(Icons.check, size: 11, color: Colors.white),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: const TextSpan(
              style: TextStyle(color: Color(0xFF6C708A), fontSize: 11),
              children: <TextSpan>[
                TextSpan(text: 'Li e concordo com os '),
                TextSpan(
                  text: 'Termos de Uso',
                  style: TextStyle(color: Color(0xFF6670FF)),
                ),
                TextSpan(text: ' e Politica de Privacidade'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SignInHint extends StatelessWidget {
  const _SignInHint();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: RichText(
        text: const TextSpan(
          style: TextStyle(color: Color(0xFF6C708A), fontSize: 12),
          children: <TextSpan>[
            TextSpan(text: 'Ja tem conta? '),
            TextSpan(
              text: 'Entrar',
              style: TextStyle(
                color: Color(0xFF6670FF),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
