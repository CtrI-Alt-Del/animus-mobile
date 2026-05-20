import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:animus/core/intake/dtos/analysis_precedent_dto.dart';
import 'package:animus/theme.dart';
import 'package:animus/ui/intake/widgets/components/analysis_precedents_bubble/chosen_precedents_summary/chosen_precedents_summary_presenter.dart';

class ChosenPrecedentsSummaryView extends ConsumerWidget {
  final String analysisId;
  final List<AnalysisPrecedentDto> precedents;
  final ValueChanged<AnalysisPrecedentDto>? onPrecedentTap;

  const ChosenPrecedentsSummaryView({
    required this.analysisId,
    required this.precedents,
    this.onPrecedentTap,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ChosenPrecedentsSummaryPresenter presenter = ref.watch(
      chosenPrecedentsSummaryPresenterProvider(analysisId),
    );
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

    if (precedents.isEmpty) {
      return const SizedBox.shrink();
    }

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
              Icon(Icons.checklist, size: 16, color: tokens.successDark),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Precedentes escolhidos',
                  style: textTheme.labelLarge?.copyWith(
                    color: tokens.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: tokens.success.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: tokens.successDark.withValues(alpha: 0.26),
                  ),
                ),
                child: Text(
                  precedents.length.toString(),
                  style: textTheme.labelSmall?.copyWith(
                    color: tokens.successDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...List<Widget>.generate(precedents.length, (int index) {
            final AnalysisPrecedentDto precedent = precedents[index];

            return Container(
              margin: EdgeInsets.only(
                bottom: index == precedents.length - 1 ? 0 : 8,
              ),
              decoration: BoxDecoration(
                color: tokens.surfaceCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: tokens.borderSubtle),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: onPrecedentTap == null
                      ? null
                      : () {
                          onPrecedentTap?.call(precedent);
                        },
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            presenter.buildIdentifierLabel(precedent),
                            style: textTheme.bodyMedium?.copyWith(
                              color: tokens.textPrimary,
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            unawaited(
                              Future<void>(() async {
                                final bool didUnchoose = await presenter
                                    .unchoosePrecedent(precedent);
                                if (!didUnchoose || !context.mounted) {
                                  return;
                                }

                                onPrecedentTap?.call(precedent);
                              }),
                            );
                          },
                          tooltip: 'Desescolher precedente',
                          icon: Icon(
                            Icons.remove_done_outlined,
                            size: 20,
                            color: tokens.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
