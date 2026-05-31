import 'package:animus/theme.dart';
import 'package:animus/ui/intake/widgets/components/regenerate_draft_dialog/regenerate_draft_dialog_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockOnConfirm extends Mock {
  Future<void> call(String comments);
}

void main() {
  late _MockOnConfirm onConfirm;

  setUp(() {
    onConfirm = _MockOnConfirm();
    when(() => onConfirm.call(any())).thenAnswer((_) async {});
  });

  testWidgets(
    'should keep confirm disabled for blank comments and enable it for valid input',
    (WidgetTester tester) async {
      await tester.pumpWidget(_createHost(onConfirm: onConfirm.call));

      await _openDialog(tester);

      expect(_confirmButton(tester).onPressed, isNull);

      await tester.enterText(find.byType(TextField), '   ');
      await tester.pump();

      expect(_confirmButton(tester).onPressed, isNull);

      await tester.enterText(find.byType(TextField), 'Comentário válido');
      await tester.pump();

      expect(_confirmButton(tester).onPressed, isNotNull);
    },
  );

  testWidgets(
    'should confirm with normalized comments and close dialog with true result',
    (WidgetTester tester) async {
      bool? result;

      await tester.pumpWidget(
        _createHost(
          onConfirm: onConfirm.call,
          onResolved: (bool? value) => result = value,
        ),
      );

      await _openDialog(tester);
      await tester.enterText(
        find.byType(TextField),
        '  Ajustar fundamentos e pedidos.  ',
      );
      await tester.pump();

      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();

      verify(() => onConfirm.call('Ajustar fundamentos e pedidos.')).called(1);
      expect(result, isTrue);
      expect(find.byType(RegenerateDraftDialogView), findsNothing);
    },
  );
}

Widget _createHost({
  required Future<void> Function(String comments) onConfirm,
  void Function(bool? result)? onResolved,
}) {
  return ProviderScope(
    child: MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: Builder(
          builder: (BuildContext context) {
            return Center(
              child: ElevatedButton(
                onPressed: () async {
                  final bool? value = await showDialog<bool>(
                    context: context,
                    builder: (_) => RegenerateDraftDialogView(
                      title: 'Regerar minuta',
                      description: 'Descreva os ajustes desejados.',
                      textFieldLabel: 'Comentários',
                      confirmLabel: 'Confirmar',
                      onConfirm: onConfirm,
                    ),
                  );

                  onResolved?.call(value);
                },
                child: const Text('Abrir dialog'),
              ),
            );
          },
        ),
      ),
    ),
  );
}

Future<void> _openDialog(WidgetTester tester) async {
  await tester.tap(find.text('Abrir dialog'));
  await tester.pumpAndSettle();
}

ButtonStyleButton _confirmButton(WidgetTester tester) {
  return tester.widget<ButtonStyleButton>(
    find.ancestor(
      of: find.text('Confirmar'),
      matching: find.byWidgetPredicate(
        (Widget widget) => widget is ButtonStyleButton,
      ),
    ),
  );
}
