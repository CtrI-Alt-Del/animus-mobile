import 'package:animus/theme.dart';
import 'package:flutter/material.dart';

class EmptyStateView extends StatelessWidget {
  final VoidCallback onCreateFolder;

  const EmptyStateView({super.key, required this.onCreateFolder});

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.folder_off_outlined, size: 64, color: tokens.textMuted),
            const SizedBox(height: 16),
            Text(
              'Sua biblioteca está vazia',
              style: textTheme.titleMedium?.copyWith(color: tokens.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Crie uma pasta para organizar suas análises.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(color: tokens.textMuted),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onCreateFolder,
              icon: const Icon(Icons.add),
              label: const Text('Criar primeira pasta'),
            ),
          ],
        ),
      ),
    );
  }
}
