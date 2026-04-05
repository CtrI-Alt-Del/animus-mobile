import 'package:flutter/material.dart';

import 'package:animus/core/intake/dtos/court_dto.dart';
import 'package:animus/core/intake/dtos/precedent_kind_dto.dart';

class PrecedentsFiltersDialogView extends StatelessWidget {
  final List<CourtDto> selectedCourts;
  final List<PrecedentKindDto> selectedKinds;
  final ValueChanged<CourtDto> onToggleCourt;
  final ValueChanged<PrecedentKindDto> onToggleKind;
  final VoidCallback onClear;
  final VoidCallback onApply;

  const PrecedentsFiltersDialogView({
    required this.selectedCourts,
    required this.selectedKinds,
    required this.onToggleCourt,
    required this.onToggleKind,
    required this.onClear,
    required this.onApply,
    super.key,
  });

  static final List<CourtDto> supportedCourts = List<CourtDto>.unmodifiable(
    CourtDto.values,
  );

  static final List<PrecedentKindDto> supportedKinds =
      List<PrecedentKindDto>.unmodifiable(PrecedentKindDto.values);

  static final List<_CourtGroup>
  _courtGroups = List<_CourtGroup>.unmodifiable(<_CourtGroup>[
    _CourtGroup(
      title: 'Superiores',
      courts: CourtDto.values
          .where(
            (CourtDto court) =>
                court == CourtDto.stf ||
                court == CourtDto.stj ||
                court == CourtDto.tst ||
                court == CourtDto.tse ||
                court == CourtDto.stm ||
                court == CourtDto.tnu,
          )
          .toList(growable: false),
    ),
    _CourtGroup(
      title: 'TRFs',
      courts: CourtDto.values
          .where(
            (CourtDto court) =>
                court == CourtDto.trfs6 || court.name.startsWith('trf'),
          )
          .toList(growable: false),
    ),
    _CourtGroup(
      title: 'TJs',
      courts: CourtDto.values
          .where(
            (CourtDto court) =>
                court == CourtDto.tjs27 || court.name.startsWith('tj'),
          )
          .toList(growable: false),
    ),
    _CourtGroup(
      title: 'TRTs',
      courts: CourtDto.values
          .where(
            (CourtDto court) =>
                court == CourtDto.trts24 || court.name.startsWith('trt'),
          )
          .toList(growable: false),
    ),
  ]);

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 352,
          maxHeight: MediaQuery.sizeOf(context).height * 0.86,
        ),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF16161A),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF2A2A2E)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Filtros de precedentes',
                    style: textTheme.titleLarge?.copyWith(
                      color: const Color(0xFFFAFAF9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  splashRadius: 18,
                  icon: const Icon(Icons.close, color: Color(0xFF8E8E93)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Refine tribunais e tipos para a proxima busca manual de precedentes.',
              style: textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF8E8E93),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 52,
              child: OutlinedButton(
                onPressed: onClear,
                style: OutlinedButton.styleFrom(
                  backgroundColor: const Color(0xFF202027),
                  side: const BorderSide(color: Color(0xFF2F2F36)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Limpar filtros',
                  style: textTheme.labelLarge?.copyWith(
                    color: const Color(0xFFFAFAF9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 52,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[Color(0xFFFBE26D), Color(0xFFC4A535)],
                  ),
                ),
                child: FilledButton(
                  onPressed: onApply,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Aplicar filtros',
                    style: textTheme.labelLarge?.copyWith(
                      color: const Color(0xFF0B0B0E),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _CourtFilterSection(
                      title: 'Tribunais',
                      appliedCount: selectedCourts.length,
                      selected: selectedCourts,
                      groups: _courtGroups,
                      onTap: onToggleCourt,
                    ),
                    const SizedBox(height: 14),
                    _FilterSection<PrecedentKindDto>(
                      title: 'Tipos',
                      appliedCount: selectedKinds.length,
                      values: supportedKinds,
                      selected: selectedKinds,
                      onTap: onToggleKind,
                      labelBuilder: (PrecedentKindDto value) => value.value,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Os filtros refinam apenas a proxima busca manual, sem afetar a analise atual ate voce refazer a busca.',
                      style: textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF8E8E93),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CourtFilterSection extends StatefulWidget {
  final String title;
  final int appliedCount;
  final List<CourtDto> selected;
  final List<_CourtGroup> groups;
  final ValueChanged<CourtDto> onTap;

  const _CourtFilterSection({
    required this.title,
    required this.appliedCount,
    required this.selected,
    required this.groups,
    required this.onTap,
  });

  @override
  State<_CourtFilterSection> createState() => _CourtFilterSectionState();
}

class _CourtFilterSectionState extends State<_CourtFilterSection> {
  late final Set<String> _expandedGroups = <String>{'Superiores'};

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _SectionHeader(title: widget.title, appliedCount: widget.appliedCount),
        const SizedBox(height: 10),
        ...widget.groups.map((_CourtGroup group) {
          final bool isExpanded = _expandedGroups.contains(group.title);
          final int selectedInGroup = group.courts
              .where((CourtDto court) => widget.selected.contains(court))
              .length;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    setState(() {
                      if (isExpanded) {
                        _expandedGroups.remove(group.title);
                      } else {
                        _expandedGroups.add(group.title);
                      }
                    });
                  },
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
                          color: const Color(0xFF8E8E93),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            group.title,
                            style: textTheme.labelMedium?.copyWith(
                              color: const Color(0xFFB2B2B9),
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
                              color: const Color(0x14FBE26D),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: const Color(0x35FBE26D),
                              ),
                            ),
                            child: Text(
                              '$selectedInGroup',
                              style: textTheme.labelSmall?.copyWith(
                                color: const Color(0xFFFBE26D),
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
                            final bool isSelected = widget.selected.contains(
                              court,
                            );
                            return _FilterChip(
                              label: court.value,
                              isSelected: isSelected,
                              onTap: () => widget.onTap(court),
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
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int appliedCount;

  const _SectionHeader({required this.title, required this.appliedCount});

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            title,
            style: textTheme.labelMedium?.copyWith(
              color: const Color(0xFF6B6B70),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0x14FBE26D),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0x35FBE26D)),
          ),
          child: Text(
            '$appliedCount aplicado${appliedCount == 1 ? '' : 's'}',
            style: textTheme.labelMedium?.copyWith(
              color: const Color(0xFFFAFAF9),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0x147A6A17) : const Color(0xFF202027),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF7A6A17)
                : const Color(0xFF2F2F36),
          ),
        ),
        child: Text(
          label,
          style: textTheme.labelMedium?.copyWith(
            color: isSelected
                ? const Color(0xFFFBE26D)
                : const Color(0xFF8E8E93),
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _FilterSection<T> extends StatelessWidget {
  final String title;
  final int appliedCount;
  final List<T> values;
  final List<T> selected;
  final ValueChanged<T> onTap;
  final String Function(T) labelBuilder;

  const _FilterSection({
    required this.title,
    required this.appliedCount,
    required this.values,
    required this.selected,
    required this.onTap,
    required this.labelBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _SectionHeader(title: title, appliedCount: appliedCount),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: values
              .map((T value) {
                final bool isSelected = selected.contains(value);
                return _FilterChip(
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

class _CourtGroup {
  final String title;
  final List<CourtDto> courts;

  const _CourtGroup({required this.title, required this.courts});
}
