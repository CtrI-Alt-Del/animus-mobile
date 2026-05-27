import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:animus/core/intake/dtos/analysis_dto.dart';
import 'package:animus/core/intake/dtos/analysis_precedent_dto.dart';
import 'package:animus/core/intake/dtos/analysis_status_dto.dart';
import 'package:animus/core/intake/dtos/analysis_type_dto.dart';
import 'package:animus/core/intake/dtos/second_instance_analysis_report_dto.dart';
import 'package:animus/core/intake/dtos/second_instance_judgment_draft_dto.dart';
import 'package:animus/core/intake/interfaces/intake_service.dart';
import 'package:animus/core/shared/interfaces/pdf_driver.dart';
import 'package:animus/core/shared/responses/rest_response.dart';
import 'package:animus/core/storage/interfaces/drivers/document_picker_driver.dart';
import 'package:animus/core/storage/interfaces/drivers/file_storage_driver.dart';
import 'package:animus/core/storage/interfaces/storage_service.dart';
import 'package:animus/ui/intake/widgets/pages/second_instance_analysis_screen/second_instance_analysis_screen_presenter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../fakers/intake/analysis_dto_faker.dart';
import '../../../../../fakers/intake/analysis_precedent_dto_faker.dart';
import '../../../../../fakers/intake/first_instance_analysis_report_dto_faker.dart';
import '../../../../../fakers/intake/petition_summary_dto_faker.dart';
import '../../../../../fakers/intake/second_instance_judgment_draft_dto_faker.dart';

class _MockIntakeService extends Mock implements IntakeService {}

class _MockStorageService extends Mock implements StorageService {}

class _MockPdfDriver extends Mock implements PdfDriver {}

class _MockFileStorageDriver extends Mock implements FileStorageDriver {}

class _MockDocumentPickerDriver extends Mock implements DocumentPickerDriver {}

class _MockFile extends Mock implements File {}

void main() {
  late _MockIntakeService intakeService;
  late _MockStorageService storageService;
  late _MockPdfDriver pdfDriver;
  late _MockFileStorageDriver fileStorageDriver;
  late _MockDocumentPickerDriver documentPickerDriver;
  late _MockFile file;

  setUpAll(() {
    registerFallbackValue(
      SecondInstanceAnalysisReportDto(
        analysis: AnalysisDtoFaker.fake(),
        document: FirstInstanceAnalysisReportDtoFaker.fake().document,
        caseSummary: PetitionSummaryDtoFaker.fake(),
        precedents: const <AnalysisPrecedentDto>[],
        judgmentDraft: SecondInstanceJudgmentDraftDtoFaker.fake(),
      ),
    );
  });

  setUp(() {
    intakeService = _MockIntakeService();
    storageService = _MockStorageService();
    pdfDriver = _MockPdfDriver();
    fileStorageDriver = _MockFileStorageDriver();
    documentPickerDriver = _MockDocumentPickerDriver();
    file = _MockFile();
  });

  SecondInstanceAnalysisScreenPresenter createPresenter() {
    return SecondInstanceAnalysisScreenPresenter(
      intakeService: intakeService,
      storageService: storageService,
      pdfDriver: pdfDriver,
      fileStorageDriver: fileStorageDriver,
      documentPickerDriver: documentPickerDriver,
      analysisId: 'analysis-1',
    );
  }

  group('SecondInstanceAnalysisScreenPresenter', () {
    test('should require chosen precedent to generate judgment draft', () {
      final presenter = createPresenter();
      addTearDown(presenter.dispose);

      presenter.precedentsReady.value = true;
      presenter.status.value = AnalysisStatusDto.precedentsSearched;

      expect(presenter.canGenerateJudgmentDraft.value, isFalse);

      presenter.syncChosenPrecedents(<AnalysisPrecedentDto>[
        AnalysisPrecedentDtoFaker.fake(isChosen: true),
      ]);

      expect(presenter.hasChosenPrecedents.value, isTrue);
      expect(presenter.canGenerateJudgmentDraft.value, isTrue);
    });

    test(
      'should not suggest generating draft again without chosen precedents',
      () {
        final presenter = createPresenter();
        addTearDown(presenter.dispose);

        presenter.status.value = AnalysisStatusDto.failed;
        presenter.precedentsReady.value = true;
        presenter.caseSummary.value = CaseSummaryDtoFaker.fake();

        expect(
          presenter.primaryActionLabel.value,
          'Tentar buscar precedentes novamente',
        );
      },
    );

    test(
      'should keep precedents ready when chosen precedents become empty',
      () {
        final presenter = createPresenter();
        addTearDown(presenter.dispose);

        presenter.precedentsReady.value = true;
        presenter.status.value = AnalysisStatusDto.precedentsSearched;
        presenter.syncChosenPrecedents(<AnalysisPrecedentDto>[
          AnalysisPrecedentDtoFaker.fake(isChosen: true),
        ]);

        presenter.syncChosenPrecedents(const <AnalysisPrecedentDto>[]);

        expect(presenter.precedentsReady.value, isTrue);
        expect(presenter.hasChosenPrecedents.value, isFalse);
        expect(presenter.canGenerateJudgmentDraft.value, isFalse);
      },
    );

    test('should reject files larger than 100MB before upload', () async {
      final presenter = createPresenter();
      addTearDown(presenter.dispose);

      when(
        () => documentPickerDriver.pickDocument(
          allowedExtensions:
              SecondInstanceAnalysisScreenPresenter.allowedExtensions,
        ),
      ).thenAnswer((_) async => file);
      when(() => file.path).thenReturn('processo.pdf');
      when(() => file.length()).thenAnswer(
        (_) async =>
            SecondInstanceAnalysisScreenPresenter.maxFileSizeInBytes + 1,
      );

      await presenter.pickDocument();

      expect(
        presenter.generalError.value,
        'O arquivo deve ter no máximo 100MB.',
      );
      verifyNever(
        () => storageService.generateAnalysisDocumentUploadUrl(
          analysisId: any(named: 'analysisId'),
          documentType: any(named: 'documentType'),
        ),
      );
    });

    test(
      'should eagerly load judgment draft during intermediate precedent states',
      () async {
        final presenter = createPresenter();
        addTearDown(presenter.dispose);
        final draft = SecondInstanceJudgmentDraftDtoFaker.fake();

        when(
          () => intakeService.getAnalysis(analysisId: 'analysis-1'),
        ).thenAnswer(
          (_) async => RestResponse<AnalysisDto>(
            statusCode: 200,
            body: AnalysisDtoFaker.fake(
              type: AnalysisTypeDto.secondInstance,
              status: AnalysisStatusDto.generatingSynthesis,
            ),
          ),
        );
        when(
          () => intakeService.getAnalysisDocument(analysisId: 'analysis-1'),
        ).thenAnswer(
          (_) async =>
              RestResponse(statusCode: 404, errorMessage: 'Nao encontrado'),
        );
        when(
          () => intakeService.getCaseSummary(analysisId: 'analysis-1'),
        ).thenAnswer(
          (_) async =>
              RestResponse(statusCode: 200, body: CaseSummaryDtoFaker.fake()),
        );
        when(
          () => intakeService.getSecondInstanceJudgmentDraft(
            analysisId: 'analysis-1',
          ),
        ).thenAnswer((_) async => RestResponse(statusCode: 200, body: draft));

        await presenter.load();

        expect(presenter.precedentsReady.value, isTrue);
        expect(presenter.judgmentDraft.value?.analysisId, draft.analysisId);
        verify(
          () => intakeService.getSecondInstanceJudgmentDraft(
            analysisId: 'analysis-1',
          ),
        ).called(1);
      },
    );

    test('should ignore not found draft during intermediate load', () async {
      final presenter = createPresenter();
      addTearDown(presenter.dispose);

      when(
        () => intakeService.getAnalysis(analysisId: 'analysis-1'),
      ).thenAnswer(
        (_) async => RestResponse<AnalysisDto>(
          statusCode: 200,
          body: AnalysisDtoFaker.fake(
            type: AnalysisTypeDto.secondInstance,
            status: AnalysisStatusDto.searchingPrecedents,
          ),
        ),
      );
      when(
        () => intakeService.getAnalysisDocument(analysisId: 'analysis-1'),
      ).thenAnswer(
        (_) async =>
            RestResponse(statusCode: 404, errorMessage: 'Nao encontrado'),
      );
      when(
        () => intakeService.getCaseSummary(analysisId: 'analysis-1'),
      ).thenAnswer(
        (_) async =>
            RestResponse(statusCode: 200, body: CaseSummaryDtoFaker.fake()),
      );
      when(
        () => intakeService.getSecondInstanceJudgmentDraft(
          analysisId: 'analysis-1',
        ),
      ).thenAnswer(
        (_) async => RestResponse(
          statusCode: HttpStatus.notFound,
          errorMessage: 'Nao encontrado',
        ),
      );

      await presenter.load();

      expect(presenter.status.value, AnalysisStatusDto.searchingPrecedents);
      expect(presenter.judgmentDraft.value, isNull);
      expect(presenter.generalError.value, isNull);
    });

    group('exportSecondInstanceAnalysisReport', () {
      test('should export report with sanitized filename', () async {
        final presenter = createPresenter();
        addTearDown(presenter.dispose);
        final SecondInstanceAnalysisReportDto report =
            SecondInstanceAnalysisReportDto(
              analysis: AnalysisDtoFaker.fake(
                id: 'analysis-1',
                name: ' Analise: final / teste? ',
                type: AnalysisTypeDto.secondInstance,
                status: AnalysisStatusDto.done,
              ),
              document: AnalysisDocumentDtoFaker.fake(),
              caseSummary: CaseSummaryDtoFaker.fake(),
              precedents: <AnalysisPrecedentDto>[
                AnalysisPrecedentDtoFaker.fake(isChosen: true),
              ],
              judgmentDraft: SecondInstanceJudgmentDraftDtoFaker.fake(),
            );
        final Uint8List bytes = Uint8List.fromList(<int>[1, 2, 3]);

        presenter.status.value = AnalysisStatusDto.done;
        presenter.judgmentDraft.value = report.judgmentDraft;
        presenter.generalError.value = 'erro antigo';

        when(
          () => intakeService.getSecondInstanceAnalysisReport(
            analysisId: 'analysis-1',
          ),
        ).thenAnswer(
          (_) async => RestResponse<SecondInstanceAnalysisReportDto>(
            statusCode: 200,
            body: report,
          ),
        );
        when(
          () => pdfDriver.generateSecondInstanceAnalysisReport(report: report),
        ).thenAnswer((_) async => bytes);
        when(
          () => pdfDriver.sharePdf(
            bytes: bytes,
            filename: 'Analise- final - teste- - Minuta de Sentenca.pdf',
          ),
        ).thenAnswer((_) async {});

        final bool exported = await presenter
            .exportSecondInstanceAnalysisReport();

        expect(exported, isTrue);
        expect(presenter.generalError.value, isNull);
        expect(presenter.isExportingReport.value, isFalse);
        expect(presenter.isManagingAnalysis.value, isFalse);
        verifyInOrder(<dynamic Function()>[
          () => intakeService.getSecondInstanceAnalysisReport(
            analysisId: 'analysis-1',
          ),
          () => pdfDriver.generateSecondInstanceAnalysisReport(report: report),
          () => pdfDriver.sharePdf(
            bytes: bytes,
            filename: 'Analise- final - teste- - Minuta de Sentenca.pdf',
          ),
        ]);
      });

      test(
        'should reuse loaded judgment draft when report payload draft is empty',
        () async {
          final presenter = createPresenter();
          addTearDown(presenter.dispose);
          final SecondInstanceJudgmentDraftDto loadedDraft =
              SecondInstanceJudgmentDraftDtoFaker.fake(
                report: 'Relatorio carregado',
                meritAnalysis: 'Merito carregado',
                ruling: <String>['Dar provimento'],
              );
          final SecondInstanceAnalysisReportDto emptyDraftReport =
              SecondInstanceAnalysisReportDto(
                analysis: AnalysisDtoFaker.fake(
                  id: 'analysis-1',
                  name: 'Analise',
                  type: AnalysisTypeDto.secondInstance,
                  status: AnalysisStatusDto.done,
                ),
                document: AnalysisDocumentDtoFaker.fake(),
                caseSummary: CaseSummaryDtoFaker.fake(),
                precedents: <AnalysisPrecedentDto>[
                  AnalysisPrecedentDtoFaker.fake(isChosen: true),
                ],
                judgmentDraft: const SecondInstanceJudgmentDraftDto(
                  analysisId: 'analysis-1',
                  report: '',
                  meritAnalysis: '',
                  precedentAdherenceAnalysis: '',
                  ruling: <String>[],
                ),
              );
          final Uint8List bytes = Uint8List.fromList(<int>[1, 2, 3]);

          presenter.status.value = AnalysisStatusDto.done;
          presenter.judgmentDraft.value = loadedDraft;

          when(
            () => intakeService.getSecondInstanceAnalysisReport(
              analysisId: 'analysis-1',
            ),
          ).thenAnswer(
            (_) async => RestResponse<SecondInstanceAnalysisReportDto>(
              statusCode: 200,
              body: emptyDraftReport,
            ),
          );
          when(
            () => pdfDriver.generateSecondInstanceAnalysisReport(
              report: any(named: 'report'),
            ),
          ).thenAnswer((_) async => bytes);
          when(
            () => pdfDriver.sharePdf(
              bytes: bytes,
              filename: 'Analise - Minuta de Sentenca.pdf',
            ),
          ).thenAnswer((_) async {});

          expect(await presenter.exportSecondInstanceAnalysisReport(), isTrue);

          final SecondInstanceAnalysisReportDto capturedReport =
              verify(
                    () => pdfDriver.generateSecondInstanceAnalysisReport(
                      report: captureAny(named: 'report'),
                    ),
                  ).captured.single
                  as SecondInstanceAnalysisReportDto;

          expect(capturedReport.judgmentDraft.report, loadedDraft.report);
          expect(
            capturedReport.judgmentDraft.meritAnalysis,
            loadedDraft.meritAnalysis,
          );
          expect(capturedReport.judgmentDraft.ruling, loadedDraft.ruling);
        },
      );

      test(
        'should preserve adherence analysis when merging loaded draft into empty report payload',
        () async {
          final presenter = createPresenter();
          addTearDown(presenter.dispose);
          final SecondInstanceJudgmentDraftDto loadedDraft =
              SecondInstanceJudgmentDraftDtoFaker.fake(
                report: 'Relatorio carregado',
                meritAnalysis: 'Merito carregado',
                precedentAdherenceAnalysis: 'Aderencia carregada',
                ruling: <String>['Dar provimento'],
              );
          final SecondInstanceAnalysisReportDto emptyDraftReport =
              SecondInstanceAnalysisReportDto(
                analysis: AnalysisDtoFaker.fake(
                  id: 'analysis-1',
                  name: 'Analise',
                  type: AnalysisTypeDto.secondInstance,
                  status: AnalysisStatusDto.done,
                ),
                document: AnalysisDocumentDtoFaker.fake(),
                caseSummary: CaseSummaryDtoFaker.fake(),
                precedents: <AnalysisPrecedentDto>[
                  AnalysisPrecedentDtoFaker.fake(isChosen: true),
                ],
                judgmentDraft: const SecondInstanceJudgmentDraftDto(
                  analysisId: 'analysis-1',
                  report: '',
                  meritAnalysis: '',
                  precedentAdherenceAnalysis: '',
                  ruling: <String>[],
                ),
              );
          final Uint8List bytes = Uint8List.fromList(<int>[1, 2, 3]);

          presenter.status.value = AnalysisStatusDto.done;
          presenter.judgmentDraft.value = loadedDraft;

          when(
            () => intakeService.getSecondInstanceAnalysisReport(
              analysisId: 'analysis-1',
            ),
          ).thenAnswer(
            (_) async => RestResponse<SecondInstanceAnalysisReportDto>(
              statusCode: 200,
              body: emptyDraftReport,
            ),
          );
          when(
            () => pdfDriver.generateSecondInstanceAnalysisReport(
              report: any(named: 'report'),
            ),
          ).thenAnswer((_) async => bytes);
          when(
            () => pdfDriver.sharePdf(
              bytes: bytes,
              filename: 'Analise - Minuta de Sentenca.pdf',
            ),
          ).thenAnswer((_) async {});

          expect(await presenter.exportSecondInstanceAnalysisReport(), isTrue);

          final SecondInstanceAnalysisReportDto capturedReport =
              verify(
                    () => pdfDriver.generateSecondInstanceAnalysisReport(
                      report: captureAny(named: 'report'),
                    ),
                  ).captured.single
                  as SecondInstanceAnalysisReportDto;

          expect(
            capturedReport.judgmentDraft.precedentAdherenceAnalysis,
            loadedDraft.precedentAdherenceAnalysis,
          );
        },
      );

      test(
        'should block concurrent export, rename and archive while exporting',
        () async {
          final presenter = createPresenter();
          addTearDown(presenter.dispose);
          final SecondInstanceAnalysisReportDto report =
              SecondInstanceAnalysisReportDto(
                analysis: AnalysisDtoFaker.fake(
                  id: 'analysis-1',
                  name: 'Analise concorrente',
                  type: AnalysisTypeDto.secondInstance,
                  status: AnalysisStatusDto.done,
                ),
                document: AnalysisDocumentDtoFaker.fake(),
                caseSummary: CaseSummaryDtoFaker.fake(),
                precedents: <AnalysisPrecedentDto>[
                  AnalysisPrecedentDtoFaker.fake(isChosen: true),
                ],
                judgmentDraft: SecondInstanceJudgmentDraftDtoFaker.fake(),
              );
          final Completer<Uint8List> generateCompleter = Completer<Uint8List>();
          final Uint8List bytes = Uint8List.fromList(<int>[9]);

          presenter.status.value = AnalysisStatusDto.done;
          presenter.judgmentDraft.value = report.judgmentDraft;

          when(
            () => intakeService.getSecondInstanceAnalysisReport(
              analysisId: 'analysis-1',
            ),
          ).thenAnswer(
            (_) async => RestResponse<SecondInstanceAnalysisReportDto>(
              statusCode: 200,
              body: report,
            ),
          );
          when(
            () =>
                pdfDriver.generateSecondInstanceAnalysisReport(report: report),
          ).thenAnswer((_) => generateCompleter.future);
          when(
            () => pdfDriver.sharePdf(
              bytes: bytes,
              filename: 'Analise concorrente - Minuta de Sentenca.pdf',
            ),
          ).thenAnswer((_) async {});

          final Future<bool> firstAttempt = presenter
              .exportSecondInstanceAnalysisReport();
          await Future<void>.delayed(Duration.zero);

          expect(presenter.isExportingReport.value, isTrue);
          expect(presenter.canExportReport.value, isFalse);
          expect(await presenter.exportSecondInstanceAnalysisReport(), isFalse);
          expect(await presenter.renameAnalysis('Novo nome'), isFalse);
          expect(await presenter.archiveAnalysis(), isFalse);
          expect(presenter.canPickDocument.value, isFalse);
          expect(presenter.canAnalyzeCase.value, isFalse);
          expect(presenter.canSearchPrecedents.value, isFalse);
          expect(presenter.canGenerateJudgmentDraft.value, isFalse);
          expect(presenter.canRegenerateJudgmentDraft.value, isFalse);
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
          expect(await firstAttempt, isTrue);
        },
      );
    });
  });
}
