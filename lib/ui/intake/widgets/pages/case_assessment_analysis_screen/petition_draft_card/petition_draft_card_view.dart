import 'dart:async';

import 'package:flutter/material.dart';

import 'package:animus/core/intake/dtos/petition_draft_dto.dart';
import 'package:animus/theme.dart';
import 'package:animus/ui/intake/widgets/pages/case_assessment_analysis_screen/petition_draft_card/preview_section/index.dart';

class PetitionDraftCardView extends StatelessWidget {
  final PetitionDraftDto draft;
  final VoidCallback onOpenDialog;
  final Future<bool> Function()? onRegenerate;

  const PetitionDraftCardView({
    required this.draft,
    required this.onOpenDialog,
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
          Text(
            'Minuta de petição',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleSmall?.copyWith(
              color: tokens.accent,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: <Widget>[
                if (onRegenerate != null)
                  TextButton.icon(
                    onPressed: () {
                      unawaited(onRegenerate!.call());
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Regerar minuta'),
                  ),
                TextButton.icon(
                  onPressed: onOpenDialog,
                  icon: const Icon(Icons.open_in_full, size: 16),
                  label: const Text('Ver minuta'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          PreviewSection(
            title: 'Fatos estruturados',
            content: draft.structuredFacts,
            emptyText: 'Os fatos estruturados ainda não estão disponíveis.',
          ),
          const SizedBox(height: 10),
          PreviewSection(
            title: 'Tese central',
            content: draft.centralThesis,
            emptyText: 'A tese central ainda não está disponível.',
          ),
          const SizedBox(height: 10),
          PreviewSection(
            title: 'Pedidos',
            items: draft.requests,
            emptyText: 'Os pedidos ainda não estão disponíveis.',
          ),
        ],
      ),
    );
  }
}
