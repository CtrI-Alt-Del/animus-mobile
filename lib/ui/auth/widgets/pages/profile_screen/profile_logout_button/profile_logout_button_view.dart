import 'package:flutter/material.dart';

import 'package:animus/theme.dart';

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
              color: tokens.danger.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: tokens.danger.withValues(alpha: 0.3)),
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
