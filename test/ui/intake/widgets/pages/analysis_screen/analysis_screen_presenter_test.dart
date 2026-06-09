import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:animus/core/intake/dtos/analysis_dto.dart';
import 'package:animus/core/intake/dtos/analysis_document_dto.dart';
import 'package:animus/core/intake/dtos/first_instance_analysis_report_dto.dart';
import 'package:animus/core/intake/dtos/analysis_status_dto.dart';
import 'package:animus/core/intake/dtos/case_summary_dto.dart';
import 'package:animus/core/intake/interfaces/intake_service.dart';
import 'package:animus/core/shared/interfaces/cache_driver.dart';
import 'package:animus/core/shared/interfaces/pdf_driver.dart';
import 'package:animus/core/shared/responses/rest_response.dart';
import 'package:animus/core/storage/interfaces/drivers/document_picker_driver.dart';
import 'package:animus/core/storage/interfaces/drivers/file_storage_driver.dart';
import 'package:animus/core/storage/interfaces/storage_service.dart';
import 'package:animus/ui/intake/widgets/pages/first_instance_analysis_screen/first_instance_analysis_screen_presenter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../fakers/intake/analysis_dto_faker.dart';
import '../../../../../fakers/intake/first_instance_analysis_report_dto_faker.dart';
import '../../../../../fakers/intake/petition_summary_dto_faker.dart';
import '../../../../../fakers/storage/upload_url_dto_faker.dart';

class _MockIntakeService extends Mock implements IntakeService {}

class _MockStorageService extends Mock implements StorageService {}

class _MockCacheDriver extends Mock implements CacheDriver {}

class _MockPdfDriver extends Mock implements PdfDriver {}

class _MockFileStorageDriver extends Mock implements FileStorageDriver {}

class _MockDocumentPickerDriver extends Mock implements DocumentPickerDriver {}

void main() {
  late _MockIntakeService intakeService;
  late _MockStorageService storageService;
  late _MockCacheDriver cacheDriver;
  late _MockPdfDriver pdfDriver;
  late _MockFileStorageDriver fileStorageDriver;
  late _MockDocumentPickerDriver documentPickerDriver;
  late Directory tempDirectory;

  setUpAll(() {
    registerFallbackValue(AnalysisStatusDto.waitingPetition);
    registerFallbackValue(
      AnalysisDocumentDto(
        analysisId: 'analysis-fallback',
        uploadedAt: '2026-01-01T00:00:00Z',
        filePath: 'uploads/fallback.pdf',
        name: 'fallback.pdf',
      ),
    );
  });

  setUp(() async {
    intakeService = _MockIntakeService();
    storageService = _MockStorageService();
    cacheDriver = _MockCacheDriver();
    pdfDriver = _MockPdfDriver();
    fileStorageDriver = _MockFileStorageDriver();
    documentPickerDriver = _MockDocumentPickerDriver();
    when(() => cacheDriver.get(any())).thenReturn(null);
    when(() => cacheDriver.set(any(), any())).thenReturn(null);
    when(
      () => intakeService.updateAnalysisStatus(
        analysisId: any(named: 'analysisId'),
        status: any(named: 'status'),
      ),
    ).thenAnswer(
      (_) async => RestResponse<AnalysisStatusDto>(
        statusCode: 200,
        body: AnalysisStatusDto.waitingPetition,
      ),
    );
    when(
      () => intakeService.getCaseSummary(analysisId: any(named: 'analysisId')),
    ).thenAnswer(
      (_) async => RestResponse<CaseSummaryDto>(
        statusCode: 200,
        body: CaseSummaryDtoFaker.fake(),
      ),
    );
    tempDirectory = await Directory.systemTemp.createTemp(
      'analysis_screen_presenter_test_',
    );
  });

  tearDown(() async {
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  FirstInstanceAnalysisScreenPresenter createPresenter() {
    return FirstInstanceAnalysisScreenPresenter(
      intakeService: intakeService,
      storageService: storageService,
      cacheDriver: cacheDriver,
      pdfDriver: pdfDriver,
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

  AnalysisDocumentDto createDocument({
    String analysisId = 'analysis-1',
    String filePath = 'uploads/documents/uploaded.pdf',
    String name = 'uploaded.pdf',
    String uploadedAt = '2026-03-31T10:00:00Z',
  }) {
    return AnalysisDocumentDto(
      analysisId: analysisId,
      uploadedAt: uploadedAt,
      filePath: filePath,
      name: name,
    );
  }

  group('load', () {
    test(
      'should clear petition data when analysis is waiting petition',
      () async {
        final FirstInstanceAnalysisScreenPresenter presenter =
            createPresenter();
        addTearDown(presenter.dispose);

        presenter.analysisDocument.value = createDocument();
        presenter.summary.value = CaseSummaryDtoFaker.fake();
        presenter.status.value = AnalysisStatusDto.caseAnalyzed;

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
        expect(presenter.analysisDocument.value, isNull);
        expect(presenter.summary.value, isNull);
        expect(presenter.selectedFile.value, isNull);
        verifyNever(
          () => intakeService.getAnalysisDocument(
            analysisId: any(named: 'analysisId'),
          ),
        );
      },
    );

    test('should keep waiting shell when getAnalysis fails', () async {
      final FirstInstanceAnalysisScreenPresenter presenter = createPresenter();
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
      expect(presenter.analysisDocument.value, isNull);
      expect(presenter.summary.value, isNull);
      expect(presenter.analysisName.value, 'Nova Análise');
    });

    test('should reset failed analysis to waiting petition on load', () async {
      final FirstInstanceAnalysisScreenPresenter presenter = createPresenter();
      addTearDown(presenter.dispose);

      presenter.analysisDocument.value = createDocument();
      presenter.summary.value = CaseSummaryDtoFaker.fake();
      presenter.status.value = AnalysisStatusDto.caseAnalyzed;

      when(
        () => intakeService.getAnalysis(analysisId: 'analysis-1'),
      ).thenAnswer(
        (_) async => RestResponse<AnalysisDto>(
          statusCode: 200,
          body: AnalysisDtoFaker.fake(
            status: AnalysisStatusDto.failed,
            name: 'Analise com falha',
          ),
        ),
      );

      await presenter.load();

      expect(presenter.status.value, AnalysisStatusDto.waitingPetition);
      expect(presenter.analysisName.value, 'Analise com falha');
      expect(presenter.analysisDocument.value, isNull);
      expect(presenter.summary.value, isNull);
      expect(presenter.selectedFile.value, isNull);
      expect(
        presenter.generalError.value,
        FirstInstanceAnalysisScreenPresenter.failedMessage,
      );
      verify(
        () => intakeService.updateAnalysisStatus(
          analysisId: 'analysis-1',
          status: AnalysisStatusDto.waitingPetition,
        ),
      ).called(1);
    });

    test(
      'should load petition and selected file when status is petitionUploaded',
      () async {
        final FirstInstanceAnalysisScreenPresenter presenter =
            createPresenter();
        addTearDown(presenter.dispose);
        final File petitionFile = await createFile('uploaded.pdf', 1024);
        final document = createDocument();

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
          () => intakeService.getAnalysisDocument(analysisId: 'analysis-1'),
        ).thenAnswer(
          (_) async => RestResponse(statusCode: 200, body: document),
        );
        when(
          () => fileStorageDriver.getFile(document.filePath),
        ).thenAnswer((_) async => petitionFile);

        await presenter.load();

        expect(presenter.analysisName.value, 'Analise pronta para resumo');
        expect(presenter.status.value, AnalysisStatusDto.petitionUploaded);
        expect(presenter.analysisDocument.value?.filePath, document.filePath);
        expect(presenter.selectedFile.value?.path, petitionFile.path);
        expect(presenter.summary.value, isNull);
        verify(
          () => intakeService.getAnalysisDocument(analysisId: 'analysis-1'),
        ).called(1);
      },
    );

    test(
      'should resume polling and load summary when status is analyzingPetition',
      () async {
        final FirstInstanceAnalysisScreenPresenter presenter =
            createPresenter();
        addTearDown(presenter.dispose);
        final File petitionFile = await createFile('uploaded.pdf', 1024);
        final document = createDocument();
        final CaseSummaryDto petitionSummary = CaseSummaryDtoFaker.fake();

        when(
          () => intakeService.getAnalysisDocument(analysisId: 'analysis-1'),
        ).thenAnswer(
          (_) async => RestResponse(statusCode: 200, body: document),
        );
        when(
          () => fileStorageDriver.getFile(document.filePath),
        ).thenAnswer((_) async => petitionFile);
        when(
          () => intakeService.getCaseSummary(analysisId: 'analysis-1'),
        ).thenAnswer(
          (_) async => RestResponse(statusCode: 200, body: petitionSummary),
        );

        var pollCount = 0;
        when(
          () => intakeService.getAnalysis(analysisId: 'analysis-1'),
        ).thenAnswer((_) async {
          pollCount++;

          if (pollCount == 1) {
            return RestResponse<AnalysisDto>(
              statusCode: 200,
              body: AnalysisDtoFaker.fake(
                status: AnalysisStatusDto.analyzingPetition,
                name: 'Analise processando resumo',
              ),
            );
          }

          return RestResponse<AnalysisDto>(
            statusCode: 200,
            body: AnalysisDtoFaker.fake(status: AnalysisStatusDto.caseAnalyzed),
          );
        });

        await presenter.load();

        expect(presenter.analysisName.value, 'Analise processando resumo');
        expect(presenter.status.value, AnalysisStatusDto.caseAnalyzed);
        expect(presenter.analysisDocument.value?.filePath, document.filePath);
        expect(presenter.selectedFile.value?.path, petitionFile.path);
        expect(
          presenter.summary.value?.caseSummary,
          petitionSummary.caseSummary,
        );
        verify(
          () => intakeService.getAnalysisDocument(analysisId: 'analysis-1'),
        ).called(1);
        verify(
          () => intakeService.getCaseSummary(analysisId: 'analysis-1'),
        ).called(1);
      },
    );

    test(
      'should load petition and summary when status is caseAnalyzed',
      () async {
        final FirstInstanceAnalysisScreenPresenter presenter =
            createPresenter();
        addTearDown(presenter.dispose);
        final File petitionFile = await createFile('uploaded.pdf', 1024);
        final document = createDocument();
        final CaseSummaryDto petitionSummary = CaseSummaryDtoFaker.fake();

        when(
          () => intakeService.getAnalysis(analysisId: 'analysis-1'),
        ).thenAnswer(
          (_) async => RestResponse<AnalysisDto>(
            statusCode: 200,
            body: AnalysisDtoFaker.fake(status: AnalysisStatusDto.caseAnalyzed),
          ),
        );
        when(
          () => intakeService.getAnalysisDocument(analysisId: 'analysis-1'),
        ).thenAnswer(
          (_) async => RestResponse(statusCode: 200, body: document),
        );
        when(
          () => fileStorageDriver.getFile(document.filePath),
        ).thenAnswer((_) async => petitionFile);
        when(
          () => intakeService.getCaseSummary(analysisId: 'analysis-1'),
        ).thenAnswer(
          (_) async => RestResponse(statusCode: 200, body: petitionSummary),
        );

        await presenter.load();

        expect(presenter.analysisName.value, 'Analise de precedente');
        expect(presenter.status.value, AnalysisStatusDto.caseAnalyzed);
        expect(presenter.analysisDocument.value?.filePath, document.filePath);
        expect(presenter.selectedFile.value?.path, petitionFile.path);
        expect(
          presenter.summary.value?.caseSummary,
          petitionSummary.caseSummary,
        );
        verify(
          () => intakeService.getCaseSummary(analysisId: 'analysis-1'),
        ).called(1);
      },
    );

    test('should load summary even when petition id is absent', () async {
      final FirstInstanceAnalysisScreenPresenter presenter = createPresenter();
      addTearDown(presenter.dispose);
      final File petitionFile = await createFile('uploaded.pdf', 1024);
      final document = createDocument();
      final CaseSummaryDto petitionSummary = CaseSummaryDtoFaker.fake();

      when(
        () => intakeService.getAnalysis(analysisId: 'analysis-1'),
      ).thenAnswer(
        (_) async => RestResponse<AnalysisDto>(
          statusCode: 200,
          body: AnalysisDtoFaker.fake(status: AnalysisStatusDto.caseAnalyzed),
        ),
      );
      when(
        () => intakeService.getAnalysisDocument(analysisId: 'analysis-1'),
      ).thenAnswer((_) async => RestResponse(statusCode: 200, body: document));
      when(
        () => fileStorageDriver.getFile(document.filePath),
      ).thenAnswer((_) async => petitionFile);
      when(
        () => intakeService.getCaseSummary(analysisId: 'analysis-1'),
      ).thenAnswer(
        (_) async => RestResponse(statusCode: 200, body: petitionSummary),
      );

      await presenter.load();

      expect(presenter.status.value, AnalysisStatusDto.caseAnalyzed);
      expect(presenter.analysisDocument.value?.filePath, document.filePath);
      expect(presenter.summary.value?.caseSummary, petitionSummary.caseSummary);
      verify(
        () => intakeService.getCaseSummary(analysisId: 'analysis-1'),
      ).called(1);
    });

    test(
      'should keep analyzed status and expose error when summary load fails',
      () async {
        final FirstInstanceAnalysisScreenPresenter presenter =
            createPresenter();
        addTearDown(presenter.dispose);
        final File petitionFile = await createFile('uploaded.pdf', 1024);
        final document = createDocument();

        when(
          () => intakeService.getAnalysis(analysisId: 'analysis-1'),
        ).thenAnswer(
          (_) async => RestResponse<AnalysisDto>(
            statusCode: 200,
            body: AnalysisDtoFaker.fake(status: AnalysisStatusDto.caseAnalyzed),
          ),
        );
        when(
          () => intakeService.getAnalysisDocument(analysisId: 'analysis-1'),
        ).thenAnswer(
          (_) async => RestResponse(statusCode: 200, body: document),
        );
        when(
          () => fileStorageDriver.getFile(document.filePath),
        ).thenAnswer((_) async => petitionFile);
        when(
          () => intakeService.getCaseSummary(analysisId: 'analysis-1'),
        ).thenAnswer(
          (_) async => RestResponse<CaseSummaryDto>(
            statusCode: 500,
            errorMessage: 'Falha ao carregar resumo.',
          ),
        );

        await presenter.load();

        expect(presenter.status.value, AnalysisStatusDto.caseAnalyzed);
        expect(presenter.summary.value, isNull);
        expect(presenter.generalError.value, 'Falha ao carregar resumo.');
      },
    );
  });

  group('pickDocument', () {
    test('should show inline error when extension is invalid', () async {
      final FirstInstanceAnalysisScreenPresenter presenter = createPresenter();
      addTearDown(presenter.dispose);
      final File file = await createFile('petition.txt', 1024);

      when(
        () => documentPickerDriver.pickDocument(
          allowedExtensions:
              FirstInstanceAnalysisScreenPresenter.allowedExtensions,
        ),
      ).thenAnswer((_) async => file);

      await presenter.pickDocument();

      expect(presenter.generalError.value, 'Selecione um arquivo PDF ou DOCX.');
      expect(presenter.selectedFile.value, isNull);
      verifyNever(
        () => storageService.generateAnalysisDocumentUploadUrl(
          analysisId: any(named: 'analysisId'),
          documentType: any(named: 'documentType'),
        ),
      );
    });

    test('should show inline error when file is larger than limit', () async {
      final FirstInstanceAnalysisScreenPresenter presenter = createPresenter();
      addTearDown(presenter.dispose);
      final File file = await createFile(
        'petition.pdf',
        FirstInstanceAnalysisScreenPresenter.maxFileSizeInBytes + 1,
      );

      when(
        () => documentPickerDriver.pickDocument(
          allowedExtensions:
              FirstInstanceAnalysisScreenPresenter.allowedExtensions,
        ),
      ).thenAnswer((_) async => file);

      await presenter.pickDocument();

      expect(
        presenter.generalError.value,
        'O arquivo deve ter no máximo 50MB.',
      );
      verifyNever(
        () => storageService.generateAnalysisDocumentUploadUrl(
          analysisId: any(named: 'analysisId'),
          documentType: any(named: 'documentType'),
        ),
      );
    });

    test('should upload file and create petition on happy path', () async {
      final FirstInstanceAnalysisScreenPresenter presenter = createPresenter();
      addTearDown(presenter.dispose);
      final File file = await createFile('petition.pdf', 4096);
      final uploadUrl = UploadUrlDtoFaker.fake();
      final createdDocument = createDocument(
        filePath: uploadUrl.filePath,
        name: 'petition.pdf',
      );

      when(
        () => documentPickerDriver.pickDocument(
          allowedExtensions:
              FirstInstanceAnalysisScreenPresenter.allowedExtensions,
        ),
      ).thenAnswer((_) async => file);
      when(
        () => storageService.generateAnalysisDocumentUploadUrl(
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
        () => intakeService.createAnalysisDocument(
          analysisId: any(named: 'analysisId'),
          document: any(named: 'document'),
        ),
      ).thenAnswer(
        (_) async => RestResponse(statusCode: 201, body: createdDocument),
      );

      await presenter.pickDocument();

      expect(presenter.status.value, AnalysisStatusDto.petitionUploaded);
      expect(
        presenter.analysisDocument.value?.filePath,
        createdDocument.filePath,
      );
      expect(presenter.summary.value, isNull);
      expect(presenter.generalError.value, isNull);
      expect(presenter.uploadProgress.value, 1);
      expect(presenter.selectedFile.value, isNull);
      verify(
        () => storageService.generateAnalysisDocumentUploadUrl(
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
        () => intakeService.createAnalysisDocument(
          analysisId: any(named: 'analysisId'),
          document: any(named: 'document'),
        ),
      ).called(1);
    });

    test('should delete remote document metadata when upload fails', () async {
      final FirstInstanceAnalysisScreenPresenter presenter = createPresenter();
      addTearDown(presenter.dispose);
      final File file = await createFile('petition.pdf', 4096);
      final uploadUrl = UploadUrlDtoFaker.fake();

      when(
        () => documentPickerDriver.pickDocument(
          allowedExtensions:
              FirstInstanceAnalysisScreenPresenter.allowedExtensions,
        ),
      ).thenAnswer((_) async => file);
      when(
        () => storageService.generateAnalysisDocumentUploadUrl(
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
      ).thenThrow(Exception('upload failed'));
      when(
        () => intakeService.removeAnalysisDocument(
          analysisId: 'analysis-1',
          filePath: uploadUrl.filePath,
        ),
      ).thenAnswer(
        (_) async => RestResponse<AnalysisStatusDto>(
          statusCode: 200,
          body: AnalysisStatusDto.waitingDocumentUpload,
        ),
      );

      await presenter.pickDocument();

      expect(
        presenter.generalError.value,
        FirstInstanceAnalysisScreenPresenter.failedMessage,
      );
      expect(presenter.uploadProgress.value, isNull);
      verify(
        () => intakeService.removeAnalysisDocument(
          analysisId: 'analysis-1',
          filePath: uploadUrl.filePath,
        ),
      ).called(1);
      verifyNever(
        () => intakeService.createAnalysisDocument(
          analysisId: any(named: 'analysisId'),
          document: any(named: 'document'),
        ),
      );
    });

    test(
      'should reset to waiting petition when upload url request fails',
      () async {
        final FirstInstanceAnalysisScreenPresenter presenter =
            createPresenter();
        addTearDown(presenter.dispose);
        final File file = await createFile('petition.pdf', 2048);

        when(
          () => documentPickerDriver.pickDocument(
            allowedExtensions:
                FirstInstanceAnalysisScreenPresenter.allowedExtensions,
          ),
        ).thenAnswer((_) async => file);
        when(
          () => storageService.generateAnalysisDocumentUploadUrl(
            analysisId: 'analysis-1',
            documentType: 'pdf',
          ),
        ).thenAnswer(
          (_) async => RestResponse(
            statusCode: 500,
            errorMessage: 'Falha ao gerar URL.',
          ),
        );

        await presenter.pickDocument();

        expect(presenter.status.value, AnalysisStatusDto.waitingPetition);
        expect(presenter.generalError.value, 'Falha ao gerar URL.');
        expect(presenter.selectedFile.value, isNull);
        expect(presenter.uploadProgress.value, isNull);
        expect(presenter.analysisDocument.value, isNull);
        expect(presenter.summary.value, isNull);
        verify(
          () => intakeService.updateAnalysisStatus(
            analysisId: 'analysis-1',
            status: AnalysisStatusDto.waitingPetition,
          ),
        ).called(1);
        verifyNever(
          () => intakeService.createAnalysisDocument(
            analysisId: any(named: 'analysisId'),
            document: any(named: 'document'),
          ),
        );
      },
    );
  });

  group('analyze', () {
    test('should summarize petition successfully', () async {
      final FirstInstanceAnalysisScreenPresenter presenter = createPresenter();
      addTearDown(presenter.dispose);
      final document = createDocument();
      final CaseSummaryDto petitionSummary = CaseSummaryDtoFaker.fake();

      presenter.analysisDocument.value = document;
      presenter.status.value = AnalysisStatusDto.petitionUploaded;

      when(
        () => intakeService.triggerFirstInstanceCaseSummarization(
          analysisId: 'analysis-1',
        ),
      ).thenAnswer((_) async => RestResponse<void>(statusCode: 202));
      when(
        () => intakeService.getAnalysis(analysisId: 'analysis-1'),
      ).thenAnswer(
        (_) async => RestResponse<AnalysisDto>(
          statusCode: 200,
          body: AnalysisDtoFaker.fake(status: AnalysisStatusDto.caseAnalyzed),
        ),
      );
      when(
        () => intakeService.getCaseSummary(analysisId: 'analysis-1'),
      ).thenAnswer(
        (_) async => RestResponse<CaseSummaryDto>(
          statusCode: 200,
          body: petitionSummary,
        ),
      );

      await presenter.analyze();

      expect(presenter.status.value, AnalysisStatusDto.caseAnalyzed);
      expect(presenter.summary.value?.legalIssue, petitionSummary.legalIssue);
      expect(presenter.generalError.value, isNull);
    });

    test(
      'should reset to waiting petition when summarize petition returns remote error',
      () async {
        final FirstInstanceAnalysisScreenPresenter presenter =
            createPresenter();
        addTearDown(presenter.dispose);
        final document = createDocument();

        presenter.analysisDocument.value = document;
        presenter.status.value = AnalysisStatusDto.petitionUploaded;

        when(
          () => intakeService.triggerFirstInstanceCaseSummarization(
            analysisId: 'analysis-1',
          ),
        ).thenAnswer(
          (_) async => RestResponse<void>(
            statusCode: 500,
            errorMessage: 'Falha ao gerar resumo.',
          ),
        );

        await presenter.analyze();

        expect(presenter.status.value, AnalysisStatusDto.waitingPetition);
        expect(presenter.generalError.value, 'Falha ao gerar resumo.');
        expect(presenter.summary.value, isNull);
        expect(presenter.analysisDocument.value, isNull);
        verify(
          () => intakeService.updateAnalysisStatus(
            analysisId: 'analysis-1',
            status: AnalysisStatusDto.waitingPetition,
          ),
        ).called(1);
      },
    );

    test('should reset when analysis polling returns failed status', () async {
      final FirstInstanceAnalysisScreenPresenter presenter = createPresenter();
      addTearDown(presenter.dispose);
      final document = createDocument();

      presenter.analysisDocument.value = document;
      presenter.status.value = AnalysisStatusDto.petitionUploaded;

      when(
        () => intakeService.triggerFirstInstanceCaseSummarization(
          analysisId: 'analysis-1',
        ),
      ).thenAnswer((_) async => RestResponse<void>(statusCode: 202));
      when(
        () => intakeService.getAnalysis(analysisId: 'analysis-1'),
      ).thenAnswer(
        (_) async => RestResponse<AnalysisDto>(
          statusCode: 200,
          body: AnalysisDtoFaker.fake(status: AnalysisStatusDto.failed),
        ),
      );

      await presenter.analyze();

      expect(presenter.status.value, AnalysisStatusDto.waitingPetition);
      expect(
        presenter.generalError.value,
        FirstInstanceAnalysisScreenPresenter.failedMessage,
      );
      expect(presenter.summary.value, isNull);
      expect(presenter.analysisDocument.value, isNull);
      verify(
        () => intakeService.updateAnalysisStatus(
          analysisId: 'analysis-1',
          status: AnalysisStatusDto.waitingPetition,
        ),
      ).called(1);
    });
  });

  group('analysis management', () {
    test('should rename analysis successfully', () async {
      final FirstInstanceAnalysisScreenPresenter presenter = createPresenter();
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
        final FirstInstanceAnalysisScreenPresenter presenter =
            createPresenter();
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
      final FirstInstanceAnalysisScreenPresenter presenter = createPresenter();
      addTearDown(presenter.dispose);
      presenter.generalError.value = 'erro antigo';

      when(
        () => intakeService.archiveAnalysis(analysisId: 'analysis-1'),
      ).thenAnswer(
        (_) async => RestResponse<List<AnalysisDto>>(
          statusCode: 200,
          body: <AnalysisDto>[
            AnalysisDtoFaker.fake(id: 'analysis-1', isArchived: true),
          ],
        ),
      );

      final bool archived = await presenter.archiveAnalysis();

      expect(archived, isTrue);
      expect(presenter.generalError.value, isNull);
    });

    test('should expose remote error when archive analysis fails', () async {
      final FirstInstanceAnalysisScreenPresenter presenter = createPresenter();
      addTearDown(presenter.dispose);

      when(
        () => intakeService.archiveAnalysis(analysisId: 'analysis-1'),
      ).thenAnswer(
        (_) async => RestResponse<List<AnalysisDto>>(
          statusCode: 500,
          errorMessage: 'Falha ao arquivar analise.',
        ),
      );

      final bool archived = await presenter.archiveAnalysis();

      expect(archived, isFalse);
      expect(presenter.generalError.value, 'Falha ao arquivar analise.');
    });

    test('should unarchive analysis successfully', () async {
      final FirstInstanceAnalysisScreenPresenter presenter = createPresenter();
      addTearDown(presenter.dispose);

      when(
        () => intakeService.unarchiveAnalysis(analysisId: 'analysis-1'),
      ).thenAnswer(
        (_) async => RestResponse<AnalysisDto>(
          statusCode: 200,
          body: AnalysisDtoFaker.fake(id: 'analysis-1', isArchived: false),
        ),
      );

      final bool unarchived = await presenter.unarchiveAnalysis();

      expect(unarchived, isTrue);
      expect(presenter.isArchived.value, isFalse);
      expect(presenter.generalError.value, isNull);
    });

    test(
      'should clear previous state and reuse pick document flow on replace',
      () async {
        final FirstInstanceAnalysisScreenPresenter presenter =
            createPresenter();
        addTearDown(presenter.dispose);
        final File oldFile = await createFile('old.pdf', 1024);
        final File newFile = await createFile('new.docx', 4096);
        final uploadUrl = UploadUrlDtoFaker.fake(
          filePath: 'uploads/petitions/new.docx',
        );
        final newDocument = createDocument(
          filePath: uploadUrl.filePath,
          name: 'new.docx',
        );
        final Completer<File?> pickCompleter = Completer<File?>();

        presenter.analysisDocument.value = createDocument(name: 'old.pdf');
        presenter.summary.value = CaseSummaryDtoFaker.fake();
        presenter.selectedFile.value = oldFile;
        presenter.generalError.value = 'erro antigo';
        presenter.status.value = AnalysisStatusDto.caseAnalyzed;

        when(
          () => documentPickerDriver.pickDocument(
            allowedExtensions:
                FirstInstanceAnalysisScreenPresenter.allowedExtensions,
          ),
        ).thenAnswer((_) => pickCompleter.future);
        when(
          () => storageService.generateAnalysisDocumentUploadUrl(
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
          () => intakeService.createAnalysisDocument(
            analysisId: any(named: 'analysisId'),
            document: any(named: 'document'),
          ),
        ).thenAnswer(
          (_) async => RestResponse(statusCode: 201, body: newDocument),
        );

        final Future<void> replaceFuture = presenter.replaceDocument();

        expect(presenter.status.value, AnalysisStatusDto.waitingPetition);
        expect(presenter.analysisDocument.value, isNull);
        expect(presenter.summary.value, isNull);
        expect(presenter.selectedFile.value, isNull);
        expect(presenter.generalError.value, isNull);

        pickCompleter.complete(newFile);
        await replaceFuture;

        expect(presenter.status.value, AnalysisStatusDto.petitionUploaded);
        expect(
          presenter.analysisDocument.value?.filePath,
          newDocument.filePath,
        );
        expect(presenter.summary.value, isNull);
        expect(presenter.selectedFile.value, isNull);
        expect(presenter.uploadProgress.value, 1);
        verify(
          () => documentPickerDriver.pickDocument(
            allowedExtensions:
                FirstInstanceAnalysisScreenPresenter.allowedExtensions,
          ),
        ).called(1);
        verify(
          () => storageService.generateAnalysisDocumentUploadUrl(
            analysisId: 'analysis-1',
            documentType: 'docx',
          ),
        ).called(1);
        verify(
          () => intakeService.createAnalysisDocument(
            analysisId: any(named: 'analysisId'),
            document: any(named: 'document'),
          ),
        ).called(1);
      },
    );
  });

  group('exportAnalysisReport', () {
    test(
      'should fetch report, generate pdf, share file and clear transient states on success',
      () async {
        final FirstInstanceAnalysisScreenPresenter presenter =
            createPresenter();
        addTearDown(presenter.dispose);
        final FirstInstanceAnalysisReportDto report =
            FirstInstanceAnalysisReportDtoFaker.fake(
              analysis: AnalysisDtoFaker.fake(
                id: 'analysis-1',
                name: 'Analise final',
                status: AnalysisStatusDto.precedentChosen,
              ),
            );
        final Uint8List bytes = Uint8List.fromList(<int>[1, 2, 3]);

        presenter.status.value = AnalysisStatusDto.precedentChosen;
        presenter.generalError.value = 'erro antigo';

        when(
          () => intakeService.getFirstInstanceAnalysisReport(
            analysisId: 'analysis-1',
          ),
        ).thenAnswer(
          (_) async => RestResponse<FirstInstanceAnalysisReportDto>(
            statusCode: 200,
            body: report,
          ),
        );
        when(
          () => pdfDriver.generateFirstInstanceAnalysisReport(report: report),
        ).thenAnswer((_) async => bytes);
        when(
          () => pdfDriver.sharePdf(
            bytes: bytes,
            filename: 'Analise final — Relatório.pdf',
          ),
        ).thenAnswer((_) async {});

        final bool exported = await presenter.exportAnalysisReport();

        expect(exported, isTrue);
        expect(presenter.generalError.value, isNull);
        expect(presenter.isExportingReport.value, isFalse);
        expect(presenter.isManagingAnalysis.value, isFalse);
        verifyInOrder(<dynamic Function()>[
          () => intakeService.getFirstInstanceAnalysisReport(
            analysisId: 'analysis-1',
          ),
          () => pdfDriver.generateFirstInstanceAnalysisReport(report: report),
          () => pdfDriver.sharePdf(
            bytes: bytes,
            filename: 'Analise final — Relatório.pdf',
          ),
        ]);
      },
    );

    test(
      'should expose friendly error and allow retry when remote request fails',
      () async {
        final FirstInstanceAnalysisScreenPresenter presenter =
            createPresenter();
        addTearDown(presenter.dispose);
        final FirstInstanceAnalysisReportDto report =
            FirstInstanceAnalysisReportDtoFaker.fake(
              analysis: AnalysisDtoFaker.fake(
                id: 'analysis-1',
                name: 'Analise para retry',
                status: AnalysisStatusDto.precedentChosen,
              ),
            );
        final Uint8List bytes = Uint8List.fromList(<int>[7, 8, 9]);

        presenter.status.value = AnalysisStatusDto.precedentChosen;

        when(
          () => intakeService.getFirstInstanceAnalysisReport(
            analysisId: 'analysis-1',
          ),
        ).thenAnswer(
          (_) async => RestResponse<FirstInstanceAnalysisReportDto>(
            statusCode: 500,
            errorMessage: 'Falha remota.',
          ),
        );

        final bool firstAttempt = await presenter.exportAnalysisReport();

        expect(firstAttempt, isFalse);
        expect(
          presenter.generalError.value,
          FirstInstanceAnalysisScreenPresenter.exportFailedMessage,
        );
        expect(presenter.isExportingReport.value, isFalse);

        when(
          () => intakeService.getFirstInstanceAnalysisReport(
            analysisId: 'analysis-1',
          ),
        ).thenAnswer(
          (_) async => RestResponse<FirstInstanceAnalysisReportDto>(
            statusCode: 200,
            body: report,
          ),
        );
        when(
          () => pdfDriver.generateFirstInstanceAnalysisReport(report: report),
        ).thenAnswer((_) async => bytes);
        when(
          () => pdfDriver.sharePdf(
            bytes: bytes,
            filename: 'Analise para retry — Relatório.pdf',
          ),
        ).thenAnswer((_) async {});

        final bool secondAttempt = await presenter.exportAnalysisReport();

        expect(secondAttempt, isTrue);
        expect(presenter.generalError.value, isNull);
        verify(
          () => intakeService.getFirstInstanceAnalysisReport(
            analysisId: 'analysis-1',
          ),
        ).called(2);
      },
    );

    test(
      'should expose friendly error and clear loading when pdf generation or share fails',
      () async {
        final FirstInstanceAnalysisScreenPresenter presenter =
            createPresenter();
        addTearDown(presenter.dispose);
        final FirstInstanceAnalysisReportDto report =
            FirstInstanceAnalysisReportDtoFaker.fake(
              analysis: AnalysisDtoFaker.fake(
                id: 'analysis-1',
                name: 'Analise com falha no share',
                status: AnalysisStatusDto.precedentChosen,
              ),
            );
        final Uint8List bytes = Uint8List.fromList(<int>[4, 5, 6]);

        presenter.status.value = AnalysisStatusDto.precedentChosen;

        when(
          () => intakeService.getFirstInstanceAnalysisReport(
            analysisId: 'analysis-1',
          ),
        ).thenAnswer(
          (_) async => RestResponse<FirstInstanceAnalysisReportDto>(
            statusCode: 200,
            body: report,
          ),
        );
        when(
          () => pdfDriver.generateFirstInstanceAnalysisReport(report: report),
        ).thenAnswer((_) async => bytes);
        when(
          () => pdfDriver.sharePdf(
            bytes: bytes,
            filename: 'Analise com falha no share — Relatório.pdf',
          ),
        ).thenThrow(Exception('share failed'));

        final bool exported = await presenter.exportAnalysisReport();

        expect(exported, isFalse);
        expect(
          presenter.generalError.value,
          FirstInstanceAnalysisScreenPresenter.exportFailedMessage,
        );
        expect(presenter.isExportingReport.value, isFalse);
        expect(presenter.isManagingAnalysis.value, isFalse);
      },
    );

    test(
      'should use deterministic fallback filename when analysis name is empty',
      () async {
        final FirstInstanceAnalysisScreenPresenter presenter =
            createPresenter();
        addTearDown(presenter.dispose);
        final FirstInstanceAnalysisReportDto report =
            FirstInstanceAnalysisReportDtoFaker.fake(
              analysis: AnalysisDtoFaker.fake(
                id: 'analysis-1',
                name: '   ',
                status: AnalysisStatusDto.precedentChosen,
              ),
            );
        final Uint8List bytes = Uint8List.fromList(<int>[9, 9, 9]);

        presenter.status.value = AnalysisStatusDto.precedentChosen;

        when(
          () => intakeService.getFirstInstanceAnalysisReport(
            analysisId: 'analysis-1',
          ),
        ).thenAnswer(
          (_) async => RestResponse<FirstInstanceAnalysisReportDto>(
            statusCode: 200,
            body: report,
          ),
        );
        when(
          () => pdfDriver.generateFirstInstanceAnalysisReport(report: report),
        ).thenAnswer((_) async => bytes);
        when(
          () => pdfDriver.sharePdf(
            bytes: bytes,
            filename: 'Análise-analysis-1 — Relatório.pdf',
          ),
        ).thenAnswer((_) async {});

        final bool exported = await presenter.exportAnalysisReport();

        expect(exported, isTrue);
        verify(
          () => pdfDriver.sharePdf(
            bytes: bytes,
            filename: 'Análise-analysis-1 — Relatório.pdf',
          ),
        ).called(1);
      },
    );

    test(
      'should block concurrent export attempts while export is in progress',
      () async {
        final FirstInstanceAnalysisScreenPresenter presenter =
            createPresenter();
        addTearDown(presenter.dispose);
        final FirstInstanceAnalysisReportDto report =
            FirstInstanceAnalysisReportDtoFaker.fake(
              analysis: AnalysisDtoFaker.fake(
                id: 'analysis-1',
                name: 'Analise concorrente',
                status: AnalysisStatusDto.precedentChosen,
              ),
            );
        final Completer<Uint8List> generateCompleter = Completer<Uint8List>();
        final Uint8List bytes = Uint8List.fromList(<int>[1]);

        presenter.status.value = AnalysisStatusDto.precedentChosen;

        when(
          () => intakeService.getFirstInstanceAnalysisReport(
            analysisId: 'analysis-1',
          ),
        ).thenAnswer(
          (_) async => RestResponse<FirstInstanceAnalysisReportDto>(
            statusCode: 200,
            body: report,
          ),
        );
        when(
          () => pdfDriver.generateFirstInstanceAnalysisReport(report: report),
        ).thenAnswer((_) => generateCompleter.future);
        when(
          () => pdfDriver.sharePdf(
            bytes: bytes,
            filename: 'Analise concorrente — Relatório.pdf',
          ),
        ).thenAnswer((_) async {});

        final Future<bool> firstAttempt = presenter.exportAnalysisReport();
        await Future<void>.delayed(Duration.zero);

        expect(presenter.isExportingReport.value, isTrue);

        final bool secondAttempt = await presenter.exportAnalysisReport();

        expect(secondAttempt, isFalse);
        verify(
          () => intakeService.getFirstInstanceAnalysisReport(
            analysisId: 'analysis-1',
          ),
        ).called(1);

        generateCompleter.complete(bytes);
        expect(await firstAttempt, isTrue);
      },
    );

    test(
      'should block rename and archive while export is in progress',
      () async {
        final FirstInstanceAnalysisScreenPresenter presenter =
            createPresenter();
        addTearDown(presenter.dispose);
        final FirstInstanceAnalysisReportDto report =
            FirstInstanceAnalysisReportDtoFaker.fake(
              analysis: AnalysisDtoFaker.fake(
                id: 'analysis-1',
                name: 'Analise bloqueada',
                status: AnalysisStatusDto.precedentChosen,
              ),
            );
        final Completer<Uint8List> generateCompleter = Completer<Uint8List>();
        final Uint8List bytes = Uint8List.fromList(<int>[2]);

        presenter.status.value = AnalysisStatusDto.precedentChosen;

        when(
          () => intakeService.getFirstInstanceAnalysisReport(
            analysisId: 'analysis-1',
          ),
        ).thenAnswer(
          (_) async => RestResponse<FirstInstanceAnalysisReportDto>(
            statusCode: 200,
            body: report,
          ),
        );
        when(
          () => pdfDriver.generateFirstInstanceAnalysisReport(report: report),
        ).thenAnswer((_) => generateCompleter.future);
        when(
          () => pdfDriver.sharePdf(
            bytes: bytes,
            filename: 'Analise bloqueada — Relatório.pdf',
          ),
        ).thenAnswer((_) async {});

        final Future<bool> exportFuture = presenter.exportAnalysisReport();
        await Future<void>.delayed(Duration.zero);

        final bool renamed = await presenter.renameAnalysis('Novo nome');
        final bool archived = await presenter.archiveAnalysis();

        expect(renamed, isFalse);
        expect(archived, isFalse);
        verifyNever(
          () => intakeService.renameAnalysis(
            analysisId: any(named: 'analysisId'),
            name: any(named: 'name'),
          ),
        );
        verifyNever(
          () => intakeService.archiveAnalysis(
            analysisId: any(named: 'analysisId'),
          ),
        );

        generateCompleter.complete(bytes);
        expect(await exportFuture, isTrue);
      },
    );
  });
}
