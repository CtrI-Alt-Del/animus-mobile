import 'package:flutter/material.dart';

import 'package:animus/theme.dart';

class PrimaryActionButtonView extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isBusy;

  const PrimaryActionButtonView({
    required this.label,
    required this.onPressed,
    required this.isBusy,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Opacity(
      opacity: onPressed == null && !isBusy ? 0.5 : 1,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[tokens.accent, tokens.accentStrong],
            ),
          ),
          child: Center(
            child: isBusy
                ? SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: tokens.surfacePage,
                    ),
                  )
                : Text(
                    label,
                    style: textTheme.labelMedium?.copyWith(
                      color: tokens.surfacePage,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
