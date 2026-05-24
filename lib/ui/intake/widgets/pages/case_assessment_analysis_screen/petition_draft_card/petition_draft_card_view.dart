import 'package:flutter/material.dart';

import 'package:animus/core/intake/dtos/petition_draft_dto.dart';
import 'package:animus/theme.dart';
import 'package:animus/ui/intake/widgets/pages/case_assessment_analysis_screen/petition_draft_card/preview_section/index.dart';

class PetitionDraftCardView extends StatelessWidget {
  final PetitionDraftDto draft;
  final VoidCallback onOpenModal;
  final VoidCallback? onRegenerate;

  const PetitionDraftCardView({
    required this.draft,
    required this.onOpenModal,
    this.onRegenerate,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: tokens.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tokens.borderSubtle),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Minuta de petição',
                  style: textTheme.titleSmall?.copyWith(
                    color: tokens.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onOpenModal,
                icon: const Icon(Icons.open_in_full, size: 16),
                label: const Text('Ver minuta'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          PreviewSection(
            title: 'Conteúdo',
            content: draft.content,
            emptyText: 'A minuta ainda não tem conteúdo disponível.',
          ),
          if (onRegenerate != null) ...<Widget>[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onRegenerate,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Regerar minuta'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
