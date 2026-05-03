import 'package:flutter/material.dart';

import 'package:animus/theme.dart';

class FolderSelectionActionBarView extends StatelessWidget {
  final int selectedCount;
  final bool isOperating;
  final VoidCallback onMove;
  final VoidCallback onArchive;

  const FolderSelectionActionBarView({
    required this.selectedCount,
    required this.isOperating,
    required this.onMove,
    required this.onArchive,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: tokens.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: tokens.borderStrong),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.24),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                '$selectedCount selecionada${selectedCount == 1 ? '' : 's'}',
                style: textTheme.bodyMedium?.copyWith(
                  color: tokens.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: isOperating ? null : onMove,
              icon: const Icon(Icons.folder_open_outlined),
              label: const Text('Mover'),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: isOperating ? null : onArchive,
              style: FilledButton.styleFrom(
                backgroundColor: tokens.danger,
                foregroundColor: tokens.white,
              ),
              icon: isOperating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_outline_rounded),
              label: Text(isOperating ? 'Processando' : 'Deletar'),
            ),
          ],
        ),
      ),
    );
  }
}
