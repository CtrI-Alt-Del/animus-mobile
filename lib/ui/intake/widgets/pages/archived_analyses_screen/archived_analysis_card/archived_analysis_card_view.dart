import 'package:flutter/material.dart';

import 'package:animus/theme.dart';
import 'package:animus/ui/intake/widgets/pages/archived_analyses_screen/unarchive_analysis_dialog/index.dart';

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
    final BuildContext dialogHostContext = Navigator.of(
      context,
      rootNavigator: true,
    ).context;

    final bool confirmed =
        await showDialog<bool>(
          context: dialogHostContext,
          barrierColor: (Theme.of(context).extension<AppThemeTokens>()?.scrim ?? AppTheme.tokens.scrim),
          builder: (_) => UnarchiveAnalysisDialog(
            analysisName: title.isEmpty ? null : title,
          ),
        ) ??
        false;

    if (!confirmed) {
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
