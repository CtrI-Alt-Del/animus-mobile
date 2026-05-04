import 'package:flutter/material.dart';

import 'package:animus/theme.dart';

class ArchiveSelectedAnalysesDialogView extends StatelessWidget {
  final int selectedCount;

  const ArchiveSelectedAnalysesDialogView({
    required this.selectedCount,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String confirmationText = selectedCount == 1
        ? '1 analise sera arquivada. Ela nao sera excluida permanentemente.'
        : '$selectedCount analises serao arquivadas. Elas nao serao excluidas permanentemente.';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 352),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: tokens.surfaceCard,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: tokens.borderSubtle),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Arquivar analises',
              style: textTheme.titleMedium?.copyWith(
                color: tokens.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              confirmationText,
              style: textTheme.bodyMedium?.copyWith(
                color: tokens.textMuted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: FilledButton.styleFrom(
                      backgroundColor: tokens.danger,
                      foregroundColor: tokens.white,
                    ),
                    child: const Text('Arquivar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
