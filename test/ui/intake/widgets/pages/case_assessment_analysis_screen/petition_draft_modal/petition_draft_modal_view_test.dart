import 'package:animus/theme.dart';
import 'package:animus/ui/intake/widgets/pages/case_assessment_analysis_screen/petition_draft_modal/petition_draft_modal_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../../fakers/intake/petition_draft_dto_faker.dart';

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

    await _openModal(tester);
    await tester.tap(find.text('Regerar minuta'));
    await tester.pumpAndSettle();

    verify(() => onRegenerate.call()).called(1);
    expect(find.byType(PetitionDraftModalView), findsNothing);
  });

  testWidgets(
    'should keep fullscreen view open when regeneration returns false',
    (WidgetTester tester) async {
      when(() => onRegenerate.call()).thenAnswer((_) async => false);

      await tester.pumpWidget(_createHost(onRegenerate: onRegenerate.call));

      await _openModal(tester);
      await tester.tap(find.text('Regerar minuta'));
      await tester.pumpAndSettle();

      verify(() => onRegenerate.call()).called(1);
      expect(find.byType(PetitionDraftModalView), findsOneWidget);
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
                    builder: (_) => PetitionDraftModalView(
                      draft: PetitionDraftDtoFaker.fake(),
                      onRegenerate: onRegenerate,
                    ),
                  ),
                );
              },
              child: const Text('Abrir modal'),
            ),
          );
        },
      ),
    ),
  );
}

Future<void> _openModal(WidgetTester tester) async {
  await tester.tap(find.text('Abrir modal'));
  await tester.pumpAndSettle();
}
