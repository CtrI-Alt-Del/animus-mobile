import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:animus/core/intake/dtos/petition_draft_dto.dart';
import 'package:animus/theme.dart';
import 'package:animus/ui/intake/widgets/pages/case_assessment_analysis_screen/petition_draft_card/petition_draft_card_presenter.dart';

class PetitionDraftCardView extends ConsumerWidget {
  final PetitionDraftDto draft;
  final VoidCallback? onRegenerate;

  const PetitionDraftCardView({
    required this.draft,
    this.onRegenerate,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final PetitionDraftCardPresenter presenter = ref.watch(
      petitionDraftCardPresenterProvider,
    );
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String preview = presenter.buildPreview(draft);

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
                  'Minuta de Petição Inicial',
                  style: textTheme.titleSmall?.copyWith(
                    color: tokens.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  unawaited(presenter.openDraftDialog(context, draft));
                },
                icon: const Icon(Icons.open_in_full, size: 16),
                label: const Text('Ver minuta'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: tokens.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: tokens.borderSubtle),
            ),
            child: Text(
              preview.isEmpty ? 'A minuta não foi disponibilizada.' : preview,
              style: textTheme.bodyMedium?.copyWith(
                color: tokens.textSecondary,
                height: 1.5,
              ),
            ),
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
