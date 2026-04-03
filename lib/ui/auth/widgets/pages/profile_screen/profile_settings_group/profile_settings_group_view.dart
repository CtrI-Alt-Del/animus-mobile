import 'package:flutter/material.dart';

import 'package:animus/theme.dart';
import 'package:animus/ui/auth/widgets/pages/profile_screen/profile_settings_group/profile_divider/index.dart';
import 'package:animus/ui/auth/widgets/pages/profile_screen/profile_settings_group/profile_settings_tile/index.dart';
import 'package:animus/ui/auth/widgets/pages/profile_screen/profile_settings_group/profile_theme_preview/index.dart';

const Color _profileSettingsSurfaceColor = Color(0xFF1E1E24);
const Color _profileSettingsBorderColor = Color(0x33FBE26D);
const Color _profileSettingsDividerColor = Color(0x1AFBE26D);

class ProfileSettingsGroupView extends StatelessWidget {
  final bool isDarkThemeEnabled;
  final String appVersionLabel;

  const ProfileSettingsGroupView({
    required this.isDarkThemeEnabled,
    required this.appVersionLabel,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: _profileSettingsSurfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _profileSettingsBorderColor),
      ),
      child: Column(
        children: <Widget>[
          ProfileSettingsTile(
            title: 'Editar Nome',
            icon: Icons.person_outline,
            iconColor: tokens.accent,
            onTap: _noop,
          ),
          const ProfileDivider(color: _profileSettingsDividerColor),
          ProfileSettingsTile(
            title: 'Alterar Senha',
            icon: Icons.lock_outline,
            iconColor: tokens.accent,
            onTap: _noop,
          ),
          const ProfileDivider(color: _profileSettingsDividerColor),
          ProfileSettingsTile(
            title: 'Tema',
            icon: Icons.brightness_6_outlined,
            iconColor: tokens.accent,
            trailing: ProfileThemePreview(isEnabled: isDarkThemeEnabled),
            onTap: _noop,
          ),
          const ProfileDivider(color: _profileSettingsDividerColor),
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
          const ProfileDivider(color: _profileSettingsDividerColor),
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
