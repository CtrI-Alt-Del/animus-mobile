import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:animus/theme.dart';

class BrandHeaderView extends StatelessWidget {
  const BrandHeaderView({super.key});

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Column(
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.gavel, color: tokens.accent, size: 30),
            const SizedBox(width: 12),
            const _LogoText(),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Inteligencia juridica ao seu lado',
          textAlign: TextAlign.center,
          style: textTheme.bodySmall?.copyWith(
            color: tokens.accent.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}

class _LogoText extends StatelessWidget {
  const _LogoText();

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;

    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (Rect bounds) {
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[tokens.accent, tokens.accentStrong],
        ).createShader(bounds);
      },
      child: Text(
        'Animus',
        style: GoogleFonts.fraunces(
          textStyle: Theme.of(context).textTheme.headlineLarge?.copyWith(
            color: tokens.textPrimary,
            letterSpacing: -1,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
