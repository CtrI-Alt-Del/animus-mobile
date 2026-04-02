import 'package:flutter/material.dart';

import 'package:animus/theme.dart';

const Color _profileSettingsSurfaceColor = Color(0xFF1E1E24);
const Color _profileSettingsBorderColor = Color(0x33FBE26D);
const Color _profileSettingsDividerColor = Color(0x1AFBE26D);
const Color _profileChevronColor = Color(0x66FBE26D);

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
          _ProfileSettingsTile(
            title: 'Editar Nome',
            icon: Icons.person_outline,
            iconColor: tokens.accent,
            onTap: _noop,
          ),
          const _ProfileDivider(color: _profileSettingsDividerColor),
          _ProfileSettingsTile(
            title: 'Alterar Senha',
            icon: Icons.lock_outline,
            iconColor: tokens.accent,
            onTap: _noop,
          ),
          const _ProfileDivider(color: _profileSettingsDividerColor),
          _ProfileSettingsTile(
            title: 'Tema',
            icon: Icons.brightness_6_outlined,
            iconColor: tokens.accent,
            trailing: _ThemePreview(isEnabled: isDarkThemeEnabled),
            onTap: _noop,
          ),
          const _ProfileDivider(color: _profileSettingsDividerColor),
          _ProfileSettingsTile(
            title: 'Sobre o App',
            icon: Icons.info_outline,
            iconColor: tokens.accent,
            trailing: Text(
              appVersionLabel,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: tokens.textMuted,
                fontSize: 13,
              ),
            ),
            onTap: _noop,
            showChevron: false,
          ),
          const _ProfileDivider(color: _profileSettingsDividerColor),
          _ProfileSettingsTile(
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

class _ProfileSettingsTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;
  final bool isDestructive;
  final bool showChevron;
  final Widget? trailing;
  final Color? chevronColor;

  const _ProfileSettingsTile({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.onTap,
    this.isDestructive = false,
    this.showChevron = true,
    this.trailing,
    this.chevronColor,
  });

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final Color titleColor = isDestructive ? tokens.danger : tokens.textPrimary;

    final Color resolvedChevronColor = chevronColor ?? _profileChevronColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Row(
            children: <Widget>[
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: 12),
              Text(
                title,
                style: textTheme.bodyMedium?.copyWith(
                  color: titleColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              if (trailing case final Widget trailingWidget) trailingWidget,
              if (trailing != null && showChevron) const SizedBox(width: 8),
              if (showChevron)
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: resolvedChevronColor,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemePreview extends StatelessWidget {
  final bool isEnabled;

  const _ThemePreview({required this.isEnabled});

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;

    return Container(
      width: 44,
      height: 26,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(13),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isEnabled
              ? <Color>[tokens.accent, tokens.accentStrong]
              : <Color>[tokens.borderStrong, tokens.borderSubtle],
        ),
      ),
      child: Align(
        alignment: isEnabled ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: tokens.white,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}

class _ProfileDivider extends StatelessWidget {
  final Color color;

  const _ProfileDivider({required this.color});

  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, thickness: 1, color: color);
  }
}
