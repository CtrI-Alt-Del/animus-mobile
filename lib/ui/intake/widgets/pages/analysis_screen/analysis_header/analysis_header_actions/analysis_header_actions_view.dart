import 'package:flutter/material.dart';

import 'package:animus/theme.dart';

class AnalysisHeaderActionsView extends StatelessWidget {
  final VoidCallback? onRename;
  final VoidCallback? onArchive;
  final bool isEnabled;

  const AnalysisHeaderActionsView({
    required this.onRename,
    required this.onArchive,
    required this.isEnabled,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return PopupMenuButton<String>(
      enabled: isEnabled,
      offset: const Offset(0, 40),
      color: tokens.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: tokens.borderSubtle),
      ),
      onSelected: (String value) {
        if (value == 'rename') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            onRename?.call();
          });
          return;
        }

        if (value == 'archive') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            onArchive?.call();
          });
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'rename',
          height: 48,
          child: Row(
            children: <Widget>[
              Icon(Icons.edit_outlined, color: tokens.textPrimary, size: 18),
              const SizedBox(width: 10),
              Text(
                'Renomear',
                style: textTheme.bodyMedium?.copyWith(
                  color: tokens.textPrimary,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'archive',
          height: 48,
          child: Row(
            children: <Widget>[
              Icon(
                Icons.inventory_2_outlined,
                color: tokens.textPrimary,
                size: 18,
              ),
              const SizedBox(width: 10),
              Text(
                'Arquivar',
                style: textTheme.bodyMedium?.copyWith(
                  color: tokens.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(Icons.tune, color: tokens.textSecondary, size: 20),
      ),
    );
  }
}
