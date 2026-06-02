import 'dart:io';

import 'package:animus/core/intake/dtos/court_dto.dart';
import 'package:animus/core/intake/dtos/precedent_kind_dto.dart';
import 'package:animus/core/intake/interfaces/intake_service.dart';
import 'package:animus/core/shared/responses/rest_response.dart';
import 'package:animus/ui/intake/widgets/components/analysis_precedents_bubble/add_precedent_dialog/add_precedent_dialog_presenter.dart';
import 'package:animus/ui/intake/widgets/components/analysis_precedents_bubble/analysis_precedents_bubble_presenter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../../fakers/intake/analysis_precedent_dto_faker.dart';

class _MockIntakeService extends Mock implements IntakeService {}

class _MockAnalysisPrecedentsBubblePresenter extends Mock
    implements AnalysisPrecedentsBubblePresenter {}

void main() {
  late _MockIntakeService intakeService;
  late _MockAnalysisPrecedentsBubblePresenter bubblePresenter;

  setUpAll(() {
    registerFallbackValue(PrecedentIdentifierDtoFaker.fake());
  });

  setUp(() {
    intakeService = _MockIntakeService();
    bubblePresenter = _MockAnalysisPrecedentsBubblePresenter();
    when(() => bubblePresenter.reloadPrecedents()).thenAnswer((_) async {});
  });

  AddPrecedentDialogPresenter createPresenter() {
    return AddPrecedentDialogPresenter(
      intakeService: intakeService,
      bubblePresenter: bubblePresenter,
      analysisId: 'analysis-1',
    );
  }

  Future<void> fillValidIdentifier(
    AddPrecedentDialogPresenter presenter,
  ) async {
    presenter.courtControl.value = CourtDto.stf;
    presenter.kindControl.value = PrecedentKindDto.sum;
    presenter.numberControl.value = '123';
    await Future<void>.delayed(Duration.zero);
  }

  group('AddPrecedentDialogPresenter', () {
    test('should fetch preview successfully', () async {
      final presenter = createPresenter();
      addTearDown(presenter.dispose);
      final preview = PrecedentDtoFaker.fake();
      await fillValidIdentifier(presenter);

      when(
        () => intakeService.getPrecedent(identifier: any(named: 'identifier')),
      ).thenAnswer((_) async => RestResponse(statusCode: 200, body: preview));

      await presenter.fetchPreview();

      expect(presenter.previewPrecedent.value, same(preview));
      expect(presenter.generalError.value, isNull);
      expect(presenter.canSubmit.value, isTrue);
    });

    test('should show not found error when preview returns 404', () async {
      final presenter = createPresenter();
      addTearDown(presenter.dispose);
      await fillValidIdentifier(presenter);

      when(
        () => intakeService.getPrecedent(identifier: any(named: 'identifier')),
      ).thenAnswer(
        (_) async => RestResponse(
          statusCode: HttpStatus.notFound,
          errorMessage: 'Nao encontrado',
        ),
      );

      await presenter.fetchPreview();

      expect(presenter.previewPrecedent.value, isNull);
      expect(presenter.generalError.value, 'Precedente não encontrado.');
      expect(presenter.canSubmit.value, isFalse);
    });

    test(
      'should keep fields and show generic error when preview fails',
      () async {
        final presenter = createPresenter();
        addTearDown(presenter.dispose);
        await fillValidIdentifier(presenter);

        when(
          () =>
              intakeService.getPrecedent(identifier: any(named: 'identifier')),
        ).thenAnswer(
          (_) async => RestResponse(statusCode: 500, errorMessage: 'Falha'),
        );

        await presenter.fetchPreview();

        expect(presenter.courtControl.value, CourtDto.stf);
        expect(presenter.kindControl.value, PrecedentKindDto.sum);
        expect(presenter.numberControl.value, '123');
        expect(
          presenter.generalError.value,
          'Não foi possivel buscar o precedente agora. Verifique o identificador e tente novamente.',
        );
      },
    );

    test('should submit successfully and reload bubble precedents', () async {
      final presenter = createPresenter();
      addTearDown(presenter.dispose);
      await fillValidIdentifier(presenter);
      presenter.previewPrecedent.value = PrecedentDtoFaker.fake();

      when(
        () => intakeService.addAnalysisPrecedent(
          analysisId: 'analysis-1',
          identifier: any(named: 'identifier'),
        ),
      ).thenAnswer(
        (_) async => RestResponse(
          statusCode: 200,
          body: AnalysisPrecedentDtoFaker.fake(isManuallyAdded: true),
        ),
      );

      final result = await presenter.submit();

      expect(result, isTrue);
      expect(presenter.generalError.value, isNull);
      verify(() => bubblePresenter.reloadPrecedents()).called(1);
    });

    test('should preserve preview and fields when submit fails', () async {
      final presenter = createPresenter();
      addTearDown(presenter.dispose);
      final preview = PrecedentDtoFaker.fake();
      await fillValidIdentifier(presenter);
      presenter.previewPrecedent.value = preview;

      when(
        () => intakeService.addAnalysisPrecedent(
          analysisId: 'analysis-1',
          identifier: any(named: 'identifier'),
        ),
      ).thenAnswer(
        (_) async => RestResponse(statusCode: 500, errorMessage: 'Falha'),
      );

      final result = await presenter.submit();

      expect(result, isFalse);
      expect(presenter.previewPrecedent.value, same(preview));
      expect(presenter.numberControl.value, '123');
      expect(
        presenter.generalError.value,
        'Não foi possivel adicionar o precedente agora. Tente novamente.',
      );
      verifyNever(() => bubblePresenter.reloadPrecedents());
    });

    test('should invalidate preview when identifier changes', () async {
      final presenter = createPresenter();
      addTearDown(presenter.dispose);
      presenter.previewPrecedent.value = PrecedentDtoFaker.fake();
      presenter.generalError.value = 'Erro';

      presenter.numberControl.value = '999';
      await Future<void>.delayed(Duration.zero);

      expect(presenter.previewPrecedent.value, isNull);
      expect(presenter.generalError.value, isNull);
    });

    test('should clear invalid kind when court changes', () async {
      final presenter = createPresenter();
      addTearDown(presenter.dispose);

      presenter.courtControl.value = CourtDto.stf;
      presenter.kindControl.value = PrecedentKindDto.adi;
      await Future<void>.delayed(Duration.zero);

      presenter.courtControl.value = CourtDto.trfs6;
      await Future<void>.delayed(Duration.zero);

      expect(presenter.kindControl.value, isNull);
      expect(
        presenter.supportedKindsForSelectedCourt.value,
        contains(PrecedentKindDto.irdr),
      );
      expect(
        presenter.supportedKindsForSelectedCourt.value,
        isNot(contains(PrecedentKindDto.adi)),
      );
    });
  });
}
