import 'dart:io';

import 'package:animus/core/intake/dtos/analysis_dto.dart';
import 'package:animus/core/intake/dtos/analysis_precedent_dto.dart';
import 'package:animus/core/intake/dtos/analysis_status_dto.dart';
import 'package:animus/core/intake/dtos/analysis_type_dto.dart';
import 'package:animus/core/intake/interfaces/intake_service.dart';
import 'package:animus/core/shared/responses/rest_response.dart';
import 'package:animus/core/storage/interfaces/drivers/document_picker_driver.dart';
import 'package:animus/core/storage/interfaces/drivers/file_storage_driver.dart';
import 'package:animus/core/storage/interfaces/storage_service.dart';
import 'package:animus/ui/intake/widgets/pages/second_instance_analysis_screen/second_instance_analysis_screen_presenter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../fakers/intake/analysis_dto_faker.dart';
import '../../../../../fakers/intake/analysis_precedent_dto_faker.dart';
import '../../../../../fakers/intake/petition_summary_dto_faker.dart';
import '../../../../../fakers/intake/second_instance_judgment_draft_dto_faker.dart';

class _MockIntakeService extends Mock implements IntakeService {}

class _MockStorageService extends Mock implements StorageService {}

class _MockFileStorageDriver extends Mock implements FileStorageDriver {}

class _MockDocumentPickerDriver extends Mock implements DocumentPickerDriver {}

void main() {
  late _MockIntakeService intakeService;
  late _MockStorageService storageService;
  late _MockFileStorageDriver fileStorageDriver;
  late _MockDocumentPickerDriver documentPickerDriver;

  setUp(() {
    intakeService = _MockIntakeService();
    storageService = _MockStorageService();
    fileStorageDriver = _MockFileStorageDriver();
    documentPickerDriver = _MockDocumentPickerDriver();
  });

  SecondInstanceFirstInstanceAnalysisScreenPresenter createPresenter() {
    return SecondInstanceFirstInstanceAnalysisScreenPresenter(
      intakeService: intakeService,
      storageService: storageService,
      fileStorageDriver: fileStorageDriver,
      documentPickerDriver: documentPickerDriver,
      analysisId: 'analysis-1',
    );
  }

  group('SecondInstanceFirstInstanceAnalysisScreenPresenter', () {
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
  });
}
