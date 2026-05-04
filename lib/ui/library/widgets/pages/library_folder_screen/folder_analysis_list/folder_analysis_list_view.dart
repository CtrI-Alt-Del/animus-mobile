import 'dart:async';

import 'package:flutter/material.dart';

import 'package:animus/core/intake/dtos/analysis_dto.dart';
import 'package:animus/theme.dart';
import 'package:animus/ui/library/widgets/pages/library_folder_screen/folder_analysis_card/index.dart';

class FolderAnalysisListView extends StatelessWidget {
  final List<AnalysisDto> analyses;
  final Set<String> selectedIds;
  final bool isLoadingMore;
  final bool hasMore;
  final String Function(String value) formatCreatedAt;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onLoadMore;
  final Future<void> Function(AnalysisDto analysis) onTapAnalysis;
  final void Function(String analysisId) onToggleSelection;

  const FolderAnalysisListView({
    required this.analyses,
    required this.selectedIds,
    required this.isLoadingMore,
    required this.hasMore,
    required this.formatCreatedAt,
    required this.onRefresh,
    required this.onLoadMore,
    required this.onTapAnalysis,
    required this.onToggleSelection,
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
          if (isLoadingMore || !hasMore) {
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
          padding: const EdgeInsets.only(bottom: 112),
          itemCount: analyses.length + (isLoadingMore ? 1 : 0),
          separatorBuilder: (_, separatorIndex) => const SizedBox(height: 12),
          itemBuilder: (BuildContext context, int index) {
            if (index >= analyses.length) {
              return const _LoadingMoreCard();
            }

            final AnalysisDto analysis = analyses[index];
            final String analysisId = (analysis.id ?? '').trim();
            final bool isSelected = selectedIds.contains(analysisId);
            final bool isSelectionMode = selectedIds.isNotEmpty;

            return FolderAnalysisCard(
              analysis: analysis,
              dateLabel: formatCreatedAt(analysis.createdAt),
              isSelected: isSelected,
              onTap: () {
                if (analysisId.isEmpty) {
                  return;
                }

                if (isSelectionMode) {
                  onToggleSelection(analysisId);
                  return;
                }

                unawaited(onTapAnalysis(analysis));
              },
              onToggleSelection: () {
                if (analysisId.isEmpty) {
                  return;
                }

                onToggleSelection(analysisId);
              },
            );
          },
        ),
      ),
    );
  }
}

class _LoadingMoreCard extends StatelessWidget {
  const _LoadingMoreCard();

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: tokens.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tokens.borderSubtle),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}
