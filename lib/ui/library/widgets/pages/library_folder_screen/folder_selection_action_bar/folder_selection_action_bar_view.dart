import 'package:flutter/material.dart';

import 'package:animus/theme.dart';

class FolderSelectionActionBarView extends StatelessWidget {
  final int selectedCount;
  final bool isOperating;
  final VoidCallback onMove;
  final VoidCallback onArchive;

  const FolderSelectionActionBarView({
    required this.selectedCount,
    required this.isOperating,
    required this.onMove,
    required this.onArchive,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: tokens.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: tokens.borderStrong),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.24),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool useCompactActions = constraints.maxWidth < 360;

            return Row(
              children: <Widget>[
                _SelectedCountBadge(
                  selectedCount: selectedCount,
                  tokens: tokens,
                  textTheme: textTheme,
                ),
                const Spacer(),
                _ActionBarButton(
                  label: 'Mover',
                  icon: const Icon(Icons.folder_open_outlined),
                  tokens: tokens,
                  onTap: isOperating ? null : onMove,
                  showLabel: !useCompactActions,
                ),
                const SizedBox(width: 8),
                _ActionBarButton(
                  label: isOperating ? 'Processando' : 'Arquivar',
                  icon: isOperating
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              tokens.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.archive_outlined),
                  tokens: tokens,
                  onTap: isOperating ? null : onArchive,
                  isFilled: true,
                  showLabel: !useCompactActions,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ActionBarButton extends StatelessWidget {
  final String label;
  final Widget icon;
  final AppThemeTokens tokens;
  final VoidCallback? onTap;
  final bool isFilled;
  final bool showLabel;

  const _ActionBarButton({
    required this.label,
    required this.icon,
    required this.tokens,
    required this.onTap,
    this.isFilled = false,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool isEnabled = onTap != null;
    final Color foregroundColor = isFilled ? tokens.white : tokens.textPrimary;
    final Color disabledColor = tokens.textMuted.withValues(alpha: 0.62);

    return Semantics(
      button: true,
      enabled: isEnabled,
      label: label,
      child: Tooltip(
        message: label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Ink(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: isFilled ? tokens.danger : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isFilled ? tokens.danger : tokens.borderStrong,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  IconTheme(
                    data: IconThemeData(
                      color: isEnabled ? foregroundColor : disabledColor,
                      size: 18,
                    ),
                    child: icon,
                  ),
                  if (showLabel) ...<Widget>[
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: textTheme.labelMedium?.copyWith(
                        color: isEnabled ? foregroundColor : disabledColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectedCountBadge extends StatelessWidget {
  final int selectedCount;
  final AppThemeTokens tokens;
  final TextTheme textTheme;

  const _SelectedCountBadge({
    required this.selectedCount,
    required this.tokens,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    final String semanticLabel =
        '$selectedCount selecionada${selectedCount == 1 ? '' : 's'}';

    return Semantics(
      label: semanticLabel,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: tokens.surfaceCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: tokens.borderSubtle),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.check_circle_outline, color: tokens.accent, size: 18),
            const SizedBox(width: 6),
            Text(
              selectedCount.toString(),
              style: textTheme.bodyMedium?.copyWith(
                color: tokens.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
