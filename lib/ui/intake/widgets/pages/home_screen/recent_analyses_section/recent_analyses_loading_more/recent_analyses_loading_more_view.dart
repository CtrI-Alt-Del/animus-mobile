import 'package:flutter/material.dart';

import 'package:animus/theme.dart';

class RecentAnalysesLoadingMoreView extends StatelessWidget {
  const RecentAnalysesLoadingMoreView({super.key});

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(tokens.accent),
          ),
        ),
      ),
    );
  }
}
