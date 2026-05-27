import 'package:flutter/material.dart';

import 'package:animus/theme.dart';

class FolderEmptyStateView extends StatelessWidget {
  final String folderName;
  final Future<void> Function() onRefresh;

  const FolderEmptyStateView({
    required this.folderName,
    required this.onRefresh,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.only(top: 32, bottom: 32),
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: tokens.surfaceCard,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: tokens.borderSubtle),
          ),
          child: Column(
            children: <Widget>[
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: tokens.surfaceElevated,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.folder_open_outlined,
                  color: tokens.textPrimary,
                  size: 30,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Sem análises em ${folderName.trim().isEmpty ? 'esta pasta' : folderName}',
                textAlign: TextAlign.center,
                style: textTheme.titleSmall?.copyWith(
                  color: tokens.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Quando novas análises forem movidas para esta pasta, elas aparecerão aqui.',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: tokens.textMuted,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Atualizar'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
