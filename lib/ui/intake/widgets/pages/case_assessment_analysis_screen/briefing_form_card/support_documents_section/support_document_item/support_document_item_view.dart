import 'package:flutter/material.dart';

import 'package:animus/core/intake/dtos/analysis_document_dto.dart';
import 'package:animus/theme.dart';

class SupportDocumentItemView extends StatelessWidget {
  final AnalysisDocumentDto document;
  final double? progress;
  final bool isUploading;
  final bool enabled;
  final VoidCallback? onRemove;

  const SupportDocumentItemView({
    required this.document,
    required this.progress,
    required this.isUploading,
    required this.enabled,
    required this.onRemove,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final double normalizedProgress = progress == null
        ? 0
        : progress!.clamp(0, 1).toDouble();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tokens.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: tokens.surfaceCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: tokens.borderSubtle),
                ),
                child: Center(
                  child: isUploading
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            value: progress,
                            color: tokens.accent,
                          ),
                        )
                      : Icon(
                          Icons.description_outlined,
                          size: 18,
                          color: tokens.accent,
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      document.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        color: tokens.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isUploading
                          ? 'Enviando documento de apoio...'
                          : 'Documento anexado',
                      style: textTheme.bodySmall?.copyWith(
                        color: isUploading
                            ? tokens.textSecondary
                            : tokens.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: enabled && !isUploading ? onRemove : null,
                tooltip: 'Remover documento',
                icon: const Icon(Icons.close_rounded),
                color: tokens.textSecondary,
              ),
            ],
          ),
          if (isUploading) ...<Widget>[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: tokens.surfaceCard,
                valueColor: AlwaysStoppedAnimation<Color>(tokens.accent),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${(normalizedProgress * 100).round()}% concluído',
              style: textTheme.bodySmall?.copyWith(color: tokens.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}
