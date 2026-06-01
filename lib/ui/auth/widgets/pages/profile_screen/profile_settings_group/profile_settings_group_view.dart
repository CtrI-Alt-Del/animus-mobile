import 'package:flutter/material.dart';

import 'package:animus/theme.dart';
import 'package:animus/ui/auth/widgets/pages/profile_screen/profile_settings_group/profile_divider/index.dart';
import 'package:animus/ui/auth/widgets/pages/profile_screen/profile_settings_group/profile_settings_tile/index.dart';
import 'package:animus/ui/auth/widgets/pages/profile_screen/profile_settings_group/profile_theme_preview/index.dart';

class ProfileSettingsGroupView extends StatelessWidget {
  final bool isDarkThemeEnabled;
  final String appVersionLabel;
  final VoidCallback onEditNameTap;
  final VoidCallback onChangePasswordTap;
  final VoidCallback onArchivedAnalysesTap;
  final VoidCallback onThemeTap;

  const ProfileSettingsGroupView({
    required this.isDarkThemeEnabled,
    required this.appVersionLabel,
    required this.onEditNameTap,
    required this.onChangePasswordTap,
    required this.onArchivedAnalysesTap,
    required this.onThemeTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final Color surfaceColor = tokens.surfaceElevated;
    final Color borderColor = tokens.accent.withValues(alpha: 0.2);
    final Color dividerColor = tokens.accent.withValues(alpha: 0.1);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: <Widget>[
          ProfileSettingsTile(
            title: 'Editar Nome',
            icon: Icons.person_outline,
            iconColor: tokens.accent,
            onTap: onEditNameTap,
          ),
          ProfileDivider(color: dividerColor),
          ProfileSettingsTile(
            title: 'Alterar Senha',
            icon: Icons.lock_outline,
            iconColor: tokens.accent,
            onTap: onChangePasswordTap,
          ),
          ProfileDivider(color: dividerColor),
          ProfileSettingsTile(
            title: 'Análises arquivadas',
            icon: Icons.inventory_2_outlined,
            iconColor: tokens.accent,
            onTap: onArchivedAnalysesTap,
          ),
          ProfileDivider(color: dividerColor),
          ProfileSettingsTile(
            title: 'Tema',
            icon: Icons.brightness_6_outlined,
            iconColor: tokens.accent,
            trailing: ProfileThemePreview(isEnabled: isDarkThemeEnabled),
            onTap: onThemeTap,
          ),
          ProfileDivider(color: dividerColor),
          ProfileSettingsTile(
            title: 'Sobre o App',
            icon: Icons.info_outline,
            iconColor: tokens.accent,
            trailing: Text(
              appVersionLabel,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: tokens.textMuted),
            ),
            onTap: _noop,
            showChevron: false,
          ),
          ProfileDivider(color: dividerColor),
          ProfileSettingsTile(
            title: 'Deletar Conta',
            icon: Icons.delete_outline,
            iconColor: tokens.danger,
            onTap: _noop,
            isDestructive: true,
            chevronColor: tokens.danger.withValues(alpha: 0.4),
          ),
        ],
      ),
    );
  }

  static void _noop() {}
}
