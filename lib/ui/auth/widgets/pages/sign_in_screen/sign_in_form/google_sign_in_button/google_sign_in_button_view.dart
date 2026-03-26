import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:animus/theme.dart';

class GoogleSignInButtonView extends StatelessWidget {
  final bool enabled;

  const GoogleSignInButtonView({required this.enabled, super.key});

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;

    return OutlinedButton.icon(
      onPressed: enabled ? () {} : null,
      icon: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: SvgPicture.asset(
          'assets/images/google-logo.svg',
          width: 18,
          height: 18,
        ),
      ),
      label: Text(
        'Continuar com Google',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: enabled ? tokens.textPrimary : tokens.textTertiary,
        ),
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        side: BorderSide(color: tokens.borderSubtle),
      ),
    );
  }
}
