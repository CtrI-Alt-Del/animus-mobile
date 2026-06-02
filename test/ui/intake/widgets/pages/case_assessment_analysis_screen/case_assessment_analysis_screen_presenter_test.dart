import 'dart:io';

import 'package:animus/core/intake/dtos/analysis_dto.dart';
import 'package:animus/core/intake/dtos/analysis_document_dto.dart';
import 'package:animus/core/intake/dtos/analysis_precedent_dto.dart';
import 'package:animus/core/intake/dtos/analysis_status_dto.dart';
import 'package:animus/core/intake/dtos/analysis_type_dto.dart';
import 'package:animus/core/intake/dtos/petition_draft_dto.dart';
import 'package:animus/core/intake/interfaces/intake_service.dart';
import 'package:animus/core/shared/interfaces/cache_driver.dart';
import 'package:animus/core/shared/interfaces/pdf_driver.dart';
import 'package:animus/core/shared/responses/rest_response.dart';
import 'package:animus/core/storage/interfaces/drivers/document_picker_driver.dart';
import 'package:animus/core/storage/interfaces/drivers/file_storage_driver.dart';
import 'package:animus/core/storage/interfaces/storage_service.dart';
import 'package:animus/ui/intake/widgets/pages/case_assessment_analysis_screen/case_assessment_analysis_screen_presenter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../fakers/intake/analysis_dto_faker.dart';
import '../../../../../fakers/intake/analysis_precedent_dto_faker.dart';
import '../../../../../fakers/intake/petition_summary_dto_faker.dart';
import '../../../../../fakers/storage/upload_url_dto_faker.dart';

class _MockIntakeService extends Mock implements IntakeService {}

class _MockStorageService extends Mock implements StorageService {}

class _MockFileStorageDriver extends Mock implements FileStorageDriver {}

class _MockDocumentPickerDriver extends Mock implements DocumentPickerDriver {}

class _MockCacheDriver extends Mock implements CacheDriver {}

class _MockPdfDriver extends Mock implements PdfDriver {}

class _MockFile extends Mock implements File {}

void main() {
  late _MockIntakeService intakeService;
  late _MockStorageService storageService;
  late _MockFileStorageDriver fileStorageDriver;
  late _MockDocumentPickerDriver documentPickerDriver;
  late _MockCacheDriver cacheDriver;
  late _MockPdfDriver pdfDriver;

  setUpAll(() {
    registerFallbackValue(
      const AnalysisDocumentDto(
        analysisId: 'analysis-fallback',
        uploadedAt: '2026-01-01T00:00:00Z',
        filePath: 'uploads/fallback.pdf',
        name: 'fallback.pdf',
      ),
    );
  });

  setUp(() {
    intakeService = _MockIntakeService();
    storageService = _MockStorageService();
    fileStorageDriver = _MockFileStorageDriver();
    documentPickerDriver = _MockDocumentPickerDriver();
    cacheDriver = _MockCacheDriver();
    pdfDriver = _MockPdfDriver();
  });

  CaseAssessmentAnalysisScreenPresenter createPresenter() {
    return CaseAssessmentAnalysisScreenPresenter(
      intakeService: intakeService,
      storageService: storageService,
      fileStorageDriver: fileStorageDriver,
      documentPickerDriver: documentPickerDriver,
      cacheDriver: cacheDriver,
      pdfDriver: pdfDriver,
      analysisId: 'analysis-1',
    );
  }

  group('CaseAssessmentAnalysisScreenPresenter', () {
    test('inicia com status waitingDocumentUpload', () {
      final presenter = createPresenter();
      addTearDown(presenter.dispose);

      expect(presenter.status.value, AnalysisStatusDto.waitingDocumentUpload);
      expect(presenter.fileActionLabel.value, 'Selecionar documento do caso');
      expect(presenter.primaryActionLabel.value, 'Analisar');
    });

    test(
      'primaryActionLabel transiciona conforme o status do fluxo do advogado',
      () {
        final presenter = createPresenter();
        addTearDown(presenter.dispose);

        presenter.status.value = AnalysisStatusDto.caseAnalyzed;
        presenter.caseSummary.value = CaseSummaryDtoFaker.fake();
        expect(presenter.primaryActionLabel.value, 'Buscar precedentes');

        presenter.status.value = AnalysisStatusDto.searchingPrecedents;
        expect(presenter.primaryActionLabel.value, 'Buscando precedentes');

        presenter.status.value = AnalysisStatusDto.done;
        presenter.petitionDraft.value = const PetitionDraftDto(
          analysisId: 'analysis-1',
          structuredFacts: 'Fatos estruturados.',
          legalGrounds: 'Fundamentos juridicos.',
          centralThesis: 'Tese central.',
          requests: <String>['Pedido 1'],
          precedentCitations: <String>['Precedente 1'],
        );
        expect(presenter.primaryActionLabel.value, 'Regerar minuta');
      },
    );

    test('canGeneratePetitionDraft exige precedentes prontos e escolhidos', () {
      final presenter = createPresenter();
      addTearDown(presenter.dispose);

      presenter.status.value = AnalysisStatusDto.searchingPrecedents;
      expect(presenter.canGeneratePetitionDraft.value, isFalse);

      presenter.precedentsReady.value = true;
      presenter.hasChosenPrecedents.value = true;
      expect(presenter.canGeneratePetitionDraft.value, isFalse);

      presenter.status.value = AnalysisStatusDto.precedentsSearched;
      expect(presenter.canGeneratePetitionDraft.value, isTrue);

      presenter.status.value = AnalysisStatusDto.generatingPetitionDraft;
      expect(
        presenter.canGeneratePetitionDraft.value,
        isFalse,
        reason: 'Não permite regenerar enquanto está gerando.',
      );
    });

    test('iniciar busca limpa precedentes anteriores e bloqueia minuta', () {
      final presenter = createPresenter();
      addTearDown(presenter.dispose);

      presenter.status.value = AnalysisStatusDto.caseAnalyzed;
      presenter.caseSummary.value = CaseSummaryDtoFaker.fake();
      presenter.precedentsReady.value = true;
      presenter.hasChosenPrecedents.value = true;

      presenter.confirmAndViewPrecedents();

      expect(presenter.status.value, AnalysisStatusDto.searchingPrecedents);
      expect(presenter.precedentsReady.value, isFalse);
      expect(presenter.hasChosenPrecedents.value, isFalse);
      expect(presenter.canGeneratePetitionDraft.value, isFalse);
      expect(presenter.canPickDocument.value, isFalse);
      expect(presenter.primaryActionLabel.value, 'Buscando precedentes');
    });

    test('libera gerar minuta quando precedentes ficam prontos', () {
      final presenter = createPresenter();
      addTearDown(presenter.dispose);

      presenter.status.value = AnalysisStatusDto.searchingPrecedents;
      presenter.syncChosenPrecedents(<AnalysisPrecedentDto>[
        AnalysisPrecedentDtoFaker.fake(isChosen: true),
      ]);

      presenter.markPrecedentsReady();

      expect(presenter.precedentsReady.value, isTrue);
      expect(presenter.status.value, AnalysisStatusDto.precedentsSearched);
      expect(presenter.canGeneratePetitionDraft.value, isTrue);
      expect(presenter.primaryActionLabel.value, 'Gerar minuta');
    });

    test('bloqueia regerar minuta quando não há precedente escolhido', () {
      final presenter = createPresenter();
      addTearDown(presenter.dispose);

      presenter.status.value = AnalysisStatusDto.done;
      presenter.precedentsReady.value = true;
      presenter.petitionDraft.value = const PetitionDraftDto(
        analysisId: 'analysis-1',
        structuredFacts: 'Fatos estruturados.',
        legalGrounds: 'Fundamentos juridicos.',
        centralThesis: 'Tese central.',
        requests: <String>['Pedido 1'],
        precedentCitations: <String>['Precedente 1'],
      );

      expect(presenter.canRegeneratePetitionDraft.value, isFalse);

      presenter.hasChosenPrecedents.value = true;

      expect(presenter.canRegeneratePetitionDraft.value, isTrue);
    });

    test(
      'mantém card de geração visível enquanto backend ainda está em precedents searched',
      () async {
        final presenter = createPresenter();
        addTearDown(presenter.dispose);

        presenter.status.value = AnalysisStatusDto.precedentsSearched;
        presenter.precedentsReady.value = true;
        presenter.hasChosenPrecedents.value = true;

        when(
          () => intakeService.triggerPetitionDraftGeneration(
            analysisId: 'analysis-1',
          ),
        ).thenAnswer((_) async => RestResponse<void>(statusCode: 202));

        int getAnalysisCalls = 0;
        when(
          () => intakeService.getAnalysis(analysisId: 'analysis-1'),
        ).thenAnswer((_) async {
          getAnalysisCalls++;
          return RestResponse<AnalysisDto>(
            statusCode: 200,
            body: AnalysisDtoFaker.fake(
              type: AnalysisTypeDto.caseAssessment,
              status: getAnalysisCalls == 1
                  ? AnalysisStatusDto.precedentsSearched
                  : AnalysisStatusDto.done,
            ),
          );
        });

        when(
          () => intakeService.getPetitionDraft(analysisId: 'analysis-1'),
        ).thenAnswer(
          (_) async => RestResponse<PetitionDraftDto>(
            statusCode: 200,
            body: const PetitionDraftDto(
              analysisId: 'analysis-1',
              structuredFacts: 'Fatos estruturados.',
              legalGrounds: 'Fundamentos juridicos.',
              centralThesis: 'Tese central.',
              requests: <String>['Pedido 1'],
              precedentCitations: <String>['Precedente 1'],
            ),
          ),
        );

        final Future<void> requestFuture = presenter.requestPetitionDraft();
        await Future<void>.delayed(const Duration(milliseconds: 20));

        expect(
          presenter.status.value,
          AnalysisStatusDto.generatingPetitionDraft,
        );
        expect(presenter.showPetitionDraftProcessingCard.value, isTrue);

        await Future<void>.delayed(
          CaseAssessmentAnalysisScreenPresenter.pollingInterval +
              const Duration(milliseconds: 50),
        );
        await requestFuture;

        expect(presenter.status.value, AnalysisStatusDto.done);
        expect(presenter.showPetitionDraftProcessingCard.value, isFalse);
      },
    );

    test('load não restaura gerar minuta enquanto busca precedentes', () async {
      final presenter = createPresenter();
      addTearDown(presenter.dispose);

      when(
        () => intakeService.getAnalysis(analysisId: 'analysis-1'),
      ).thenAnswer(
        (_) async => RestResponse<AnalysisDto>(
          statusCode: 200,
          body: AnalysisDtoFaker.fake(
            type: AnalysisTypeDto.caseAssessment,
            status: AnalysisStatusDto.searchingPrecedents,
          ),
        ),
      );
      when(
        () => intakeService.getAnalysisDocument(analysisId: 'analysis-1'),
      ).thenAnswer(
        (_) async => RestResponse<AnalysisDocumentDto>(
          statusCode: 404,
          errorMessage: 'Nao encontrado',
        ),
      );
      when(
        () => intakeService.getCaseSummary(analysisId: 'analysis-1'),
      ).thenAnswer(
        (_) async =>
            RestResponse(statusCode: 200, body: CaseSummaryDtoFaker.fake()),
      );

      await presenter.load();

      expect(presenter.status.value, AnalysisStatusDto.searchingPrecedents);
      expect(presenter.precedentsReady.value, isFalse);
      expect(presenter.canGeneratePetitionDraft.value, isFalse);
      expect(presenter.primaryActionLabel.value, 'Buscando precedentes');
      verifyNever(
        () => intakeService.getPetitionDraft(analysisId: 'analysis-1'),
      );
    });

    test('load retoma polling quando análise ainda está processando', () async {
      final presenter = createPresenter();
      addTearDown(presenter.dispose);
      int getAnalysisCalls = 0;

      when(
        () => intakeService.getAnalysis(analysisId: 'analysis-1'),
      ).thenAnswer((_) async {
        getAnalysisCalls++;
        return RestResponse<AnalysisDto>(
          statusCode: 200,
          body: AnalysisDtoFaker.fake(
            type: AnalysisTypeDto.caseAssessment,
            status: getAnalysisCalls == 1
                ? AnalysisStatusDto.analyzingCase
                : AnalysisStatusDto.caseAnalyzed,
          ),
        );
      });
      when(
        () => intakeService.getAnalysisDocument(analysisId: 'analysis-1'),
      ).thenAnswer(
        (_) async => RestResponse<AnalysisDocumentDto>(
          statusCode: 404,
          errorMessage: 'Nao encontrado',
        ),
      );
      when(
        () => intakeService.getCaseSummary(analysisId: 'analysis-1'),
      ).thenAnswer(
        (_) async =>
            RestResponse(statusCode: 200, body: CaseSummaryDtoFaker.fake()),
      );

      await presenter.load();
      await Future<void>.delayed(
        CaseAssessmentAnalysisScreenPresenter.pollingInterval +
            const Duration(milliseconds: 50),
      );

      expect(presenter.status.value, AnalysisStatusDto.caseAnalyzed);
      expect(presenter.showCaseProcessingBubble.value, isFalse);
      expect(presenter.caseSummary.value, isNotNull);
    });

    test('remove metadados remotos quando upload do documento falha', () async {
      final presenter = createPresenter();
      addTearDown(presenter.dispose);
      final file = _MockFile();
      final uploadUrl = UploadUrlDtoFaker.fake();

      when(
        () => documentPickerDriver.pickDocument(
          allowedExtensions:
              CaseAssessmentAnalysisScreenPresenter.allowedExtensions,
        ),
      ).thenAnswer((_) async => file);
      when(() => file.path).thenReturn('processo.pdf');
      when(() => file.length()).thenAnswer((_) async => 4096);
      when(() => file.uri).thenReturn(Uri.parse('file:///processo.pdf'));
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
        () => intakeService.deleteAnalysisDocument(
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

      expect(presenter.status.value, AnalysisStatusDto.failed);
      expect(presenter.uploadProgress.value, isNull);
      verify(
        () => intakeService.deleteAnalysisDocument(
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

    test('retry contextual em FAILED escolhe label conforme etapa', () {
      final presenter = createPresenter();
      addTearDown(presenter.dispose);

      presenter.status.value = AnalysisStatusDto.failed;
      expect(presenter.primaryActionLabel.value, 'Tentar analisar novamente');

      presenter.caseSummary.value = CaseSummaryDtoFaker.fake();
      expect(
        presenter.primaryActionLabel.value,
        'Tentar buscar precedentes novamente',
      );

      presenter.precedentsReady.value = true;
      expect(
        presenter.primaryActionLabel.value,
        'Tentar buscar precedentes novamente',
      );

      presenter.hasChosenPrecedents.value = true;
      expect(
        presenter.primaryActionLabel.value,
        'Tentar gerar minuta novamente',
      );
    });

    test('load reconstrói estado de DONE carregando minuta', () async {
      final presenter = createPresenter();
      addTearDown(presenter.dispose);

      const PetitionDraftDto draft = PetitionDraftDto(
        analysisId: 'analysis-1',
        structuredFacts: 'Conteúdo da minuta.',
        legalGrounds: 'Fundamentos juridicos.',
        centralThesis: 'Tese central.',
        requests: <String>['Pedido 1'],
        precedentCitations: <String>['Precedente 1'],
      );

      when(
        () => intakeService.getAnalysis(analysisId: 'analysis-1'),
      ).thenAnswer(
        (_) async => RestResponse<AnalysisDto>(
          statusCode: 200,
          body: AnalysisDtoFaker.fake(
            type: AnalysisTypeDto.caseAssessment,
            status: AnalysisStatusDto.done,
          ),
        ),
      );
      when(
        () => intakeService.getAnalysisDocument(analysisId: 'analysis-1'),
      ).thenAnswer(
        (_) async => RestResponse(statusCode: 404, errorMessage: 'sem doc'),
      );
      when(
        () => intakeService.getCaseSummary(analysisId: 'analysis-1'),
      ).thenAnswer(
        (_) async =>
            RestResponse(statusCode: 200, body: CaseSummaryDtoFaker.fake()),
      );
      when(
        () => intakeService.getPetitionDraft(analysisId: 'analysis-1'),
      ).thenAnswer((_) async => RestResponse(statusCode: 200, body: draft));

      await presenter.load();

      expect(presenter.status.value, AnalysisStatusDto.done);
      expect(presenter.precedentsReady.value, isTrue);
      expect(
        presenter.petitionDraft.value?.structuredFacts,
        draft.structuredFacts,
      );
      expect(presenter.canExportReport.value, isTrue);
    });

    test('canExportReport exige status DONE e minuta carregada', () {
      final presenter = createPresenter();
      addTearDown(presenter.dispose);

      presenter.status.value = AnalysisStatusDto.done;
      expect(
        presenter.canExportReport.value,
        isFalse,
        reason: 'Sem minuta não exporta.',
      );

      presenter.petitionDraft.value = const PetitionDraftDto(
        analysisId: 'analysis-1',
        structuredFacts: 'Conteúdo.',
        legalGrounds: 'Fundamentos juridicos.',
        centralThesis: 'Tese central.',
        requests: <String>['Pedido 1'],
        precedentCitations: <String>['Precedente 1'],
      );
      expect(presenter.canExportReport.value, isTrue);

      presenter.status.value = AnalysisStatusDto.caseAnalyzed;
      expect(
        presenter.canExportReport.value,
        isFalse,
        reason: 'Sem status DONE não exporta.',
      );
    });

    test(
      'regeneratePetitionDraft recarrega a minuta ao concluir a regeracao',
      () async {
        final presenter = createPresenter();
        addTearDown(presenter.dispose);
        const PetitionDraftDto previousDraft = PetitionDraftDto(
          analysisId: 'analysis-1',
          structuredFacts: 'Versao anterior.',
          legalGrounds: 'Fundamentos anteriores.',
          centralThesis: 'Tese anterior.',
          requests: <String>['Pedido anterior'],
          precedentCitations: <String>['Precedente anterior'],
        );
        const PetitionDraftDto regeneratedDraft = PetitionDraftDto(
          analysisId: 'analysis-1',
          structuredFacts: 'Versao nova.',
          legalGrounds: 'Fundamentos novos.',
          centralThesis: 'Tese nova.',
          requests: <String>['Pedido novo'],
          precedentCitations: <String>['Precedente novo'],
        );

        presenter.status.value = AnalysisStatusDto.done;
        presenter.hasChosenPrecedents.value = true;
        presenter.petitionDraft.value = previousDraft;

        when(
          () => intakeService.regeneratePetitionDraft(
            analysisId: 'analysis-1',
            comments: 'Ajustar a tese central.',
          ),
        ).thenAnswer((_) async => RestResponse<void>(statusCode: 202));
        when(
          () => intakeService.getAnalysis(analysisId: 'analysis-1'),
        ).thenAnswer(
          (_) async => RestResponse<AnalysisDto>(
            statusCode: 200,
            body: AnalysisDtoFaker.fake(
              id: 'analysis-1',
              type: AnalysisTypeDto.caseAssessment,
              status: AnalysisStatusDto.done,
            ),
          ),
        );
        when(
          () => intakeService.getPetitionDraft(analysisId: 'analysis-1'),
        ).thenAnswer(
          (_) async => RestResponse<PetitionDraftDto>(
            statusCode: 200,
            body: regeneratedDraft,
          ),
        );

        await presenter.regeneratePetitionDraft('Ajustar a tese central.');

        expect(presenter.status.value, AnalysisStatusDto.done);
        expect(presenter.generalError.value, isNull);
        expect(
          presenter.petitionDraft.value?.structuredFacts,
          regeneratedDraft.structuredFacts,
        );
        verifyInOrder(<dynamic Function()>[
          () => intakeService.regeneratePetitionDraft(
            analysisId: 'analysis-1',
            comments: 'Ajustar a tese central.',
          ),
          () => intakeService.getAnalysis(analysisId: 'analysis-1'),
          () => intakeService.getPetitionDraft(analysisId: 'analysis-1'),
        ]);
      },
    );

    test(
      'regeneratePetitionDraft preserva a minuta anterior quando a analise falha',
      () async {
        final presenter = createPresenter();
        addTearDown(presenter.dispose);
        const PetitionDraftDto previousDraft = PetitionDraftDto(
          analysisId: 'analysis-1',
          structuredFacts: 'Versao anterior.',
          legalGrounds: 'Fundamentos anteriores.',
          centralThesis: 'Tese anterior.',
          requests: <String>['Pedido anterior'],
          precedentCitations: <String>['Precedente anterior'],
        );

        presenter.status.value = AnalysisStatusDto.done;
        presenter.hasChosenPrecedents.value = true;
        presenter.petitionDraft.value = previousDraft;

        when(
          () => intakeService.regeneratePetitionDraft(
            analysisId: 'analysis-1',
            comments: 'Refazer minuta.',
          ),
        ).thenAnswer((_) async => RestResponse<void>(statusCode: 202));
        when(
          () => intakeService.getAnalysis(analysisId: 'analysis-1'),
        ).thenAnswer(
          (_) async => RestResponse<AnalysisDto>(
            statusCode: 200,
            body: AnalysisDtoFaker.fake(
              id: 'analysis-1',
              type: AnalysisTypeDto.caseAssessment,
              status: AnalysisStatusDto.failed,
            ),
          ),
        );

        await presenter.regeneratePetitionDraft('Refazer minuta.');

        expect(presenter.status.value, AnalysisStatusDto.failed);
        expect(presenter.generalError.value, isNotNull);
        expect(
          presenter.petitionDraft.value?.structuredFacts,
          previousDraft.structuredFacts,
        );
        verifyNever(
          () => intakeService.getPetitionDraft(analysisId: 'analysis-1'),
        );
      },
    );
  });
}
