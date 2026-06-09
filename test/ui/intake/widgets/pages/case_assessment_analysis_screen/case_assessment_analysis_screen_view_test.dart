import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:animus/core/intake/dtos/analysis_precedent_dto.dart';
import 'package:animus/core/intake/dtos/analysis_document_dto.dart';
import 'package:animus/core/intake/dtos/analysis_status_dto.dart';
import 'package:animus/core/intake/dtos/case_assessment_briefing_dto.dart';
import 'package:animus/core/intake/dtos/case_summary_dto.dart';
import 'package:animus/core/intake/dtos/court_dto.dart';
import 'package:animus/core/intake/dtos/legal_area_dto.dart';
import 'package:animus/core/intake/dtos/petition_draft_dto.dart';
import 'package:animus/core/intake/dtos/precedent_kind_dto.dart';
import 'package:animus/theme.dart';
import 'package:animus/ui/intake/widgets/components/analysis_precedents_bubble/analysis_precedents_bubble_presenter.dart';
import 'package:animus/ui/intake/widgets/pages/case_assessment_analysis_screen/briefing_form_card/briefing_form_card_presenter.dart';
import 'package:animus/ui/intake/widgets/pages/case_assessment_analysis_screen/briefing_form_card/briefing_form_card_view.dart';
import 'package:animus/ui/intake/widgets/pages/case_assessment_analysis_screen/briefing_form_card/support_documents_section/support_documents_section_presenter.dart';
import 'package:animus/ui/intake/widgets/pages/case_assessment_analysis_screen/case_assessment_analysis_screen_presenter.dart';
import 'package:animus/ui/intake/widgets/pages/case_assessment_analysis_screen/case_assessment_analysis_screen_view.dart';

import '../../../../../fakers/intake/case_assessment_briefing_dto_faker.dart';
import '../../../../../fakers/intake/first_instance_analysis_report_dto_faker.dart';

class _MockCaseAssessmentAnalysisScreenPresenter extends Mock
    implements CaseAssessmentAnalysisScreenPresenter {}

class _MockAnalysisPrecedentsBubblePresenter extends Mock
    implements AnalysisPrecedentsBubblePresenter {}

class _MockBriefingFormCardPresenter extends Mock
    implements BriefingFormCardPresenter {}

class _MockSupportDocumentsSectionPresenter extends Mock
    implements SupportDocumentsSectionPresenter {}

void main() {
  setUpAll(() {
    registerFallbackValue(CaseAssessmentBriefingDtoFaker.fake());
    registerFallbackValue(AnalysisDocumentDtoFaker.fake());
    registerFallbackValue(AnalysisStatusDto.waitingBriefing);
  });

  testWidgets('should render initial briefing flow and action bar', (
    WidgetTester tester,
  ) async {
    final screenPresenter = _createScreenPresenter();
    final briefingPresenter = _createBriefingPresenter();
    final supportPresenter = _createSupportDocumentsPresenter();

    await tester.pumpWidget(
      _createWidget(
        screenPresenter: screenPresenter,
        briefingPresenter: briefingPresenter,
        supportPresenter: supportPresenter,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(BriefingFormCardView), findsOneWidget);
    expect(
      find.text(
        'Preencha o briefing do caso e, se desejar, anexe documentos de apoio para iniciar a análise.',
      ),
      findsOneWidget,
    );
    expect(find.text('Analisar'), findsOneWidget);
  });

  testWidgets(
    'should submit briefing and analyze from action bar when waiting briefing',
    (WidgetTester tester) async {
      final briefing = CaseAssessmentBriefingDtoFaker.fake();
      final screenPresenter = _createScreenPresenter();
      final briefingPresenter = _createBriefingPresenter(
        submitResult: briefing,
      );
      final supportPresenter = _createSupportDocumentsPresenter();

      await tester.pumpWidget(
        _createWidget(
          screenPresenter: screenPresenter,
          briefingPresenter: briefingPresenter,
          supportPresenter: supportPresenter,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Analisar'));
      await tester.pumpAndSettle();

      verify(() => screenPresenter.markBriefingSubmitted(briefing)).called(1);
      verify(() => screenPresenter.analyzeCase()).called(1);
    },
  );

  testWidgets('should analyze directly when briefing is already submitted', (
    WidgetTester tester,
  ) async {
    final screenPresenter = _createScreenPresenter(
      status: signal<AnalysisStatusDto>(AnalysisStatusDto.briefingSubmitted),
      canAnalyzeCase: signal<bool>(true),
    );
    final briefingPresenter = _createBriefingPresenter();
    final supportPresenter = _createSupportDocumentsPresenter();

    await tester.pumpWidget(
      _createWidget(
        screenPresenter: screenPresenter,
        briefingPresenter: briefingPresenter,
        supportPresenter: supportPresenter,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Analisar'));
    await tester.pumpAndSettle();

    verifyNever(() => screenPresenter.markBriefingSubmitted(any()));
    verify(() => screenPresenter.analyzeCase()).called(1);
  });
}

Widget _createWidget({
  required _MockCaseAssessmentAnalysisScreenPresenter screenPresenter,
  required _MockBriefingFormCardPresenter briefingPresenter,
  required _MockSupportDocumentsSectionPresenter supportPresenter,
}) {
  final precedentsPresenter = _createPrecedentsPresenter();

  return SizedBox(
    width: 430,
    height: 900,
    child: ProviderScope(
      overrides: [
        caseAssessmentAnalysisScreenPresenterProvider(
          'analysis-1',
        ).overrideWithValue(screenPresenter),
        briefingFormCardPresenterProvider(
          'analysis-1',
        ).overrideWithValue(briefingPresenter),
        supportDocumentsSectionPresenterProvider(
          'analysis-1',
        ).overrideWithValue(supportPresenter),
        analysisPrecedentsBubblePresenterProvider(
          'analysis-1',
        ).overrideWithValue(precedentsPresenter),
      ],
      child: MaterialApp(
        theme: AppTheme.dark,
        home: const CaseAssessmentAnalysisScreenView(analysisId: 'analysis-1'),
      ),
    ),
  );
}

_MockCaseAssessmentAnalysisScreenPresenter _createScreenPresenter({
  Signal<AnalysisStatusDto>? status,
  ReadonlySignal<bool>? canAnalyzeCase,
}) {
  final presenter = _MockCaseAssessmentAnalysisScreenPresenter();
  final resolvedStatus =
      status ?? signal<AnalysisStatusDto>(AnalysisStatusDto.waitingBriefing);

  when(() => presenter.status).thenReturn(resolvedStatus);
  when(
    () => presenter.briefing,
  ).thenReturn(signal<CaseAssessmentBriefingDto?>(null));
  when(() => presenter.caseSummary).thenReturn(signal<CaseSummaryDto?>(null));
  when(
    () => presenter.petitionDraft,
  ).thenReturn(signal<PetitionDraftDto?>(null));
  when(() => presenter.generalError).thenReturn(signal<String?>(null));
  when(
    () => presenter.analysisName,
  ).thenReturn(signal<String>('Análise teste'));
  when(() => presenter.isArchived).thenReturn(signal<bool>(false));
  when(() => presenter.isManagingAnalysis).thenReturn(signal<bool>(false));
  when(() => presenter.isExportingReport).thenReturn(signal<bool>(false));
  when(() => presenter.precedentsReady).thenReturn(signal<bool>(false));
  when(() => presenter.hasChosenPrecedents).thenReturn(signal<bool>(false));
  when(
    () => presenter.canAnalyzeCase,
  ).thenReturn(canAnalyzeCase ?? signal<bool>(true));
  when(() => presenter.canRegenerateSummary).thenReturn(signal<bool>(false));
  when(() => presenter.canSearchPrecedents).thenReturn(signal<bool>(false));
  when(
    () => presenter.canGeneratePetitionDraft,
  ).thenReturn(signal<bool>(false));
  when(
    () => presenter.canRegeneratePetitionDraft,
  ).thenReturn(signal<bool>(false));
  when(
    () => presenter.showCaseProcessingBubble,
  ).thenReturn(signal<bool>(false));
  when(
    () => presenter.showPetitionDraftProcessingCard,
  ).thenReturn(signal<bool>(false));
  when(() => presenter.canExportReport).thenReturn(signal<bool>(false));
  when(
    () => presenter.primaryActionLabel,
  ).thenReturn(signal<String>('Analisar'));
  when(() => presenter.markBriefingSubmitted(any())).thenReturn(null);
  when(() => presenter.analyzeCase()).thenAnswer((_) async {});
  when(() => presenter.retrySummary()).thenAnswer((_) async {});
  when(() => presenter.confirmAndViewPrecedents()).thenReturn(null);
  when(() => presenter.markPrecedentsReady()).thenReturn(null);
  when(() => presenter.syncChosenPrecedents(any())).thenReturn(null);
  when(
    () => presenter.requestPetitionDraft(force: any(named: 'force')),
  ).thenAnswer((_) async {});
  when(() => presenter.regeneratePetitionDraft(any())).thenAnswer((_) async {});
  when(() => presenter.reloadPetitionDraft()).thenAnswer((_) async => true);
  when(() => presenter.renameAnalysis(any())).thenAnswer((_) async => true);
  when(() => presenter.archiveAnalysis()).thenAnswer((_) async => true);
  when(() => presenter.unarchiveAnalysis()).thenAnswer((_) async => true);
  when(() => presenter.exportAnalysisReport()).thenAnswer((_) async => true);
  return presenter;
}

_MockBriefingFormCardPresenter _createBriefingPresenter({
  bool canSubmit = true,
  CaseAssessmentBriefingDto? submitResult,
}) {
  final presenter = _MockBriefingFormCardPresenter();
  final form = FormGroup(<String, AbstractControl<Object>>{
    'legalArea': FormControl<LegalAreaDto>(),
    'courtJurisdiction': FormControl<CourtDto>(),
    'mainClaims': FormControl<String>(),
    'intendedThesis': FormControl<String>(),
  });

  when(() => presenter.form).thenReturn(form);
  when(() => presenter.generalError).thenReturn(signal<String?>(null));
  when(() => presenter.isSubmitting).thenReturn(signal<bool>(false));
  when(() => presenter.isReadOnly).thenReturn(signal<bool>(false));
  when(
    () => presenter.briefing,
  ).thenReturn(signal<CaseAssessmentBriefingDto?>(null));
  when(() => presenter.canSubmit).thenReturn(signal<bool>(canSubmit));
  when(
    () => presenter.legalAreaValidationMessages,
  ).thenReturn(<String, String Function(Object)>{});
  when(
    () => presenter.courtJurisdictionValidationMessages,
  ).thenReturn(<String, String Function(Object)>{});
  when(
    () => presenter.mainClaimsValidationMessages,
  ).thenReturn(<String, String Function(Object)>{});
  when(
    () => presenter.intendedThesisValidationMessages,
  ).thenReturn(<String, String Function(Object)>{});
  when(() => presenter.submitBriefing()).thenAnswer((_) async => submitResult);

  return presenter;
}

_MockSupportDocumentsSectionPresenter _createSupportDocumentsPresenter() {
  final presenter = _MockSupportDocumentsSectionPresenter();
  when(
    () => presenter.documents,
  ).thenReturn(signal<List<AnalysisDocumentDto>>(<AnalysisDocumentDto>[]));
  when(
    () => presenter.uploadingDocuments,
  ).thenReturn(signal<Map<String, double?>>(<String, double?>{}));
  when(() => presenter.isPicking).thenReturn(signal<bool>(false));
  when(() => presenter.generalError).thenReturn(signal<String?>(null));
  when(() => presenter.canAddDocument).thenReturn(signal<bool>(true));
  when(() => presenter.formatFileSize(any())).thenReturn('20.0 MB');
  when(() => presenter.addSupportDocument()).thenAnswer((_) async {});
  when(() => presenter.removeSupportDocument(any())).thenAnswer((_) async {});
  return presenter;
}

_MockAnalysisPrecedentsBubblePresenter _createPrecedentsPresenter() {
  final presenter = _MockAnalysisPrecedentsBubblePresenter();
  when(() => presenter.selectedLimit).thenReturn(signal<int>(5));
  when(
    () => presenter.selectedCourts,
  ).thenReturn(signal<List<CourtDto>>(<CourtDto>[]));
  when(
    () => presenter.selectedKinds,
  ).thenReturn(signal<List<PrecedentKindDto>>(<PrecedentKindDto>[]));
  when(
    () => presenter.chosenPrecedents,
  ).thenReturn(signal<List<AnalysisPrecedentDto>>(<AnalysisPrecedentDto>[]));
  when(() => presenter.retry()).thenAnswer((_) async {});
  when(() => presenter.syncSelectedLimit(any())).thenReturn(null);
  when(
    () => presenter.syncSelectedFilters(
      courts: any(named: 'courts'),
      kinds: any(named: 'kinds'),
    ),
  ).thenReturn(null);
  return presenter;
}
