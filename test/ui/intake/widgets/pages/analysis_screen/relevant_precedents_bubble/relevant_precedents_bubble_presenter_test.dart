import 'package:animus/core/intake/dtos/analysis_dto.dart';
import 'package:animus/core/intake/dtos/analysis_precedent_dto.dart';
import 'package:animus/core/intake/dtos/analysis_precedents_search_filters_dto.dart';
import 'package:animus/core/intake/dtos/analysis_status_dto.dart';
import 'package:animus/core/intake/dtos/court_dto.dart';
import 'package:animus/core/intake/dtos/precedent_kind_dto.dart';
import 'package:animus/core/intake/interfaces/intake_service.dart';
import 'package:animus/core/shared/responses/list_response.dart';
import 'package:animus/core/shared/responses/rest_response.dart';
import 'package:animus/ui/intake/widgets/pages/analysis_screen/relevant_precedents_bubble/relevant_precedents_bubble_presenter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../../fakers/intake/analysis_dto_faker.dart';
import '../../../../../../fakers/intake/analysis_precedent_dto_faker.dart';

class _MockIntakeService extends Mock implements IntakeService {}

void main() {
  late _MockIntakeService intakeService;

  setUpAll(() {
    dotenv.loadFromString(envString: 'PANGEA_URL=https://pangea.example.com');
    registerFallbackValue(
      const AnalysisPrecedentsSearchFiltersDto(
        courts: <CourtDto>[],
        precedentKinds: <PrecedentKindDto>[],
        limit: RelevantPrecedentsBubblePresenter.defaultLimit,
      ),
    );
  });

  setUp(() {
    intakeService = _MockIntakeService();
  });

  RelevantPrecedentsBubblePresenter createPresenter() {
    return RelevantPrecedentsBubblePresenter(
      intakeService: intakeService,
      analysisId: 'analysis-1',
    );
  }

  group('RelevantPrecedentsBubblePresenter', () {
    test(
      'should trigger search on initialize when status is petitionAnalyzed',
      () async {
        final RelevantPrecedentsBubblePresenter presenter = createPresenter();
        addTearDown(presenter.dispose);

        when(
          () => intakeService.getAnalysis(analysisId: 'analysis-1'),
        ).thenAnswer(
          (_) async => RestResponse<AnalysisDto>(
            statusCode: 200,
            body: AnalysisDtoFaker.fake(
              status: AnalysisStatusDto.petitionAnalyzed,
            ),
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

    test(
      'should not trigger search again on reentry when status is already waiting choice',
      () async {
        final RelevantPrecedentsBubblePresenter presenter = createPresenter();
        addTearDown(presenter.dispose);
        final precedents = <AnalysisPrecedentDto>[
          AnalysisPrecedentDtoFaker.fake(applicabilityPercentage: 72),
        ];

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
            body: ListResponse<AnalysisPrecedentDto>(items: precedents),
          ),
        );

        await presenter.initialize();

        verifyNever(
          () => intakeService.searchAnalysisPrecedents(
            analysisId: any(named: 'analysisId'),
            filters: any(named: 'filters'),
          ),
        );
        verify(
          () => intakeService.listAnalysisPrecedents(analysisId: 'analysis-1'),
        ).called(1);
      },
    );

    test(
      'should order precedents by applicability desc and select chosen precedent',
      () async {
        final RelevantPrecedentsBubblePresenter presenter = createPresenter();
        addTearDown(presenter.dispose);
        final lower = AnalysisPrecedentDtoFaker.fake(
          applicabilityPercentage: 65,
          precedent: PrecedentDtoFaker.fake(
            identifier: PrecedentIdentifierDtoFaker.fake(number: 1),
          ),
        );
        final chosen = AnalysisPrecedentDtoFaker.fake(
          isChosen: true,
          applicabilityPercentage: 88,
          precedent: PrecedentDtoFaker.fake(
            identifier: PrecedentIdentifierDtoFaker.fake(number: 2),
          ),
        );
        final highest = AnalysisPrecedentDtoFaker.fake(
          applicabilityPercentage: 97,
          precedent: PrecedentDtoFaker.fake(
            identifier: PrecedentIdentifierDtoFaker.fake(number: 3),
          ),
        );

        when(
          () => intakeService.listAnalysisPrecedents(analysisId: 'analysis-1'),
        ).thenAnswer(
          (_) async => RestResponse<ListResponse<AnalysisPrecedentDto>>(
            statusCode: 200,
            body: ListResponse<AnalysisPrecedentDto>(
              items: <AnalysisPrecedentDto>[lower, chosen, highest],
            ),
          ),
        );

        presenter.processingStatus.value =
            AnalysisStatusDto.waitingPrecedentChoice;
        await presenter.loadPrecedents();

        expect(
          presenter.precedents.value.map(
            (item) => item.applicabilityPercentage,
          ),
          <double>[97, 88, 65],
        );
        expect(
          presenter.selectedPrecedent.value?.precedent.identifier.number,
          2,
        );
        expect(
          presenter.processingStatus.value,
          AnalysisStatusDto.precedentChosen,
        );
      },
    );

    test(
      'should mark selected precedent locally when confirmation succeeds',
      () async {
        final RelevantPrecedentsBubblePresenter presenter = createPresenter();
        addTearDown(presenter.dispose);
        final first = AnalysisPrecedentDtoFaker.fake(
          precedent: PrecedentDtoFaker.fake(
            identifier: PrecedentIdentifierDtoFaker.fake(number: 1),
          ),
        );
        final target = AnalysisPrecedentDtoFaker.fake(
          precedent: PrecedentDtoFaker.fake(
            identifier: PrecedentIdentifierDtoFaker.fake(number: 2),
          ),
        );
        presenter.precedents.value = <AnalysisPrecedentDto>[first, target];
        presenter.choosePrecedent(target);

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

        final bool result = await presenter.confirmPrecedentChoice();

        expect(result, isTrue);
        expect(presenter.selectedPrecedent.value?.isChosen, isTrue);
        expect(presenter.precedents.value.first.isChosen, isFalse);
        expect(presenter.precedents.value.last.isChosen, isTrue);
        expect(presenter.generalError.value, isNull);
      },
    );

    test(
      'should keep recoverable error when precedent confirmation fails',
      () async {
        final RelevantPrecedentsBubblePresenter presenter = createPresenter();
        addTearDown(presenter.dispose);
        final target = AnalysisPrecedentDtoFaker.fake();
        presenter.precedents.value = <AnalysisPrecedentDto>[target];
        presenter.choosePrecedent(target);

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

        final bool result = await presenter.confirmPrecedentChoice();

        expect(result, isFalse);
        expect(
          presenter.generalError.value,
          'Nao foi possivel escolher o precedente agora. Tente novamente.',
        );
        expect(presenter.selectedPrecedent.value?.isChosen, isFalse);
        expect(presenter.isLoading.value, isFalse);
      },
    );

    test('should build pangea uri correctly', () {
      final RelevantPrecedentsBubblePresenter presenter = createPresenter();
      addTearDown(presenter.dispose);

      final uri = presenter.buildPangeaUri(
        PrecedentIdentifierDtoFaker.fake(number: 0),
      );

      expect(
        uri.toString(),
        'https://pangea.example.com/pesquisa?orgao=trt7&tipo=NT&nr=0',
      );
    });

    test('should clear state and restart flow on retry', () async {
      final RelevantPrecedentsBubblePresenter presenter = createPresenter();
      addTearDown(presenter.dispose);
      presenter.precedents.value = <AnalysisPrecedentDto>[
        AnalysisPrecedentDtoFaker.fake(),
      ];
      presenter.selectedPrecedent.value = AnalysisPrecedentDtoFaker.fake();
      presenter.generalError.value = 'Erro anterior';

      when(
        () => intakeService.searchAnalysisPrecedents(
          analysisId: 'analysis-1',
          filters: any(named: 'filters'),
        ),
      ).thenAnswer((_) async => RestResponse<void>(statusCode: 202));

      await presenter.retry();

      expect(presenter.precedents.value, isEmpty);
      expect(presenter.selectedPrecedent.value, isNull);
      expect(presenter.generalError.value, isNull);
      expect(
        presenter.processingStatus.value,
        AnalysisStatusDto.searchingPrecedents,
      );
      expect(presenter.isLoading.value, isTrue);
      verify(
        () => intakeService.searchAnalysisPrecedents(
          analysisId: 'analysis-1',
          filters: any(named: 'filters'),
        ),
      ).called(1);
    });
  });
}
