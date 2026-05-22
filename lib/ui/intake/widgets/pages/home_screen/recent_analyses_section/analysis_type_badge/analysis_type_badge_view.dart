import 'package:flutter/material.dart';

import 'package:animus/core/intake/dtos/analysis_type_dto.dart';
import 'package:animus/theme.dart';
import 'package:animus/ui/intake/widgets/pages/home_screen/recent_analyses_section/analysis_type_presentation/index.dart';

class AnalysisTypeBadgeView extends StatelessWidget {
  final AnalysisTypeDto type;

  const AnalysisTypeBadgeView({required this.type, super.key});

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

    final String label = AnalysisTypePresentation.shortLabelFor(type);
    final IconData icon = AnalysisTypePresentation.iconFor(type);

    return Semantics(
      label: 'Tipo: $label',
      container: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: tokens.surfaceElevated,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: tokens.borderSubtle),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 14, color: tokens.textSecondary),
            const SizedBox(width: 4),
            Text(
              label,
              style: textTheme.labelSmall?.copyWith(
                color: tokens.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
