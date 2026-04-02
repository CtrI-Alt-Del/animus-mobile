import 'dart:io';

import 'package:animus/core/intake/dtos/analysis_dto.dart';
import 'package:animus/core/intake/dtos/analysis_status_dto.dart';
import 'package:animus/core/intake/dtos/petition_dto.dart';
import 'package:animus/core/intake/dtos/petition_summary_dto.dart';
import 'package:animus/core/intake/interfaces/intake_service.dart';
import 'package:animus/core/shared/responses/rest_response.dart';
import 'package:animus/core/storage/interfaces/drivers/document_picker_driver.dart';
import 'package:animus/core/storage/interfaces/drivers/file_storage_driver.dart';
import 'package:animus/core/storage/interfaces/storage_service.dart';
import 'package:animus/drivers/document-picker-driver/index.dart';
import 'package:animus/drivers/storage/file_storage/index.dart';
import 'package:animus/rest/services/index.dart';
import 'package:animus/theme.dart';
import 'package:animus/ui/intake/widgets/pages/analysis_screen/analysis_screen_presenter.dart';
import 'package:animus/ui/intake/widgets/pages/analysis_screen/analysis_screen_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../../fakers/intake/petition_dto_faker.dart';
import '../../../../../fakers/intake/petition_summary_dto_faker.dart';

class _MockIntakeService extends Mock implements IntakeService {}

class _MockStorageService extends Mock implements StorageService {}

class _MockFileStorageDriver extends Mock implements FileStorageDriver {}

class _MockDocumentPickerDriver extends Mock implements DocumentPickerDriver {}

class _MockAnalysisScreenPresenter extends Mock
    implements AnalysisScreenPresenter {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(File('dummy.pdf'));
  });

  Widget createWidget(AnalysisScreenPresenter presenter) {
    return ProviderScope(
      overrides: [
        analysisScreenPresenterProvider(
          'analysis-123',
        ).overrideWithValue(presenter),
      ],
      child: MaterialApp(
        theme: AppTheme.dark,
        home: const AnalysisScreenView(analysisId: 'analysis-123'),
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
    final _MockFileStorageDriver fileStorageDriver = _MockFileStorageDriver();
    final _MockDocumentPickerDriver documentPickerDriver =
        _MockDocumentPickerDriver();

    when(
      () => intakeService.getAnalysis(analysisId: 'analysis-123'),
    ).thenAnswer(
      (_) async => RestResponse<AnalysisDto>(
        statusCode: 200,
        body: const AnalysisDto(
          id: 'analysis-123',
          name: 'Analise de precedente',
          accountId: 'account-1',
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
          fileStorageDriverProvider.overrideWithValue(fileStorageDriver),
          documentPickerDriverProvider.overrideWithValue(documentPickerDriver),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const AnalysisScreenView(analysisId: 'analysis-123'),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Selecionar petição'), findsOneWidget);
    expect(find.text('Analisar'), findsOneWidget);
    expect(find.textContaining('Formatos aceitos: PDF, DOCX'), findsOneWidget);
  });

  group('AnalysisScreenView states', () {
    late _MockAnalysisScreenPresenter presenter;
    late Signal<AnalysisStatusDto> status;
    late Signal<File?> selectedFile;
    late Signal<bool> isUploading;
    late Signal<double?> uploadProgress;
    late Signal<String?> generalError;
    late Signal<String> analysisName;
    late Signal<bool> isManagingAnalysis;
    late Signal<PetitionDto?> petition;
    late Signal<PetitionSummaryDto?> summary;
    late Signal<bool> canPickDocument;
    late Signal<bool> canAnalyze;
    late Signal<bool> showProcessingBubble;
    late Signal<String> primaryActionLabel;
    late Signal<String> fileActionLabel;

    setUp(() {
      presenter = _MockAnalysisScreenPresenter();
      status = signal<AnalysisStatusDto>(AnalysisStatusDto.waitingPetition);
      selectedFile = signal<File?>(null);
      isUploading = signal<bool>(false);
      uploadProgress = signal<double?>(null);
      generalError = signal<String?>(null);
      analysisName = signal<String>('Analise de precedente');
      isManagingAnalysis = signal<bool>(false);
      petition = signal<PetitionDto?>(null);
      summary = signal<PetitionSummaryDto?>(null);
      canPickDocument = signal<bool>(true);
      canAnalyze = signal<bool>(false);
      showProcessingBubble = signal<bool>(false);
      primaryActionLabel = signal<String>('Analisar');
      fileActionLabel = signal<String>('Selecionar petição');

      when(() => presenter.status).thenReturn(status);
      when(() => presenter.selectedFile).thenReturn(selectedFile);
      when(() => presenter.isUploading).thenReturn(isUploading);
      when(() => presenter.uploadProgress).thenReturn(uploadProgress);
      when(() => presenter.generalError).thenReturn(generalError);
      when(() => presenter.analysisName).thenReturn(analysisName);
      when(() => presenter.isManagingAnalysis).thenReturn(isManagingAnalysis);
      when(() => presenter.petition).thenReturn(petition);
      when(() => presenter.summary).thenReturn(summary);
      when(() => presenter.canPickDocument).thenReturn(canPickDocument);
      when(() => presenter.canAnalyze).thenReturn(canAnalyze);
      when(
        () => presenter.showProcessingBubble,
      ).thenReturn(showProcessingBubble);
      when(() => presenter.primaryActionLabel).thenReturn(primaryActionLabel);
      when(() => presenter.fileActionLabel).thenReturn(fileActionLabel);
      when(() => presenter.pickDocument()).thenAnswer((_) async {});
      when(() => presenter.analyze()).thenAnswer((_) async {});
      when(() => presenter.retrySummary()).thenAnswer((_) async {});
      when(() => presenter.replaceDocument()).thenAnswer((_) async {});
      when(() => presenter.confirmAndViewPrecedents()).thenReturn(null);
      when(() => presenter.renameAnalysis(any())).thenAnswer((_) async => true);
      when(() => presenter.archiveAnalysis()).thenAnswer((_) async => true);
      when(() => presenter.fileName(any())).thenReturn('petition.pdf');
      when(() => presenter.formatFileSize(any())).thenReturn('1.0 KB');
    });

    tearDown(() {
      status.dispose();
      selectedFile.dispose();
      isUploading.dispose();
      uploadProgress.dispose();
      generalError.dispose();
      analysisName.dispose();
      isManagingAnalysis.dispose();
      petition.dispose();
      summary.dispose();
      canPickDocument.dispose();
      canAnalyze.dispose();
      showProcessingBubble.dispose();
      primaryActionLabel.dispose();
      fileActionLabel.dispose();
    });

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
        petition.value = PetitionDtoFaker.fake();
        summary.value = PetitionSummaryDtoFaker.fake(
          caseSummary: 'Resumo expandivel da peticao.',
        );
        status.value = AnalysisStatusDto.petitionAnalyzed;
        primaryActionLabel.value = 'Buscar precedentes';
        fileActionLabel.value = 'Enviar outro documento';

        await tester.pumpWidget(createWidget(presenter));
        await tester.pump(const Duration(milliseconds: 400));

        expect(find.text('Resumo da Analise'), findsOneWidget);
        expect(find.text('Tentar resumo novamente'), findsOneWidget);
        expect(find.text('Buscar precedentes'), findsOneWidget);
        expect(find.text('Enviar outro documento'), findsOneWidget);
      },
    );

    testWidgets('aciona retry do resumo pelo presenter', (
      WidgetTester tester,
    ) async {
      petition.value = PetitionDtoFaker.fake();
      summary.value = PetitionSummaryDtoFaker.fake();
      status.value = AnalysisStatusDto.petitionAnalyzed;
      primaryActionLabel.value = 'Buscar precedentes';
      fileActionLabel.value = 'Enviar outro documento';

      await tester.pumpWidget(createWidget(presenter));
      await tester.pump(const Duration(milliseconds: 400));

      await tester.ensureVisible(find.text('Tentar resumo novamente'));

      await tester.tap(find.text('Tentar resumo novamente'));
      await tester.pump();

      verify(() => presenter.retrySummary()).called(1);
    });

    testWidgets('aciona CTA final quando status e petitionAnalyzed', (
      WidgetTester tester,
    ) async {
      petition.value = PetitionDtoFaker.fake();
      summary.value = PetitionSummaryDtoFaker.fake();
      status.value = AnalysisStatusDto.petitionAnalyzed;
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
        petition.value = PetitionDtoFaker.fake();
        summary.value = PetitionSummaryDtoFaker.fake();
        status.value = AnalysisStatusDto.petitionAnalyzed;
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
      petition.value = PetitionDtoFaker.fake();
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
  });
}
