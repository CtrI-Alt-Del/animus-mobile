import 'dart:async';
import 'dart:io';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:reactive_forms/reactive_forms.dart';

import 'package:animus/core/intake/dtos/analysis_document_dto.dart';
import 'package:animus/core/intake/dtos/petition_draft_dto.dart';
import 'package:animus/core/intake/interfaces/intake_service.dart';
import 'package:animus/core/shared/interfaces/file_share_driver.dart';
import 'package:animus/core/shared/responses/rest_response.dart';
import 'package:animus/core/storage/interfaces/drivers/file_storage_driver.dart';
import 'package:animus/ui/intake/widgets/components/save_status_indicator/save_status.dart';
import 'package:animus/ui/intake/widgets/pages/case_assessment_analysis_screen/petition_draft_dialog/petition_draft_dialog_presenter.dart';

import '../../../../../../fakers/intake/petition_draft_dto_faker.dart';

class _MockIntakeService extends Mock implements IntakeService {}

class _MockFileStorageDriver extends Mock implements FileStorageDriver {}

class _MockFileShareDriver extends Mock implements FileShareDriver {}

void main() {
  late _MockIntakeService intakeService;
  late _MockFileStorageDriver fileStorageDriver;
  late _MockFileShareDriver fileShareDriver;

  setUpAll(() {
    registerFallbackValue(PetitionDraftDtoFaker.fake());
    registerFallbackValue(File('dummy.docx'));
  });

  setUp(() {
    intakeService = _MockIntakeService();
    fileStorageDriver = _MockFileStorageDriver();
    fileShareDriver = _MockFileShareDriver();

    when(
      () => fileShareDriver.shareFile(
        file: any(named: 'file'),
        filename: any(named: 'filename'),
      ),
    ).thenAnswer((_) async {});
  });

  group('PetitionDraftDialogPresenter', () {
    test('should autosave edited form fields after debounce', () {
      fakeAsync((FakeAsync async) {
        final Completer<RestResponse<PetitionDraftDto>> saveCompleter =
            Completer<RestResponse<PetitionDraftDto>>();
        final PetitionDraftDialogPresenter presenter = _createPresenter(
          intakeService: intakeService,
          fileStorageDriver: fileStorageDriver,
          fileShareDriver: fileShareDriver,
        );
        addTearDown(presenter.dispose);

        when(
          () => intakeService.updatePetitionDraft(
            analysisId: 'analysis-id',
            draft: any(named: 'draft'),
          ),
        ).thenAnswer((_) => saveCompleter.future);

        presenter.form.control('structuredFacts').value = 'Fatos atualizados';

        async.elapse(const Duration(seconds: 1));
        async.flushMicrotasks();
        verifyNever(
          () => intakeService.updatePetitionDraft(
            analysisId: any(named: 'analysisId'),
            draft: any(named: 'draft'),
          ),
        );

        async.elapse(const Duration(seconds: 1));
        async.flushMicrotasks();

        expect(presenter.saveStatus.value, SaveStatus.saving);

        saveCompleter.complete(
          RestResponse<PetitionDraftDto>(body: presenter.currentDraft),
        );
        async.flushMicrotasks();

        final VerificationResult verification = verify(
          () => intakeService.updatePetitionDraft(
            analysisId: 'analysis-id',
            draft: captureAny(named: 'draft'),
          ),
        );
        final PetitionDraftDto savedDraft =
            verification.captured.single as PetitionDraftDto;

        expect(savedDraft.structuredFacts, 'Fatos atualizados');
        expect(presenter.saveStatus.value, SaveStatus.saved);
      });
    });

    test('should autosave edited list items after debounce', () {
      fakeAsync((FakeAsync async) {
        final PetitionDraftDialogPresenter presenter = _createPresenter(
          intakeService: intakeService,
          fileStorageDriver: fileStorageDriver,
          fileShareDriver: fileShareDriver,
        );
        addTearDown(presenter.dispose);

        when(
          () => intakeService.updatePetitionDraft(
            analysisId: 'analysis-id',
            draft: any(named: 'draft'),
          ),
        ).thenAnswer(
          (_) async =>
              RestResponse<PetitionDraftDto>(body: presenter.currentDraft),
        );

        presenter.updateRequest(0, 'Pedido atualizado');

        async.elapse(PetitionDraftDialogPresenter.autosaveDebounce);
        async.flushMicrotasks();

        final VerificationResult verification = verify(
          () => intakeService.updatePetitionDraft(
            analysisId: 'analysis-id',
            draft: captureAny(named: 'draft'),
          ),
        );
        final PetitionDraftDto savedDraft =
            verification.captured.single as PetitionDraftDto;

        expect(savedDraft.requests, const <String>['Pedido atualizado']);
      });
    });

    test('should not save when form data is invalid', () {
      fakeAsync((FakeAsync async) {
        final PetitionDraftDialogPresenter presenter = _createPresenter(
          intakeService: intakeService,
          fileStorageDriver: fileStorageDriver,
          fileShareDriver: fileShareDriver,
        );
        addTearDown(presenter.dispose);

        presenter.form.control('structuredFacts').value = '   ';
        presenter.form.control('structuredFacts').markAsTouched();

        async.elapse(PetitionDraftDialogPresenter.autosaveDebounce);
        async.flushMicrotasks();

        verifyNever(
          () => intakeService.updatePetitionDraft(
            analysisId: any(named: 'analysisId'),
            draft: any(named: 'draft'),
          ),
        );
        expect(presenter.saveStatus.value, SaveStatus.idle);
        expect(
          presenter.fieldErrorMessage(
            control:
                presenter.form.control('structuredFacts')
                    as FormControl<Object?>,
          ),
          'Campo obrigatório.',
        );
      });
    });

    test('should not save when a touched list item is invalid', () {
      fakeAsync((FakeAsync async) {
        final PetitionDraftDialogPresenter presenter = _createPresenter(
          intakeService: intakeService,
          fileStorageDriver: fileStorageDriver,
          fileShareDriver: fileShareDriver,
        );
        addTearDown(presenter.dispose);

        presenter.updateRequest(0, '   ');

        async.elapse(PetitionDraftDialogPresenter.autosaveDebounce);
        async.flushMicrotasks();

        verifyNever(
          () => intakeService.updatePetitionDraft(
            analysisId: any(named: 'analysisId'),
            draft: any(named: 'draft'),
          ),
        );
        expect(
          presenter.fieldErrorMessage(listFieldName: 'requests', index: 0),
          'Campo obrigatório.',
        );
      });
    });

    test('should set error status when autosave request fails', () {
      fakeAsync((FakeAsync async) {
        final PetitionDraftDialogPresenter presenter = _createPresenter(
          intakeService: intakeService,
          fileStorageDriver: fileStorageDriver,
          fileShareDriver: fileShareDriver,
        );
        addTearDown(presenter.dispose);

        when(
          () => intakeService.updatePetitionDraft(
            analysisId: 'analysis-id',
            draft: any(named: 'draft'),
          ),
        ).thenAnswer(
          (_) async => RestResponse<PetitionDraftDto>(
            statusCode: 500,
            errorMessage: 'Falha ao salvar',
          ),
        );

        presenter.form.control('legalGrounds').value = 'Novos fundamentos';

        async.elapse(PetitionDraftDialogPresenter.autosaveDebounce);
        async.flushMicrotasks();

        expect(presenter.saveStatus.value, SaveStatus.error);
        expect(
          presenter.generalError.value,
          'Não foi possível salvar a minuta agora. Tente novamente.',
        );
      });
    });

    test('should block close when there are invalid pending changes', () async {
      final PetitionDraftDialogPresenter presenter = _createPresenter(
        intakeService: intakeService,
        fileStorageDriver: fileStorageDriver,
        fileShareDriver: fileShareDriver,
      );
      addTearDown(presenter.dispose);

      presenter.updateRequest(0, '   ');

      final bool result = await presenter.flushPendingChanges();

      expect(result, isFalse);
      verifyNever(
        () => intakeService.updatePetitionDraft(
          analysisId: any(named: 'analysisId'),
          draft: any(named: 'draft'),
        ),
      );
      expect(
        presenter.generalError.value,
        'Corrija os campos obrigatórios antes de fechar a minuta.',
      );
    });

    test('should allow close after persisting valid pending changes', () async {
      final PetitionDraftDialogPresenter presenter = _createPresenter(
        intakeService: intakeService,
        fileStorageDriver: fileStorageDriver,
        fileShareDriver: fileShareDriver,
      );
      addTearDown(presenter.dispose);

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

      presenter.form.control('centralThesis').value = 'Tese atualizada';

      final bool result = await presenter.flushPendingChanges();

      expect(result, isTrue);
      verify(
        () => intakeService.updatePetitionDraft(
          analysisId: 'analysis-id',
          draft: any(named: 'draft'),
        ),
      ).called(1);
      expect(presenter.generalError.value, isNull);
      expect(presenter.saveStatus.value, SaveStatus.saved);
    });

    test(
      'should export draft, download file and share with sanitized filename on happy path',
      () async {
        final Directory tempDir = Directory.systemTemp.createTempSync();
        final File downloadedFile = File(
          '${tempDir.path}${Platform.pathSeparator}server-file.docx',
        )..writeAsStringSync('docx-content');
        File? sharedFile;

        addTearDown(() async {
          if (await downloadedFile.exists()) {
            await downloadedFile.delete();
          }
          if (sharedFile != null && await sharedFile!.exists()) {
            await sharedFile!.delete();
          }
          if (await tempDir.exists()) {
            await tempDir.delete(recursive: true);
          }
        });

        when(
          () => intakeService.exportPetitionDraft(analysisId: 'analysis-id'),
        ).thenAnswer(
          (_) async => RestResponse<AnalysisDocumentDto>(
            statusCode: 201,
            body: const AnalysisDocumentDto(
              analysisId: 'analysis-id',
              uploadedAt: '2026-06-06T00:00:00Z',
              filePath: 'gcs/exports/draft.docx',
              name: 'draft.docx',
            ),
          ),
        );
        when(
          () => fileStorageDriver.getFile('gcs/exports/draft.docx'),
        ).thenAnswer((_) async => downloadedFile);
        when(
          () => fileShareDriver.shareFile(
            file: any(named: 'file'),
            filename: any(named: 'filename'),
          ),
        ).thenAnswer((Invocation invocation) async {
          sharedFile = invocation.namedArguments[#file] as File;
        });

        final PetitionDraftDialogPresenter presenter = _createPresenter(
          intakeService: intakeService,
          fileStorageDriver: fileStorageDriver,
          fileShareDriver: fileShareDriver,
          analysisName: '  Analise: teste/abc  ',
          initialDraft: PetitionDraftDtoFaker.fake(analysisId: 'analysis-id'),
        );
        addTearDown(presenter.dispose);

        final bool result = await presenter.exportPetitionDraft();

        expect(result, isTrue);
        expect(presenter.generalError.value, isNull);
        expect(presenter.isExportingDraft.value, isFalse);
        expect(sharedFile, isNotNull);
        expect(
          sharedFile!.path,
          endsWith('${Platform.pathSeparator}Analise- teste-abc — Minuta.docx'),
        );
        verify(
          () => intakeService.exportPetitionDraft(analysisId: 'analysis-id'),
        ).called(1);
        verify(
          () => fileStorageDriver.getFile('gcs/exports/draft.docx'),
        ).called(1);
        verify(
          () => fileShareDriver.shareFile(
            file: any(named: 'file'),
            filename: 'Analise- teste-abc — Minuta.docx',
          ),
        ).called(1);
      },
    );

    test(
      'should block export when form is invalid and expose friendly error',
      () async {
        final PetitionDraftDialogPresenter presenter = _createPresenter(
          intakeService: intakeService,
          fileStorageDriver: fileStorageDriver,
          fileShareDriver: fileShareDriver,
        );
        addTearDown(presenter.dispose);

        presenter.updateRequest(0, '   ');

        final bool result = await presenter.exportPetitionDraft();

        expect(result, isFalse);
        expect(
          presenter.generalError.value,
          'Preencha todos os campos da minuta antes de exportar.',
        );
        expect(presenter.saveStatus.value, SaveStatus.idle);
        expect(presenter.isExportingDraft.value, isFalse);
        verifyNever(
          () => intakeService.exportPetitionDraft(analysisId: 'analysis-id'),
        );
        verifyNever(() => fileStorageDriver.getFile(any()));
      },
    );

    test(
      'should block concurrent export attempts while export is in progress',
      () async {
        final Completer<RestResponse<AnalysisDocumentDto>> exportCompleter =
            Completer<RestResponse<AnalysisDocumentDto>>();
        final Directory tempDir = Directory.systemTemp.createTempSync();
        final File downloadedFile = File(
          '${tempDir.path}${Platform.pathSeparator}draft.docx',
        )..writeAsStringSync('docx-content');
        File? sharedFile;

        addTearDown(() async {
          if (await downloadedFile.exists()) {
            await downloadedFile.delete();
          }
          if (sharedFile != null && await sharedFile!.exists()) {
            await sharedFile!.delete();
          }
          if (await tempDir.exists()) {
            await tempDir.delete(recursive: true);
          }
        });

        when(
          () => intakeService.exportPetitionDraft(analysisId: 'analysis-id'),
        ).thenAnswer((_) => exportCompleter.future);
        when(
          () => fileStorageDriver.getFile('gcs/exports/draft.docx'),
        ).thenAnswer((_) async => downloadedFile);
        when(
          () => fileShareDriver.shareFile(
            file: any(named: 'file'),
            filename: any(named: 'filename'),
          ),
        ).thenAnswer((Invocation invocation) async {
          sharedFile = invocation.namedArguments[#file] as File;
        });

        final PetitionDraftDialogPresenter presenter = _createPresenter(
          intakeService: intakeService,
          fileStorageDriver: fileStorageDriver,
          fileShareDriver: fileShareDriver,
        );
        addTearDown(presenter.dispose);

        final Future<bool> firstAttempt = presenter.exportPetitionDraft();
        await Future<void>.delayed(Duration.zero);

        expect(presenter.isExportingDraft.value, isTrue);

        final bool secondAttempt = await presenter.exportPetitionDraft();

        expect(secondAttempt, isFalse);
        verify(
          () => intakeService.exportPetitionDraft(analysisId: 'analysis-id'),
        ).called(1);

        exportCompleter.complete(
          RestResponse<AnalysisDocumentDto>(
            statusCode: 201,
            body: const AnalysisDocumentDto(
              analysisId: 'analysis-id',
              uploadedAt: '2026-06-06T00:00:00Z',
              filePath: 'gcs/exports/draft.docx',
              name: 'draft.docx',
            ),
          ),
        );

        expect(await firstAttempt, isTrue);
        expect(presenter.isExportingDraft.value, isFalse);
      },
    );

    test(
      'should return false and expose friendly error when export post fails',
      () async {
        final PetitionDraftDialogPresenter presenter = _createPresenter(
          intakeService: intakeService,
          fileStorageDriver: fileStorageDriver,
          fileShareDriver: fileShareDriver,
        );
        addTearDown(presenter.dispose);

        when(
          () => intakeService.exportPetitionDraft(analysisId: 'analysis-id'),
        ).thenAnswer(
          (_) async => RestResponse<AnalysisDocumentDto>(
            statusCode: 500,
            errorMessage: 'server-error',
          ),
        );

        final bool result = await presenter.exportPetitionDraft();

        expect(result, isFalse);
        expect(
          presenter.generalError.value,
          'Não foi possível exportar a minuta agora. Tente novamente.',
        );
        expect(presenter.isExportingDraft.value, isFalse);
        expect(presenter.currentDraft.analysisId, 'analysis-id');
        expect(
          presenter.currentDraft.structuredFacts,
          'Fatos estruturados da petição.',
        );
        verifyNever(() => fileStorageDriver.getFile(any()));
      },
    );

    test(
      'should return false and expose friendly error when download fails',
      () async {
        final PetitionDraftDialogPresenter presenter = _createPresenter(
          intakeService: intakeService,
          fileStorageDriver: fileStorageDriver,
          fileShareDriver: fileShareDriver,
        );
        addTearDown(presenter.dispose);

        when(
          () => intakeService.exportPetitionDraft(analysisId: 'analysis-id'),
        ).thenAnswer(
          (_) async => RestResponse<AnalysisDocumentDto>(
            statusCode: 201,
            body: const AnalysisDocumentDto(
              analysisId: 'analysis-id',
              uploadedAt: '2026-06-06T00:00:00Z',
              filePath: 'gcs/exports/draft.docx',
              name: 'draft.docx',
            ),
          ),
        );
        when(
          () => fileStorageDriver.getFile('gcs/exports/draft.docx'),
        ).thenAnswer((_) async => null);

        final bool result = await presenter.exportPetitionDraft();

        expect(result, isFalse);
        expect(
          presenter.generalError.value,
          'Não foi possível exportar a minuta agora. Tente novamente.',
        );
        expect(presenter.isExportingDraft.value, isFalse);
        expect(presenter.currentDraft.analysisId, 'analysis-id');
        expect(
          presenter.currentDraft.structuredFacts,
          'Fatos estruturados da petição.',
        );
      },
    );

    test(
      'should return false and expose friendly error when file share fails',
      () async {
        final Directory tempDir = Directory.systemTemp.createTempSync();
        final File downloadedFile = File(
          '${tempDir.path}${Platform.pathSeparator}draft.docx',
        )..writeAsStringSync('docx-content');

        addTearDown(() async {
          if (await downloadedFile.exists()) {
            await downloadedFile.delete();
          }
          if (await tempDir.exists()) {
            await tempDir.delete(recursive: true);
          }
        });

        when(
          () => intakeService.exportPetitionDraft(analysisId: 'analysis-id'),
        ).thenAnswer(
          (_) async => RestResponse<AnalysisDocumentDto>(
            statusCode: 201,
            body: const AnalysisDocumentDto(
              analysisId: 'analysis-id',
              uploadedAt: '2026-06-06T00:00:00Z',
              filePath: 'gcs/exports/draft.docx',
              name: 'draft.docx',
            ),
          ),
        );
        when(
          () => fileStorageDriver.getFile('gcs/exports/draft.docx'),
        ).thenAnswer((_) async => downloadedFile);
        when(
          () => fileShareDriver.shareFile(
            file: any(named: 'file'),
            filename: any(named: 'filename'),
          ),
        ).thenThrow(Exception('share-failed'));

        final PetitionDraftDialogPresenter presenter = _createPresenter(
          intakeService: intakeService,
          fileStorageDriver: fileStorageDriver,
          fileShareDriver: fileShareDriver,
        );
        addTearDown(presenter.dispose);

        final bool result = await presenter.exportPetitionDraft();

        expect(result, isFalse);
        expect(
          presenter.generalError.value,
          'Não foi possível exportar a minuta agora. Tente novamente.',
        );
        expect(presenter.isExportingDraft.value, isFalse);
        expect(presenter.currentDraft.analysisId, 'analysis-id');
        expect(
          presenter.currentDraft.structuredFacts,
          'Fatos estruturados da petição.',
        );
      },
    );
  });
}

PetitionDraftDialogPresenter _createPresenter({
  required IntakeService intakeService,
  required FileStorageDriver fileStorageDriver,
  required FileShareDriver fileShareDriver,
  String analysisName = 'Análise teste',
  PetitionDraftDto? initialDraft,
}) {
  final PetitionDraftDialogPresenter presenter = PetitionDraftDialogPresenter(
    intakeService: intakeService,
    fileStorageDriver: fileStorageDriver,
    fileShareDriver: fileShareDriver,
    analysisId: 'analysis-id',
    analysisName: analysisName,
    initialDraft:
        initialDraft ?? PetitionDraftDtoFaker.fake(analysisId: 'analysis-id'),
  );
  presenter.init();
  return presenter;
}
