import 'package:flutter/material.dart';

import 'package:animus/theme.dart';

const Color _profileChevronColor = Color(0x66FBE26D);

class ProfileSettingsTileView extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;
  final bool isDestructive;
  final bool showChevron;
  final Widget? trailing;
  final Color? chevronColor;

  const ProfileSettingsTileView({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.onTap,
    this.isDestructive = false,
    this.showChevron = true,
    this.trailing,
    this.chevronColor,
    super.key,
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
                style: textTheme.labelMedium?.copyWith(
                  color: titleColor,
                  fontWeight: FontWeight.w500,
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
