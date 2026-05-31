import 'package:flutter/material.dart';

import 'package:animus/theme.dart';

class AnalysisPrecedentsBubblePrecedentsLimitDialogView
    extends StatelessWidget {
  final int currentValue;
  final int minValue;
  final int maxValue;
  final ValueChanged<int> onChanged;
  final VoidCallback onCancel;
  final VoidCallback onApply;

  const AnalysisPrecedentsBubblePrecedentsLimitDialogView({
    required this.currentValue,
    required this.minValue,
    required this.maxValue,
    required this.onChanged,
    required this.onCancel,
    required this.onApply,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final int sliderDivisions = (maxValue - minValue).clamp(1, 200);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
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
              'Qtd. de precedentes',
              style: textTheme.titleLarge?.copyWith(
                color: tokens.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Escolha quantos precedentes a IA deve retornar para esta analise.',
              style: textTheme.bodyMedium?.copyWith(
                color: tokens.textMuted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Quantidade retornada',
                    style: textTheme.labelMedium?.copyWith(
                      color: tokens.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: tokens.warning.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: tokens.warning.withValues(alpha: 0.22),
                    ),
                  ),
                  child: Text(
                    '$currentValue',
                    style: textTheme.labelMedium?.copyWith(
                      color: tokens.warning,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: tokens.accent,
                inactiveTrackColor: tokens.borderStrong,
                thumbColor: tokens.accent,
                overlayColor: tokens.accent.withValues(alpha: 0.2),
              ),
              child: Slider(
                value: currentValue.toDouble(),
                min: minValue.toDouble(),
                max: maxValue.toDouble(),
                divisions: sliderDivisions,
                onChanged: (double value) {
                  onChanged(value.round());
                },
              ),
            ),
            Row(
              children: <Widget>[
                Text(
                  minValue.toString(),
                  style: textTheme.bodySmall?.copyWith(
                    color: tokens.textMuted,
                  ),
                ),
                const Spacer(),
                Text(
                  maxValue.toString(),
                  style: textTheme.bodySmall?.copyWith(
                    color: tokens.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Defina quantos resultados relevantes devem aparecer antes da escolha final.',
              style: textTheme.bodySmall?.copyWith(
                color: tokens.textMuted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 52,
              child: OutlinedButton(
                onPressed: onCancel,
                style: OutlinedButton.styleFrom(
                  backgroundColor: tokens.surfaceElevated,
                  side: BorderSide(color: tokens.borderStrong),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Cancelar',
                  style: textTheme.labelLarge?.copyWith(
                    color: tokens.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 52,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[tokens.accent, tokens.accentStrong],
                  ),
                ),
                child: FilledButton(
                  onPressed: onApply,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Aplicar',
                    style: textTheme.labelLarge?.copyWith(
                      color: tokens.surfacePage,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
