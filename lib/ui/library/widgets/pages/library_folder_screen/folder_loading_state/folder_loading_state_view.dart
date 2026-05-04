import 'package:flutter/material.dart';

import 'package:animus/theme.dart';

class FolderLoadingStateView extends StatelessWidget {
  const FolderLoadingStateView({super.key});

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;

    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 8, bottom: 32),
      itemCount: 4,
      separatorBuilder: (_, separatorIndex) => const SizedBox(height: 12),
      itemBuilder: (_, itemIndex) {
        return Container(
          height: 92,
          decoration: BoxDecoration(
            color: tokens.surfaceCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: tokens.borderSubtle),
          ),
        );
      },
    );
  }
}
