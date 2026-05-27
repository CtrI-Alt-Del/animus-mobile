import 'dart:async';

import 'package:flutter/material.dart';

import 'package:animus/core/intake/dtos/analysis_dto.dart';
import 'package:animus/theme.dart';

class FolderAvailableAnalysisPickerView extends StatelessWidget {
  final List<AnalysisDto> availableAnalyses;
  final Set<String> selectedAnalysisIds;
  final bool isLoading;
  final bool isAdding;
  final void Function(String analysisId) onToggleSelection;
  final Future<void> Function() onConfirm;
  final Future<void> Function() onRetry;

  const FolderAvailableAnalysisPickerView({
    required this.availableAnalyses,
    required this.selectedAnalysisIds,
    required this.isLoading,
    required this.isAdding,
    required this.onToggleSelection,
    required this.onConfirm,
    required this.onRetry,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Adicionar análises',
            style: textTheme.titleSmall?.copyWith(
              color: tokens.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Selecione análises disponíveis para preencher esta pasta.',
            style: textTheme.bodySmall?.copyWith(color: tokens.textMuted),
          ),
          const SizedBox(height: 16),
          Expanded(child: _buildBody(context, tokens)),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: selectedAnalysisIds.isEmpty || isAdding
                ? null
                : () {
                    unawaited(onConfirm());
                  },
            style: FilledButton.styleFrom(
              backgroundColor: tokens.accent,
              foregroundColor: tokens.surfacePage,
            ),
            icon: isAdding
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        tokens.surfacePage,
                      ),
                    ),
                  )
                : const Icon(Icons.add),
            label: Text(
              selectedAnalysisIds.length <= 1
                  ? 'Adicionar selecionada'
                  : 'Adicionar selecionadas',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppThemeTokens tokens) {
    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(tokens.accent),
        ),
      );
    }

    if (availableAnalyses.isEmpty) {
      final TextTheme textTheme = Theme.of(context).textTheme;

      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.inventory_2_outlined, color: tokens.textMuted, size: 42),
            const SizedBox(height: 12),
            Text(
              'Nenhuma análise disponível',
              textAlign: TextAlign.center,
              style: textTheme.labelMedium?.copyWith(
                color: tokens.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => unawaited(onRetry()),
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      itemCount: availableAnalyses.length,
      separatorBuilder: (BuildContext context, int index) =>
          const SizedBox(height: 12),
      itemBuilder: (BuildContext context, int index) {
        final AnalysisDto analysis = availableAnalyses[index];
        final String analysisId = (analysis.id ?? '').trim();

        return _AvailableAnalysisTile(
          key: ValueKey<String>('available-analysis-$analysisId'),
          analysis: analysis,
          isSelected: selectedAnalysisIds.contains(analysisId),
          onTap: () {
            onToggleSelection(analysisId);
          },
        );
      },
    );
  }
}

class _AvailableAnalysisTile extends StatelessWidget {
  final AnalysisDto analysis;
  final bool isSelected;
  final VoidCallback onTap;

  const _AvailableAnalysisTile({
    required this.analysis,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String title = analysis.name.trim().isEmpty
        ? 'Análise sem nome'
        : analysis.name.trim();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
          decoration: BoxDecoration(
            color: isSelected
                ? tokens.accent.withValues(alpha: 0.10)
                : tokens.surfaceElevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? tokens.accent.withValues(alpha: 0.45)
                  : tokens.borderSubtle,
            ),
          ),
          child: Row(
            children: <Widget>[
              Icon(Icons.description_outlined, color: tokens.accent, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelMedium?.copyWith(
                    color: tokens.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Checkbox(
                value: isSelected,
                onChanged: (_) => onTap(),
                visualDensity: VisualDensity.compact,
                side: BorderSide(color: tokens.accent.withValues(alpha: 0.4)),
                activeColor: tokens.accent,
                checkColor: tokens.surfacePage,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
