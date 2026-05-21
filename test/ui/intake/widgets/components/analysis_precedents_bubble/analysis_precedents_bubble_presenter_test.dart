import 'package:animus/core/intake/dtos/analysis_dto.dart';
import 'package:animus/core/intake/dtos/analysis_precedent_dto.dart';
import 'package:animus/core/intake/dtos/analysis_precedents_search_filters_dto.dart';
import 'package:animus/core/intake/dtos/analysis_status_dto.dart';
import 'package:animus/core/intake/dtos/court_dto.dart';
import 'package:animus/core/intake/dtos/precedent_kind_dto.dart';
import 'package:animus/core/intake/interfaces/intake_service.dart';
import 'package:animus/core/shared/responses/list_response.dart';
import 'package:animus/core/shared/responses/rest_response.dart';
import 'package:animus/ui/intake/widgets/components/analysis_precedents_bubble/analysis_precedents_bubble_presenter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../fakers/intake/analysis_dto_faker.dart';
import '../../../../../fakers/intake/analysis_precedent_dto_faker.dart';

class _MockIntakeService extends Mock implements IntakeService {}

void main() {
  late _MockIntakeService intakeService;

  setUpAll(() {
    dotenv.loadFromString(envString: 'PANGEA_URL=https://pangea.example.com');
    registerFallbackValue(
      const AnalysisPrecedentsSearchFiltersDto(
        courts: <CourtDto>[],
        precedentKinds: <PrecedentKindDto>[],
        limit: AnalysisPrecedentsBubblePresenter.defaultLimit,
      ),
    );
    registerFallbackValue(PrecedentIdentifierDtoFaker.fake());
  });

  setUp(() {
    intakeService = _MockIntakeService();
  });

  AnalysisPrecedentsBubblePresenter createPresenter() {
    return AnalysisPrecedentsBubblePresenter(
      intakeService: intakeService,
      analysisId: 'analysis-1',
    );
  }

  group('AnalysisPrecedentsBubblePresenter', () {
    test(
      'should trigger search on initialize when status is caseAnalyzed',
      () async {
        final presenter = createPresenter();
        addTearDown(presenter.dispose);

        when(
          () => intakeService.getAnalysis(analysisId: 'analysis-1'),
        ).thenAnswer(
          (_) async => RestResponse<AnalysisDto>(
            statusCode: 200,
            body: AnalysisDtoFaker.fake(status: AnalysisStatusDto.caseAnalyzed),
          ),
        );
        when(
          () => intakeService.searchAnalysisPrecedents(
            analysisId: 'analysis-1',
            filters: any(named: 'filters'),
          ),
        ).thenAnswer((_) async => RestResponse<void>(statusCode: 202));

        await presenter.initialize();

        expect(
          presenter.processingStatus.value,
          AnalysisStatusDto.searchingPrecedents,
        );
        expect(presenter.isLoading.value, isTrue);
        verify(
          () => intakeService.getAnalysis(analysisId: 'analysis-1'),
        ).called(1);
        verify(
          () => intakeService.searchAnalysisPrecedents(
            analysisId: 'analysis-1',
            filters: any(named: 'filters'),
          ),
        ).called(1);
      },
    );

    test('should rebuild chosen precedents from list on reentry', () async {
      final presenter = createPresenter();
      addTearDown(presenter.dispose);
      final firstChosen = AnalysisPrecedentDtoFaker.fake(
        isChosen: true,
        precedent: PrecedentDtoFaker.fake(
          identifier: PrecedentIdentifierDtoFaker.fake(number: 1),
        ),
      );
      final secondChosen = AnalysisPrecedentDtoFaker.fake(
        isChosen: true,
        precedent: PrecedentDtoFaker.fake(
          identifier: PrecedentIdentifierDtoFaker.fake(number: 2),
        ),
      );
      final notChosen = AnalysisPrecedentDtoFaker.fake(
        isChosen: false,
        precedent: PrecedentDtoFaker.fake(
          identifier: PrecedentIdentifierDtoFaker.fake(number: 3),
        ),
      );

      when(
        () => intakeService.getAnalysis(analysisId: 'analysis-1'),
      ).thenAnswer(
        (_) async => RestResponse<AnalysisDto>(
          statusCode: 200,
          body: AnalysisDtoFaker.fake(
            status: AnalysisStatusDto.waitingPrecedentChoice,
          ),
        ),
      );
      when(
        () => intakeService.listAnalysisPrecedents(analysisId: 'analysis-1'),
      ).thenAnswer(
        (_) async => RestResponse<ListResponse<AnalysisPrecedentDto>>(
          statusCode: 200,
          body: ListResponse<AnalysisPrecedentDto>(
            items: <AnalysisPrecedentDto>[notChosen, secondChosen, firstChosen],
          ),
        ),
      );

      await presenter.initialize();

      expect(presenter.chosenPrecedents.value.length, 2);
      expect(
        presenter.chosenPrecedents.value.map(
          (AnalysisPrecedentDto item) => item.precedent.identifier.number,
        ),
        <int>[2, 1],
      );
      expect(presenter.hasChosenPrecedents.value, isTrue);
      expect(presenter.focusedPrecedent.value, isNull);
    });

    test(
      'should keep chosen items when confirming another precedent',
      () async {
        final presenter = createPresenter();
        addTearDown(presenter.dispose);
        final alreadyChosen = AnalysisPrecedentDtoFaker.fake(
          isChosen: true,
          precedent: PrecedentDtoFaker.fake(
            identifier: PrecedentIdentifierDtoFaker.fake(number: 1),
          ),
        );
        final target = AnalysisPrecedentDtoFaker.fake(
          isChosen: false,
          precedent: PrecedentDtoFaker.fake(
            identifier: PrecedentIdentifierDtoFaker.fake(number: 2),
          ),
        );
        presenter.precedents.value = <AnalysisPrecedentDto>[
          alreadyChosen,
          target,
        ];
        presenter.focusPrecedent(target);

        when(
          () => intakeService.chooseAnalysisPrecedent(
            analysisId: 'analysis-1',
            identifier: target.precedent.identifier,
          ),
        ).thenAnswer(
          (_) async => RestResponse<AnalysisStatusDto>(
            statusCode: 200,
            body: AnalysisStatusDto.precedentChosen,
          ),
        );

        final result = await presenter.confirmPrecedentChoice();

        expect(result, isTrue);
        expect(presenter.chosenPrecedents.value.length, 2);
        expect(
          presenter.chosenPrecedents.value.map(
            (AnalysisPrecedentDto item) => item.precedent.identifier.number,
          ),
          <int>[1, 2],
        );
        expect(presenter.focusedPrecedent.value?.isChosen, isTrue);
        expect(presenter.generalError.value, isNull);
      },
    );

    test('should preserve state when choosing precedent fails', () async {
      final presenter = createPresenter();
      addTearDown(presenter.dispose);
      final chosen = AnalysisPrecedentDtoFaker.fake(
        isChosen: true,
        precedent: PrecedentDtoFaker.fake(
          identifier: PrecedentIdentifierDtoFaker.fake(number: 1),
        ),
      );
      final target = AnalysisPrecedentDtoFaker.fake(
        precedent: PrecedentDtoFaker.fake(
          identifier: PrecedentIdentifierDtoFaker.fake(number: 2),
        ),
      );
      presenter.precedents.value = <AnalysisPrecedentDto>[chosen, target];
      presenter.focusPrecedent(target);

      when(
        () => intakeService.chooseAnalysisPrecedent(
          analysisId: 'analysis-1',
          identifier: target.precedent.identifier,
        ),
      ).thenAnswer(
        (_) async => RestResponse<AnalysisStatusDto>(
          statusCode: 500,
          errorMessage: 'Falha',
        ),
      );

      final result = await presenter.confirmPrecedentChoice();

      expect(result, isFalse);
      expect(presenter.chosenPrecedents.value.length, 1);
      expect(
        presenter.chosenPrecedents.value.single.precedent.identifier.number,
        1,
      );
      expect(presenter.focusedPrecedent.value?.precedent.identifier.number, 2);
      expect(
        presenter.generalError.value,
        'Não foi possível escolher o precedente agora. Tente novamente.',
      );
    });

    test('should unchoose only the targeted precedent', () async {
      final presenter = createPresenter();
      addTearDown(presenter.dispose);
      final target = AnalysisPrecedentDtoFaker.fake(
        isChosen: true,
        precedent: PrecedentDtoFaker.fake(
          identifier: PrecedentIdentifierDtoFaker.fake(number: 1),
        ),
      );
      final stillChosen = AnalysisPrecedentDtoFaker.fake(
        isChosen: true,
        precedent: PrecedentDtoFaker.fake(
          identifier: PrecedentIdentifierDtoFaker.fake(number: 2),
        ),
      );
      presenter.precedents.value = <AnalysisPrecedentDto>[target, stillChosen];
      presenter.focusPrecedent(target);

      when(
        () => intakeService.unchooseAnalysisPrecedent(
          analysisId: 'analysis-1',
          identifier: target.precedent.identifier,
        ),
      ).thenAnswer(
        (_) async => RestResponse<AnalysisStatusDto>(
          statusCode: 200,
          body: AnalysisStatusDto.waitingPrecedentChoice,
        ),
      );

      final result = await presenter.unchoosePrecedent(target);

      expect(result, isTrue);
      expect(presenter.precedents.value.first.isChosen, isFalse);
      expect(presenter.precedents.value.last.isChosen, isTrue);
      expect(presenter.focusedPrecedent.value?.isChosen, isFalse);
      expect(presenter.chosenPrecedents.value.length, 1);
      expect(
        presenter.chosenPrecedents.value.single.precedent.identifier.number,
        2,
      );
    });

    test('should preserve state when unchoose fails', () async {
      final presenter = createPresenter();
      addTearDown(presenter.dispose);
      final target = AnalysisPrecedentDtoFaker.fake(isChosen: true);
      presenter.precedents.value = <AnalysisPrecedentDto>[target];
      presenter.focusPrecedent(target);

      when(
        () => intakeService.unchooseAnalysisPrecedent(
          analysisId: 'analysis-1',
          identifier: target.precedent.identifier,
        ),
      ).thenAnswer(
        (_) async => RestResponse<AnalysisStatusDto>(
          statusCode: 500,
          errorMessage: 'Falha',
        ),
      );

      final result = await presenter.unchoosePrecedent(target);

      expect(result, isFalse);
      expect(presenter.precedents.value.single.isChosen, isTrue);
      expect(presenter.focusedPrecedent.value?.isChosen, isTrue);
      expect(
        presenter.generalError.value,
        'Não foi possível desfazer a escolha do precedente agora. Tente novamente.',
      );
    });

    test(
      'should clear transient state on retry and keep filters state intact',
      () async {
        final presenter = createPresenter();
        addTearDown(presenter.dispose);
        presenter.precedents.value = <AnalysisPrecedentDto>[
          AnalysisPrecedentDtoFaker.fake(isChosen: true),
        ];
        presenter.focusedPrecedent.value = AnalysisPrecedentDtoFaker.fake();
        presenter.generalError.value = 'Erro anterior';
        presenter.syncSelectedFilters(
          courts: const <CourtDto>[CourtDto.stf],
          kinds: const <PrecedentKindDto>[PrecedentKindDto.sum],
        );

        when(
          () => intakeService.searchAnalysisPrecedents(
            analysisId: 'analysis-1',
            filters: any(named: 'filters'),
          ),
        ).thenAnswer((_) async => RestResponse<void>(statusCode: 202));

        await presenter.retry();

        expect(presenter.precedents.value, isEmpty);
        expect(presenter.focusedPrecedent.value, isNull);
        expect(presenter.generalError.value, isNull);
        expect(presenter.selectedCourts.value, const <CourtDto>[CourtDto.stf]);
        expect(presenter.selectedKinds.value, const <PrecedentKindDto>[
          PrecedentKindDto.sum,
        ]);
      },
    );

    test(
      'should reload precedents preserving manual flag and chosen state from api',
      () async {
        final presenter = createPresenter();
        addTearDown(presenter.dispose);
        final precedent = AnalysisPrecedentDtoFaker.fake(
          isChosen: true,
          isManuallyAdded: true,
        );

        when(
          () => intakeService.listAnalysisPrecedents(analysisId: 'analysis-1'),
        ).thenAnswer(
          (_) async => RestResponse<ListResponse<AnalysisPrecedentDto>>(
            statusCode: 200,
            body: ListResponse<AnalysisPrecedentDto>(
              items: <AnalysisPrecedentDto>[precedent],
            ),
          ),
        );

        presenter.processingStatus.value =
            AnalysisStatusDto.waitingPrecedentChoice;
        await presenter.reloadPrecedents();

        expect(presenter.precedents.value.single.isManuallyAdded, isTrue);
        expect(presenter.chosenPrecedents.value.single.isChosen, isTrue);
      },
    );

    test('should build pangea uri correctly', () {
      final presenter = createPresenter();
      addTearDown(presenter.dispose);

      final uri = presenter.buildPangeaUri(
        PrecedentIdentifierDtoFaker.fake(number: 0),
      );

      expect(
        uri.toString(),
        'https://pangea.example.com/pesquisa?orgao=trt7&tipo=NT&nr=0',
      );
    });
  });
}
