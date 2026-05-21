import 'package:flutter/material.dart';

import 'package:animus/core/intake/dtos/court_dto.dart';
import 'package:animus/core/intake/dtos/precedent_kind_dto.dart';
import 'package:animus/ui/intake/widgets/components/analysis_precedents_bubble/precedents_filters_dialog/court_filter_section/index.dart';
import 'package:animus/ui/intake/widgets/components/analysis_precedents_bubble/precedents_filters_dialog/court_group.dart';
import 'package:animus/ui/intake/widgets/components/analysis_precedents_bubble/precedents_filters_dialog/filter_section/index.dart';

class AnalysisPrecedentsBubblePrecedentsFiltersDialogView
    extends StatelessWidget {
  final List<CourtDto> selectedCourts;
  final List<PrecedentKindDto> selectedKinds;
  final ValueChanged<CourtDto> onToggleCourt;
  final ValueChanged<PrecedentKindDto> onToggleKind;
  final VoidCallback onClear;
  final VoidCallback onApply;

  const AnalysisPrecedentsBubblePrecedentsFiltersDialogView({
    required this.selectedCourts,
    required this.selectedKinds,
    required this.onToggleCourt,
    required this.onToggleKind,
    required this.onClear,
    required this.onApply,
    super.key,
  });

  static final List<PrecedentKindDto> supportedKinds =
      List<PrecedentKindDto>.unmodifiable(PrecedentKindDto.values);

  static final List<CourtGroup>
  _courtGroups = List<CourtGroup>.unmodifiable(<CourtGroup>[
    CourtGroup(
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
    CourtGroup(
      title: 'TRFs',
      courts: CourtDto.values
          .where(
            (CourtDto court) =>
                court == CourtDto.trfs6 || court.name.startsWith('trf'),
          )
          .toList(growable: false),
    ),
    CourtGroup(
      title: 'TJs',
      courts: CourtDto.values
          .where(
            (CourtDto court) =>
                court == CourtDto.tjs27 || court.name.startsWith('tj'),
          )
          .toList(growable: false),
    ),
    CourtGroup(
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
              'Refine tribunais e espécies para a próxima busca manual de precedentes.',
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
                    CourtFilterSection(
                      title: 'Tribunais',
                      appliedCount: selectedCourts.length,
                      selected: selectedCourts,
                      groups: _courtGroups,
                      onTap: onToggleCourt,
                    ),
                    const SizedBox(height: 14),
                    FilterSection<PrecedentKindDto>(
                      title: 'Espécies',
                      appliedCount: selectedKinds.length,
                      values: supportedKinds,
                      selected: selectedKinds,
                      onTap: onToggleKind,
                      labelBuilder: (PrecedentKindDto value) => value.value,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Os filtros refinam apenas a próxima busca manual, sem afetar a análise atual até você refazer a busca.',
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
