import 'package:flutter/material.dart';

import 'package:animus_mobile/ui/auth/widgets/pages/sign_up_screen/password_strength_indicator/rule_item/index.dart';

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
    const Color metColor = Color(0xFF3BC67C);
    const Color pendingColor = Color(0xFF585D76);

    final List<bool> states = <bool>[
      hasMinLength,
      hasUppercaseLetter,
      hasNumber,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          height: 2,
          child: Row(
            children: states
                .map(
                  (bool state) => Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(right: 3),
                      color: state ? const Color(0xFFF0B91F) : pendingColor,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: <Widget>[
            RuleItem(
              label: '8 chars',
              isMet: hasMinLength,
              successColor: metColor,
            ),
            const SizedBox(width: 10),
            RuleItem(
              label: 'Maiuscula',
              isMet: hasUppercaseLetter,
              successColor: metColor,
            ),
            const SizedBox(width: 10),
            RuleItem(label: 'Numero', isMet: hasNumber, successColor: metColor),
            const Spacer(),
            Text(
              _labelByScore(score),
              style: const TextStyle(color: Color(0xFF8085A1), fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }

  String _labelByScore(int value) {
    if (value >= 3) {
      return 'Forte';
    }
    if (value == 2) {
      return 'Media';
    }
    if (value == 1) {
      return 'Fraca';
    }
    return 'Muito fraca';
  }
}
