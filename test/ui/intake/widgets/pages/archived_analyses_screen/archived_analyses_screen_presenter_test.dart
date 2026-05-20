import 'package:animus/constants/routes.dart';
import 'package:animus/core/intake/dtos/analysis_dto.dart';
import 'package:animus/core/intake/dtos/analysis_type_dto.dart';
import 'package:animus/core/intake/interfaces/intake_service.dart';
import 'package:animus/core/shared/interfaces/navigation_driver.dart';
import 'package:animus/core/shared/responses/cursor_pagination_response.dart';
import 'package:animus/core/shared/responses/rest_response.dart';
import 'package:animus/ui/intake/widgets/pages/archived_analyses_screen/archived_analyses_screen_presenter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../fakers/intake/analysis_dto_faker.dart';

class _MockIntakeService extends Mock implements IntakeService {}

class _MockNavigationDriver extends Mock implements NavigationDriver {}

void main() {
  late _MockIntakeService intakeService;
  late _MockNavigationDriver navigationDriver;

  setUp(() {
    intakeService = _MockIntakeService();
    navigationDriver = _MockNavigationDriver();

    when(() => navigationDriver.canGoBack()).thenReturn(true);
    when(() => navigationDriver.goBack()).thenReturn(null);
    when(() => navigationDriver.goTo(any())).thenReturn(null);
    when(() => navigationDriver.pushTo(any())).thenAnswer((_) async {});
  });

  ArchivedAnalysesScreenPresenter createPresenter({
    Duration searchDebounce = Duration.zero,
  }) {
    return ArchivedAnalysesScreenPresenter(
      intakeService: intakeService,
      navigationDriver: navigationDriver,
      searchDebounce: searchDebounce,
    );
  }

  group('initialize', () {
    test('carrega a primeira pagina e popula os signals', () async {
      final ArchivedAnalysesScreenPresenter presenter = createPresenter();
      addTearDown(presenter.dispose);

      final List<AnalysisDto> items = <AnalysisDto>[
        AnalysisDtoFaker.fake(id: 'a-1', name: 'Analise 1', isArchived: true),
        AnalysisDtoFaker.fake(id: 'a-2', name: 'Analise 2', isArchived: true),
      ];

      when(
        () => intakeService.listAnalyses(
          limit: any(named: 'limit'),
          isArchived: any(named: 'isArchived'),
          cursor: any(named: 'cursor'),
          search: any(named: 'search'),
        ),
      ).thenAnswer(
        (_) async => RestResponse<CursorPaginationResponse<AnalysisDto>>(
          statusCode: 200,
          body: CursorPaginationResponse<AnalysisDto>(
            items: items,
            nextCursor: 'cursor-2',
          ),
        ),
      );

      await presenter.initialize();

      expect(presenter.archivedAnalyses.value, items);
      expect(presenter.nextCursor.value, 'cursor-2');
      expect(presenter.hasMore.value, isTrue);
      expect(presenter.isLoadingInitialData.value, isFalse);
      expect(presenter.generalError.value, isNull);
      expect(presenter.showEmptyState.value, isFalse);
    });

    test('mantem estado de erro quando a carga falha', () async {
      final ArchivedAnalysesScreenPresenter presenter = createPresenter();
      addTearDown(presenter.dispose);

      when(
        () => intakeService.listAnalyses(
          limit: any(named: 'limit'),
          isArchived: any(named: 'isArchived'),
          cursor: any(named: 'cursor'),
          search: any(named: 'search'),
        ),
      ).thenAnswer(
        (_) async => RestResponse<CursorPaginationResponse<AnalysisDto>>(
          statusCode: 500,
          errorMessage: 'Falha de servidor',
        ),
      );

      await presenter.initialize();

      expect(presenter.archivedAnalyses.value, isEmpty);
      expect(presenter.generalError.value, 'Falha de servidor');
      expect(presenter.isLoadingInitialData.value, isFalse);
    });

    test('ignora chamadas repetidas apos sucesso', () async {
      final ArchivedAnalysesScreenPresenter presenter = createPresenter();
      addTearDown(presenter.dispose);

      when(
        () => intakeService.listAnalyses(
          limit: any(named: 'limit'),
          isArchived: any(named: 'isArchived'),
          cursor: any(named: 'cursor'),
          search: any(named: 'search'),
        ),
      ).thenAnswer(
        (_) async => RestResponse<CursorPaginationResponse<AnalysisDto>>(
          statusCode: 200,
          body: CursorPaginationResponse<AnalysisDto>(
            items: <AnalysisDto>[AnalysisDtoFaker.fake()],
            nextCursor: null,
          ),
        ),
      );

      await presenter.initialize();
      await presenter.initialize();

      verify(
        () => intakeService.listAnalyses(
          limit: any(named: 'limit'),
          isArchived: any(named: 'isArchived'),
          cursor: any(named: 'cursor'),
          search: any(named: 'search'),
        ),
      ).called(1);
    });
  });

  group('loadNextPage', () {
    test('append items e atualiza cursor quando ha proxima pagina', () async {
      final ArchivedAnalysesScreenPresenter presenter = createPresenter();
      addTearDown(presenter.dispose);

      final List<AnalysisDto> firstPage = <AnalysisDto>[
        AnalysisDtoFaker.fake(id: 'a-1'),
      ];
      final List<AnalysisDto> secondPage = <AnalysisDto>[
        AnalysisDtoFaker.fake(id: 'a-2'),
        AnalysisDtoFaker.fake(id: 'a-3'),
      ];

      int callCount = 0;
      when(
        () => intakeService.listAnalyses(
          limit: any(named: 'limit'),
          isArchived: any(named: 'isArchived'),
          cursor: any(named: 'cursor'),
          search: any(named: 'search'),
        ),
      ).thenAnswer((_) async {
        callCount += 1;
        if (callCount == 1) {
          return RestResponse<CursorPaginationResponse<AnalysisDto>>(
            statusCode: 200,
            body: CursorPaginationResponse<AnalysisDto>(
              items: firstPage,
              nextCursor: 'cursor-2',
            ),
          );
        }
        return RestResponse<CursorPaginationResponse<AnalysisDto>>(
          statusCode: 200,
          body: CursorPaginationResponse<AnalysisDto>(
            items: secondPage,
            nextCursor: null,
          ),
        );
      });

      await presenter.initialize();
      await presenter.loadNextPage();

      expect(presenter.archivedAnalyses.value.length, 3);
      expect(presenter.archivedAnalyses.value.last.id, 'a-3');
      expect(presenter.nextCursor.value, isNull);
      expect(presenter.hasMore.value, isFalse);
    });

    test(
      'marca paginationError em falha sem alterar lista carregada',
      () async {
        final ArchivedAnalysesScreenPresenter presenter = createPresenter();
        addTearDown(presenter.dispose);

        int callCount = 0;
        when(
          () => intakeService.listAnalyses(
            limit: any(named: 'limit'),
            isArchived: any(named: 'isArchived'),
            cursor: any(named: 'cursor'),
          ),
        ).thenAnswer((_) async {
          callCount += 1;
          if (callCount == 1) {
            return RestResponse<CursorPaginationResponse<AnalysisDto>>(
              statusCode: 200,
              body: CursorPaginationResponse<AnalysisDto>(
                items: <AnalysisDto>[AnalysisDtoFaker.fake(id: 'a-1')],
                nextCursor: 'cursor-2',
              ),
            );
          }
          return RestResponse<CursorPaginationResponse<AnalysisDto>>(
            statusCode: 500,
            errorMessage: 'Falha paginacao',
          );
        });

        await presenter.initialize();
        await presenter.loadNextPage();

        expect(presenter.archivedAnalyses.value.length, 1);
        expect(presenter.paginationError.value, 'Falha paginacao');
        expect(presenter.isLoadingMore.value, isFalse);
      },
    );
  });

  group('search', () {
    test(
      'refaz a busca no server quando a query muda e atualiza a lista',
      () async {
        final ArchivedAnalysesScreenPresenter presenter = createPresenter();
        addTearDown(presenter.dispose);

        final List<AnalysisDto> initial = <AnalysisDto>[
          AnalysisDtoFaker.fake(id: 'a-1', name: 'Habeas Corpus 2024'),
          AnalysisDtoFaker.fake(id: 'a-2', name: 'Mandado de Seguranca'),
          AnalysisDtoFaker.fake(id: 'a-3', name: 'Apelacao Civil'),
        ];
        final List<AnalysisDto> filtered = <AnalysisDto>[
          AnalysisDtoFaker.fake(id: 'a-1', name: 'Habeas Corpus 2024'),
        ];

        when(
          () => intakeService.listAnalyses(
            limit: any(named: 'limit'),
            isArchived: any(named: 'isArchived'),
            cursor: any(named: 'cursor'),
            search: '',
          ),
        ).thenAnswer(
          (_) async => RestResponse<CursorPaginationResponse<AnalysisDto>>(
            statusCode: 200,
            body: CursorPaginationResponse<AnalysisDto>(
              items: initial,
              nextCursor: null,
            ),
          ),
        );
        when(
          () => intakeService.listAnalyses(
            limit: any(named: 'limit'),
            isArchived: any(named: 'isArchived'),
            cursor: any(named: 'cursor'),
            search: 'HABEAS',
          ),
        ).thenAnswer(
          (_) async => RestResponse<CursorPaginationResponse<AnalysisDto>>(
            statusCode: 200,
            body: CursorPaginationResponse<AnalysisDto>(
              items: filtered,
              nextCursor: null,
            ),
          ),
        );

        await presenter.initialize();
        expect(presenter.archivedAnalyses.value.length, 3);

        presenter.updateSearchQuery('HABEAS');
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);

        expect(presenter.archivedAnalyses.value.length, 1);
        expect(presenter.archivedAnalyses.value.first.id, 'a-1');
        expect(presenter.showSearchEmptyState.value, isFalse);

        verify(
          () => intakeService.listAnalyses(
            limit: any(named: 'limit'),
            isArchived: any(named: 'isArchived'),
            cursor: any(named: 'cursor'),
            search: 'HABEAS',
          ),
        ).called(1);
      },
    );

    test(
      'mostra showSearchEmptyState quando o server retorna lista vazia',
      () async {
        final ArchivedAnalysesScreenPresenter presenter = createPresenter();
        addTearDown(presenter.dispose);

        when(
          () => intakeService.listAnalyses(
            limit: any(named: 'limit'),
            isArchived: any(named: 'isArchived'),
            cursor: any(named: 'cursor'),
            search: '',
          ),
        ).thenAnswer(
          (_) async => RestResponse<CursorPaginationResponse<AnalysisDto>>(
            statusCode: 200,
            body: CursorPaginationResponse<AnalysisDto>(
              items: <AnalysisDto>[AnalysisDtoFaker.fake(id: 'a-1')],
              nextCursor: null,
            ),
          ),
        );
        when(
          () => intakeService.listAnalyses(
            limit: any(named: 'limit'),
            isArchived: any(named: 'isArchived'),
            cursor: any(named: 'cursor'),
            search: 'inexistente',
          ),
        ).thenAnswer(
          (_) async => RestResponse<CursorPaginationResponse<AnalysisDto>>(
            statusCode: 200,
            body: CursorPaginationResponse<AnalysisDto>(
              items: const <AnalysisDto>[],
              nextCursor: null,
            ),
          ),
        );

        await presenter.initialize();
        presenter.updateSearchQuery('inexistente');
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);

        expect(presenter.archivedAnalyses.value, isEmpty);
        expect(presenter.showSearchEmptyState.value, isTrue);
        expect(presenter.showEmptyState.value, isFalse);
      },
    );

    test('clearSearch dispara nova busca sem search', () async {
      final ArchivedAnalysesScreenPresenter presenter = createPresenter();
      addTearDown(presenter.dispose);

      when(
        () => intakeService.listAnalyses(
          limit: any(named: 'limit'),
          isArchived: any(named: 'isArchived'),
          cursor: any(named: 'cursor'),
          search: '',
        ),
      ).thenAnswer(
        (_) async => RestResponse<CursorPaginationResponse<AnalysisDto>>(
          statusCode: 200,
          body: CursorPaginationResponse<AnalysisDto>(
            items: <AnalysisDto>[AnalysisDtoFaker.fake(id: 'a-1')],
            nextCursor: null,
          ),
        ),
      );
      when(
        () => intakeService.listAnalyses(
          limit: any(named: 'limit'),
          isArchived: any(named: 'isArchived'),
          cursor: any(named: 'cursor'),
          search: 'habeas',
        ),
      ).thenAnswer(
        (_) async => RestResponse<CursorPaginationResponse<AnalysisDto>>(
          statusCode: 200,
          body: CursorPaginationResponse<AnalysisDto>(
            items: const <AnalysisDto>[],
            nextCursor: null,
          ),
        ),
      );

      await presenter.initialize();
      presenter.updateSearchQuery('habeas');
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(presenter.archivedAnalyses.value, isEmpty);

      presenter.clearSearch();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(presenter.archivedAnalyses.value.length, 1);

      verify(
        () => intakeService.listAnalyses(
          limit: any(named: 'limit'),
          isArchived: any(named: 'isArchived'),
          cursor: any(named: 'cursor'),
          search: '',
        ),
      ).called(2);
    });
  });

  group('unarchive', () {
    test('remove o item da lista em sucesso e retorna true', () async {
      final ArchivedAnalysesScreenPresenter presenter = createPresenter();
      addTearDown(presenter.dispose);

      final AnalysisDto target = AnalysisDtoFaker.fake(
        id: 'a-1',
        name: 'Analise',
      );
      final AnalysisDto other = AnalysisDtoFaker.fake(id: 'a-2');

      when(
        () => intakeService.listAnalyses(
          limit: any(named: 'limit'),
          isArchived: any(named: 'isArchived'),
          cursor: any(named: 'cursor'),
          search: any(named: 'search'),
        ),
      ).thenAnswer(
        (_) async => RestResponse<CursorPaginationResponse<AnalysisDto>>(
          statusCode: 200,
          body: CursorPaginationResponse<AnalysisDto>(
            items: <AnalysisDto>[target, other],
            nextCursor: null,
          ),
        ),
      );
      when(() => intakeService.unarchiveAnalysis(analysisId: 'a-1')).thenAnswer(
        (_) async => RestResponse<AnalysisDto>(statusCode: 200, body: target),
      );

      await presenter.initialize();
      final bool result = await presenter.unarchive(target);

      expect(result, isTrue);
      expect(presenter.archivedAnalyses.value.length, 1);
      expect(presenter.archivedAnalyses.value.first.id, 'a-2');
      expect(presenter.isUnarchiving.value, isFalse);
      expect(presenter.unarchivingId.value, isNull);
    });

    test('mantem o item na lista em falha e retorna false', () async {
      final ArchivedAnalysesScreenPresenter presenter = createPresenter();
      addTearDown(presenter.dispose);

      final AnalysisDto target = AnalysisDtoFaker.fake(id: 'a-1');

      when(
        () => intakeService.listAnalyses(
          limit: any(named: 'limit'),
          isArchived: any(named: 'isArchived'),
          cursor: any(named: 'cursor'),
          search: any(named: 'search'),
        ),
      ).thenAnswer(
        (_) async => RestResponse<CursorPaginationResponse<AnalysisDto>>(
          statusCode: 200,
          body: CursorPaginationResponse<AnalysisDto>(
            items: <AnalysisDto>[target],
            nextCursor: null,
          ),
        ),
      );
      when(() => intakeService.unarchiveAnalysis(analysisId: 'a-1')).thenAnswer(
        (_) async =>
            RestResponse<AnalysisDto>(statusCode: 500, errorMessage: 'Falha'),
      );

      await presenter.initialize();
      final bool result = await presenter.unarchive(target);

      expect(result, isFalse);
      expect(presenter.archivedAnalyses.value.length, 1);
      expect(presenter.isUnarchiving.value, isFalse);
    });
  });

  group('openAnalysis', () {
    test('navega para a rota de primeira instancia', () async {
      final ArchivedAnalysesScreenPresenter presenter = createPresenter();
      addTearDown(presenter.dispose);

      final AnalysisDto analysis = AnalysisDtoFaker.fake(
        id: 'a-1',
        type: AnalysisTypeDto.firstInstance,
      );

      await presenter.openAnalysis(analysis);

      verify(
        () => navigationDriver.pushTo(
          Routes.getAnalysis(
            analysisId: 'a-1',
            analysisType: AnalysisTypeDto.firstInstance,
          ),
        ),
      ).called(1);
    });

    test('navega para a rota de segunda instancia', () async {
      final ArchivedAnalysesScreenPresenter presenter = createPresenter();
      addTearDown(presenter.dispose);

      final AnalysisDto analysis = AnalysisDtoFaker.fake(
        id: 'a-2',
        type: AnalysisTypeDto.secondInstance,
      );

      await presenter.openAnalysis(analysis);

      verify(
        () => navigationDriver.pushTo(
          Routes.getAnalysis(
            analysisId: 'a-2',
            analysisType: AnalysisTypeDto.secondInstance,
          ),
        ),
      ).called(1);
    });

    test(
      'navega para a rota de case assessment usando segunda instancia',
      () async {
        final ArchivedAnalysesScreenPresenter presenter = createPresenter();
        addTearDown(presenter.dispose);

        final AnalysisDto analysis = AnalysisDtoFaker.fake(
          id: 'a-3',
          type: AnalysisTypeDto.caseAssessment,
        );

        await presenter.openAnalysis(analysis);

        verify(
          () => navigationDriver.pushTo(
            Routes.getAnalysis(
              analysisId: 'a-3',
              analysisType: AnalysisTypeDto.caseAssessment,
            ),
          ),
        ).called(1);
      },
    );
  });

  group('goBack', () {
    test('usa goBack quando pode voltar na pilha', () {
      final ArchivedAnalysesScreenPresenter presenter = createPresenter();
      addTearDown(presenter.dispose);

      presenter.goBack();

      verify(() => navigationDriver.goBack()).called(1);
      verifyNever(() => navigationDriver.goTo(any()));
    });

    test('volta para o perfil quando nao pode voltar na pilha', () {
      final ArchivedAnalysesScreenPresenter presenter = createPresenter();
      addTearDown(presenter.dispose);

      when(() => navigationDriver.canGoBack()).thenReturn(false);

      presenter.goBack();

      verify(() => navigationDriver.goTo(Routes.profile)).called(1);
      verifyNever(() => navigationDriver.goBack());
    });
  });

  group('formatCreatedAt', () {
    test('formata data ISO para dd/MM/yyyy', () {
      final ArchivedAnalysesScreenPresenter presenter = createPresenter();
      addTearDown(presenter.dispose);

      expect(presenter.formatCreatedAt('2026-05-18T10:00:00Z'), '18/05/2026');
    });

    test('retorna fallback para data invalida', () {
      final ArchivedAnalysesScreenPresenter presenter = createPresenter();
      addTearDown(presenter.dispose);

      expect(presenter.formatCreatedAt('invalid'), 'Data indisponivel');
    });
  });
}
