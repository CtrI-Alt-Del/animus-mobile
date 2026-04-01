import 'package:flutter/material.dart';

import 'package:animus/theme.dart';
import 'package:animus/ui/auth/widgets/pages/sign_up_screen/password_strength_indicator/rule_item/index.dart';

class PasswordStrengthIndicatorView extends StatelessWidget {
  final int score;
  final bool hasMinLength;
  final bool hasUppercaseLetter;
  final bool hasNumber;

  const PasswordStrengthIndicatorView({
    required this.score,
    required this.hasMinLength,
    required this.hasUppercaseLetter,
    required this.hasNumber,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;

    final List<bool> states = <bool>[
      hasMinLength,
      hasUppercaseLetter,
      hasNumber,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          height: 3,
          child: Row(
            children:
                states
                    .map(
                      (bool state) => Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(right: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            color: state ? tokens.accent : tokens.borderSubtle,
                          ),
                        ),
                      ),
                    )
                    .toList(),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: <Widget>[
            RuleItem(
              label: '8 chars',
              isMet: hasMinLength,
              successColor: tokens.success,
            ),
            RuleItem(
              label: 'Maiuscula',
              isMet: hasUppercaseLetter,
              successColor: tokens.success,
            ),
            RuleItem(
              label: 'Numero',
              isMet: hasNumber,
              successColor: tokens.success,
            ),
          ],
        ),
      ],
    );
  }
}
