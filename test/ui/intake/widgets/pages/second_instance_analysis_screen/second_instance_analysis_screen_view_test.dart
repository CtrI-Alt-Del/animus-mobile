import 'dart:io';

import 'package:animus/core/intake/dtos/analysis_document_dto.dart';
import 'package:animus/core/intake/dtos/analysis_precedent_dto.dart';
import 'package:animus/core/intake/dtos/analysis_status_dto.dart';
import 'package:animus/core/intake/dtos/case_summary_dto.dart';
import 'package:animus/core/intake/dtos/court_dto.dart';
import 'package:animus/core/intake/dtos/precedent_kind_dto.dart';
import 'package:animus/core/intake/dtos/second_instance_judgment_draft_dto.dart';
import 'package:animus/theme.dart';
import 'package:animus/ui/intake/widgets/components/analysis_header/analysis_header_view.dart';
import 'package:animus/ui/intake/widgets/components/analysis_precedents_bubble/analysis_precedents_bubble_presenter.dart';
import 'package:animus/ui/intake/widgets/pages/second_instance_analysis_screen/index.dart';
import 'package:animus/ui/intake/widgets/pages/second_instance_analysis_screen/second_instance_analysis_screen_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../../fakers/intake/analysis_precedent_dto_faker.dart';

class _MockSecondInstanceAnalysisScreenPresenter extends Mock
    implements SecondInstanceFirstInstanceAnalysisScreenPresenter {}

class _MockAnalysisPrecedentsBubblePresenter extends Mock
    implements AnalysisPrecedentsBubblePresenter {}

void main() {
  late _MockSecondInstanceAnalysisScreenPresenter presenter;
  late _MockAnalysisPrecedentsBubblePresenter bubblePresenter;
  late Signal<AnalysisStatusDto> status;
  late Signal<File?> selectedFile;
  late Signal<AnalysisDocumentDto?> analysisDocument;
  late Signal<bool> isUploading;
  late Signal<double?> uploadProgress;
  late Signal<CaseSummaryDto?> caseSummary;
  late Signal<SecondInstanceJudgmentDraftDto?> judgmentDraft;
  late Signal<String?> generalError;
  late Signal<String> analysisName;
  late Signal<bool> isManagingAnalysis;
  late Signal<bool> canPickDocument;
  late Signal<bool> canAnalyzeCase;
  late Signal<bool> canSearchPrecedents;
  late Signal<bool> canGenerateJudgmentDraft;
  late Signal<bool> canRegenerateJudgmentDraft;
  late Signal<bool> showCaseProcessingBubble;
  late Signal<bool> showJudgmentDraftProcessingBubble;
  late Signal<bool> showPetitionNotFound;
  late Signal<String> primaryActionLabel;
  late Signal<List<AnalysisPrecedentDto>> precedents;
  late Signal<List<AnalysisPrecedentDto>> chosenPrecedents;
  late Signal<List<CourtDto>> selectedCourts;
  late Signal<List<PrecedentKindDto>> selectedKinds;
  late Signal<bool> bubbleIsLoading;
  late Signal<String?> bubbleGeneralError;
  late ReadonlySignal<int> totalCount;
  late ReadonlySignal<String> loadingMessage;
  late ReadonlySignal<bool> showEmptyState;

  setUpAll(() {
    registerFallbackValue(AnalysisPrecedentDtoFaker.fake());
    registerFallbackValue(AnalysisStatusDto.searchingPrecedents);
    registerFallbackValue(<AnalysisPrecedentDto>[]);
    registerFallbackValue(<CourtDto>[]);
    registerFallbackValue(<PrecedentKindDto>[]);
    registerFallbackValue(File('fallback.pdf'));
  });

  setUp(() {
    presenter = _MockSecondInstanceAnalysisScreenPresenter();
    bubblePresenter = _MockAnalysisPrecedentsBubblePresenter();
    status = signal<AnalysisStatusDto>(AnalysisStatusDto.searchingPrecedents);
    selectedFile = signal<File?>(null);
    analysisDocument = signal<AnalysisDocumentDto?>(null);
    isUploading = signal<bool>(false);
    uploadProgress = signal<double?>(null);
    caseSummary = signal<CaseSummaryDto?>(null);
    judgmentDraft = signal<SecondInstanceJudgmentDraftDto?>(null);
    generalError = signal<String?>(null);
    analysisName = signal<String>('Análise de segunda instância');
    isManagingAnalysis = signal<bool>(false);
    canPickDocument = signal<bool>(false);
    canAnalyzeCase = signal<bool>(false);
    canSearchPrecedents = signal<bool>(false);
    canGenerateJudgmentDraft = signal<bool>(false);
    canRegenerateJudgmentDraft = signal<bool>(false);
    showCaseProcessingBubble = signal<bool>(false);
    showJudgmentDraftProcessingBubble = signal<bool>(false);
    showPetitionNotFound = signal<bool>(false);
    primaryActionLabel = signal<String>('Gerar minuta');
    precedents = signal<List<AnalysisPrecedentDto>>(<AnalysisPrecedentDto>[]);
    chosenPrecedents = signal<List<AnalysisPrecedentDto>>(<AnalysisPrecedentDto>[]);
    selectedCourts = signal<List<CourtDto>>(<CourtDto>[]);
    selectedKinds = signal<List<PrecedentKindDto>>(<PrecedentKindDto>[]);
    bubbleIsLoading = signal<bool>(false);
    bubbleGeneralError = signal<String?>(null);
    totalCount = computed(() => precedents.value.length);
    loadingMessage = computed(() => 'Buscando precedentes');
    showEmptyState = computed(
      () =>
          !bubbleIsLoading.value &&
          bubbleGeneralError.value == null &&
          precedents.value.isEmpty,
    );

    when(() => presenter.status).thenReturn(status);
    when(() => presenter.selectedFile).thenReturn(selectedFile);
    when(() => presenter.analysisDocument).thenReturn(analysisDocument);
    when(() => presenter.isUploading).thenReturn(isUploading);
    when(() => presenter.uploadProgress).thenReturn(uploadProgress);
    when(() => presenter.caseSummary).thenReturn(caseSummary);
    when(() => presenter.judgmentDraft).thenReturn(judgmentDraft);
    when(() => presenter.generalError).thenReturn(generalError);
    when(() => presenter.analysisName).thenReturn(analysisName);
    when(() => presenter.isManagingAnalysis).thenReturn(isManagingAnalysis);
    when(() => presenter.canPickDocument).thenReturn(canPickDocument);
    when(() => presenter.canAnalyzeCase).thenReturn(canAnalyzeCase);
    when(() => presenter.canSearchPrecedents).thenReturn(canSearchPrecedents);
    when(() => presenter.canGenerateJudgmentDraft)
        .thenReturn(canGenerateJudgmentDraft);
    when(() => presenter.canRegenerateJudgmentDraft)
        .thenReturn(canRegenerateJudgmentDraft);
    when(() => presenter.showCaseProcessingBubble)
        .thenReturn(showCaseProcessingBubble);
    when(() => presenter.showJudgmentDraftProcessingBubble)
        .thenReturn(showJudgmentDraftProcessingBubble);
    when(() => presenter.showPetitionNotFound).thenReturn(showPetitionNotFound);
    when(() => presenter.primaryActionLabel).thenReturn(primaryActionLabel);
    when(() => presenter.syncChosenPrecedents(any())).thenReturn(null);
    when(() => presenter.renameAnalysis(any())).thenAnswer((_) async => true);
    when(() => presenter.archiveAnalysis()).thenAnswer((_) async => true);
    when(() => presenter.pickDocument()).thenAnswer((_) async {});
    when(() => presenter.regenerateJudgmentDraft()).thenAnswer((_) async {});
    when(() => presenter.requestJudgmentDraft()).thenAnswer((_) async {});
    when(() => presenter.markPrecedentsReady()).thenReturn(null);
    when(() => presenter.analyzeCase()).thenAnswer((_) async {});
    when(() => presenter.resendDocument()).thenAnswer((_) async {});
    when(() => presenter.reanalyzeCase()).thenAnswer((_) async {});
    when(() => presenter.fileName(any())).thenReturn('processo.pdf');
    when(() => presenter.formatFileSize(any())).thenReturn('1.0 KB');

    when(() => bubblePresenter.selectedCourts).thenReturn(selectedCourts);
    when(() => bubblePresenter.selectedKinds).thenReturn(selectedKinds);
    when(() => bubblePresenter.chosenPrecedents).thenReturn(chosenPrecedents);
    when(() => bubblePresenter.precedents).thenReturn(precedents);
    when(() => bubblePresenter.isLoading).thenReturn(bubbleIsLoading);
    when(() => bubblePresenter.generalError).thenReturn(bubbleGeneralError);
    when(() => bubblePresenter.totalCount).thenReturn(totalCount);
    when(() => bubblePresenter.loadingMessage).thenReturn(loadingMessage);
    when(() => bubblePresenter.showEmptyState).thenReturn(showEmptyState);
    when(() => bubblePresenter.selectedLimit).thenReturn(signal<int>(5));
    when(() => bubblePresenter.syncSelectedLimit(any())).thenReturn(null);
    when(
      () => bubblePresenter.syncSelectedFilters(
        courts: any(named: 'courts'),
        kinds: any(named: 'kinds'),
      ),
    ).thenReturn(null);
    when(() => bubblePresenter.syncAnalysisStatus(any())).thenReturn(null);
    when(() => bubblePresenter.retry()).thenAnswer((_) async {});
    when(() => bubblePresenter.focusPrecedent(any())).thenReturn(null);
  });

  tearDown(() {
    status.dispose();
    selectedFile.dispose();
    analysisDocument.dispose();
    isUploading.dispose();
    uploadProgress.dispose();
    caseSummary.dispose();
    judgmentDraft.dispose();
    generalError.dispose();
    analysisName.dispose();
    isManagingAnalysis.dispose();
    canPickDocument.dispose();
    canAnalyzeCase.dispose();
    canSearchPrecedents.dispose();
    canGenerateJudgmentDraft.dispose();
    canRegenerateJudgmentDraft.dispose();
    showCaseProcessingBubble.dispose();
    showJudgmentDraftProcessingBubble.dispose();
    showPetitionNotFound.dispose();
    primaryActionLabel.dispose();
    precedents.dispose();
    chosenPrecedents.dispose();
    selectedCourts.dispose();
    selectedKinds.dispose();
    bubbleIsLoading.dispose();
    bubbleGeneralError.dispose();
    totalCount.dispose();
    loadingMessage.dispose();
    showEmptyState.dispose();
  });

  Widget createWidget() {
    return SizedBox(
      width: 430,
      height: 900,
      child: ProviderScope(
        overrides: [
          secondInstanceFirstInstanceAnalysisScreenPresenterProvider(
            'analysis-123',
          ).overrideWithValue(presenter),
          analysisPrecedentsBubblePresenterProvider(
            'analysis-123',
          ).overrideWithValue(bubblePresenter),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const SecondInstanceAnalysisScreenView(
            analysisId: 'analysis-123',
          ),
        ),
      ),
    );
  }

  testWidgets(
    'expõe ações de filtros e quantidade no header durante fluxo de precedentes',
    (WidgetTester tester) async {
      status.value = AnalysisStatusDto.searchingPrecedents;

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      final AnalysisHeaderView header = tester.widget<AnalysisHeaderView>(
        find.byType(AnalysisHeaderView),
      );

      expect(header.onFilters, isNotNull);
      expect(header.onPrecedentsCount, isNotNull);
    },
  );

  testWidgets(
    'sincroniza chosenPrecedents do bubble com o presenter da tela',
    (WidgetTester tester) async {
      final initialChosen = <AnalysisPrecedentDto>[
        AnalysisPrecedentDtoFaker.fake(isChosen: true),
      ];
      final updatedChosen = <AnalysisPrecedentDto>[
        AnalysisPrecedentDtoFaker.fake(
          isChosen: true,
          precedent: PrecedentDtoFaker.fake(
            identifier: PrecedentIdentifierDtoFaker.fake(number: 2),
          ),
        ),
        AnalysisPrecedentDtoFaker.fake(
          isChosen: true,
          precedent: PrecedentDtoFaker.fake(
            identifier: PrecedentIdentifierDtoFaker.fake(number: 3),
          ),
        ),
      ];
      chosenPrecedents.value = initialChosen;

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      verify(() => presenter.syncChosenPrecedents(initialChosen)).called(1);

      chosenPrecedents.value = updatedChosen;
      await tester.pump();
      await tester.pumpAndSettle();

      verify(() => presenter.syncChosenPrecedents(updatedChosen)).called(1);
    },
  );
}
