import 'package:flutter/material.dart';

import 'package:animus/core/intake/dtos/precedent_dto.dart';
import 'package:animus/theme.dart';
import 'package:animus/ui/intake/widgets/components/analysis_precedents_bubble/add_precedent_dialog/preview_text_block/index.dart';

class PreviewCardView extends StatelessWidget {
  final PrecedentDto precedent;

  const PreviewCardView({required this.precedent, super.key});

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

    final String identifier =
        '${precedent.identifier.court.value} ${precedent.identifier.kind.value} ${precedent.identifier.number}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tokens.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tokens.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.balance_outlined, size: 16, color: tokens.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  identifier,
                  style: textTheme.bodyMedium?.copyWith(
                    color: tokens.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          PreviewTextBlock(label: 'Status', value: precedent.status),
          const SizedBox(height: 8),
          PreviewTextBlock(label: 'Enunciado', value: precedent.enunciation),
          const SizedBox(height: 8),
          PreviewTextBlock(label: 'Tese', value: precedent.thesis),
        ],
      ),
    );
  }
}
