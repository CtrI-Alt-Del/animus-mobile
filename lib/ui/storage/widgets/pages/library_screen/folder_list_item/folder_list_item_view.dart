import 'package:animus/core/library/dtos/folder_dto.dart';
import 'package:animus/theme.dart';
import 'package:flutter/material.dart';

class FolderListItemView extends StatelessWidget {
  final FolderDto folder;
  final VoidCallback onTap;

  const FolderListItemView({
    super.key,
    required this.folder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: tokens.borderSubtle, width: 1),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.folder_outlined, color: tokens.textMuted),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    folder.name,
                    style: textTheme.bodyLarge?.copyWith(
                      color: tokens.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${folder.analysisCount} análises',
                    style: textTheme.bodySmall?.copyWith(
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
    );
  }
}
