import 'package:animus/core/intake/dtos/analysis_type_dto.dart';
import 'package:animus/theme.dart';
import 'package:animus/ui/intake/widgets/pages/home_screen/recent_analyses_section/analysis_type_badge/analysis_type_badge_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renderiza label e icone para caseAssessment', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _createWidget(type: AnalysisTypeDto.caseAssessment),
    );

    expect(find.text('Avaliação de caso'), findsOneWidget);
    expect(find.byIcon(Icons.fact_check_outlined), findsOneWidget);
  });

  testWidgets('renderiza label e icone para firstInstance', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_createWidget(type: AnalysisTypeDto.firstInstance));

    expect(find.text('Primeira instância'), findsOneWidget);
    expect(find.byIcon(Icons.gavel_outlined), findsOneWidget);
  });

  testWidgets('renderiza label e icone para secondInstance', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _createWidget(type: AnalysisTypeDto.secondInstance),
    );

    expect(find.text('Segunda instância'), findsOneWidget);
    expect(find.byIcon(Icons.account_balance_outlined), findsOneWidget);
  });

  testWidgets('expoe semantica de tipo para leitores de tela', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      _createWidget(type: AnalysisTypeDto.secondInstance),
    );

    expect(
      find.bySemanticsLabel(RegExp(r'^Tipo: Segunda instância')),
      findsOneWidget,
    );

    semantics.dispose();
  });
}

Widget _createWidget({required AnalysisTypeDto type}) {
  return MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(
      body: Center(child: AnalysisTypeBadgeView(type: type)),
    ),
  );
}
