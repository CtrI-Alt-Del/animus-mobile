import 'package:animus/theme.dart';
import 'package:animus/ui/intake/widgets/pages/home_screen/create_analysis_type_dialog/create_analysis_type_option/create_analysis_type_option_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'renderiza titulo, descricao, icone e indicador desmarcado quando nao selecionado',
    (WidgetTester tester) async {
      await tester.pumpWidget(_createWidget(isSelected: false, onTap: () {}));

      expect(find.text('Primeira instancia'), findsOneWidget);
      expect(find.text('Resposta a peticao inicial'), findsOneWidget);
      expect(find.byIcon(Icons.gavel_outlined), findsOneWidget);
      expect(find.byIcon(Icons.radio_button_unchecked), findsOneWidget);
      expect(find.byIcon(Icons.radio_button_checked), findsNothing);
    },
  );

  testWidgets('exibe indicador marcado quando selecionado', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_createWidget(isSelected: true, onTap: () {}));

    expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
    expect(find.byIcon(Icons.radio_button_unchecked), findsNothing);
  });

  testWidgets('dispara onTap ao tocar no tile', (WidgetTester tester) async {
    int taps = 0;

    await tester.pumpWidget(
      _createWidget(isSelected: false, onTap: () => taps += 1),
    );

    await tester.tap(find.byType(CreateAnalysisTypeOptionView));
    await tester.pumpAndSettle();

    expect(taps, 1);
  });

  testWidgets('expoe Semantics com selected refletindo o estado atual', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_createWidget(isSelected: true, onTap: () {}));

    final Iterable<Semantics> semanticsWidgets = tester
        .widgetList<Semantics>(
          find.ancestor(
            of: find.text('Primeira instancia'),
            matching: find.byType(Semantics),
          ),
        )
        .where(
          (Semantics widget) => widget.properties.label == 'Primeira instancia',
        );

    expect(semanticsWidgets, isNotEmpty);
    final Semantics semantics = semanticsWidgets.first;
    expect(semantics.properties.selected, isTrue);
    expect(semantics.properties.button, isTrue);
    expect(semantics.properties.label, 'Primeira instancia');
  });
}

Widget _createWidget({required bool isSelected, required VoidCallback onTap}) {
  return MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(
      body: CreateAnalysisTypeOptionView(
        title: 'Primeira instancia',
        description: 'Resposta a peticao inicial',
        icon: Icons.gavel_outlined,
        isSelected: isSelected,
        onTap: onTap,
      ),
    ),
  );
}
