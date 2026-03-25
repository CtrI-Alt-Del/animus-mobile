import 'package:flutter/material.dart';
import 'package:reactive_forms/reactive_forms.dart';

import 'package:animus/theme.dart';

class TermsLabelView extends StatelessWidget {
  const TermsLabelView({super.key});

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final Color linkColor = Theme.of(context).colorScheme.primary;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Row(
      children: <Widget>[
        SizedBox(
          height: 20,
          width: 20,
          child: ReactiveCheckbox(
            formControlName: 'termsAccepted',
            activeColor: tokens.accent,
            checkColor: tokens.white,
            side: BorderSide(color: tokens.accent.withValues(alpha: 0.35)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: textTheme.labelSmall?.copyWith(
                color: tokens.textSecondary,
                fontWeight: FontWeight.w400,
              ),
              children: <TextSpan>[
                const TextSpan(text: 'Ao continuar, voce concorda com os '),
                TextSpan(
                  text: 'Termos de Uso',
                  style: textTheme.labelSmall?.copyWith(
                    color: linkColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const TextSpan(text: ' e com a '),
                TextSpan(
                  text: 'Politica de Privacidade',
                  style: textTheme.labelSmall?.copyWith(
                    color: linkColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
