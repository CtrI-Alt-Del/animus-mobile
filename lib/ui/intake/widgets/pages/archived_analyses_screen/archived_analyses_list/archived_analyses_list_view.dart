import 'dart:async';

import 'package:flutter/material.dart';

import 'package:animus/core/intake/dtos/analysis_dto.dart';
import 'package:animus/ui/intake/widgets/pages/archived_analyses_screen/archived_analyses_inline_error/index.dart';
import 'package:animus/ui/intake/widgets/pages/archived_analyses_screen/archived_analyses_loading_more/index.dart';
import 'package:animus/ui/intake/widgets/pages/archived_analyses_screen/archived_analysis_card/index.dart';

class ArchivedAnalysesListView extends StatelessWidget {
  final List<AnalysisDto> analyses;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? errorMessage;
  final String? unarchivingId;
  final String Function(String value) formatCreatedAt;
  final Future<void> Function() onLoadMore;
  final Future<void> Function(AnalysisDto analysis) onTapAnalysis;
  final Future<void> Function(AnalysisDto analysis) onUnarchive;

  const ArchivedAnalysesListView({
    required this.analyses,
    required this.isLoading,
    required this.isLoadingMore,
    required this.hasMore,
    required this.errorMessage,
    required this.unarchivingId,
    required this.formatCreatedAt,
    required this.onLoadMore,
    required this.onTapAnalysis,
    required this.onUnarchive,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (errorMessage != null) ...<Widget>[
          ArchivedAnalysesInlineError(message: errorMessage!),
          const SizedBox(height: 12),
        ],
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification notification) {
              if (isLoading || isLoadingMore || !hasMore) {
                return false;
              }

              if (notification is! ScrollEndNotification) {
                return false;
              }

              final double maxExtent = notification.metrics.maxScrollExtent;
              final double pixels = notification.metrics.pixels;
              if (maxExtent > 0 && pixels >= maxExtent - 120) {
                unawaited(onLoadMore());
              }
              return false;
            },
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: analyses.length + (isLoadingMore ? 1 : 0),
              separatorBuilder: (BuildContext context, int index) =>
                  const SizedBox(height: 12),
              itemBuilder: (BuildContext context, int index) {
                if (index < analyses.length) {
                  final AnalysisDto analysis = analyses[index];
                  final String analysisId = (analysis.id ?? '').trim();
                  final String title = analysis.name.trim().isEmpty
                      ? 'Analise sem nome'
                      : analysis.name;

                  return ArchivedAnalysisCard(
                    title: title,
                    dateLabel: formatCreatedAt(analysis.createdAt),
                    isUnarchiving:
                        unarchivingId != null && unarchivingId == analysisId,
                    onTap: () {
                      unawaited(onTapAnalysis(analysis));
                    },
                    onUnarchive: () => onUnarchive(analysis),
                  );
                }

                return const ArchivedAnalysesLoadingMore();
              },
            ),
          ),
        ),
      ],
    );
  }
}
