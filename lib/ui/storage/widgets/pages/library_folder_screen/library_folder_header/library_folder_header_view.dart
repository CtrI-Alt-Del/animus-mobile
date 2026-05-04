import 'package:flutter/material.dart';

import 'package:animus/theme.dart';

class LibraryFolderHeaderView extends StatelessWidget {
  final String title;
  final int count;
  final VoidCallback onBackPressed;
  final VoidCallback onSettingsPressed;
  final bool showSettings;

  const LibraryFolderHeaderView({
    required this.title,
    required this.count,
    required this.onBackPressed,
    required this.onSettingsPressed,
    this.showSettings = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String normalizedTitle = title.trim().isEmpty ? 'Pasta' : title;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 24, 12),
      child: Row(
        children: <Widget>[
          IconButton(
            onPressed: onBackPressed,
            tooltip: 'Voltar',
            icon: const Icon(Icons.arrow_back),
            constraints: const BoxConstraints.tightFor(width: 44, height: 44),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              normalizedTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.titleMedium?.copyWith(
                color: tokens.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            constraints: const BoxConstraints(minHeight: 24, minWidth: 24),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: tokens.accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              count.toString(),
              style: textTheme.labelSmall?.copyWith(
                color: tokens.accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (showSettings) ...<Widget>[
            const SizedBox(width: 12),
            DecoratedBox(
              decoration: BoxDecoration(
                color: tokens.surfaceElevated,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: tokens.accent.withValues(alpha: 0.18),
                ),
              ),
              child: IconButton(
                onPressed: onSettingsPressed,
                tooltip: 'Configuracoes da pasta',
                icon: Icon(Icons.settings_outlined, color: tokens.accent),
                constraints: const BoxConstraints.tightFor(
                  width: 44,
                  height: 44,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
