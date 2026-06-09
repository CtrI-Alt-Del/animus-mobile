import 'package:animus/core/intake/interfaces/intake_service.dart';
import 'package:animus/core/shared/interfaces/file_share_driver.dart';
import 'package:animus/core/storage/interfaces/drivers/file_storage_driver.dart';
import 'package:animus/drivers/file-share-driver/index.dart';
import 'package:animus/drivers/file_storage/index.dart';
import 'package:animus/rest/services/index.dart';
import 'package:animus/theme.dart';
import 'package:animus/ui/intake/widgets/pages/second_instance_analysis_screen/judgment_draft_dialog/judgment_draft_dialog_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../../fakers/intake/second_instance_judgment_draft_dto_faker.dart';

class _MockOnRegenerate extends Mock {
  Future<bool> call();
}

class _MockIntakeService extends Mock implements IntakeService {}

class _MockFileStorageDriver extends Mock implements FileStorageDriver {}

class _MockFileShareDriver extends Mock implements FileShareDriver {}

void main() {
  late _MockOnRegenerate onRegenerate;
  late _MockIntakeService intakeService;
  late _MockFileStorageDriver fileStorageDriver;
  late _MockFileShareDriver fileShareDriver;

  setUp(() {
    onRegenerate = _MockOnRegenerate();
    intakeService = _MockIntakeService();
    fileStorageDriver = _MockFileStorageDriver();
    fileShareDriver = _MockFileShareDriver();
  });

  testWidgets('should close fullscreen view when regeneration succeeds', (
    WidgetTester tester,
  ) async {
    when(() => onRegenerate.call()).thenAnswer((_) async => true);

    await tester.pumpWidget(
      _createHost(
        intakeService: intakeService,
        fileStorageDriver: fileStorageDriver,
        fileShareDriver: fileShareDriver,
        onRegenerate: onRegenerate.call,
      ),
    );

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

      await tester.pumpWidget(
        _createHost(
          intakeService: intakeService,
          fileStorageDriver: fileStorageDriver,
          fileShareDriver: fileShareDriver,
          onRegenerate: onRegenerate.call,
        ),
      );

      await _openDialog(tester);
      await tester.tap(find.text('Regerar minuta'));
      await tester.pumpAndSettle();

      verify(() => onRegenerate.call()).called(1);
      expect(find.byType(JudgmentDraftDialogView), findsOneWidget);
    },
  );
}

Widget _createHost({
  required IntakeService intakeService,
  required FileStorageDriver fileStorageDriver,
  required FileShareDriver fileShareDriver,
  required Future<bool> Function() onRegenerate,
}) {
  return ProviderScope(
    overrides: [
      intakeServiceProvider.overrideWithValue(intakeService),
      fileStorageDriverProvider.overrideWithValue(fileStorageDriver),
      fileShareDriverProvider.overrideWithValue(fileShareDriver),
    ],
    child: MaterialApp(
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
                        analysisId: 'analysis-id',
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
    ),
  );
}

Future<void> _openDialog(WidgetTester tester) async {
  await tester.tap(find.text('Abrir dialog'));
  await tester.pumpAndSettle();
}
