import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:animus/core/intake/dtos/petition_draft_dto.dart';
import 'package:animus/core/intake/interfaces/intake_service.dart';
import 'package:animus/core/shared/interfaces/file_share_driver.dart';
import 'package:animus/core/shared/responses/rest_response.dart';
import 'package:animus/core/storage/interfaces/drivers/file_storage_driver.dart';
import 'package:animus/drivers/file-share-driver/index.dart';
import 'package:animus/drivers/file_storage/index.dart';
import 'package:animus/rest/services/index.dart';
import 'package:animus/theme.dart';
import 'package:animus/ui/intake/widgets/pages/case_assessment_analysis_screen/petition_draft_dialog/petition_draft_dialog_presenter.dart';
import 'package:animus/ui/intake/widgets/pages/case_assessment_analysis_screen/petition_draft_dialog/petition_draft_dialog_view.dart';

import '../../../../../../fakers/intake/petition_draft_dto_faker.dart';

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

  setUpAll(() {
    registerFallbackValue(PetitionDraftDtoFaker.fake());
  });

  setUp(() {
    onRegenerate = _MockOnRegenerate();
    intakeService = _MockIntakeService();
    fileStorageDriver = _MockFileStorageDriver();
    fileShareDriver = _MockFileShareDriver();
  });

  testWidgets('should prevent closing when there are invalid pending changes', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _createHost(
        intakeService: intakeService,
        fileStorageDriver: fileStorageDriver,
        fileShareDriver: fileShareDriver,
        onRegenerate: onRegenerate.call,
      ),
    );

    await _openDialog(tester);
    await tester.enterText(find.byType(EditableText).first, '   ');
    await tester.pump();

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.byType(PetitionDraftDialogView), findsOneWidget);
    expect(
      find.text('Corrija os campos obrigatórios antes de fechar a minuta.'),
      findsOneWidget,
    );
    verifyNever(
      () => intakeService.updatePetitionDraft(
        analysisId: any(named: 'analysisId'),
        draft: any(named: 'draft'),
      ),
    );
  });

  testWidgets('should allow closing after saving valid pending changes', (
    WidgetTester tester,
  ) async {
    when(
      () => intakeService.updatePetitionDraft(
        analysisId: 'analysis-id',
        draft: any(named: 'draft'),
      ),
    ).thenAnswer(
      (Invocation invocation) async => RestResponse<PetitionDraftDto>(
        body: invocation.namedArguments[#draft] as PetitionDraftDto,
      ),
    );

    await tester.pumpWidget(
      _createHost(
        intakeService: intakeService,
        fileStorageDriver: fileStorageDriver,
        fileShareDriver: fileShareDriver,
        onRegenerate: onRegenerate.call,
      ),
    );

    await _openDialog(tester);
    await tester.enterText(
      find.byType(EditableText).first,
      'Fatos atualizados',
    );
    await tester.pump();

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    verify(
      () => intakeService.updatePetitionDraft(
        analysisId: 'analysis-id',
        draft: any(named: 'draft'),
      ),
    ).called(1);
    expect(find.byType(PetitionDraftDialogView), findsNothing);
  });

  testWidgets(
    'should show list item validation only after relevant interaction',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        _createHost(
          draft: PetitionDraftDtoFaker.fake(
            analysisId: 'analysis-id',
            requests: const <String>[],
          ),
          intakeService: intakeService,
          fileStorageDriver: fileStorageDriver,
          fileShareDriver: fileShareDriver,
          onRegenerate: onRegenerate.call,
        ),
      );

      await _openDialog(tester);

      expect(find.text('Campo obrigatório.'), findsNothing);

      await tester.ensureVisible(find.text('Adicionar pedido'));
      await tester.tap(find.text('Adicionar pedido'));
      await tester.pump();

      expect(find.text('Campo obrigatório.'), findsWidgets);
    },
  );

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
    expect(find.byType(PetitionDraftDialogView), findsNothing);
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
      expect(find.byType(PetitionDraftDialogView), findsOneWidget);
    },
  );

  testWidgets('should disable export button when form becomes invalid', (
    WidgetTester tester,
  ) async {
    final PetitionDraftDto draft = PetitionDraftDtoFaker.fake();
    final ProviderContainer container = ProviderContainer(
      overrides: [
        intakeServiceProvider.overrideWithValue(intakeService),
        fileStorageDriverProvider.overrideWithValue(fileStorageDriver),
        fileShareDriverProvider.overrideWithValue(fileShareDriver),
      ],
    );

    when(() => onRegenerate.call()).thenAnswer((_) async => false);

    await tester.pumpWidget(
      _createHost(
        container: container,
        draft: draft,
        intakeService: intakeService,
        fileStorageDriver: fileStorageDriver,
        fileShareDriver: fileShareDriver,
        onRegenerate: onRegenerate.call,
      ),
    );

    await _openDialog(tester);

    final PetitionDraftDialogPresenter presenter = container.read(
      petitionDraftDialogPresenterProvider((
        analysisId: 'analysis-id',
        analysisName: 'Análise teste',
        initialDraft: draft,
      )),
    );

    presenter.updateRequest(0, '   ');
    await tester.pump();

    expect(_exportButton(tester).onPressed, isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
    await tester.pumpAndSettle();
  });

  testWidgets('should show loading and disable export button while exporting', (
    WidgetTester tester,
  ) async {
    final PetitionDraftDto draft = PetitionDraftDtoFaker.fake();
    final ProviderContainer container = ProviderContainer(
      overrides: [
        intakeServiceProvider.overrideWithValue(intakeService),
        fileStorageDriverProvider.overrideWithValue(fileStorageDriver),
        fileShareDriverProvider.overrideWithValue(fileShareDriver),
      ],
    );

    addTearDown(container.dispose);
    when(() => onRegenerate.call()).thenAnswer((_) async => false);

    await tester.pumpWidget(
      _createHost(
        container: container,
        draft: draft,
        intakeService: intakeService,
        fileStorageDriver: fileStorageDriver,
        fileShareDriver: fileShareDriver,
        onRegenerate: onRegenerate.call,
      ),
    );

    await _openDialog(tester);

    final PetitionDraftDialogPresenter presenter = container.read(
      petitionDraftDialogPresenterProvider((
        analysisId: 'analysis-id',
        analysisName: 'Análise teste',
        initialDraft: draft,
      )),
    );

    presenter.isExportingDraft.value = true;
    await tester.pump();

    expect(find.text('Exportando...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(_exportButton(tester).onPressed, isNull);
  });
}

Widget _createHost({
  ProviderContainer? container,
  PetitionDraftDto? draft,
  required IntakeService intakeService,
  required FileStorageDriver fileStorageDriver,
  required FileShareDriver fileShareDriver,
  required Future<bool> Function() onRegenerate,
}) {
  final PetitionDraftDto resolvedDraft = draft ?? PetitionDraftDtoFaker.fake();

  final Widget app = MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(
      body: Builder(
        builder: (BuildContext context) {
          return Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => PetitionDraftDialogView(
                      analysisId: 'analysis-id',
                      analysisName: 'Análise teste',
                      initialDraft: resolvedDraft,
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

  if (container != null) {
    return UncontrolledProviderScope(container: container, child: app);
  }

  return ProviderScope(
    overrides: [
      intakeServiceProvider.overrideWithValue(intakeService),
      fileStorageDriverProvider.overrideWithValue(fileStorageDriver),
      fileShareDriverProvider.overrideWithValue(fileShareDriver),
    ],
    child: app,
  );
}

Future<void> _openDialog(WidgetTester tester) async {
  await tester.tap(find.text('Abrir dialog'));
  await tester.pumpAndSettle();
}

ButtonStyleButton _exportButton(WidgetTester tester) {
  return tester.widget<ButtonStyleButton>(
    find.ancestor(
      of: find.byWidgetPredicate(
        (Widget widget) =>
            widget is Text &&
            (widget.data == 'Exportar minuta' ||
                widget.data == 'Exportando...'),
      ),
      matching: find.byWidgetPredicate(
        (Widget widget) => widget is ButtonStyleButton,
      ),
    ),
  );
}
