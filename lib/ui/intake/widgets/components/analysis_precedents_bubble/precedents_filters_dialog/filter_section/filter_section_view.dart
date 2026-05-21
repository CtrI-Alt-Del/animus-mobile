import 'package:flutter/material.dart';

import 'package:animus/ui/intake/widgets/components/analysis_precedents_bubble/precedents_filters_dialog/filter_chip/index.dart';
import 'package:animus/ui/intake/widgets/components/analysis_precedents_bubble/precedents_filters_dialog/section_header/index.dart';

class FilterSectionView<T> extends StatelessWidget {
  final String title;
  final int appliedCount;
  final List<T> values;
  final List<T> selected;
  final ValueChanged<T> onTap;
  final String Function(T) labelBuilder;

  const FilterSectionView({
    required this.title,
    required this.appliedCount,
    required this.values,
    required this.selected,
    required this.onTap,
    required this.labelBuilder,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SectionHeader(title: title, appliedCount: appliedCount),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: values
              .map((T value) {
                final bool isSelected = selected.contains(value);
                return PrecedentsFilterChip(
                  label: labelBuilder(value),
                  isSelected: isSelected,
                  onTap: () => onTap(value),
                );
              })
              .toList(growable: false),
        ),
      ],
    );
  }
}
