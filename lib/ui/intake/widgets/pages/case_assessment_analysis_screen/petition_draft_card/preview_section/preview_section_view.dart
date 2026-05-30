import 'package:flutter/material.dart';

import 'package:animus/theme.dart';

class PreviewSectionView extends StatelessWidget {
  final String title;
  final String? content;
  final List<String>? items;
  final String emptyText;

  const PreviewSectionView({
    required this.title,
    this.content,
    this.items,
    required this.emptyText,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String normalizedContent = (content ?? '').trim();
    final List<String> normalizedItems = (items ?? const <String>[])
        .map((String item) => item.trim())
        .where((String item) => item.isNotEmpty)
        .toList(growable: false);
    final bool hasItems = normalizedItems.isNotEmpty;
    final bool hasContent = normalizedContent.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tokens.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: textTheme.titleSmall?.copyWith(
              color: tokens.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          if (!hasContent && !hasItems)
            Text(
              emptyText,
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyMedium?.copyWith(
                color: tokens.textSecondary,
                height: 1.5,
              ),
            )
          else if (hasItems)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: normalizedItems
                  .take(4)
                  .map(
                    (String item) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        '• $item',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyMedium?.copyWith(
                          color: tokens.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ),
                  )
                  .toList(growable: false),
            )
          else
            Text(
              normalizedContent,
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyMedium?.copyWith(
                color: tokens.textSecondary,
                height: 1.5,
              ),
            ),
        ],
      ),
    );
  }
}
