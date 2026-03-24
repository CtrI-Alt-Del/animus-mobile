import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;
import 'package:signals_flutter/signals_flutter.dart';

import 'package:animus_mobile/ui/auth/widgets/pages/email_confirmation_screen/email_confirmation_screen_presenter.dart';
import 'package:animus_mobile/ui/auth/widgets/pages/email_confirmation_screen/message_box/index.dart';

class EmailConfirmationScreenView extends ConsumerWidget {
  final String email;

  const EmailConfirmationScreenView({required this.email, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final EmailConfirmationScreenPresenter presenter = ref.watch(
      emailConfirmationScreenPresenterProvider(email),
    );

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(
                        'Confirme seu e-mail',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enviamos um link de verificacao para $email. '
                        'Abra sua caixa de entrada para concluir o cadastro.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      Watch((BuildContext context) {
                        final String? feedback = presenter.feedbackMessage
                            .watch(context);
                        if (feedback == null || feedback.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: MessageBox(
                            message: feedback,
                            color: Theme.of(context).colorScheme.primary,
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
                          padding: const EdgeInsets.only(bottom: 12),
                          child: MessageBox(
                            message: error,
                            color: Theme.of(context).colorScheme.error,
                          ),
                        );
                      }),
                      Watch((BuildContext context) {
                        final bool isResending = presenter.isResending.watch(
                          context,
                        );
                        return shadcn.Button.primary(
                          onPressed: isResending
                              ? null
                              : presenter.resendVerificationEmail,
                          trailing: isResending
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : null,
                          child: Text(
                            isResending
                                ? 'Reenviando...'
                                : 'Reenviar e-mail de verificacao',
                          ),
                        );
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
