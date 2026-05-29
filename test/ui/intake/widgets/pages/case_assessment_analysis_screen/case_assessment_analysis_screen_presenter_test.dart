import 'package:animus/core/intake/dtos/analysis_dto.dart';
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
import '../../../../../fakers/intake/petition_summary_dto_faker.dart';

class _MockIntakeService extends Mock implements IntakeService {}

class _MockStorageService extends Mock implements StorageService {}

class _MockFileStorageDriver extends Mock implements FileStorageDriver {}

class _MockDocumentPickerDriver extends Mock implements DocumentPickerDriver {}

class _MockCacheDriver extends Mock implements CacheDriver {}

class _MockPdfDriver extends Mock implements PdfDriver {}

void main() {
  late _MockIntakeService intakeService;
  late _MockStorageService storageService;
  late _MockFileStorageDriver fileStorageDriver;
  late _MockDocumentPickerDriver documentPickerDriver;
  late _MockCacheDriver cacheDriver;
  late _MockPdfDriver pdfDriver;

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
      expect(presenter.fileActionLabel.value, 'Selecionar petição');
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

        presenter.precedentsReady.value = true;
        presenter.status.value = AnalysisStatusDto.searchingPrecedents;
        expect(presenter.primaryActionLabel.value, 'Gerar minuta');

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

    test('canGeneratePetitionDraft exige precedentes prontos', () {
      final presenter = createPresenter();
      addTearDown(presenter.dispose);

      presenter.status.value = AnalysisStatusDto.searchingPrecedents;
      expect(presenter.canGeneratePetitionDraft.value, isFalse);

      presenter.precedentsReady.value = true;
      expect(presenter.canGeneratePetitionDraft.value, isTrue);

      presenter.status.value = AnalysisStatusDto.generatingPetitionDraft;
      expect(
        presenter.canGeneratePetitionDraft.value,
        isFalse,
        reason: 'Não permite regenerar enquanto está gerando.',
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
  });
}
