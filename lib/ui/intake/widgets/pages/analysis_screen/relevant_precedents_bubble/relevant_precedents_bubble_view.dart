import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:animus/core/intake/dtos/analysis_precedent_dto.dart';
import 'package:animus/core/intake/dtos/analysis_status_dto.dart';
import 'package:animus/theme.dart';
import 'package:animus/ui/intake/widgets/pages/analysis_screen/relevant_precedents_bubble/content_state/index.dart';
import 'package:animus/ui/intake/widgets/pages/analysis_screen/relevant_precedents_bubble/empty_state/index.dart';
import 'package:animus/ui/intake/widgets/pages/analysis_screen/relevant_precedents_bubble/error_state/index.dart';
import 'package:animus/ui/intake/widgets/pages/analysis_screen/relevant_precedents_bubble/loading_state/index.dart';
import 'package:animus/ui/intake/widgets/pages/analysis_screen/relevant_precedents_bubble/relevant_precedents_bubble_presenter.dart';

class RelevantPrecedentsBubbleView extends ConsumerWidget {
  final String analysisId;
  final AnalysisStatusDto? analysisStatus;
  final ValueChanged<AnalysisPrecedentDto>? onPrecedentTap;

  const RelevantPrecedentsBubbleView({
    required this.analysisId,
    this.analysisStatus,
    this.onPrecedentTap,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final RelevantPrecedentsBubblePresenter presenter = ref.watch(
      relevantPrecedentsBubblePresenterProvider(analysisId),
    );
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

    if (analysisStatus != null) {
      presenter.syncAnalysisStatus(analysisStatus!);
    }

    return Watch((BuildContext context) {
      final bool isLoading = presenter.isLoading.watch(context);
      final String? generalError = presenter.generalError.watch(context);
      final List<AnalysisPrecedentDto> precedents = presenter.precedents.watch(
        context,
      );
      final int totalCount = presenter.totalCount.watch(context);
      final String loadingMessage = presenter.loadingMessage.watch(context);
      final bool showEmptyState = presenter.showEmptyState.watch(context);

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: tokens.warning,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.auto_awesome,
              color: tokens.surfacePage,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: tokens.surfaceCard,
                  border: Border.all(color: tokens.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: tokens.surfaceElevated,
                        border: Border(
                          bottom: BorderSide(color: tokens.borderSubtle),
                        ),
                      ),
                      child: Row(
                        children: <Widget>[
                          Icon(Icons.scale, size: 16, color: tokens.accent),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Precedentes Relevantes',
                              style: textTheme.titleSmall?.copyWith(
                                color: tokens.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (!isLoading && generalError == null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: tokens.warning.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: tokens.warning.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                totalCount.toString(),
                                style: textTheme.labelSmall?.copyWith(
                                  color: tokens.warning,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (isLoading)
                      LoadingState(message: loadingMessage)
                    else if (generalError != null && generalError.isNotEmpty)
                      ErrorState(
                        message: generalError,
                        onRetry: presenter.retry,
                      )
                    else if (showEmptyState)
                      const EmptyState()
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          ContentState(
                            precedents: precedents,
                            onTap: (AnalysisPrecedentDto precedent) {
                              onPrecedentTap?.call(precedent);
                            },
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                              child: TextButton.icon(
                                onPressed: () {
                                  unawaited(presenter.retry());
                                },
                                icon: const Icon(Icons.refresh, size: 16),
                                label: const Text('Refazer busca'),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}
