import 'package:flutter/material.dart';

import 'package:animus/theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:animus/core/intake/dtos/court_dto.dart';
import 'package:animus/ui/intake/widgets/components/analysis_precedents_bubble/precedents_filters_dialog/court_filter_section/court_filter_section_presenter.dart';
import 'package:animus/ui/intake/widgets/components/analysis_precedents_bubble/precedents_filters_dialog/court_group.dart';
import 'package:animus/ui/intake/widgets/components/analysis_precedents_bubble/precedents_filters_dialog/filter_chip/index.dart';
import 'package:animus/ui/intake/widgets/components/analysis_precedents_bubble/precedents_filters_dialog/section_header/index.dart';

class CourtFilterSectionView extends ConsumerWidget {
  final String title;
  final int appliedCount;
  final List<CourtDto> selected;
  final List<CourtGroup> groups;
  final ValueChanged<CourtDto> onTap;

  const CourtFilterSectionView({
    required this.title,
    required this.appliedCount,
    required this.selected,
    required this.groups,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final CourtFilterSectionPresenter presenter = ref.watch(
      courtFilterSectionPresenterProvider('Superiores'),
    );
    final TextTheme textTheme = Theme.of(context).textTheme;
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;

    return Watch((BuildContext context) {
      final Set<String> expandedGroups = presenter.expandedGroups.watch(
        context,
      );

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SectionHeader(title: title, appliedCount: appliedCount),
          const SizedBox(height: 10),
          ...groups.map((CourtGroup group) {
            final bool isExpanded = expandedGroups.contains(group.title);
            final int selectedInGroup = group.courts
                .where((CourtDto court) => selected.contains(court))
                .length;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => presenter.toggleGroup(group.title),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 2,
                        vertical: 6,
                      ),
                      child: Row(
                        children: <Widget>[
                          Icon(
                            isExpanded
                                ? Icons.keyboard_arrow_down
                                : Icons.keyboard_arrow_right,
                            size: 18,
                            color: tokens.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              group.title,
                              style: textTheme.labelMedium?.copyWith(
                                color: tokens.textMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (selectedInGroup > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: tokens.accent.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: tokens.accent.withValues(alpha: 0.21),
                                ),
                              ),
                              child: Text(
                                '$selectedInGroup',
                                style: textTheme.labelSmall?.copyWith(
                                  color: tokens.accent,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (isExpanded)
                    Padding(
                      padding: const EdgeInsets.only(left: 24, top: 4),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: group.courts
                            .map((CourtDto court) {
                              final bool isSelected = selected.contains(court);
                              return PrecedentsFilterChip(
                                label: court.value,
                                isSelected: isSelected,
                                onTap: () => onTap(court),
                              );
                            })
                            .toList(growable: false),
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      );
    });
  }
}
