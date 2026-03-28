import 'package:flutter/material.dart';

import 'package:animus/theme.dart';

class OrDividerView extends StatelessWidget {
  const OrDividerView({super.key});

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;

    return Row(
      children: <Widget>[
        Expanded(child: Divider(color: tokens.borderSubtle)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'ou',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: tokens.textMuted),
          ),
        ),
        Expanded(child: Divider(color: tokens.borderSubtle)),
      ],
    );
  }
}
