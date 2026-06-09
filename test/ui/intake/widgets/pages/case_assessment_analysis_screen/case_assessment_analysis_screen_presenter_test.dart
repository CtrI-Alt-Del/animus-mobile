import 'package:animus/core/intake/dtos/analysis_dto.dart';
import 'package:animus/core/intake/dtos/analysis_precedent_dto.dart';
import 'package:animus/core/intake/dtos/analysis_status_dto.dart';
import 'package:animus/core/intake/dtos/analysis_type_dto.dart';
import 'package:animus/core/intake/dtos/case_assessment_briefing_dto.dart';
import 'package:animus/core/intake/dtos/court_dto.dart';
import 'package:animus/core/intake/dtos/legal_area_dto.dart';
import 'package:animus/core/intake/dtos/petition_draft_dto.dart';
import 'package:animus/core/intake/interfaces/intake_service.dart';
import 'package:animus/core/shared/interfaces/cache_driver.dart';
import 'package:animus/core/shared/interfaces/pdf_driver.dart';
import 'package:animus/core/shared/responses/rest_response.dart';
import 'package:animus/ui/intake/widgets/pages/case_assessment_analysis_screen/case_assessment_analysis_screen_presenter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../fakers/intake/analysis_dto_faker.dart';
import '../../../../../fakers/intake/analysis_precedent_dto_faker.dart';
import '../../../../../fakers/intake/petition_summary_dto_faker.dart';

class _MockIntakeService extends Mock implements IntakeService {}

class _MockCacheDriver extends Mock implements CacheDriver {}

class _MockPdfDriver extends Mock implements PdfDriver {}

const CaseAssessmentBriefingDto _briefing = CaseAssessmentBriefingDto(
  analysisId: 'analysis-1',
  legalArea: LegalAreaDto.civil,
  courtJurisdiction: CourtDto.tjsp,
  mainClaims: 'Pedido principal',
  intendedThesis: 'Tese pretendida',
);

void main() {
  late _MockIntakeService intakeService;
  late _MockCacheDriver cacheDriver;
  late _MockPdfDriver pdfDriver;

  setUp(() {
    intakeService = _MockIntakeService();
    cacheDriver = _MockCacheDriver();
    pdfDriver = _MockPdfDriver();

    when(
      () => intakeService.getCaseAssessmentBriefing(analysisId: 'analysis-1'),
    ).thenAnswer(
      (_) async => RestResponse<CaseAssessmentBriefingDto>(
        statusCode: 200,
        body: _briefing,
      ),
    );
  });

  CaseAssessmentAnalysisScreenPresenter createPresenter() {
    return CaseAssessmentAnalysisScreenPresenter(
      intakeService: intakeService,
      cacheDriver: cacheDriver,
      pdfDriver: pdfDriver,
      analysisId: 'analysis-1',
    );
  }

  group('CaseAssessmentAnalysisScreenPresenter', () {
    test('inicia com status waitingBriefing', () {
      final presenter = createPresenter();
      addTearDown(presenter.dispose);

      expect(presenter.status.value, AnalysisStatusDto.waitingBriefing);
      expect(presenter.briefing.value, isNull);
      expect(presenter.primaryActionLabel.value, 'Analisar');
      expect(presenter.canAnalyzeCase.value, isFalse);
    });

    test('libera análise após briefing submetido', () {
      final presenter = createPresenter();
      addTearDown(presenter.dispose);

      presenter.markBriefingSubmitted(_briefing);

      expect(presenter.briefing.value, _briefing);
      expect(presenter.status.value, AnalysisStatusDto.briefingSubmitted);
      expect(presenter.canAnalyzeCase.value, isTrue);
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

    test(
      'reanalyzeCase preserva briefing e limpa resultados derivados',
      () async {
        final presenter = createPresenter();
        addTearDown(presenter.dispose);

        presenter.markBriefingSubmitted(_briefing);
        presenter.status.value = AnalysisStatusDto.caseAnalyzed;
        presenter.caseSummary.value = CaseSummaryDtoFaker.fake();
        presenter.petitionDraft.value = const PetitionDraftDto(
          analysisId: 'analysis-1',
          structuredFacts: 'Versao anterior.',
          legalGrounds: 'Fundamentos anteriores.',
          centralThesis: 'Tese anterior.',
          requests: <String>['Pedido anterior'],
          precedentCitations: <String>['Precedente anterior'],
        );
        presenter.precedentsReady.value = true;
        presenter.hasChosenPrecedents.value = true;

        when(
          () => intakeService.triggerCaseAssessmentCaseSummarization(
            analysisId: 'analysis-1',
          ),
        ).thenAnswer((_) async => RestResponse<void>(statusCode: 202));
        when(
          () => intakeService.getAnalysis(analysisId: 'analysis-1'),
        ).thenAnswer(
          (_) async => RestResponse<AnalysisDto>(
            statusCode: 200,
            body: AnalysisDtoFaker.fake(
              type: AnalysisTypeDto.caseAssessment,
              status: AnalysisStatusDto.caseAnalyzed,
            ),
          ),
        );
        when(
          () => intakeService.getCaseSummary(analysisId: 'analysis-1'),
        ).thenAnswer(
          (_) async =>
              RestResponse(statusCode: 200, body: CaseSummaryDtoFaker.fake()),
        );

        await presenter.reanalyzeCase();

        expect(presenter.briefing.value, _briefing);
        expect(presenter.status.value, AnalysisStatusDto.caseAnalyzed);
        expect(presenter.precedentsReady.value, isFalse);
        expect(presenter.hasChosenPrecedents.value, isFalse);
        expect(presenter.caseSummary.value, isNotNull);
      },
    );

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
