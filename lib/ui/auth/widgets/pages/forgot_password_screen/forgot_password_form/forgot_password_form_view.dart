import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:animus/theme.dart';
import 'package:animus/ui/auth/widgets/pages/email_confirmation_screen/message_box/index.dart';
import 'package:animus/ui/auth/widgets/pages/forgot_password_screen/forgot_password_form/forgot_password_submit_button/index.dart';
import 'package:animus/ui/auth/widgets/pages/forgot_password_screen/forgot_password_form/remembered_sign_in_hint/index.dart';
import 'package:animus/ui/auth/widgets/pages/sign_up_screen/sign_up_form/input_decoration/index.dart';

import 'forgot_password_form_presenter.dart';

class ForgotPasswordFormView extends ConsumerWidget {
  final String? initialErrorCode;

  const ForgotPasswordFormView({this.initialErrorCode, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ForgotPasswordFormPresenter presenter = ref.watch(
      forgotPasswordFormPresenterProvider(initialErrorCode),
    );

    return ReactiveForm(
      formGroup: presenter.form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ReactiveTextField<String>(
            formControlName: 'email',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color:
                  (Theme.of(context).extension<AppThemeTokens>() ??
                          AppTheme.tokens)
                      .textPrimary,
            ),
            onSubmitted: (_) => presenter.submit(),
            decoration: SignUpInputDecoration.build(
              context: context,
              hintText: 'Email',
              icon: Icons.mail_outline,
            ),
            validationMessages: presenter.emailValidationMessages,
          ),
          const SizedBox(height: 12),
          Watch((BuildContext context) {
            final String? error = presenter.generalError.watch(context);

            if (error == null || error.isEmpty) {
              return const SizedBox.shrink();
            }

            return MessageBox(message: error, color: AppTheme.tokens.danger);
          }),
          const SizedBox(height: 12),
          Watch((BuildContext context) {
            final bool isSubmitting = presenter.isSubmitting.watch(context);
            final bool canSubmit = presenter.canSubmit.watch(context);

            return ForgotPasswordSubmitButton(
              isSubmitting: isSubmitting,
              enabled: canSubmit,
              onPressed: presenter.submit,
            );
          }),
          const SizedBox(height: 12),
          RememberedSignInHint(onTap: presenter.goToSignIn),
        ],
      ),
    );
  }
}
