import 'package:flutter/material.dart';

import 'package:animus/theme.dart';

class RuleItemView extends StatelessWidget {
  final String label;
  final bool isMet;
  final Color successColor;

  const RuleItemView({
    required this.label,
    required this.isMet,
    required this.successColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(
          isMet ? Icons.check : Icons.circle_outlined,
          size: 11,
          color: isMet ? successColor : tokens.textTertiary,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: isMet ? tokens.textMuted : tokens.textTertiary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
