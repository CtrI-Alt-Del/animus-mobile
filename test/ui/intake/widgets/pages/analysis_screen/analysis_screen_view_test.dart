import 'package:animus/theme.dart';
import 'package:animus/ui/intake/widgets/pages/analysis_screen/analysis_screen_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renderiza placeholder com o analysisId recebido', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const AnalysisScreenView(analysisId: 'analysis-123'),
      ),
    );

    expect(find.byType(AppBar), findsOneWidget);
    expect(find.text('Analise'), findsOneWidget);
    expect(find.text('Analise criada'), findsOneWidget);
    expect(find.text('ID: analysis-123'), findsOneWidget);
    expect(
      find.text(
        'O conteudo funcional desta tela sera implementado em uma proxima sprint.',
      ),
      findsOneWidget,
    );
  });
}
