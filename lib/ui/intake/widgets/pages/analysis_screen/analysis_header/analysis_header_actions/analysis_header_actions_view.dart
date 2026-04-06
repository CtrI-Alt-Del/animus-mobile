import 'package:flutter/material.dart';

import 'package:animus/theme.dart';

class AnalysisHeaderActionsView extends StatelessWidget {
  final VoidCallback? onExportReport;
  final VoidCallback? onPrecedentsCount;
  final VoidCallback? onFilters;
  final VoidCallback? onRename;
  final VoidCallback? onArchive;
  final int appliedFiltersCount;
  final bool isEnabled;
  final bool showExportReport;
  final bool isExportingReport;

  const AnalysisHeaderActionsView({
    required this.onExportReport,
    required this.onPrecedentsCount,
    required this.onFilters,
    required this.onRename,
    required this.onArchive,
    required this.appliedFiltersCount,
    required this.isEnabled,
    this.showExportReport = false,
    this.isExportingReport = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return PopupMenuButton<String>(
      enabled: isEnabled,
      offset: const Offset(0, 40),
      color: tokens.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: tokens.borderSubtle),
      ),
      onSelected: (String value) {
        if (value == 'precedents_count') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            onPrecedentsCount?.call();
          });
          return;
        }

        if (value == 'rename') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            onRename?.call();
          });
          return;
        }

        if (value == 'filters') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            onFilters?.call();
          });
          return;
        }

        if (value == 'archive') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            onArchive?.call();
          });
          return;
        }

        if (value == 'export_report') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            onExportReport?.call();
          });
          return;
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'rename',
          height: 48,
          child: Row(
            children: <Widget>[
              Icon(Icons.edit_outlined, color: tokens.textPrimary, size: 18),
              const SizedBox(width: 10),
              Text(
                'Renomear',
                style: textTheme.bodyMedium?.copyWith(
                  color: tokens.textPrimary,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'archive',
          height: 48,
          child: Row(
            children: <Widget>[
              Icon(
                Icons.inventory_2_outlined,
                color: tokens.textPrimary,
                size: 18,
              ),
              const SizedBox(width: 10),
              Text(
                'Arquivar',
                style: textTheme.bodyMedium?.copyWith(
                  color: tokens.textPrimary,
                ),
              ),
            ],
          ),
        ),
        if (showExportReport)
          PopupMenuItem<String>(
            value: 'export_report',
            enabled: !isExportingReport && onExportReport != null,
            height: 48,
            child: Row(
              children: <Widget>[
                Icon(
                  Icons.picture_as_pdf_outlined,
                  color: tokens.textPrimary,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Text(
                  isExportingReport ? 'Exportando PDF...' : 'Exportar PDF',
                  style: textTheme.bodyMedium?.copyWith(
                    color: tokens.textPrimary,
                  ),
                ),
                if (isExportingReport) ...<Widget>[
                  const Spacer(),
                  SizedBox(
                    height: 14,
                    width: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: tokens.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        PopupMenuItem<String>(
          value: 'filters',
          height: 48,
          child: Row(
            children: <Widget>[
              Icon(
                Icons.filter_alt_outlined,
                color: tokens.textPrimary,
                size: 18,
              ),
              const SizedBox(width: 10),
              Text(
                'Filtros',
                style: textTheme.bodyMedium?.copyWith(
                  color: tokens.textPrimary,
                ),
              ),
              const Spacer(),
              if (appliedFiltersCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: tokens.warning.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: tokens.warning.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    appliedFiltersCount.toString(),
                    style: textTheme.labelSmall?.copyWith(
                      color: tokens.warning,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'precedents_count',
          height: 48,
          child: Row(
            children: <Widget>[
              Icon(Icons.balance_outlined, color: tokens.textPrimary, size: 18),
              const SizedBox(width: 10),
              Text(
                'Qtd. precedentes',
                style: textTheme.bodyMedium?.copyWith(
                  color: tokens.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(Icons.tune, color: tokens.textSecondary, size: 20),
      ),
    );
  }
}
