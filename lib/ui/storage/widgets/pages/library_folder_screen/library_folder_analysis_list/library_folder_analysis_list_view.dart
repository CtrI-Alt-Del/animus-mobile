import 'dart:async';

import 'package:flutter/material.dart';

import 'package:animus/core/intake/dtos/analysis_dto.dart';
import 'package:animus/theme.dart';
import 'package:animus/ui/storage/widgets/pages/library_folder_screen/library_folder_analysis_item/index.dart';

class LibraryFolderAnalysisListView extends StatelessWidget {
  final List<AnalysisDto> analyses;
  final Set<String> selectedAnalysisIds;
  final bool isLoadingMore;
  final bool hasMore;
  final String Function(String value) formatCreatedAt;
  final Future<void> Function(AnalysisDto analysis) onTapAnalysis;
  final void Function(String analysisId) onToggleSelection;
  final Future<void> Function() onLoadMore;
  final Future<void> Function() onRefresh;

  const LibraryFolderAnalysisListView({
    required this.analyses,
    required this.selectedAnalysisIds,
    required this.isLoadingMore,
    required this.hasMore,
    required this.formatCreatedAt,
    required this.onTapAnalysis,
    required this.onToggleSelection,
    required this.onLoadMore,
    required this.onRefresh,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: tokens.accent,
      backgroundColor: tokens.surfaceCard,
      child: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification notification) {
          if (isLoadingMore ||
              !hasMore ||
              notification is! ScrollEndNotification) {
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
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
          itemCount: analyses.length + (isLoadingMore ? 1 : 0),
          separatorBuilder: (BuildContext context, int index) =>
              const SizedBox(height: 12),
          itemBuilder: (BuildContext context, int index) {
            if (index >= analyses.length) {
              return _LoadingMoreIndicator(tokens: tokens);
            }

            final AnalysisDto analysis = analyses[index];
            final String analysisId = (analysis.id ?? '').trim();

            return LibraryFolderAnalysisItem(
              key: ValueKey<String>('library-folder-analysis-$analysisId'),
              analysis: analysis,
              isSelected: selectedAnalysisIds.contains(analysisId),
              dateLabel: formatCreatedAt(analysis.createdAt),
              onTap: () {
                unawaited(onTapAnalysis(analysis));
              },
              onToggleSelection: () {
                onToggleSelection(analysisId);
              },
            );
          },
        ),
      ),
    );
  }
}

class _LoadingMoreIndicator extends StatelessWidget {
  final AppThemeTokens tokens;

  const _LoadingMoreIndicator({required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(tokens.accent),
          ),
        ),
      ),
    );
  }
}
