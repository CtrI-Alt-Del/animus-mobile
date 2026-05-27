import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:animus/core/intake/dtos/analysis_dto.dart';
import 'package:animus/core/intake/dtos/analysis_status_dto.dart';
import 'package:animus/theme.dart';
import 'package:animus/ui/intake/widgets/pages/home_screen/home_pull_to_refresh/index.dart';
import 'package:animus/ui/intake/widgets/pages/home_screen/recent_analyses_section/recent_analyses_empty_state/index.dart';
import 'package:animus/ui/intake/widgets/pages/home_screen/recent_analyses_section/recent_analyses_error_state/index.dart';
import 'package:animus/ui/intake/widgets/pages/home_screen/recent_analyses_section/recent_analyses_inline_error/index.dart';
import 'package:animus/ui/intake/widgets/pages/home_screen/recent_analyses_section/recent_analyses_loading_more/index.dart';
import 'package:animus/ui/intake/widgets/pages/home_screen/recent_analyses_section/recent_analyses_loading_state/index.dart';
import 'package:animus/ui/intake/widgets/pages/home_screen/recent_analyses_section/processing_analysis_card/index.dart';
import 'package:animus/ui/intake/widgets/pages/home_screen/recent_analyses_section/recent_analysis_card/index.dart';

class RecentAnalysesSectionView extends StatelessWidget {
  final List<AnalysisDto> analyses;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final bool showEmptyState;
  final String? errorMessage;
  final String Function(String value) formatCreatedAt;
  final Future<void> Function() onRefresh;
  final Future<void> Function(AnalysisDto analysis) onTapAnalysis;
  final VoidCallback onRetry;
  final Future<void> Function() onLoadMore;
  final VoidCallback onCreateFirstAnalysis;

  const RecentAnalysesSectionView({
    required this.analyses,
    required this.isLoading,
    required this.isLoadingMore,
    required this.hasMore,
    required this.showEmptyState,
    required this.errorMessage,
    required this.formatCreatedAt,
    required this.onRefresh,
    required this.onTapAnalysis,
    required this.onRetry,
    required this.onLoadMore,
    required this.onCreateFirstAnalysis,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final List<AnalysisDto> processingAnalyses = analyses
        .where((AnalysisDto analysis) => _isProcessingStatus(analysis.status))
        .toList(growable: false);
    final int processingCount = processingAnalyses.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (processingCount > 0) ...<Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Em andamento',
                  style: GoogleFonts.fraunces(
                    textStyle: textTheme.titleMedium?.copyWith(
                      color: tokens.textPrimary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.4,
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: tokens.accent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$processingCount',
                  style: textTheme.labelSmall?.copyWith(
                    color: tokens.surfacePage,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        Expanded(child: _buildBody(context, processingAnalyses)),
      ],
    );
  }

  Widget _buildBody(
    BuildContext context,
    List<AnalysisDto> processingAnalyses,
  ) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final List<AnalysisDto> recentAnalyses = analyses
        .where((AnalysisDto analysis) => !_isProcessingStatus(analysis.status))
        .toList(growable: false);

    if (isLoading && analyses.isEmpty) {
      return const RecentAnalysesLoadingState();
    }

    if (errorMessage != null && analyses.isEmpty) {
      return HomePullToRefresh.box(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.only(bottom: 24),
          children: <Widget>[
            const SizedBox(height: 8),
            RecentAnalysesErrorState(message: errorMessage!, onRetry: onRetry),
          ],
        ),
      );
    }

    if (showEmptyState) {
      return HomePullToRefresh.box(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.only(bottom: 24),
          children: <Widget>[
            const SizedBox(height: 8),
            RecentAnalysesEmptyState(
              onCreateFirstAnalysis: onCreateFirstAnalysis,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (errorMessage != null) ...<Widget>[
          RecentAnalysesInlineError(message: errorMessage!),
          const SizedBox(height: 12),
        ],
        Expanded(
          child: HomePullToRefresh.scrollable(
            onRefresh: onRefresh,
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
                itemCount:
                    processingAnalyses.length +
                    recentAnalyses.length +
                    1 +
                    (isLoadingMore ? 1 : 0),
                separatorBuilder: (BuildContext context, int index) =>
                    const SizedBox(height: 12),
                itemBuilder: (BuildContext context, int index) {
                  if (index < processingAnalyses.length) {
                    final AnalysisDto analysis = processingAnalyses[index];
                    final String title = analysis.name.trim().isEmpty
                        ? 'Análise sem nome'
                        : analysis.name;

                    return ProcessingAnalysisCard(
                      title: title,
                      dateLabel: formatCreatedAt(analysis.createdAt),
                      type: analysis.type,
                      statusLabel: _resolveStatusLabel(analysis.status),
                      onTap: () {
                        unawaited(onTapAnalysis(analysis));
                      },
                    );
                  }

                  final int headingIndex = processingAnalyses.length;
                  if (index == headingIndex) {
                    return Text(
                      'Recentes',
                      style: GoogleFonts.fraunces(
                        textStyle: textTheme.titleMedium?.copyWith(
                          color: tokens.textPrimary,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.4,
                        ),
                      ),
                    );
                  }

                  final int recentStartIndex = headingIndex + 1;
                  final int recentEndIndex =
                      recentStartIndex + recentAnalyses.length - 1;

                  if (index >= recentStartIndex && index <= recentEndIndex) {
                    final AnalysisDto analysis =
                        recentAnalyses[index - recentStartIndex];
                    final String title = analysis.name.trim().isEmpty
                        ? 'Análise sem nome'
                        : analysis.name;

                    return RecentAnalysisCard(
                      title: title,
                      dateLabel: formatCreatedAt(analysis.createdAt),
                      type: analysis.type,
                      statusLabel: _resolveStatusLabel(analysis.status),
                      onTap: () {
                        unawaited(onTapAnalysis(analysis));
                      },
                    );
                  }

                  if (isLoadingMore) {
                    return const RecentAnalysesLoadingMore();
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  bool _isProcessingStatus(AnalysisStatusDto status) {
    return status == AnalysisStatusDto.analyzingPetition ||
        status == AnalysisStatusDto.extractingPetition ||
        status == AnalysisStatusDto.analyzingCase ||
        status == AnalysisStatusDto.searchingPrecedents ||
        status == AnalysisStatusDto.analyzingPrecedentsSimilarity ||
        status == AnalysisStatusDto.analyzingPrecedentsApplicability ||
        status == AnalysisStatusDto.generatingSynthesis ||
        status == AnalysisStatusDto.generatingPetitionDraft ||
        status == AnalysisStatusDto.generatingJudgmentDraft;
  }

  String _resolveStatusLabel(AnalysisStatusDto status) {
    switch (status) {
      case AnalysisStatusDto.waitingPetition:
      case AnalysisStatusDto.waitingDocumentUpload:
        return 'Aguardando petição';
      case AnalysisStatusDto.petitionUploaded:
      case AnalysisStatusDto.documentUploaded:
        return 'Petição enviada';
      case AnalysisStatusDto.analyzingPetition:
      case AnalysisStatusDto.analyzingCase:
        return 'Petição em análise';
      case AnalysisStatusDto.extractingPetition:
        return 'Extraindo petição';
      case AnalysisStatusDto.caseAnalyzed:
        return 'Petição analisada';
      case AnalysisStatusDto.searchingPrecedents:
        return 'Buscando precedentes';
      case AnalysisStatusDto.precedentsSearched:
        return 'Precedentes encontrados';
      case AnalysisStatusDto.analyzingPrecedentsSimilarity:
      case AnalysisStatusDto.analyzingPrecedentsApplicability:
        return 'Comparando precedentes';
      case AnalysisStatusDto.generatingSynthesis:
        return 'Gerando síntese';
      case AnalysisStatusDto.generatingPetitionDraft:
        return 'Gerando minuta da petição';
      case AnalysisStatusDto.generatingJudgmentDraft:
        return 'Gerando minuta do julgamento';
      case AnalysisStatusDto.waitingPrecedentChoice:
        return 'Aguardando escolha de precedente';
      case AnalysisStatusDto.precedentChosen:
      case AnalysisStatusDto.done:
        return 'Concluída';
      case AnalysisStatusDto.failed:
        return 'Falhou';
    }

    return 'Processando';
  }
}
