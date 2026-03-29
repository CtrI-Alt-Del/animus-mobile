import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:animus/theme.dart';
import 'package:animus/ui/auth/widgets/pages/forgot_password_screen/forgot_password_form/index.dart';
import 'package:animus/ui/auth/widgets/pages/forgot_password_screen/nav_back_row/index.dart';
import 'package:animus/ui/auth/widgets/pages/forgot_password_screen/forgot_password_screen_presenter.dart';

class ForgotPasswordScreenView extends ConsumerWidget {
  final String? initialErrorCode;

  const ForgotPasswordScreenView({this.initialErrorCode, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ForgotPasswordScreenPresenter presenter = ref.watch(
      forgotPasswordScreenPresenterProvider(initialErrorCode),
    );
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: tokens.surfacePage,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 402),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          NavBackRow(
                            title: 'Recuperar Senha',
                            onBack: presenter.goToSignIn,
                          ),
                          const SizedBox(height: 24),
                          Align(
                            alignment: Alignment.center,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: tokens.surfaceCard,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.lock,
                                color: tokens.accent,
                                size: 48,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Esqueceu sua senha?',
                            style: GoogleFonts.fraunces(
                              textStyle: textTheme.titleMedium?.copyWith(
                                color: tokens.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Digite seu e-mail cadastrado e enviaremos um link para redefinir sua senha.',
                            style: textTheme.bodySmall?.copyWith(
                              color: tokens.textMuted,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ForgotPasswordForm(
                            initialErrorCode: initialErrorCode,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
