import 'package:flutter/material.dart';

import 'package:animus/theme.dart';
import 'package:animus/ui/intake/widgets/pages/analysis_screen/analysis_header/analysis_header_actions/index.dart';

class AnalysisHeaderView extends StatelessWidget {
  final VoidCallback? onBack;
  final VoidCallback? onExportReport;
  final String title;
  final VoidCallback? onPrecedentsCount;
  final VoidCallback? onFilters;
  final VoidCallback? onRename;
  final VoidCallback? onArchive;
  final int appliedFiltersCount;
  final bool isMenuEnabled;
  final bool showExportReport;
  final bool isExportingReport;

  const AnalysisHeaderView({
    required this.onBack,
    required this.onExportReport,
    required this.title,
    required this.onPrecedentsCount,
    required this.onFilters,
    required this.onRename,
    required this.onArchive,
    this.appliedFiltersCount = 0,
    this.isMenuEnabled = true,
    this.showExportReport = false,
    this.isExportingReport = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 52,
        child: Row(
          children: <Widget>[
            IconButton(
              onPressed: onBack,
              icon: Icon(Icons.arrow_back, color: tokens.textPrimary, size: 22),
            ),
            Expanded(
              child: Center(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium?.copyWith(
                    color: tokens.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            AnalysisHeaderActions(
              isEnabled: isMenuEnabled,
              onExportReport: onExportReport,
              onPrecedentsCount: onPrecedentsCount,
              onFilters: onFilters,
              onRename: onRename,
              onArchive: onArchive,
              appliedFiltersCount: appliedFiltersCount,
              showExportReport: showExportReport,
              isExportingReport: isExportingReport,
            ),
          ],
        ),
      ),
    );
  }
}
