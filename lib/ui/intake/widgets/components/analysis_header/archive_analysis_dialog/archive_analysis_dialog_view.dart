import 'package:flutter/material.dart';

import 'package:animus/theme.dart';

class ArchiveAnalysisDialogView extends StatelessWidget {
  const ArchiveAnalysisDialogView({super.key});

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

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
              'Arquivar analise',
              style: textTheme.titleMedium?.copyWith(
                color: tokens.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Voce pode encontra-la novamente na lista de analises arquivadas.',
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
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      side: BorderSide(color: tokens.borderSubtle),
                      backgroundColor: tokens.surfaceElevated,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancelar',
                      style: textTheme.bodyMedium?.copyWith(
                        color: tokens.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: tokens.accent,
                      foregroundColor: const Color(0xFF0B0B0E),
                    ),
                    child: Text(
                      'Arquivar',
                      style: textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF0B0B0E),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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
