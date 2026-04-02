import 'package:animus/theme.dart';
import 'package:animus/ui/intake/widgets/pages/home_screen/home_header/home_header_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renderiza avatar com semantica e chama acao de perfil', (
    WidgetTester tester,
  ) async {
    int pressedCount = 0;
    final SemanticsHandle semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: HomeHeaderView(
            greeting: 'Bom dia, Ada',
            subtitle: 'Seu resumo juridico de hoje',
            onProfilePressed: () {
              pressedCount += 1;
            },
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('Abrir perfil'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Abrir perfil'));
    await tester.pump();

    expect(pressedCount, 1);
    semantics.dispose();
  });
}
