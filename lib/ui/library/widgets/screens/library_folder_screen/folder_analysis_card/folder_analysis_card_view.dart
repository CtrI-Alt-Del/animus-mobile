import 'package:flutter/material.dart';

import 'package:animus/core/intake/dtos/analysis_dto.dart';
import 'package:animus/theme.dart';

class FolderAnalysisCardView extends StatelessWidget {
  final AnalysisDto analysis;
  final String dateLabel;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onToggleSelection;

  const FolderAnalysisCardView({
    required this.analysis,
    required this.dateLabel,
    required this.isSelected,
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
        : analysis.name;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? tokens.accent.withValues(alpha: 0.12)
                : tokens.surfaceCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? tokens.accent : tokens.borderSubtle,
            ),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: tokens.surfaceElevated,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.description_outlined,
                  color: isSelected ? tokens.accent : tokens.textMuted,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      dateLabel,
                      style: textTheme.labelSmall?.copyWith(
                        color: tokens.textMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelMedium?.copyWith(
                        color: tokens.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 44,
                height: 44,
                child: Checkbox(
                  value: isSelected,
                  activeColor: tokens.accent,
                  checkColor: tokens.surfacePage,
                  side: BorderSide(color: tokens.borderStrong),
                  onChanged: (_) => onToggleSelection(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
