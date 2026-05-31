import 'package:flutter/material.dart';

import 'package:animus/theme.dart';

class LibraryFolderActionBarView extends StatelessWidget {
  final int selectedCount;
  final bool isMoving;
  final bool isArchiving;
  final VoidCallback onMovePressed;
  final VoidCallback onArchivePressed;

  const LibraryFolderActionBarView({
    required this.selectedCount,
    required this.isMoving,
    required this.isArchiving,
    required this.onMovePressed,
    required this.onArchivePressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool isBusy = isMoving || isArchiving;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
        decoration: BoxDecoration(
          color: tokens.surfaceElevated,
          border: Border(top: BorderSide(color: tokens.borderSubtle)),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                selectedCount == 1
                    ? '1 selecionada'
                    : '$selectedCount selecionadas',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall?.copyWith(
                  color: tokens.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: isBusy ? null : onMovePressed,
              style: FilledButton.styleFrom(
                minimumSize: const Size(92, 44),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                backgroundColor: tokens.accent,
                foregroundColor: tokens.onAccent,
              ),
              icon: isMoving
                  ? _SmallProgress(color: tokens.surfacePage)
                  : const Icon(Icons.drive_file_move_outline, size: 18),
              label: const Text('Mover'),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: isBusy ? null : onArchivePressed,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(104, 44),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                foregroundColor: tokens.danger,
                side: BorderSide(color: tokens.danger.withValues(alpha: 0.45)),
              ),
              icon: isArchiving
                  ? _SmallProgress(color: tokens.danger)
                  : const Icon(Icons.archive_outlined, size: 18),
              label: const Text('Arquivar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallProgress extends StatelessWidget {
  final Color color;

  const _SmallProgress({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}
