import 'package:flutter/material.dart';

import 'package:animus/theme.dart';

class DocumentFileBubbleView extends StatelessWidget {
  final String fileName;
  final String fileSizeLabel;
  final bool isLoading;

  const DocumentFileBubbleView({
    required this.fileName,
    required this.fileSizeLabel,
    this.isLoading = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: tokens.surfaceElevated,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: tokens.borderSubtle),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: tokens.surfaceCard,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: tokens.borderSubtle),
                  ),
                  child: Center(
                    child: isLoading
                        ? SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                tokens.accent,
                              ),
                            ),
                          )
                        : Icon(
                            Icons.description_outlined,
                            color: tokens.accent,
                            size: 16,
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        fileName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: tokens.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        fileSizeLabel,
                        style: textTheme.bodySmall?.copyWith(
                          color: tokens.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
