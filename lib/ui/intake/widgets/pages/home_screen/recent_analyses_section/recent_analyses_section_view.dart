import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:animus/core/intake/dtos/analysis_dto.dart';
import 'package:animus/theme.dart';
import 'package:animus/ui/intake/widgets/pages/home_screen/recent_analyses_section/recent_analyses_empty_state/index.dart';
import 'package:animus/ui/intake/widgets/pages/home_screen/recent_analyses_section/recent_analyses_error_state/index.dart';
import 'package:animus/ui/intake/widgets/pages/home_screen/recent_analyses_section/recent_analyses_inline_error/index.dart';
import 'package:animus/ui/intake/widgets/pages/home_screen/recent_analyses_section/recent_analyses_loading_more/index.dart';
import 'package:animus/ui/intake/widgets/pages/home_screen/recent_analyses_section/recent_analyses_loading_state/index.dart';
import 'package:animus/ui/intake/widgets/pages/home_screen/recent_analyses_section/recent_analysis_card/index.dart';

class RecentAnalysesSectionView extends StatelessWidget {
  final List<AnalysisDto> analyses;
  final bool isLoading;
  final bool isLoadingMore;
  final bool showEmptyState;
  final String? errorMessage;
  final String Function(String value) formatCreatedAt;
  final ValueChanged<AnalysisDto> onTapAnalysis;
  final VoidCallback onRetry;
  final VoidCallback onLoadMore;
  final VoidCallback onCreateFirstAnalysis;

  const RecentAnalysesSectionView({
    required this.analyses,
    required this.isLoading,
    required this.isLoadingMore,
    required this.showEmptyState,
    required this.errorMessage,
    required this.formatCreatedAt,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          'Recentes',
          style: GoogleFonts.fraunces(
            textStyle: textTheme.titleMedium?.copyWith(
              color: tokens.textPrimary,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.4,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(child: _buildBody(context)),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    if (isLoading && analyses.isEmpty) {
      return const RecentAnalysesLoadingState();
    }

    if (errorMessage != null && analyses.isEmpty) {
      return RecentAnalysesErrorState(message: errorMessage!, onRetry: onRetry);
    }

    if (showEmptyState) {
      return RecentAnalysesEmptyState(
        onCreateFirstAnalysis: onCreateFirstAnalysis,
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
          child: NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification notification) {
              final double maxExtent = notification.metrics.maxScrollExtent;
              final double pixels = notification.metrics.pixels;
              if (maxExtent > 0 && pixels >= maxExtent - 120) {
                onLoadMore();
              }
              return false;
            },
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: analyses.length + (isLoadingMore ? 1 : 0),
              separatorBuilder:
                  (BuildContext context, int index) =>
                      const SizedBox(height: 12),
              itemBuilder: (BuildContext context, int index) {
                if (index >= analyses.length) {
                  return const RecentAnalysesLoadingMore();
                }

                final AnalysisDto analysis = analyses[index];
                final String title =
                    analysis.name.trim().isEmpty
                        ? 'Analise sem nome'
                        : analysis.name;

                return RecentAnalysisCard(
                  title: title,
                  dateLabel: formatCreatedAt(analysis.createdAt),
                  onTap: () => onTapAnalysis(analysis),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
