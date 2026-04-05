import 'package:animus/core/intake/dtos/court_dto.dart';
import 'package:animus/core/intake/dtos/precedent_kind_dto.dart';
import 'package:animus/theme.dart';
import 'package:animus/ui/intake/widgets/pages/analysis_screen/precedents_filters_dialog/precedents_filters_dialog_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget createWidget({
    required ValueChanged<CourtDto> onToggleCourt,
    required ValueChanged<PrecedentKindDto> onToggleKind,
    required VoidCallback onClear,
    required VoidCallback onApply,
  }) {
    return MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 600,
            child: PrecedentsFiltersDialogView(
              selectedCourts: const <CourtDto>[CourtDto.stf],
              selectedKinds: const <PrecedentKindDto>[PrecedentKindDto.sum],
              onToggleCourt: onToggleCourt,
              onToggleKind: onToggleKind,
              onClear: onClear,
              onApply: onApply,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('renderiza grupos expansiveis e delega toggles clear e apply', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final toggledCourts = <CourtDto>[];
    final toggledKinds = <PrecedentKindDto>[];
    var clearCalls = 0;
    var applyCalls = 0;

    await tester.pumpWidget(
      createWidget(
        onToggleCourt: toggledCourts.add,
        onToggleKind: toggledKinds.add,
        onClear: () => clearCalls++,
        onApply: () => applyCalls++,
      ),
    );

    expect(find.text('Filtros de precedentes'), findsOneWidget);
    expect(find.text('Tribunais'), findsOneWidget);
    expect(find.text('Tipos'), findsOneWidget);
    expect(find.text('Superiores'), findsOneWidget);
    expect(find.text('TRFs'), findsOneWidget);
    expect(find.text('STF'), findsOneWidget);
    expect(find.text('TRFS6'), findsNothing);

    await tester.ensureVisible(find.text('TRFs'));
    await tester.tap(find.text('TRFs'));
    await tester.pump();

    expect(find.text('TRFS6'), findsOneWidget);

    await tester.ensureVisible(find.text('STF'));
    await tester.tap(find.text('STF'));
    await tester.pump();
    await tester.ensureVisible(find.text('SUM'));
    await tester.tap(find.text('SUM'));
    await tester.pump();
    await tester.ensureVisible(find.text('Limpar filtros'));
    await tester.tap(find.text('Limpar filtros'));
    await tester.pump();
    await tester.ensureVisible(find.text('Aplicar filtros'));
    await tester.tap(find.text('Aplicar filtros'));
    await tester.pump();

    expect(toggledCourts, <CourtDto>[CourtDto.stf]);
    expect(toggledKinds, <PrecedentKindDto>[PrecedentKindDto.sum]);
    expect(clearCalls, 1);
    expect(applyCalls, 1);
  });
}
