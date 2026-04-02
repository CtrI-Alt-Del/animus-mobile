import 'package:flutter/material.dart';

import 'package:animus/theme.dart';

const Color _logoutBackgroundColor = Color(0x1AEF4444);
const Color _logoutBorderColor = Color(0x4DEF4444);

class ProfileLogoutButtonView extends StatelessWidget {
  final VoidCallback onPressed;

  const ProfileLogoutButtonView({required this.onPressed, super.key});

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;

    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            height: 52,
            decoration: BoxDecoration(
              color: _logoutBackgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _logoutBorderColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(Icons.logout, size: 18, color: tokens.danger),
                const SizedBox(width: 8),
                Text(
                  'Sair da Conta',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: tokens.danger,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
