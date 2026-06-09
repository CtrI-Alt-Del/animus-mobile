import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:animus/theme.dart';
import 'package:animus/ui/intake/widgets/components/save_status_indicator/save_status.dart';
import 'package:animus/ui/intake/widgets/components/save_status_indicator/save_status_indicator_view.dart';

void main() {
  testWidgets('should hide indicator when status is idle', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_createWidget(SaveStatus.idle));

    expect(find.text('Salvando...'), findsNothing);
    expect(find.text('Salvo'), findsNothing);
    expect(find.text('Erro ao salvar'), findsNothing);
  });

  testWidgets('should show loading state when status is saving', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_createWidget(SaveStatus.saving));

    expect(find.text('Salvando...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('should show success state and hide it after a few seconds', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_createWidget(SaveStatus.saved));

    expect(find.text('Salvo'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.text('Salvo'), findsNothing);
  });

  testWidgets('should show error state when status is error', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_createWidget(SaveStatus.error));

    expect(find.text('Erro ao salvar'), findsOneWidget);
    expect(find.byIcon(Icons.error_rounded), findsOneWidget);
  });
}

Widget _createWidget(SaveStatus status) {
  return MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(
      body: Center(child: SaveStatusIndicatorView(status: status)),
    ),
  );
}
