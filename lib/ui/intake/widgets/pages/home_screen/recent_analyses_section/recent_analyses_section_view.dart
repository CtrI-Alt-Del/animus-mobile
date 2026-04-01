import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:animus/core/intake/dtos/analysis_dto.dart';
import 'package:animus/theme.dart';
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
      return const _RecentAnalysesLoadingState();
    }

    if (errorMessage != null && analyses.isEmpty) {
      return _RecentAnalysesErrorState(
        message: errorMessage!,
        onRetry: onRetry,
      );
    }

    if (showEmptyState) {
      return _RecentAnalysesEmptyState(
        onCreateFirstAnalysis: onCreateFirstAnalysis,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (errorMessage != null) ...<Widget>[
          _RecentAnalysesInlineError(message: errorMessage!),
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
              separatorBuilder: (BuildContext context, int index) =>
                  const SizedBox(height: 12),
              itemBuilder: (BuildContext context, int index) {
                if (index >= analyses.length) {
                  return const _RecentAnalysesLoadingMore();
                }

                final AnalysisDto analysis = analyses[index];
                final String title = analysis.name.trim().isEmpty
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

class _RecentAnalysesLoadingState extends StatelessWidget {
  const _RecentAnalysesLoadingState();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      separatorBuilder: (BuildContext context, int index) =>
          const SizedBox(height: 12),
      itemBuilder: (BuildContext context, int index) {
        return const _RecentAnalysesSkeletonCard();
      },
    );
  }
}

class _RecentAnalysesErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _RecentAnalysesErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.error_outline, color: tokens.danger, size: 36),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(color: tokens.textMuted),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentAnalysesEmptyState extends StatelessWidget {
  final VoidCallback onCreateFirstAnalysis;

  const _RecentAnalysesEmptyState({required this.onCreateFirstAnalysis});

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.history_toggle_off, color: tokens.textMuted, size: 40),
            const SizedBox(height: 12),
            Text(
              'Nenhuma analise ainda. Que tal comecar agora?',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(color: tokens.textMuted),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onCreateFirstAnalysis,
              icon: const Icon(Icons.add),
              label: const Text('Iniciar primeira analise'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentAnalysesInlineError extends StatelessWidget {
  final String message;

  const _RecentAnalysesInlineError({required this.message});

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: tokens.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.danger.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.info_outline, color: tokens.danger, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: textTheme.bodySmall?.copyWith(color: tokens.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentAnalysesLoadingMore extends StatelessWidget {
  const _RecentAnalysesLoadingMore();

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;

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

class _RecentAnalysesSkeletonCard extends StatelessWidget {
  const _RecentAnalysesSkeletonCard();

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;

    return Container(
      height: 84,
      decoration: BoxDecoration(
        color: tokens.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tokens.borderSubtle),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 96,
            height: 12,
            decoration: BoxDecoration(
              color: tokens.surfaceElevated,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 16,
            decoration: BoxDecoration(
              color: tokens.surfaceElevated,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ),
    );
  }
}
