import 'package:flutter/material.dart';

import 'package:animus/theme.dart';

class ForgotPasswordHintView extends StatelessWidget {
  final VoidCallback onTap;

  const ForgotPasswordHintView({required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;

    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(padding: EdgeInsets.zero),
        child: Text(
          'Esqueceu a senha?',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: tokens.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
