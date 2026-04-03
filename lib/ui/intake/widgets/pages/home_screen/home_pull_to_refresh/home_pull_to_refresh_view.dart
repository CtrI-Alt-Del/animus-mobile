import 'package:flutter/material.dart';

import 'package:animus/theme.dart';

class HomePullToRefreshView extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Widget child;

  const HomePullToRefreshView.box({
    required this.onRefresh,
    required this.child,
    super.key,
  });

  const HomePullToRefreshView.scrollable({
    required this.onRefresh,
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: tokens.accent,
      backgroundColor: tokens.surfaceCard,
      child: child,
    );
  }
}
