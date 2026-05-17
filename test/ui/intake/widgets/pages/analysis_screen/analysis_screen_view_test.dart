import 'dart:io';

import 'package:animus/core/intake/dtos/analysis_dto.dart';
import 'package:animus/core/intake/dtos/analysis_document_dto.dart';
import 'package:animus/core/intake/dtos/analysis_precedent_dto.dart';
import 'package:animus/core/intake/dtos/analysis_status_dto.dart';
import 'package:animus/core/intake/dtos/analysis_type_dto.dart';
import 'package:animus/core/intake/dtos/court_dto.dart';
import 'package:animus/core/intake/dtos/case_summary_dto.dart';
import 'package:animus/core/intake/dtos/precedent_kind_dto.dart';
import 'package:animus/core/intake/interfaces/intake_service.dart';
import 'package:animus/core/shared/interfaces/cache_driver.dart';
import 'package:animus/core/shared/responses/rest_response.dart';
import 'package:animus/core/storage/interfaces/drivers/document_picker_driver.dart';
import 'package:animus/core/storage/interfaces/drivers/file_storage_driver.dart';
import 'package:animus/core/storage/interfaces/storage_service.dart';
import 'package:animus/drivers/cache/index.dart';
import 'package:animus/drivers/document-picker-driver/index.dart';
import 'package:animus/drivers/file_storage/index.dart';
import 'package:animus/rest/services/index.dart';
import 'package:animus/theme.dart';
import 'package:animus/ui/intake/widgets/pages/first_instance_analysis_screen/first_instance_analysis_screen_presenter.dart';
import 'package:animus/ui/intake/widgets/components/analysis_action_bar/analysis_action_bar_view.dart';
import 'package:animus/ui/intake/widgets/components/analysis_header/analysis_header_view.dart';
import 'package:animus/ui/intake/widgets/pages/first_instance_analysis_screen/chosen_precedent_summary/chosen_precedent_summary_view.dart';
import 'package:animus/ui/intake/widgets/pages/first_instance_analysis_screen/relevant_precedents_bubble/relevant_precedents_bubble_presenter.dart';
import 'package:animus/ui/intake/widgets/pages/first_instance_analysis_screen/relevant_precedents_bubble/relevant_precedents_bubble_view.dart';
import 'package:animus/ui/intake/widgets/pages/first_instance_analysis_screen/first_instance_analysis_screen_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../../fakers/intake/petition_summary_dto_faker.dart';
import '../../../../../fakers/intake/analysis_precedent_dto_faker.dart';

class _MockIntakeService extends Mock implements IntakeService {}

class _MockStorageService extends Mock implements StorageService {}

class _MockCacheDriver extends Mock implements CacheDriver {}

class _MockFileStorageDriver extends Mock implements FileStorageDriver {}

class _MockDocumentPickerDriver extends Mock implements DocumentPickerDriver {}

class _MockFirstInstanceAnalysisScreenPresenter extends Mock
    implements FirstInstanceAnalysisScreenPresenter {}

class _MockRelevantPrecedentsBubblePresenter extends Mock
    implements RelevantPrecedentsBubblePresenter {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  AnalysisDocumentDto createDocument({
    String analysisId = 'analysis-123',
    String filePath = 'uploads/documents/petition.pdf',
    String name = 'petition.pdf',
  }) {
    return AnalysisDocumentDto(
      analysisId: analysisId,
      uploadedAt: '2026-03-31T10:00:00Z',
      filePath: filePath,
      name: name,
    );
  }

  setUpAll(() {
    registerFallbackValue(File('dummy.pdf'));
    registerFallbackValue(AnalysisStatusDto.searchingPrecedents);
  });

  Widget createWidget(FirstInstanceAnalysisScreenPresenter presenter) {
    return SizedBox(
      width: 430,
      height: 900,
      child: ProviderScope(
        overrides: [
          firstInstanceAnalysisScreenPresenterProvider(
            'analysis-123',
          ).overrideWithValue(presenter),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const FirstInstanceAnalysisScreenView(
            analysisId: 'analysis-123',
          ),
        ),
      ),
    );
  }

  testWidgets('renderiza tela de analise com estado inicial', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final _MockIntakeService intakeService = _MockIntakeService();
    final _MockStorageService storageService = _MockStorageService();
    final _MockCacheDriver cacheDriver = _MockCacheDriver();
    final _MockFileStorageDriver fileStorageDriver = _MockFileStorageDriver();
    final _MockDocumentPickerDriver documentPickerDriver =
        _MockDocumentPickerDriver();

    when(() => cacheDriver.get(any())).thenReturn(null);
    when(() => cacheDriver.set(any(), any())).thenReturn(null);
    when(() => cacheDriver.delete(any())).thenReturn(null);

    when(
      () => intakeService.getAnalysis(analysisId: 'analysis-123'),
    ).thenAnswer(
      (_) async => RestResponse<AnalysisDto>(
        statusCode: 200,
        body: const AnalysisDto(
          id: 'analysis-123',
          name: 'Analise de precedente',
          accountId: 'account-1',
          type: AnalysisTypeDto.firstInstance,
          status: AnalysisStatusDto.waitingPetition,
          summary: '',
          createdAt: '2026-03-31T10:00:00Z',
        ),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          intakeServiceProvider.overrideWithValue(intakeService),
          storageServiceProvider.overrideWithValue(storageService),
          cacheDriverProvider.overrideWithValue(cacheDriver),
          fileStorageDriverProvider.overrideWithValue(fileStorageDriver),
          documentPickerDriverProvider.overrideWithValue(documentPickerDriver),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const FirstInstanceAnalysisScreenView(
            analysisId: 'analysis-123',
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Selecionar petição'), findsOneWidget);
    expect(find.text('Analisar'), findsOneWidget);
    expect(
      find.textContaining('Formatos aceitos: PDF, DOCX • Máx. 50MB'),
      findsOneWidget,
    );
  });

  group('AnalysisScreenView states', () {
    late _MockFirstInstanceAnalysisScreenPresenter presenter;
    late Signal<AnalysisStatusDto> status;
    late Signal<File?> selectedFile;
    late Signal<bool> isUploading;
    late Signal<double?> uploadProgress;
    late Signal<String?> generalError;
    late Signal<String> analysisName;
    late Signal<bool> isManagingAnalysis;
    late Signal<AnalysisDocumentDto?> analysisDocument;
    late Signal<CaseSummaryDto?> summary;
    late Signal<bool> canPickDocument;
    late Signal<bool> canAnalyze;
    late Signal<bool> showProcessingBubble;
    late Signal<String> primaryActionLabel;
    late Signal<String> fileActionLabel;
    late Signal<int> appliedPrecedentFiltersCount;
    late Signal<bool> isExportingReport;
    late ReadonlySignal<bool> canExportReport;
    late _MockRelevantPrecedentsBubblePresenter relevantPrecedentsPresenter;
    late Signal<AnalysisPrecedentDto?> selectedPrecedent;
    late Signal<List<AnalysisPrecedentDto>> precedents;
    late Signal<bool> precedentsIsLoading;
    late Signal<String?> precedentsError;
    late ReadonlySignal<int> precedentsTotalCount;
    late ReadonlySignal<String> precedentsLoadingMessage;
    late ReadonlySignal<bool> precedentsShowEmptyState;

    setUp(() {
      presenter = _MockFirstInstanceAnalysisScreenPresenter();
      relevantPrecedentsPresenter = _MockRelevantPrecedentsBubblePresenter();
      status = signal<AnalysisStatusDto>(AnalysisStatusDto.waitingPetition);
      selectedFile = signal<File?>(null);
      isUploading = signal<bool>(false);
      uploadProgress = signal<double?>(null);
      generalError = signal<String?>(null);
      analysisName = signal<String>('Analise de precedente');
      isManagingAnalysis = signal<bool>(false);
      analysisDocument = signal<AnalysisDocumentDto?>(null);
      summary = signal<CaseSummaryDto?>(null);
      canPickDocument = signal<bool>(true);
      canAnalyze = signal<bool>(false);
      showProcessingBubble = signal<bool>(false);
      primaryActionLabel = signal<String>('Analisar');
      fileActionLabel = signal<String>('Selecionar petição');
      appliedPrecedentFiltersCount = signal<int>(0);
      isExportingReport = signal<bool>(false);
      canExportReport = computed(
        () =>
            status.value == AnalysisStatusDto.precedentChosen &&
            !isExportingReport.value,
      );
      selectedPrecedent = signal<AnalysisPrecedentDto?>(null);
      precedents = signal<List<AnalysisPrecedentDto>>(<AnalysisPrecedentDto>[]);
      precedentsIsLoading = signal<bool>(false);
      precedentsError = signal<String?>(null);
      precedentsTotalCount = computed(() => precedents.value.length);
      precedentsLoadingMessage = computed(() => 'Buscando precedentes');
      precedentsShowEmptyState = computed(
        () =>
            !precedentsIsLoading.value &&
            precedentsError.value == null &&
            precedents.value.isEmpty,
      );

      when(() => presenter.status).thenReturn(status);
      when(() => presenter.selectedFile).thenReturn(selectedFile);
      when(() => presenter.isUploading).thenReturn(isUploading);
      when(() => presenter.uploadProgress).thenReturn(uploadProgress);
      when(() => presenter.generalError).thenReturn(generalError);
      when(() => presenter.analysisName).thenReturn(analysisName);
      when(() => presenter.isManagingAnalysis).thenReturn(isManagingAnalysis);
      when(() => presenter.analysisDocument).thenReturn(analysisDocument);
      when(() => presenter.summary).thenReturn(summary);
      when(() => presenter.canPickDocument).thenReturn(canPickDocument);
      when(() => presenter.canAnalyze).thenReturn(canAnalyze);
      when(
        () => presenter.showProcessingBubble,
      ).thenReturn(showProcessingBubble);
      when(() => presenter.primaryActionLabel).thenReturn(primaryActionLabel);
      when(() => presenter.fileActionLabel).thenReturn(fileActionLabel);
      when(
        () => presenter.appliedPrecedentFiltersCount,
      ).thenReturn(appliedPrecedentFiltersCount);
      when(() => presenter.isExportingReport).thenReturn(isExportingReport);
      when(() => presenter.canExportReport).thenReturn(canExportReport);
      when(() => presenter.precedentsLimit).thenReturn(signal<int>(5));
      when(
        () => presenter.precedentsCourts,
      ).thenReturn(signal<List<CourtDto>>(<CourtDto>[]));
      when(
        () => presenter.precedentsKinds,
      ).thenReturn(signal<List<PrecedentKindDto>>(<PrecedentKindDto>[]));
      when(() => presenter.pickDocument()).thenAnswer((_) async {});
      when(() => presenter.analyze()).thenAnswer((_) async {});
      when(() => presenter.retrySummary()).thenAnswer((_) async {});
      when(() => presenter.replaceDocument()).thenAnswer((_) async {});
      when(() => presenter.confirmAndViewPrecedents()).thenReturn(null);
      when(() => presenter.renameAnalysis(any())).thenAnswer((_) async => true);
      when(() => presenter.archiveAnalysis()).thenAnswer((_) async => true);
      when(
        () => presenter.exportAnalysisReport(),
      ).thenAnswer((_) async => true);
      when(() => presenter.fileName(any())).thenReturn('petition.pdf');
      when(() => presenter.formatFileSize(any())).thenReturn('1.0 KB');

      when(
        () => relevantPrecedentsPresenter.selectedPrecedent,
      ).thenReturn(selectedPrecedent);
      when(() => relevantPrecedentsPresenter.precedents).thenReturn(precedents);
      when(
        () => relevantPrecedentsPresenter.isLoading,
      ).thenReturn(precedentsIsLoading);
      when(
        () => relevantPrecedentsPresenter.generalError,
      ).thenReturn(precedentsError);
      when(
        () => relevantPrecedentsPresenter.totalCount,
      ).thenReturn(precedentsTotalCount);
      when(
        () => relevantPrecedentsPresenter.loadingMessage,
      ).thenReturn(precedentsLoadingMessage);
      when(
        () => relevantPrecedentsPresenter.showEmptyState,
      ).thenReturn(precedentsShowEmptyState);
      when(
        () => relevantPrecedentsPresenter.syncSelectedLimit(any()),
      ).thenReturn(null);
      when(
        () => relevantPrecedentsPresenter.syncAnalysisStatus(any()),
      ).thenReturn(null);
      when(
        () => relevantPrecedentsPresenter.syncSelectedFilters(
          courts: any(named: 'courts'),
          kinds: any(named: 'kinds'),
        ),
      ).thenReturn(null);
      when(() => relevantPrecedentsPresenter.retry()).thenAnswer((_) async {});
    });

    tearDown(() {
      status.dispose();
      selectedFile.dispose();
      isUploading.dispose();
      uploadProgress.dispose();
      generalError.dispose();
      analysisName.dispose();
      isManagingAnalysis.dispose();
      analysisDocument.dispose();
      summary.dispose();
      canPickDocument.dispose();
      canAnalyze.dispose();
      showProcessingBubble.dispose();
      primaryActionLabel.dispose();
      fileActionLabel.dispose();
      appliedPrecedentFiltersCount.dispose();
      isExportingReport.dispose();
      canExportReport.dispose();
      selectedPrecedent.dispose();
      precedents.dispose();
      precedentsIsLoading.dispose();
      precedentsError.dispose();
      precedentsTotalCount.dispose();
      precedentsLoadingMessage.dispose();
      precedentsShowEmptyState.dispose();
    });

    Widget createWidgetWithPrecedentsPresenter() {
      return SizedBox(
        width: 430,
        height: 900,
        child: ProviderScope(
          overrides: [
            firstInstanceAnalysisScreenPresenterProvider(
              'analysis-123',
            ).overrideWithValue(presenter),
            relevantPrecedentsBubblePresenterProvider(
              'analysis-123',
            ).overrideWithValue(relevantPrecedentsPresenter),
          ],
          child: MaterialApp(
            theme: AppTheme.dark,
            home: const FirstInstanceAnalysisScreenView(
              analysisId: 'analysis-123',
            ),
          ),
        ),
      );
    }

    testWidgets('renderiza erro inline quando presenter informa falha', (
      WidgetTester tester,
    ) async {
      generalError.value = 'Falha ao enviar documento.';
      status.value = AnalysisStatusDto.failed;

      await tester.pumpWidget(createWidget(presenter));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Falha ao enviar documento.'), findsOneWidget);
    });

    testWidgets(
      'renderiza summary card e acao de retry quando peticao foi analisada',
      (WidgetTester tester) async {
        analysisDocument.value = createDocument();
        summary.value = CaseSummaryDtoFaker.fake(
          caseSummary: 'Resumo expandivel da peticao.',
        );
        status.value = AnalysisStatusDto.caseAnalyzed;
        primaryActionLabel.value = 'Buscar precedentes';
        fileActionLabel.value = 'Enviar outro documento';

        await tester.pumpWidget(createWidget(presenter));
        await tester.pump(const Duration(milliseconds: 400));

        expect(find.text('Síntese da Análise'), findsOneWidget);
        expect(find.text('Tentar resumo novamente'), findsOneWidget);
        expect(find.text('Buscar precedentes'), findsOneWidget);
        expect(find.text('Enviar outro documento'), findsOneWidget);
      },
    );

    testWidgets('aciona retry do resumo pelo presenter', (
      WidgetTester tester,
    ) async {
      analysisDocument.value = createDocument();
      summary.value = CaseSummaryDtoFaker.fake();
      status.value = AnalysisStatusDto.caseAnalyzed;
      primaryActionLabel.value = 'Buscar precedentes';
      fileActionLabel.value = 'Enviar outro documento';

      await tester.pumpWidget(createWidget(presenter));
      await tester.pump(const Duration(milliseconds: 400));

      await tester.ensureVisible(find.text('Tentar resumo novamente'));

      await tester.tap(find.text('Tentar resumo novamente'));
      await tester.pump();

      verify(() => presenter.retrySummary()).called(1);
    });

    testWidgets('aciona CTA final quando status e caseAnalyzed', (
      WidgetTester tester,
    ) async {
      analysisDocument.value = createDocument();
      summary.value = CaseSummaryDtoFaker.fake();
      status.value = AnalysisStatusDto.caseAnalyzed;
      primaryActionLabel.value = 'Buscar precedentes';
      fileActionLabel.value = 'Enviar outro documento';

      await tester.pumpWidget(createWidget(presenter));
      await tester.pump(const Duration(milliseconds: 400));

      await tester.tap(find.text('Buscar precedentes'));
      await tester.pump();

      verify(() => presenter.confirmAndViewPrecedents()).called(1);
    });

    testWidgets(
      'aciona replaceDocument pela acao secundaria quando analisada',
      (WidgetTester tester) async {
        analysisDocument.value = createDocument();
        summary.value = CaseSummaryDtoFaker.fake();
        status.value = AnalysisStatusDto.caseAnalyzed;
        primaryActionLabel.value = 'Buscar precedentes';
        fileActionLabel.value = 'Enviar outro documento';

        await tester.pumpWidget(createWidget(presenter));
        await tester.pump(const Duration(milliseconds: 400));

        await tester.tap(find.text('Enviar outro documento'));
        await tester.pump();

        verify(() => presenter.replaceDocument()).called(1);
      },
    );

    testWidgets('desabilita action bar durante upload', (
      WidgetTester tester,
    ) async {
      status.value = AnalysisStatusDto.petitionUploaded;
      isUploading.value = true;
      canAnalyze.value = true;

      await tester.pumpWidget(createWidget(presenter));
      await tester.pump(const Duration(milliseconds: 400));

      clearInteractions(presenter);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.tap(find.text('Selecionar petição'));
      await tester.tap(find.byType(CircularProgressIndicator));
      await tester.pump();

      verifyNever(() => presenter.pickDocument());
      verifyNever(() => presenter.analyze());
    });

    testWidgets('bloqueia acao primaria enquanto analisa a peticao', (
      WidgetTester tester,
    ) async {
      analysisDocument.value = createDocument();
      status.value = AnalysisStatusDto.analyzingPetition;
      canPickDocument.value = false;
      canAnalyze.value = false;
      showProcessingBubble.value = true;

      await tester.pumpWidget(createWidget(presenter));
      await tester.pump(const Duration(milliseconds: 400));

      clearInteractions(presenter);

      expect(find.text('Analisando a petição enviada.'), findsOneWidget);
      expect(find.text('Selecionar petição'), findsNothing);
      expect(find.text('Analisar'), findsOneWidget);

      await tester.tap(find.text('Analisar'));
      await tester.pump();

      verifyNever(() => presenter.pickDocument());
      verifyNever(() => presenter.analyze());
    });

    testWidgets(
      'exibe item Exportar PDF somente quando status e precedentChosen',
      (WidgetTester tester) async {
        await tester.pumpWidget(createWidgetWithPrecedentsPresenter());
        await tester.pump(const Duration(milliseconds: 400));

        AnalysisHeaderView header = tester.widget<AnalysisHeaderView>(
          find.byType(AnalysisHeaderView),
        );

        expect(header.showExportReport, isFalse);
        expect(header.onExportReport, isNull);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();

        status.value = AnalysisStatusDto.precedentChosen;

        await tester.pumpWidget(createWidgetWithPrecedentsPresenter());
        await tester.pump(const Duration(milliseconds: 400));

        header = tester.widget<AnalysisHeaderView>(
          find.byType(AnalysisHeaderView),
        );

        expect(header.showExportReport, isTrue);
        expect(header.onExportReport, isNotNull);
      },
    );

    testWidgets('delega exportacao para presenter ao tocar em Exportar PDF', (
      WidgetTester tester,
    ) async {
      status.value = AnalysisStatusDto.precedentChosen;

      await tester.pumpWidget(createWidgetWithPrecedentsPresenter());
      await tester.pump(const Duration(milliseconds: 400));

      final AnalysisHeaderView header = tester.widget<AnalysisHeaderView>(
        find.byType(AnalysisHeaderView),
      );

      header.onExportReport!.call();
      await tester.pump();

      verify(() => presenter.exportAnalysisReport()).called(1);
    });

    testWidgets(
      'exibe snackbar de sucesso quando exportacao conclui com sucesso',
      (WidgetTester tester) async {
        status.value = AnalysisStatusDto.precedentChosen;
        when(
          () => presenter.exportAnalysisReport(),
        ).thenAnswer((_) async => true);

        await tester.pumpWidget(createWidgetWithPrecedentsPresenter());
        await tester.pump(const Duration(milliseconds: 400));

        final AnalysisHeaderView header = tester.widget<AnalysisHeaderView>(
          find.byType(AnalysisHeaderView),
        );

        header.onExportReport!.call();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Relatorio exportado com sucesso.'), findsOneWidget);
      },
    );

    testWidgets(
      'mantem item de exportacao ocupado e desabilitado durante exportacao',
      (WidgetTester tester) async {
        status.value = AnalysisStatusDto.precedentChosen;
        isExportingReport.value = true;

        await tester.pumpWidget(createWidgetWithPrecedentsPresenter());
        await tester.pump(const Duration(milliseconds: 400));

        final AnalysisHeaderView header = tester.widget<AnalysisHeaderView>(
          find.byType(AnalysisHeaderView),
        );

        expect(header.showExportReport, isTrue);
        expect(header.isExportingReport, isTrue);
        expect(header.onExportReport, isNull);
      },
    );

    testWidgets(
      'exibe bubble de precedentes e oculta action bar durante fluxo de precedentes',
      (WidgetTester tester) async {
        analysisDocument.value = createDocument();
        summary.value = CaseSummaryDtoFaker.fake();
        status.value = AnalysisStatusDto.searchingPrecedents;

        await tester.pumpWidget(createWidgetWithPrecedentsPresenter());
        await tester.pump(const Duration(milliseconds: 400));

        expect(find.byType(RelevantPrecedentsBubbleView), findsOneWidget);
        expect(find.byType(AnalysisActionBarView), findsNothing);
      },
    );

    testWidgets(
      'exibe resumo de precedente escolhido somente quando existe precedente escolhido',
      (WidgetTester tester) async {
        analysisDocument.value = createDocument();
        summary.value = CaseSummaryDtoFaker.fake();
        status.value = AnalysisStatusDto.precedentChosen;

        selectedPrecedent.value = AnalysisPrecedentDtoFaker.fake(
          isChosen: false,
        );
        await tester.pumpWidget(createWidgetWithPrecedentsPresenter());
        await tester.pump(const Duration(milliseconds: 400));

        expect(find.byType(ChosenPrecedentSummaryView), findsNothing);

        selectedPrecedent.value = AnalysisPrecedentDtoFaker.fake(
          isChosen: true,
        );
        await tester.pump();

        expect(find.byType(ChosenPrecedentSummaryView), findsOneWidget);
        expect(find.text('Precedente escolhido'), findsOneWidget);
      },
    );
  });
}
