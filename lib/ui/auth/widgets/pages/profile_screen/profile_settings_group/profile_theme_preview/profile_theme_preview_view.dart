import 'package:flutter/material.dart';

import 'package:animus/theme.dart';

class ProfileThemePreviewView extends StatelessWidget {
  final bool isEnabled;

  const ProfileThemePreviewView({required this.isEnabled, super.key});

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;

    return Container(
      width: 44,
      height: 26,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(13),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isEnabled
              ? <Color>[tokens.accent, tokens.accentStrong]
              : <Color>[tokens.borderStrong, tokens.borderSubtle],
        ),
      ),
      child: Align(
        alignment: isEnabled ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: tokens.white,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}
