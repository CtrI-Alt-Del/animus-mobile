import 'package:flutter/material.dart';

import 'package:animus/theme.dart';

class SignInHintView extends StatelessWidget {
  const SignInHintView({super.key});

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Center(
      child: RichText(
        text: TextSpan(
          style: textTheme.labelSmall?.copyWith(
            color: tokens.textMuted,
            fontWeight: FontWeight.w400,
          ),
          children: <TextSpan>[
            const TextSpan(text: 'Ja tem conta? '),
            TextSpan(
              text: 'Entrar',
              style: textTheme.labelSmall?.copyWith(
                color: tokens.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
