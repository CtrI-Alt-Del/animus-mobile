import 'package:animus/theme.dart';
import 'package:flutter/material.dart';

class UnfolderedCardView extends StatelessWidget {
  final int unfolderedCount;
  final VoidCallback onTap;

  const UnfolderedCardView({
    super.key,
    required this.unfolderedCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: tokens.surfaceElevated,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.inbox_outlined, color: tokens.textPrimary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sem pasta',
                      style: textTheme.titleMedium?.copyWith(
                        color: tokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$unfolderedCount análises não organizadas',
                      style: textTheme.bodyMedium?.copyWith(
                        color: tokens.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: tokens.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
