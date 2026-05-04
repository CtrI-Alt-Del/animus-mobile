import 'package:animus/core/library/dtos/folder_dto.dart';
import 'package:animus/theme.dart';
import 'package:flutter/material.dart';

const Color _folderCardColor = Color(0xFF1E1E24);

class FolderGridCardView extends StatelessWidget {
  final FolderDto folder;
  final VoidCallback onTap;

  const FolderGridCardView({
    super.key,
    required this.folder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: _folderCardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: tokens.borderSubtle),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Icon(Icons.folder_outlined, color: tokens.accent, size: 28),
              const SizedBox(height: 8),
              Text(
                folder.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: textTheme.labelMedium?.copyWith(
                  color: tokens.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _countLabel(folder.analysisCount),
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(color: tokens.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _countLabel(int count) {
    return count == 1 ? '1 análise' : '$count análises';
  }
}
