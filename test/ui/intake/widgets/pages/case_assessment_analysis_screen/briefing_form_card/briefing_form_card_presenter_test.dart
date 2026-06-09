import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:animus/core/intake/dtos/case_assessment_briefing_dto.dart';
import 'package:animus/core/intake/dtos/court_dto.dart';
import 'package:animus/core/intake/dtos/legal_area_dto.dart';
import 'package:animus/core/intake/interfaces/intake_service.dart';
import 'package:animus/core/shared/responses/rest_response.dart';
import 'package:animus/ui/intake/widgets/pages/case_assessment_analysis_screen/briefing_form_card/briefing_form_card_presenter.dart';

import '../../../../../../fakers/intake/case_assessment_briefing_dto_faker.dart';

class _MockIntakeService extends Mock implements IntakeService {}

void main() {
  late _MockIntakeService intakeService;

  setUpAll(() {
    registerFallbackValue(CaseAssessmentBriefingDtoFaker.fake());
  });

  setUp(() {
    intakeService = _MockIntakeService();
  });

  BriefingFormCardPresenter createPresenter() {
    return BriefingFormCardPresenter(
      intakeService: intakeService,
      analysisId: 'analysis-1',
    );
  }

  group('BriefingFormCardPresenter', () {
    test('should load briefing and fill form when service succeeds', () async {
      final presenter = createPresenter();
      addTearDown(presenter.dispose);
      final briefing = CaseAssessmentBriefingDtoFaker.fake();

      when(
        () => intakeService.getCaseAssessmentBriefing(analysisId: 'analysis-1'),
      ).thenAnswer((_) async => RestResponse(statusCode: 200, body: briefing));

      await presenter.load();

      expect(presenter.briefing.value, same(briefing));
      expect(presenter.legalAreaControl.value, briefing.legalArea);
      expect(
        presenter.courtJurisdictionControl.value,
        briefing.courtJurisdiction,
      );
      expect(presenter.mainClaimsControl.value, briefing.mainClaims);
      expect(presenter.intendedThesisControl.value, briefing.intendedThesis);
      expect(presenter.isReadOnly.value, isTrue);
      expect(presenter.generalError.value, isNull);
    });

    test(
      'should ignore missing briefing when service returns not found',
      () async {
        final presenter = createPresenter();
        addTearDown(presenter.dispose);

        when(
          () =>
              intakeService.getCaseAssessmentBriefing(analysisId: 'analysis-1'),
        ).thenAnswer(
          (_) async => RestResponse(
            statusCode: HttpStatus.notFound,
            errorMessage: 'Nao encontrado',
          ),
        );

        await presenter.load();

        expect(presenter.briefing.value, isNull);
        expect(presenter.generalError.value, isNull);
        expect(presenter.isReadOnly.value, isFalse);
      },
    );

    test(
      'should mark controls as touched when submit is attempted invalid',
      () async {
        final presenter = createPresenter();
        addTearDown(presenter.dispose);

        final result = await presenter.submitBriefing();

        expect(result, isNull);
        expect(presenter.legalAreaControl.touched, isTrue);
        expect(presenter.courtJurisdictionControl.touched, isTrue);
        expect(presenter.mainClaimsControl.touched, isTrue);
        expect(presenter.intendedThesisControl.touched, isTrue);
        verifyNever(
          () => intakeService.submitCaseAssessmentBriefing(
            analysisId: any(named: 'analysisId'),
            briefing: any(named: 'briefing'),
          ),
        );
      },
    );

    test('should trim text fields and submit briefing successfully', () async {
      final presenter = createPresenter();
      addTearDown(presenter.dispose);
      final responseBriefing = CaseAssessmentBriefingDtoFaker.fake(
        mainClaims: 'Pedidos finais',
        intendedThesis: 'Tese final',
      );

      presenter.legalAreaControl.value = LegalAreaDto.civil;
      presenter.courtJurisdictionControl.value = CourtDto.tjsp;
      presenter.mainClaimsControl.value = '  Pedidos finais  ';
      presenter.intendedThesisControl.value = '  Tese final  ';
      await Future<void>.delayed(Duration.zero);

      when(
        () => intakeService.submitCaseAssessmentBriefing(
          analysisId: 'analysis-1',
          briefing: any(named: 'briefing'),
        ),
      ).thenAnswer(
        (_) async => RestResponse(statusCode: 200, body: responseBriefing),
      );

      final result = await presenter.submitBriefing();

      expect(result, same(responseBriefing));
      expect(presenter.briefing.value, same(responseBriefing));
      expect(presenter.isSubmitting.value, isFalse);
      expect(presenter.isReadOnly.value, isTrue);
      verify(
        () => intakeService.submitCaseAssessmentBriefing(
          analysisId: 'analysis-1',
          briefing: any(
            named: 'briefing',
            that: predicate(
              (value) =>
                  value is CaseAssessmentBriefingDto &&
                  value.mainClaims == 'Pedidos finais' &&
                  value.intendedThesis == 'Tese final',
            ),
          ),
        ),
      ).called(1);
    });

    test('should block whitespace-only required fields from DTO build', () {
      final presenter = createPresenter();
      addTearDown(presenter.dispose);

      presenter.legalAreaControl.value = LegalAreaDto.civil;
      presenter.courtJurisdictionControl.value = CourtDto.tjsp;
      presenter.mainClaimsControl.value = '   ';
      presenter.intendedThesisControl.value = '   ';

      expect(presenter.buildBriefingFromForm(), isNull);
      expect(presenter.canSubmit.value, isFalse);
    });

    test('should expose submit error when service fails', () async {
      final presenter = createPresenter();
      addTearDown(presenter.dispose);

      presenter.legalAreaControl.value = LegalAreaDto.civil;
      presenter.courtJurisdictionControl.value = CourtDto.tjsp;
      presenter.mainClaimsControl.value = 'Pedidos';
      presenter.intendedThesisControl.value = 'Tese';
      await Future<void>.delayed(Duration.zero);

      when(
        () => intakeService.submitCaseAssessmentBriefing(
          analysisId: 'analysis-1',
          briefing: any(named: 'briefing'),
        ),
      ).thenAnswer(
        (_) async =>
            RestResponse(statusCode: 500, errorMessage: 'Falha ao salvar'),
      );

      final result = await presenter.submitBriefing();

      expect(result, isNull);
      expect(presenter.generalError.value, 'Falha ao salvar');
      expect(presenter.isSubmitting.value, isFalse);
    });
  });
}
