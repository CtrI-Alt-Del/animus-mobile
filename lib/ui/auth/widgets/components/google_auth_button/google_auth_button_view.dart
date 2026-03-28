import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:animus/theme.dart';

class GoogleAuthButtonView extends StatelessWidget {
  final bool enabled;
  final bool isLoading;
  final VoidCallback? onPressed;

  const GoogleAuthButtonView({
    required this.enabled,
    required this.isLoading,
    required this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;

    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: enabled ? onPressed : null,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: tokens.borderSubtle),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              width: 18,
              height: 18,
              child: isLoading
                  ? CircularProgressIndicator(
                      strokeWidth: 2,
                      color: tokens.accent,
                    )
                  : SvgPicture.asset(
                      'assets/images/google-logo.svg',
                      width: 18,
                      height: 18,
                    ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                'Continuar com Google',
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: enabled ? tokens.textPrimary : tokens.textTertiary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
