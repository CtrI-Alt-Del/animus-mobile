import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:animus/theme.dart';
import 'package:animus/ui/auth/widgets/components/auth_header/index.dart';
import 'package:animus/ui/auth/widgets/pages/profile_screen/profile_account_card/index.dart';
import 'package:animus/ui/auth/widgets/pages/profile_screen/profile_error_card/index.dart';
import 'package:animus/ui/auth/widgets/pages/profile_screen/profile_loading_card/index.dart';
import 'package:animus/ui/auth/widgets/pages/profile_screen/profile_logout_button/index.dart';
import 'package:animus/ui/auth/widgets/pages/profile_screen/profile_settings_group/index.dart';
import 'package:animus/ui/auth/widgets/pages/profile_screen/profile_update_name_dialog/index.dart';

import 'profile_screen_presenter.dart';

class ProfileScreenView extends ConsumerWidget {
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
                              return const ProfileLoadingCard();
                            }

                            if (errorMessage != null && !hasAccount) {
                              return ProfileErrorCard(
                                message: errorMessage,
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
                          Watch((BuildContext context) {
                            final String appVersionLabel = presenter
                                .appVersionLabel
                                .watch(context);

                            return ProfileSettingsGroup(
                              isDarkThemeEnabled:
                                  AppTheme.defaultThemeMode == ThemeMode.dark,
                              appVersionLabel: appVersionLabel,
                              onEditNameTap: () async {
                                final String currentName =
                                    presenter.displayName.value;
                                final String? updatedName =
                                    await showDialog<String>(
                                      context: context,
                                      builder: (_) => ProfileUpdateNameDialog(
                                        initialName: currentName,
                                      ),
                                    );

                                if (updatedName == null) {
                                  return;
                                }

                                await presenter.updateDisplayName(updatedName);
                              },
                              onChangePasswordTap: presenter.goToForgotPassword,
                            );
                          }),
                          const SizedBox(height: 24),
                          ProfileLogoutButton(onPressed: presenter.signOut),
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
}
