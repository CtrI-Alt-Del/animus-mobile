import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:animus/theme.dart';
import 'package:animus/ui/auth/widgets/pages/forgot_password_screen/nav_back_row/index.dart';
import 'package:animus/ui/auth/widgets/pages/new_password_screen/new_password_form/index.dart';
import 'package:animus/ui/auth/widgets/pages/new_password_screen/new_password_screen_presenter.dart';

class NewPasswordScreenView extends ConsumerWidget {
  final String accountId;

  const NewPasswordScreenView({required this.accountId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final NewPasswordScreenPresenter presenter = ref.watch(
      newPasswordScreenPresenterProvider(accountId),
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
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    NavBackRow(
                      title: 'Nova Senha',
                      onBack: presenter.goToSignIn,
                    ),
                    const SizedBox(height: 24),
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
                          Icons.shield_outlined,
                          color: tokens.accent,
                          size: 48,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Nova Senha',
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
                      'Crie uma nova senha segura.',
                      textAlign: TextAlign.center,
                      style: textTheme.bodySmall?.copyWith(
                        color: tokens.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    NewPasswordForm(accountId: accountId),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
