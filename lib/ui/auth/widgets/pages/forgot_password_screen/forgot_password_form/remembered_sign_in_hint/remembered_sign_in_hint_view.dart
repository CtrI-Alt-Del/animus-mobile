import 'package:flutter/material.dart';

import 'package:animus/theme.dart';

class RememberedSignInHintView extends StatelessWidget {
  final VoidCallback onTap;

  const RememberedSignInHintView({required this.onTap, super.key});

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
            'Lembrou? ',
            style: textTheme.bodySmall?.copyWith(
              color: tokens.textMuted,
              fontWeight: FontWeight.w400,
            ),
          ),
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: tokens.accent,
            ),
            child: Text(
              'Entrar',
              style: textTheme.bodySmall?.copyWith(
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
