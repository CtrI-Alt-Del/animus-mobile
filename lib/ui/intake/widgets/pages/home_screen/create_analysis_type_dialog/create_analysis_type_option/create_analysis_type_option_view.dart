import 'package:flutter/material.dart';

import 'package:animus/theme.dart';

class CreateAnalysisTypeOptionView extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const CreateAnalysisTypeOptionView({
    required this.title,
    required this.description,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

    final BorderRadius borderRadius = BorderRadius.circular(16);
    final Color backgroundColor = isSelected
        ? tokens.surfaceElevated
        : tokens.surfacePage;
    final Color borderColor = isSelected ? tokens.accent : tokens.borderSubtle;
    final double borderWidth = isSelected ? 1.5 : 1;
    final IconData indicatorIcon = isSelected
        ? Icons.radio_button_checked
        : Icons.radio_button_unchecked;
    final Color indicatorColor = isSelected ? tokens.accent : tokens.textMuted;

    return Semantics(
      button: true,
      selected: isSelected,
      label: title,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: Ink(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: borderRadius,
              border: Border.all(color: borderColor, width: borderWidth),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Icon(icon, color: tokens.textPrimary, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: textTheme.labelMedium?.copyWith(
                          color: tokens.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: textTheme.bodySmall?.copyWith(
                          color: tokens.textMuted,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(indicatorIcon, color: indicatorColor, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
