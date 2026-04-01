import 'package:flutter/material.dart';

import 'package:animus/theme.dart';

class ForgotPasswordSubmitButtonView extends StatelessWidget {
  final bool isSubmitting;
  final bool enabled;
  final VoidCallback? onPressed;

  const ForgotPasswordSubmitButtonView({
    required this.isSubmitting,
    required this.enabled,
    required this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return SizedBox(
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.topLeft,
            colors: enabled
                ? <Color>[tokens.accent, tokens.accentStrong]
                : <Color>[tokens.borderStrong, tokens.borderSubtle],
          ),
          boxShadow: enabled
              ? <BoxShadow>[
                  BoxShadow(
                    color: tokens.accent.withValues(alpha: 0.2),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ]
              : const <BoxShadow>[],
        ),
        child: ElevatedButton(
          onPressed: enabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: isSubmitting
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: tokens.surfacePage,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Enviando...',
                      style: textTheme.labelMedium?.copyWith(
                        color: tokens.surfacePage,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
              : Text(
                  'Enviar Link',
                  style: textTheme.labelMedium?.copyWith(
                    color: tokens.surfacePage,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}
