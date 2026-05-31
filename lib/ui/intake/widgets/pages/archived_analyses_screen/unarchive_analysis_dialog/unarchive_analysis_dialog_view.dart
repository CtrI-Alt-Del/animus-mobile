import 'package:flutter/material.dart';

import 'package:animus/theme.dart';

class UnarchiveAnalysisDialogView extends StatelessWidget {
  final String? analysisName;

  const UnarchiveAnalysisDialogView({this.analysisName, super.key});

  String _bodyText() {
    final String trimmed = (analysisName ?? '').trim();
    if (trimmed.isEmpty) {
      return 'Ela voltará a aparecer na sua lista de análises ativas.';
    }
    return '"$trimmed" voltará a aparecer na sua lista de análises ativas.';
  }

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
              'Desarquivar análise',
              style: textTheme.titleMedium?.copyWith(
                color: tokens.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _bodyText(),
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
                      foregroundColor: tokens.onAccent,
                    ),
                    child: Text(
                      'Desarquivar',
                      style: textTheme.bodyMedium?.copyWith(
                        color: tokens.onAccent,
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
