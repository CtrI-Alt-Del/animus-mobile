import 'package:flutter/material.dart';

import 'package:animus/core/intake/dtos/analysis_dto.dart';
import 'package:animus/theme.dart';

class LibraryFolderAnalysisItemView extends StatelessWidget {
  final AnalysisDto analysis;
  final bool isSelected;
  final String dateLabel;
  final VoidCallback onTap;
  final VoidCallback onToggleSelection;

  const LibraryFolderAnalysisItemView({
    required this.analysis,
    required this.isSelected,
    required this.dateLabel,
    required this.onTap,
    required this.onToggleSelection,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String title = analysis.name.trim().isEmpty
        ? 'Analise sem nome'
        : analysis.name.trim();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
          decoration: BoxDecoration(
            color: isSelected
                ? tokens.accent.withValues(alpha: 0.10)
                : tokens.surfaceElevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? tokens.accent.withValues(alpha: 0.45)
                  : tokens.borderSubtle,
            ),
          ),
          child: Row(
            children: <Widget>[
              Icon(Icons.description_outlined, color: tokens.accent, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelMedium?.copyWith(
                        color: tokens.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: tokens.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Semantics(
                label: isSelected
                    ? 'Remover analise da selecao'
                    : 'Selecionar analise',
                button: true,
                child: Checkbox(
                  value: isSelected,
                  onChanged: (_) => onToggleSelection(),
                  visualDensity: VisualDensity.compact,
                  side: BorderSide(color: tokens.accent.withValues(alpha: 0.4)),
                  activeColor: tokens.accent,
                  checkColor: tokens.surfacePage,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
