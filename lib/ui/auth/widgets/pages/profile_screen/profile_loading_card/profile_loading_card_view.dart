import 'package:flutter/material.dart';

import 'package:animus/theme.dart';

class ProfileLoadingCardView extends StatelessWidget {
  const ProfileLoadingCardView({super.key});

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.surfaceElevated,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: tokens.accent.withValues(alpha: 0.2)),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
