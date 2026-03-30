import 'package:flutter/material.dart';

import 'package:animus/theme.dart';

class PasswordRuleRowView extends StatelessWidget {
  final String label;
  final bool isMet;

  const PasswordRuleRowView({
    required this.label,
    required this.isMet,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;

    return Row(
      children: <Widget>[
        Icon(
          Icons.check_circle,
          size: 18,
          color: isMet ? tokens.success : tokens.borderStrong,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isMet ? tokens.textPrimary : tokens.textSecondary,
          ),
        ),
      ],
    );
  }
}
