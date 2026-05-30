import 'package:animus/theme.dart';
import 'package:animus/ui/intake/widgets/pages/second_instance_analysis_screen/judgment_draft_dialog/judgment_draft_dialog_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../../fakers/intake/second_instance_judgment_draft_dto_faker.dart';

class _MockOnRegenerate extends Mock {
  Future<bool> call();
}

void main() {
  late _MockOnRegenerate onRegenerate;

  setUp(() {
    onRegenerate = _MockOnRegenerate();
  });

  testWidgets('should close fullscreen view when regeneration succeeds', (
    WidgetTester tester,
  ) async {
    when(() => onRegenerate.call()).thenAnswer((_) async => true);

    await tester.pumpWidget(_createHost(onRegenerate: onRegenerate.call));

    await _openDialog(tester);
    await tester.tap(find.text('Regerar minuta'));
    await tester.pumpAndSettle();

    verify(() => onRegenerate.call()).called(1);
    expect(find.byType(JudgmentDraftDialogView), findsNothing);
  });

  testWidgets(
    'should keep fullscreen view open when regeneration returns false',
    (WidgetTester tester) async {
      when(() => onRegenerate.call()).thenAnswer((_) async => false);

      await tester.pumpWidget(_createHost(onRegenerate: onRegenerate.call));

      await _openDialog(tester);
      await tester.tap(find.text('Regerar minuta'));
      await tester.pumpAndSettle();

      verify(() => onRegenerate.call()).called(1);
      expect(find.byType(JudgmentDraftDialogView), findsOneWidget);
    },
  );
}

Widget _createHost({required Future<bool> Function() onRegenerate}) {
  return MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(
      body: Builder(
        builder: (BuildContext context) {
          return Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => JudgmentDraftDialogView(
                      draft: SecondInstanceJudgmentDraftDtoFaker.fake(),
                      onRegenerate: onRegenerate,
                    ),
                  ),
                );
              },
              child: const Text('Abrir dialog'),
            ),
          );
        },
      ),
    ),
  );
}

Future<void> _openDialog(WidgetTester tester) async {
  await tester.tap(find.text('Abrir dialog'));
  await tester.pumpAndSettle();
}
