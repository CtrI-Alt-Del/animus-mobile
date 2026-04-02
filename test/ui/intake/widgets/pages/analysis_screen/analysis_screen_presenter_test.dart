import 'dart:async';
import 'dart:io';

import 'package:animus/core/intake/dtos/analysis_dto.dart';
import 'package:animus/core/intake/dtos/analysis_status_dto.dart';
import 'package:animus/core/intake/dtos/petition_summary_dto.dart';
import 'package:animus/core/intake/interfaces/intake_service.dart';
import 'package:animus/core/shared/responses/rest_response.dart';
import 'package:animus/core/storage/interfaces/drivers/document_picker_driver.dart';
import 'package:animus/core/storage/interfaces/drivers/file_storage_driver.dart';
import 'package:animus/core/storage/interfaces/storage_service.dart';
import 'package:animus/ui/intake/widgets/pages/analysis_screen/analysis_screen_presenter.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../fakers/intake/analysis_dto_faker.dart';
import '../../../../../fakers/intake/petition_dto_faker.dart';
import '../../../../../fakers/intake/petition_summary_dto_faker.dart';
import '../../../../../fakers/storage/upload_url_dto_faker.dart';

class _MockIntakeService extends Mock implements IntakeService {}

class _MockStorageService extends Mock implements StorageService {}

class _MockFileStorageDriver extends Mock implements FileStorageDriver {}

class _MockDocumentPickerDriver extends Mock implements DocumentPickerDriver {}

void main() {
  late _MockIntakeService intakeService;
  late _MockStorageService storageService;
  late _MockFileStorageDriver fileStorageDriver;
  late _MockDocumentPickerDriver documentPickerDriver;
  late Directory tempDirectory;

  setUpAll(() {
    registerFallbackValue(PetitionDtoFaker.fake());
  });

  setUp(() async {
    intakeService = _MockIntakeService();
    storageService = _MockStorageService();
    fileStorageDriver = _MockFileStorageDriver();
    documentPickerDriver = _MockDocumentPickerDriver();
    tempDirectory = await Directory.systemTemp.createTemp(
      'analysis_screen_presenter_test_',
    );
  });

  tearDown(() async {
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  AnalysisScreenPresenter createPresenter() {
    return AnalysisScreenPresenter(
      intakeService: intakeService,
      storageService: storageService,
      fileStorageDriver: fileStorageDriver,
      documentPickerDriver: documentPickerDriver,
      analysisId: 'analysis-1',
    );
  }

  Future<File> createFile(String name, int sizeInBytes) async {
    final File file = File('${tempDirectory.path}/$name');
    final RandomAccessFile accessFile = file.openSync(mode: FileMode.write);
    accessFile.truncateSync(sizeInBytes);
    accessFile.closeSync();
    return file;
  }

  group('load', () {
    test(
      'should clear petition data when analysis is waiting petition',
      () async {
        final AnalysisScreenPresenter presenter = createPresenter();
        addTearDown(presenter.dispose);

        presenter.petition.value = PetitionDtoFaker.fake();
        presenter.summary.value = PetitionSummaryDtoFaker.fake();
        presenter.status.value = AnalysisStatusDto.petitionAnalyzed;

        when(
          () => intakeService.getAnalysis(analysisId: 'analysis-1'),
        ).thenAnswer(
          (_) async => RestResponse<AnalysisDto>(
            statusCode: 200,
            body: AnalysisDtoFaker.fake(
              status: AnalysisStatusDto.waitingPetition,
              name: 'Nova analise pendente',
            ),
          ),
        );

        await presenter.load();

        expect(presenter.status.value, AnalysisStatusDto.waitingPetition);
        expect(presenter.analysisName.value, 'Nova analise pendente');
        expect(presenter.petition.value, isNull);
        expect(presenter.summary.value, isNull);
        expect(presenter.selectedFile.value, isNull);
        verifyNever(
          () => intakeService.getAnalysisPetition(
            analysisId: any(named: 'analysisId'),
          ),
        );
      },
    );

    test('should keep waiting shell when getAnalysis fails', () async {
      final AnalysisScreenPresenter presenter = createPresenter();
      addTearDown(presenter.dispose);

      when(
        () => intakeService.getAnalysis(analysisId: 'analysis-1'),
      ).thenAnswer(
        (_) async => RestResponse<AnalysisDto>(
          statusCode: 500,
          errorMessage: 'Falha ao carregar analise.',
        ),
      );

      await presenter.load();

      expect(presenter.status.value, AnalysisStatusDto.waitingPetition);
      expect(presenter.petition.value, isNull);
      expect(presenter.summary.value, isNull);
      expect(presenter.analysisName.value, 'Nova Análise');
    });

    test(
      'should load petition and selected file when status is petitionUploaded',
      () async {
        final AnalysisScreenPresenter presenter = createPresenter();
        addTearDown(presenter.dispose);
        final File petitionFile = await createFile('uploaded.pdf', 1024);
        final petition = PetitionDtoFaker.fake();

        when(
          () => intakeService.getAnalysis(analysisId: 'analysis-1'),
        ).thenAnswer(
          (_) async => RestResponse<AnalysisDto>(
            statusCode: 200,
            body: AnalysisDtoFaker.fake(
              status: AnalysisStatusDto.petitionUploaded,
              name: 'Analise pronta para resumo',
            ),
          ),
        );
        when(
          () => intakeService.getAnalysisPetition(analysisId: 'analysis-1'),
        ).thenAnswer(
          (_) async => RestResponse(statusCode: 200, body: petition),
        );
        when(
          () => fileStorageDriver.getFile(petition.document.filePath),
        ).thenAnswer((_) async => petitionFile);

        await presenter.load();

        expect(presenter.analysisName.value, 'Analise pronta para resumo');
        expect(presenter.status.value, AnalysisStatusDto.petitionUploaded);
        expect(presenter.petition.value?.id, petition.id);
        expect(presenter.selectedFile.value?.path, petitionFile.path);
        expect(presenter.summary.value, isNull);
        verify(
          () => intakeService.getAnalysisPetition(analysisId: 'analysis-1'),
        ).called(1);
      },
    );

    test(
      'should load petition and summary when status is petitionAnalyzed',
      () async {
        final AnalysisScreenPresenter presenter = createPresenter();
        addTearDown(presenter.dispose);
        final File petitionFile = await createFile('uploaded.pdf', 1024);
        final petition = PetitionDtoFaker.fake();
        final PetitionSummaryDto petitionSummary =
            PetitionSummaryDtoFaker.fake();

        when(
          () => intakeService.getAnalysis(analysisId: 'analysis-1'),
        ).thenAnswer(
          (_) async => RestResponse<AnalysisDto>(
            statusCode: 200,
            body: AnalysisDtoFaker.fake(
              status: AnalysisStatusDto.petitionAnalyzed,
            ),
          ),
        );
        when(
          () => intakeService.getAnalysisPetition(analysisId: 'analysis-1'),
        ).thenAnswer(
          (_) async => RestResponse(statusCode: 200, body: petition),
        );
        when(
          () => fileStorageDriver.getFile(petition.document.filePath),
        ).thenAnswer((_) async => petitionFile);
        when(
          () => intakeService.getPetitionSummary(petitionId: petition.id!),
        ).thenAnswer(
          (_) async => RestResponse(statusCode: 200, body: petitionSummary),
        );

        await presenter.load();

        expect(presenter.analysisName.value, 'Analise de precedente');
        expect(presenter.status.value, AnalysisStatusDto.petitionAnalyzed);
        expect(presenter.petition.value?.id, petition.id);
        expect(presenter.selectedFile.value?.path, petitionFile.path);
        expect(
          presenter.summary.value?.caseSummary,
          petitionSummary.caseSummary,
        );
        verify(
          () => intakeService.getPetitionSummary(petitionId: petition.id!),
        ).called(1);
      },
    );
  });

  group('pickDocument', () {
    test('should show inline error when extension is invalid', () async {
      final AnalysisScreenPresenter presenter = createPresenter();
      addTearDown(presenter.dispose);
      final File file = await createFile('petition.txt', 1024);

      when(
        () => documentPickerDriver.pickDocument(
          allowedExtensions: AnalysisScreenPresenter.allowedExtensions,
        ),
      ).thenAnswer((_) async => file);

      await presenter.pickDocument();

      expect(presenter.generalError.value, 'Selecione um arquivo PDF ou DOCX.');
      expect(presenter.selectedFile.value, isNull);
      verifyNever(
        () => storageService.generatePetitionUploadUrl(
          analysisId: any(named: 'analysisId'),
          documentType: any(named: 'documentType'),
        ),
      );
    });

    test('should show inline error when file is larger than limit', () async {
      final AnalysisScreenPresenter presenter = createPresenter();
      addTearDown(presenter.dispose);
      final File file = await createFile(
        'petition.pdf',
        AnalysisScreenPresenter.maxFileSizeInBytes + 1,
      );

      when(
        () => documentPickerDriver.pickDocument(
          allowedExtensions: AnalysisScreenPresenter.allowedExtensions,
        ),
      ).thenAnswer((_) async => file);

      await presenter.pickDocument();

      expect(
        presenter.generalError.value,
        'O arquivo deve ter no maximo 20MB.',
      );
      verifyNever(
        () => storageService.generatePetitionUploadUrl(
          analysisId: any(named: 'analysisId'),
          documentType: any(named: 'documentType'),
        ),
      );
    });

    test('should upload file and create petition on happy path', () async {
      final AnalysisScreenPresenter presenter = createPresenter();
      addTearDown(presenter.dispose);
      final File file = await createFile('petition.pdf', 4096);
      final uploadUrl = UploadUrlDtoFaker.fake();
      final createdPetition = PetitionDtoFaker.fake(
        document: PetitionDocumentDtoFaker.fake(
          filePath: uploadUrl.filePath,
          name: 'petition.pdf',
        ),
      );

      when(
        () => documentPickerDriver.pickDocument(
          allowedExtensions: AnalysisScreenPresenter.allowedExtensions,
        ),
      ).thenAnswer((_) async => file);
      when(
        () => storageService.generatePetitionUploadUrl(
          analysisId: 'analysis-1',
          documentType: 'pdf',
        ),
      ).thenAnswer((_) async => RestResponse(statusCode: 200, body: uploadUrl));
      when(
        () => fileStorageDriver.uploadFile(
          file,
          uploadUrl,
          onProgress: any(named: 'onProgress'),
        ),
      ).thenAnswer((Invocation invocation) async {
        final void Function(int, int)? onProgress =
            invocation.namedArguments[#onProgress] as void Function(int, int)?;
        onProgress?.call(2048, 4096);
        onProgress?.call(4096, 4096);
      });
      when(
        () => intakeService.createPetition(petition: any(named: 'petition')),
      ).thenAnswer(
        (_) async => RestResponse(statusCode: 201, body: createdPetition),
      );

      await presenter.pickDocument();

      expect(presenter.status.value, AnalysisStatusDto.petitionUploaded);
      expect(presenter.petition.value?.id, createdPetition.id);
      expect(presenter.summary.value, isNull);
      expect(presenter.generalError.value, isNull);
      expect(presenter.uploadProgress.value, 1);
      expect(presenter.selectedFile.value?.path, file.path);
      verify(
        () => storageService.generatePetitionUploadUrl(
          analysisId: 'analysis-1',
          documentType: 'pdf',
        ),
      ).called(1);
      verify(
        () => fileStorageDriver.uploadFile(
          file,
          uploadUrl,
          onProgress: any(named: 'onProgress'),
        ),
      ).called(1);
      verify(
        () => intakeService.createPetition(petition: any(named: 'petition')),
      ).called(1);
    });

    test('should apply failed state when upload url request fails', () async {
      final AnalysisScreenPresenter presenter = createPresenter();
      addTearDown(presenter.dispose);
      final File file = await createFile('petition.pdf', 2048);

      when(
        () => documentPickerDriver.pickDocument(
          allowedExtensions: AnalysisScreenPresenter.allowedExtensions,
        ),
      ).thenAnswer((_) async => file);
      when(
        () => storageService.generatePetitionUploadUrl(
          analysisId: 'analysis-1',
          documentType: 'pdf',
        ),
      ).thenAnswer(
        (_) async =>
            RestResponse(statusCode: 500, errorMessage: 'Falha ao gerar URL.'),
      );

      await presenter.pickDocument();

      expect(presenter.status.value, AnalysisStatusDto.failed);
      expect(presenter.generalError.value, 'Falha ao gerar URL.');
      expect(presenter.selectedFile.value?.path, file.path);
      expect(presenter.uploadProgress.value, isNull);
      verifyNever(
        () => intakeService.createPetition(petition: any(named: 'petition')),
      );
    });
  });

  group('analyze', () {
    test('should summarize petition successfully', () async {
      final AnalysisScreenPresenter presenter = createPresenter();
      addTearDown(presenter.dispose);
      final petition = PetitionDtoFaker.fake();
      final PetitionSummaryDto petitionSummary = PetitionSummaryDtoFaker.fake();

      presenter.petition.value = petition;
      presenter.status.value = AnalysisStatusDto.petitionUploaded;

      when(
        () => intakeService.summarizePetition(petitionId: petition.id!),
      ).thenAnswer(
        (_) async => RestResponse(statusCode: 200, body: petitionSummary),
      );

      await presenter.analyze();

      expect(presenter.status.value, AnalysisStatusDto.petitionAnalyzed);
      expect(presenter.summary.value?.legalIssue, petitionSummary.legalIssue);
      expect(presenter.generalError.value, isNull);
    });

    test(
      'should move to failed when summarize petition returns remote error',
      () async {
        final AnalysisScreenPresenter presenter = createPresenter();
        addTearDown(presenter.dispose);
        final petition = PetitionDtoFaker.fake();

        presenter.petition.value = petition;
        presenter.status.value = AnalysisStatusDto.petitionUploaded;

        when(
          () => intakeService.summarizePetition(petitionId: petition.id!),
        ).thenAnswer(
          (_) async => RestResponse<PetitionSummaryDto>(
            statusCode: 500,
            errorMessage: 'Falha ao gerar resumo.',
          ),
        );

        await presenter.analyze();

        expect(presenter.status.value, AnalysisStatusDto.failed);
        expect(presenter.generalError.value, 'Falha ao gerar resumo.');
        expect(presenter.summary.value, isNull);
      },
    );

    test('should timeout summarize request after 60 seconds', () {
      final AnalysisScreenPresenter presenter = createPresenter();
      addTearDown(presenter.dispose);
      final petition = PetitionDtoFaker.fake();
      final completer = Completer<RestResponse<PetitionSummaryDto>>();

      presenter.petition.value = petition;
      presenter.status.value = AnalysisStatusDto.petitionUploaded;

      when(
        () => intakeService.summarizePetition(petitionId: petition.id!),
      ).thenAnswer((_) => completer.future);

      fakeAsync((FakeAsync async) {
        unawaited(presenter.analyze());

        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 61));
        async.flushMicrotasks();

        expect(presenter.status.value, AnalysisStatusDto.failed);
        expect(
          presenter.generalError.value,
          contains('O resumo excedeu o tempo limite de 60 segundos.'),
        );
      });
    });
  });

  group('analysis management', () {
    test('should rename analysis successfully', () async {
      final AnalysisScreenPresenter presenter = createPresenter();
      addTearDown(presenter.dispose);

      when(
        () => intakeService.renameAnalysis(
          analysisId: 'analysis-1',
          name: 'Novo nome',
        ),
      ).thenAnswer(
        (_) async => RestResponse(
          statusCode: 200,
          body: AnalysisDtoFaker.fake(name: 'Novo nome'),
        ),
      );

      final bool renamed = await presenter.renameAnalysis(' Novo nome ');

      expect(renamed, isTrue);
      expect(presenter.analysisName.value, 'Novo nome');
      expect(presenter.generalError.value, isNull);
    });

    test(
      'should validate empty analysis name before calling service',
      () async {
        final AnalysisScreenPresenter presenter = createPresenter();
        addTearDown(presenter.dispose);

        final bool renamed = await presenter.renameAnalysis('   ');

        expect(renamed, isFalse);
        expect(
          presenter.generalError.value,
          'Informe um nome válido para a análise.',
        );
        verifyNever(
          () => intakeService.renameAnalysis(
            analysisId: any(named: 'analysisId'),
            name: any(named: 'name'),
          ),
        );
      },
    );

    test('should archive analysis successfully', () async {
      final AnalysisScreenPresenter presenter = createPresenter();
      addTearDown(presenter.dispose);
      presenter.generalError.value = 'erro antigo';

      when(
        () => intakeService.archiveAnalysis(analysisId: 'analysis-1'),
      ).thenAnswer(
        (_) async => RestResponse(
          statusCode: 200,
          body: AnalysisDtoFaker.fake(isArchived: true),
        ),
      );

      final bool archived = await presenter.archiveAnalysis();

      expect(archived, isTrue);
      expect(presenter.generalError.value, isNull);
    });

    test('should expose remote error when archive analysis fails', () async {
      final AnalysisScreenPresenter presenter = createPresenter();
      addTearDown(presenter.dispose);

      when(
        () => intakeService.archiveAnalysis(analysisId: 'analysis-1'),
      ).thenAnswer(
        (_) async => RestResponse<AnalysisDto>(
          statusCode: 500,
          errorMessage: 'Falha ao arquivar analise.',
        ),
      );

      final bool archived = await presenter.archiveAnalysis();

      expect(archived, isFalse);
      expect(presenter.generalError.value, 'Falha ao arquivar analise.');
    });

    test(
      'should clear previous state and reuse pick document flow on replace',
      () async {
        final AnalysisScreenPresenter presenter = createPresenter();
        addTearDown(presenter.dispose);
        final File oldFile = await createFile('old.pdf', 1024);
        final File newFile = await createFile('new.docx', 4096);
        final uploadUrl = UploadUrlDtoFaker.fake(
          filePath: 'uploads/petitions/new.docx',
        );
        final newPetition = PetitionDtoFaker.fake(
          id: 'petition-2',
          document: PetitionDocumentDtoFaker.fake(
            filePath: uploadUrl.filePath,
            name: 'new.docx',
          ),
        );
        final Completer<File?> pickCompleter = Completer<File?>();

        presenter.petition.value = PetitionDtoFaker.fake(id: 'petition-1');
        presenter.summary.value = PetitionSummaryDtoFaker.fake();
        presenter.selectedFile.value = oldFile;
        presenter.generalError.value = 'erro antigo';
        presenter.status.value = AnalysisStatusDto.petitionAnalyzed;

        when(
          () => documentPickerDriver.pickDocument(
            allowedExtensions: AnalysisScreenPresenter.allowedExtensions,
          ),
        ).thenAnswer((_) => pickCompleter.future);
        when(
          () => storageService.generatePetitionUploadUrl(
            analysisId: 'analysis-1',
            documentType: 'docx',
          ),
        ).thenAnswer(
          (_) async => RestResponse(statusCode: 200, body: uploadUrl),
        );
        when(
          () => fileStorageDriver.uploadFile(
            newFile,
            uploadUrl,
            onProgress: any(named: 'onProgress'),
          ),
        ).thenAnswer((_) async {});
        when(
          () => intakeService.createPetition(petition: any(named: 'petition')),
        ).thenAnswer(
          (_) async => RestResponse(statusCode: 201, body: newPetition),
        );

        final Future<void> replaceFuture = presenter.replaceDocument();

        expect(presenter.status.value, AnalysisStatusDto.waitingPetition);
        expect(presenter.petition.value, isNull);
        expect(presenter.summary.value, isNull);
        expect(presenter.selectedFile.value, isNull);
        expect(presenter.generalError.value, isNull);

        pickCompleter.complete(newFile);
        await replaceFuture;

        expect(presenter.status.value, AnalysisStatusDto.petitionUploaded);
        expect(presenter.petition.value?.id, 'petition-2');
        expect(presenter.summary.value, isNull);
        expect(presenter.selectedFile.value?.path, newFile.path);
        expect(presenter.uploadProgress.value, 1);
        verify(
          () => documentPickerDriver.pickDocument(
            allowedExtensions: AnalysisScreenPresenter.allowedExtensions,
          ),
        ).called(1);
        verify(
          () => storageService.generatePetitionUploadUrl(
            analysisId: 'analysis-1',
            documentType: 'docx',
          ),
        ).called(1);
        verify(
          () => intakeService.createPetition(petition: any(named: 'petition')),
        ).called(1);
      },
    );
  });
}
