import 'package:flutter/material.dart';

import 'package:animus/theme.dart';

class TopProgressBarView extends StatelessWidget {
  const TopProgressBarView({super.key});

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;

    return SizedBox(
      height: 2,
      child: Row(
        children: <Widget>[
          Expanded(flex: 1, child: ColoredBox(color: tokens.accent)),
          Expanded(flex: 2, child: ColoredBox(color: tokens.borderSubtle)),
        ],
      ),
    );
  }
}
