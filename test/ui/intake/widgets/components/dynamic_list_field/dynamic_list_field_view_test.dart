import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:animus/theme.dart';
import 'package:animus/ui/intake/widgets/components/dynamic_list_field/dynamic_list_field_view.dart';

void main() {
  testWidgets('should disable remove action when only one item remains', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _createWidget(
        items: const <String>['Pedido inicial'],
        itemErrorTextBuilder: (int index, String value) => null,
      ),
    );

    final IconButton removeButton = tester.widget<IconButton>(
      find.byType(IconButton),
    );

    expect(removeButton.onPressed, isNull);
    expect(find.byTooltip('É necessário manter ao menos 1 item.'), findsOne);
  });

  testWidgets(
    'should render inline error only when custom validation returns it',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        _createWidget(
          items: const <String>[''],
          itemErrorTextBuilder: (int index, String value) => null,
        ),
      );

      expect(find.text('Campo obrigatório.'), findsNothing);

      await tester.pumpWidget(
        _createWidget(
          items: const <String>[''],
          itemErrorTextBuilder: (int index, String value) =>
              'Campo obrigatório.',
        ),
      );

      expect(find.text('Campo obrigatório.'), findsOneWidget);
    },
  );

  testWidgets(
    'should call onAdd, onUpdate and onRemove for list interactions',
    (WidgetTester tester) async {
      int? removedIndex;
      int? updatedIndex;
      String? updatedValue;
      var addCalls = 0;

      await tester.pumpWidget(
        _createWidget(
          items: const <String>['Pedido 1', 'Pedido 2'],
          itemErrorTextBuilder: (int index, String value) => null,
          onAdd: () {
            addCalls += 1;
          },
          onRemove: (int index) {
            removedIndex = index;
          },
          onUpdate: (int index, String value) {
            updatedIndex = index;
            updatedValue = value;
          },
        ),
      );

      await tester.enterText(
        find.byType(TextFormField).first,
        'Pedido alterado',
      );
      await tester.tap(find.byIcon(Icons.close_rounded).first);
      await tester.tap(find.text('Adicionar pedido'));

      expect(updatedIndex, 0);
      expect(updatedValue, 'Pedido alterado');
      expect(removedIndex, 0);
      expect(addCalls, 1);
    },
  );
}

Widget _createWidget({
  required List<String> items,
  VoidCallback? onAdd,
  void Function(int index)? onRemove,
  void Function(int index, String value)? onUpdate,
  String? Function(int index, String value)? itemErrorTextBuilder,
}) {
  return MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(
      body: DynamicListFieldView(
        items: items,
        onAdd: onAdd ?? () {},
        onRemove: onRemove ?? (int index) {},
        onUpdate: onUpdate ?? (int index, String value) {},
        addLabel: 'Adicionar pedido',
        itemLabel: 'Pedido',
        itemHintText: 'Descreva o pedido.',
        itemErrorTextBuilder: itemErrorTextBuilder,
      ),
    ),
  );
}
