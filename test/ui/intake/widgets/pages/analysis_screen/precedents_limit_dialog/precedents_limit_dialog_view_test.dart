import 'package:animus/theme.dart';
import 'package:animus/ui/intake/widgets/pages/analysis_screen/precedents_limit_dialog/precedents_limit_dialog_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget createWidget({
    required int currentValue,
    required ValueChanged<int> onChanged,
    required VoidCallback onCancel,
    required VoidCallback onApply,
  }) {
    return MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 600,
            child: PrecedentsLimitDialogView(
              currentValue: currentValue,
              minValue: 1,
              maxValue: 20,
              onChanged: onChanged,
              onCancel: onCancel,
              onApply: onApply,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('renderiza slider valor e delega callbacks', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    int? changedValue;
    var cancelCalls = 0;
    var applyCalls = 0;

    await tester.pumpWidget(
      createWidget(
        currentValue: 5,
        onChanged: (int value) => changedValue = value,
        onCancel: () => cancelCalls++,
        onApply: () => applyCalls++,
      ),
    );

    expect(find.text('Qtd. de precedentes'), findsOneWidget);
    expect(find.text('Quantidade retornada'), findsOneWidget);
    expect(find.text('5'), findsWidgets);
    expect(find.byType(Slider), findsOneWidget);

    final Slider slider = tester.widget<Slider>(find.byType(Slider));
    slider.onChanged!(7);
    await tester.pump();

    expect(changedValue, 7);

    await tester.tap(find.text('Cancelar'));
    await tester.pump();
    await tester.tap(find.text('Aplicar'));
    await tester.pump();

    expect(cancelCalls, 1);
    expect(applyCalls, 1);
  });
}
