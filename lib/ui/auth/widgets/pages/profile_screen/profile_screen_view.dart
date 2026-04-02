import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:animus/theme.dart';
import 'package:animus/ui/auth/widgets/components/auth_header/index.dart';
import 'package:animus/ui/auth/widgets/pages/email_confirmation_screen/message_box/index.dart';
import 'package:animus/ui/auth/widgets/pages/profile_screen/profile_account_card/index.dart';
import 'package:animus/ui/auth/widgets/pages/profile_screen/profile_logout_button/index.dart';
import 'package:animus/ui/auth/widgets/pages/profile_screen/profile_settings_group/index.dart';

import 'profile_screen_presenter.dart';

const Color _profileFeedbackSurfaceColor = Color(0xFF1E1E24);
const Color _profileFeedbackBorderColor = Color(0x33FBE26D);

class ProfileScreenView extends ConsumerWidget {
  static const String _appVersionLabel = 'v1.0.0';

  const ProfileScreenView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(profileScreenInitializationProvider);

    final ProfileScreenPresenter presenter = ref.watch(
      profileScreenPresenterProvider,
    );
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;

    return Scaffold(
      backgroundColor: tokens.surfacePage,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const AuthHeader(
                    title: 'Perfil',
                    subtitle: 'Gerencie as informacoes da sua conta',
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Watch((BuildContext context) {
                            final bool isLoading = presenter
                                .isLoadingInitialData
                                .watch(context);
                            final bool hasAccount = presenter.hasAccount.watch(
                              context,
                            );
                            final String? errorMessage = presenter.generalError
                                .watch(context);
                            final String initial = presenter.displayInitial
                                .watch(context);
                            final String name = presenter.displayName.watch(
                              context,
                            );
                            final String email = presenter.displayEmail.watch(
                              context,
                            );

                            if (isLoading && !hasAccount) {
                              return _ProfileLoadingCard(tokens: tokens);
                            }

                            if (errorMessage != null && !hasAccount) {
                              return _ProfileErrorCard(
                                message: errorMessage,
                                tokens: tokens,
                                onRetry: presenter.initialize,
                              );
                            }

                            return ProfileAccountCard(
                              initial: initial,
                              name: name,
                              email: email,
                            );
                          }),
                          const SizedBox(height: 16),
                          const ProfileSettingsGroup(
                            isDarkThemeEnabled:
                                AppTheme.defaultThemeMode == ThemeMode.dark,
                            appVersionLabel: _appVersionLabel,
                          ),
                          const SizedBox(height: 24),
                          ProfileLogoutButton(onPressed: _noop),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static void _noop() {}
}

class _ProfileLoadingCard extends StatelessWidget {
  final AppThemeTokens tokens;

  const _ProfileLoadingCard({required this.tokens});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _profileFeedbackSurfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _profileFeedbackBorderColor),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _ProfileErrorCard extends StatelessWidget {
  final String message;
  final AppThemeTokens tokens;
  final VoidCallback onRetry;

  const _ProfileErrorCard({
    required this.message,
    required this.tokens,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _profileFeedbackSurfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _profileFeedbackBorderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            MessageBox(message: message, color: tokens.danger),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}
