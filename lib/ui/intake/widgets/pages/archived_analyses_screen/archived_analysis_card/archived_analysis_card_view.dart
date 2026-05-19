import 'package:flutter/material.dart';

import 'package:animus/theme.dart';

class ArchivedAnalysisCardView extends StatelessWidget {
  final String title;
  final String dateLabel;
  final bool isUnarchiving;
  final VoidCallback onTap;
  final Future<void> Function() onUnarchive;

  const ArchivedAnalysisCardView({
    required this.title,
    required this.dateLabel,
    required this.isUnarchiving,
    required this.onTap,
    required this.onUnarchive,
    super.key,
  });

  Future<void> _handleUnarchive(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Desarquivar analise'),
          content: Text(
            'Tem certeza que deseja desarquivar "${title.isEmpty ? 'esta analise' : title}"? Ela voltara a aparecer na sua lista de analises ativas.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Desarquivar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await onUnarchive();
  }

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

    final BorderRadius borderRadius = BorderRadius.circular(18);
    final BoxDecoration decoration = BoxDecoration(
      color: tokens.surfaceCard,
      borderRadius: borderRadius,
      border: Border.all(color: tokens.borderSubtle),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isUnarchiving ? null : onTap,
        borderRadius: borderRadius,
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: decoration,
          child: Row(
            children: <Widget>[
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
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              isUnarchiving
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          tokens.accent,
                        ),
                      ),
                    )
                  : IconButton(
                      tooltip: 'Desarquivar',
                      icon: Icon(
                        Icons.unarchive_outlined,
                        color: tokens.accent,
                      ),
                      onPressed: () => _handleUnarchive(context),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
