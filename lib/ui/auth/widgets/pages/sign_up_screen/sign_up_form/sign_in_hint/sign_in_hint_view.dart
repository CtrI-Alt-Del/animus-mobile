import 'package:flutter/material.dart';

import 'package:animus/theme.dart';

class SignInHintView extends StatelessWidget {
  final VoidCallback onTap;

  const SignInHintView({required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          Text(
            'Ja tem conta? ',
            style: textTheme.labelSmall?.copyWith(
              color: tokens.textMuted,
              fontWeight: FontWeight.w400,
            ),
          ),
          TextButton(
            onPressed: onTap,
            child: Text(
              'Entrar',
              style: textTheme.labelSmall?.copyWith(
                color: tokens.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
