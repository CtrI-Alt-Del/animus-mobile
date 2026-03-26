import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:animus/theme.dart';

class AuthHeaderView extends StatelessWidget {
  final String title;
  final String subtitle;

  const AuthHeaderView({
    required this.title,
    required this.subtitle,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          title,
          style: GoogleFonts.fraunces(
            textStyle: textTheme.headlineSmall?.copyWith(
              color: tokens.textPrimary,
              letterSpacing: -0.8,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: textTheme.bodySmall?.copyWith(color: tokens.textSecondary),
        ),
      ],
    );
  }
}
