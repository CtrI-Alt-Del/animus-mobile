import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:animus/theme.dart';

class HomeHeaderView extends StatelessWidget {
  final String greeting;
  final String subtitle;

  const HomeHeaderView({
    required this.greeting,
    required this.subtitle,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                greeting,
                style: GoogleFonts.fraunces(
                  textStyle: textTheme.titleLarge?.copyWith(
                    color: tokens.textPrimary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.6,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: textTheme.bodySmall?.copyWith(color: tokens.textMuted),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Container(
          width: 52,
          height: 52,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: <Color>[
                tokens.accent.withValues(alpha: 0.9),
                tokens.accentStrong.withValues(alpha: 0.7),
              ],
            ),
          ),
          child: CircleAvatar(
            backgroundColor: tokens.surfaceElevated,
            child: Icon(Icons.person_outline, color: tokens.textPrimary),
          ),
        ),
      ],
    );
  }
}
