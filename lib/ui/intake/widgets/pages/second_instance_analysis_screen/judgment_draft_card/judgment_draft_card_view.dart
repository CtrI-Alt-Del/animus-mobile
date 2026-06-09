import 'dart:async';

import 'package:flutter/material.dart';

import 'package:animus/core/intake/dtos/second_instance_judgment_draft_dto.dart';
import 'package:animus/theme.dart';
import 'package:animus/ui/intake/widgets/pages/second_instance_analysis_screen/judgment_draft_dialog/index.dart';
import 'package:animus/ui/intake/widgets/pages/second_instance_analysis_screen/judgment_draft_card/preview_section/index.dart';

class JudgmentDraftCardView extends StatelessWidget {
  final String analysisId;
  final SecondInstanceJudgmentDraftDto draft;
  final void Function(SecondInstanceJudgmentDraftDto draft)? onDraftUpdated;
  final Future<bool> Function()? onRegenerate;

  const JudgmentDraftCardView({
    required this.analysisId,
    required this.draft,
    this.onDraftUpdated,
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
            'Minuta de sentença',
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
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (BuildContext context) {
                          return JudgmentDraftDialog(
                            analysisId: analysisId,
                            draft: draft,
                            onDraftUpdated: onDraftUpdated,
                            onRegenerate: onRegenerate,
                          );
                        },
                        fullscreenDialog: true,
                      ),
                    );
                  },
                  icon: const Icon(Icons.open_in_full, size: 16),
                  label: const Text('Ver completa'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          PreviewSection(
            title: 'Relatório',
            content: draft.report,
            emptyText: 'O relatório não foi disponibilizado.',
          ),
          const SizedBox(height: 12),
          if (_hasContent(draft.preliminaryIssues)) ...<Widget>[
            PreviewSection(
              title: 'Questões Preliminares',
              content: draft.preliminaryIssues!,
              emptyText: 'Sem questões preliminares registradas.',
            ),
            const SizedBox(height: 12),
          ],
          PreviewSection(
            title: 'Análise do Mérito',
            content: draft.meritAnalysis,
            emptyText: 'A análise do mérito não foi disponibilizada.',
          ),
          const SizedBox(height: 12),
          PreviewSection(
            title: 'Aderência aos Precedentes',
            content: draft.precedentAdherenceAnalysis,
            emptyText: 'A análise de aderência não foi disponibilizada.',
          ),
          if (_hasContent(draft.noApplicablePrecedentNotice)) ...<Widget>[
            const SizedBox(height: 12),
            PreviewSection(
              title: 'Aviso',
              content: draft.noApplicablePrecedentNotice!,
              emptyText: '',
            ),
          ],
          const SizedBox(height: 12),
          Container(
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
                  'Dispositivo',
                  style: textTheme.titleSmall?.copyWith(
                    color: tokens.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                if (draft.ruling.isEmpty)
                  Text(
                    'O dispositivo não foi disponibilizado.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: tokens.textSecondary,
                      height: 1.5,
                    ),
                  )
                else
                  Text(
                    draft.ruling.first,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(
                      color: tokens.textSecondary,
                      height: 1.5,
                    ),
                  ),
                if (draft.ruling.length > 1) ...<Widget>[
                  const SizedBox(height: 10),
                  Text(
                    '+${draft.ruling.length - 1} itens no dispositivo',
                    style: textTheme.bodySmall?.copyWith(
                      color: tokens.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _hasContent(String? value) {
    return value != null && value.trim().isNotEmpty;
  }
}
