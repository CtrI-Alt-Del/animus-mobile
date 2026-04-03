import 'package:animus/core/auth/dtos/account_dto.dart';
import 'package:animus/core/auth/interfaces/auth_service.dart';
import 'package:animus/core/intake/dtos/analysis_dto.dart';
import 'package:animus/core/intake/interfaces/intake_service.dart';
import 'package:animus/core/shared/interfaces/cache_driver.dart';
import 'package:animus/core/shared/interfaces/navigation_driver.dart';
import 'package:animus/core/shared/responses/cursor_pagination_response.dart';
import 'package:animus/core/shared/responses/rest_response.dart';
import 'package:animus/constants/routes.dart';
import 'package:animus/ui/intake/widgets/pages/home_screen/home_screen_presenter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../fakers/auth/account_dto_faker.dart';
import '../../../../../fakers/intake/analysis_dto_faker.dart';

class _MockAuthService extends Mock implements AuthService {}

class _MockIntakeService extends Mock implements IntakeService {}

class _MockCacheDriver extends Mock implements CacheDriver {}

class _MockNavigationDriver extends Mock implements NavigationDriver {}

void main() {
  late _MockAuthService authService;
  late _MockIntakeService intakeService;
  late _MockCacheDriver cacheDriver;
  late _MockNavigationDriver navigationDriver;

  setUp(() {
    authService = _MockAuthService();
    intakeService = _MockIntakeService();
    cacheDriver = _MockCacheDriver();
    navigationDriver = _MockNavigationDriver();

    when(() => cacheDriver.get(any())).thenReturn('access-token');
    when(() => navigationDriver.goTo(any())).thenReturn(null);
    when(() => navigationDriver.pushTo(any())).thenAnswer((_) async {});
  });

  CursorPaginationResponse<AnalysisDto> createPagination({
    required List<AnalysisDto> items,
    String? nextCursor,
  }) {
    return CursorPaginationResponse<AnalysisDto>(
      items: items,
      nextCursor: nextCursor,
    );
  }

  HomeScreenPresenter createPresenter() {
    return HomeScreenPresenter(
      authService: authService,
      intakeService: intakeService,
      cacheDriver: cacheDriver,
      navigationDriver: navigationDriver,
    );
  }

  group('initialize', () {
    test('carrega conta e primeira pagina com sucesso', () async {
      final HomeScreenPresenter presenter = createPresenter();
      final AnalysisDto analysis = AnalysisDtoFaker.fake();
      addTearDown(presenter.dispose);

      when(() => authService.getAccount()).thenAnswer(
        (_) async => RestResponse<AccountDto>(
          statusCode: 200,
          body: AccountDtoFaker.fake(name: 'Ada Lovelace'),
        ),
      );
      when(
        () => intakeService.listAnalyses(limit: 10, isArchived: false),
      ).thenAnswer(
        (_) async => RestResponse<CursorPaginationResponse<AnalysisDto>>(
          statusCode: 200,
          body: createPagination(
            items: <AnalysisDto>[analysis],
            nextCursor: 'cursor-2',
          ),
        ),
      );

      await presenter.initialize();

      expect(presenter.isLoadingInitialData.value, isFalse);
      expect(presenter.generalError.value, isNull);
      expect(presenter.firstName.value, 'Ada');
      expect(presenter.greeting.value, contains('Ada'));
      expect(
        presenter.greeting.value,
        matches(r'^(Bom dia|Boa tarde|Boa noite), Ada$'),
      );
      expect(presenter.recentAnalyses.value, hasLength(1));
      expect(presenter.recentAnalyses.value.first.id, analysis.id);
      expect(presenter.nextCursor.value, 'cursor-2');
      expect(presenter.hasMore.value, isTrue);
      expect(presenter.showEmptyState.value, isFalse);
    });

    test('redireciona para sign in quando nao existe token salvo', () async {
      final HomeScreenPresenter presenter = createPresenter();
      addTearDown(presenter.dispose);

      when(() => cacheDriver.get(any())).thenReturn('   ');

      await presenter.initialize();

      verify(() => navigationDriver.goTo(Routes.signIn)).called(1);
      verifyNever(() => authService.getAccount());
      verifyNever(
        () => intakeService.listAnalyses(
          limit: any(named: 'limit'),
          isArchived: any(named: 'isArchived'),
        ),
      );
    });
  });

  group('loadNextPage', () {
    test('acumula itens quando a proxima pagina carrega com sucesso', () async {
      final HomeScreenPresenter presenter = createPresenter();
      final AnalysisDto firstAnalysis = AnalysisDtoFaker.fake(id: 'analysis-1');
      final AnalysisDto secondAnalysis = AnalysisDtoFaker.fake(
        id: 'analysis-2',
      );
      addTearDown(presenter.dispose);

      when(() => authService.getAccount()).thenAnswer(
        (_) async => RestResponse<AccountDto>(
          statusCode: 200,
          body: AccountDtoFaker.fake(),
        ),
      );
      when(
        () => intakeService.listAnalyses(limit: 10, isArchived: false),
      ).thenAnswer(
        (_) async => RestResponse<CursorPaginationResponse<AnalysisDto>>(
          statusCode: 200,
          body: createPagination(
            items: <AnalysisDto>[firstAnalysis],
            nextCursor: 'cursor-1',
          ),
        ),
      );
      when(
        () => intakeService.listAnalyses(
          cursor: 'cursor-1',
          limit: 10,
          isArchived: false,
        ),
      ).thenAnswer(
        (_) async => RestResponse<CursorPaginationResponse<AnalysisDto>>(
          statusCode: 200,
          body: createPagination(items: <AnalysisDto>[secondAnalysis]),
        ),
      );

      await presenter.initialize();
      await presenter.loadNextPage();

      expect(presenter.isLoadingMore.value, isFalse);
      expect(presenter.generalError.value, isNull);
      expect(
        presenter.recentAnalyses.value.map((AnalysisDto item) => item.id),
        <String?>['analysis-1', 'analysis-2'],
      );
      expect(presenter.nextCursor.value, isNull);
      expect(presenter.hasMore.value, isFalse);
    });

    test('preserva itens quando a paginacao falha', () async {
      final HomeScreenPresenter presenter = createPresenter();
      final AnalysisDto analysis = AnalysisDtoFaker.fake(id: 'analysis-1');
      addTearDown(presenter.dispose);

      when(() => authService.getAccount()).thenAnswer(
        (_) async => RestResponse<AccountDto>(
          statusCode: 200,
          body: AccountDtoFaker.fake(),
        ),
      );
      when(
        () => intakeService.listAnalyses(limit: 10, isArchived: false),
      ).thenAnswer(
        (_) async => RestResponse<CursorPaginationResponse<AnalysisDto>>(
          statusCode: 200,
          body: createPagination(
            items: <AnalysisDto>[analysis],
            nextCursor: 'cursor-1',
          ),
        ),
      );
      when(
        () => intakeService.listAnalyses(
          cursor: 'cursor-1',
          limit: 10,
          isArchived: false,
        ),
      ).thenAnswer(
        (_) async => RestResponse<CursorPaginationResponse<AnalysisDto>>(
          statusCode: 500,
          errorMessage: 'falha tecnica',
        ),
      );

      await presenter.initialize();
      await presenter.loadNextPage();

      expect(presenter.isLoadingMore.value, isFalse);
      expect(presenter.recentAnalyses.value, hasLength(1));
      expect(presenter.recentAnalyses.value.first.id, 'analysis-1');
      expect(presenter.generalError.value, 'falha tecnica');
      expect(presenter.nextCursor.value, 'cursor-1');
    });
  });

  group('createAnalysis', () {
    test('navega para a analise criada quando o id e retornado', () async {
      final HomeScreenPresenter presenter = createPresenter();
      addTearDown(presenter.dispose);

      when(() => intakeService.createAnalysis()).thenAnswer(
        (_) async => RestResponse<AnalysisDto>(
          statusCode: 201,
          body: AnalysisDtoFaker.fake(id: 'analysis-123'),
        ),
      );
      when(() => authService.getAccount()).thenAnswer(
        (_) async => RestResponse<AccountDto>(
          statusCode: 200,
          body: AccountDtoFaker.fake(name: 'Ada Lovelace'),
        ),
      );
      when(
        () => intakeService.listAnalyses(limit: 10, isArchived: false),
      ).thenAnswer(
        (_) async => RestResponse<CursorPaginationResponse<AnalysisDto>>(
          statusCode: 200,
          body: createPagination(
            items: <AnalysisDto>[AnalysisDtoFaker.fake(id: 'analysis-123')],
            nextCursor: null,
          ),
        ),
      );

      await presenter.createAnalysis();

      expect(presenter.isCreatingAnalysis.value, isFalse);
      expect(presenter.generalError.value, isNull);
      verify(
        () => navigationDriver.pushTo(
          Routes.getAnalysis(analysisId: 'analysis-123'),
        ),
      ).called(1);
    });

    test('exibe erro quando createAnalysis retorna analise sem id', () async {
      final HomeScreenPresenter presenter = createPresenter();
      addTearDown(presenter.dispose);

      when(() => intakeService.createAnalysis()).thenAnswer(
        (_) async => RestResponse<AnalysisDto>(
          statusCode: 201,
          body: AnalysisDtoFaker.fake(id: '   '),
        ),
      );

      await presenter.createAnalysis();

      expect(presenter.isCreatingAnalysis.value, isFalse);
      expect(
        presenter.generalError.value,
        'Nao foi possivel abrir a analise criada.',
      );
      verifyNever(() => navigationDriver.pushTo(any()));
    });
  });

  group('openAnalysis', () {
    test('ignora analise sem id', () {
      final HomeScreenPresenter presenter = createPresenter();
      addTearDown(presenter.dispose);

      presenter.openAnalysis(AnalysisDtoFaker.fake(id: null));

      verifyNever(() => navigationDriver.pushTo(any()));
    });
  });

  group('navigation', () {
    test('openProfile navega para perfil', () {
      final HomeScreenPresenter presenter = createPresenter();
      addTearDown(presenter.dispose);

      presenter.openProfile();

      verify(() => navigationDriver.goTo(Routes.profile)).called(1);
    });
  });

  group('formatCreatedAt', () {
    test('formata datas validas em dd/MM/yyyy', () {
      final HomeScreenPresenter presenter = createPresenter();
      addTearDown(presenter.dispose);

      expect(presenter.formatCreatedAt('2026-03-31T10:30:00Z'), '31/03/2026');
    });

    test('retorna fallback quando a data e invalida', () {
      final HomeScreenPresenter presenter = createPresenter();
      addTearDown(presenter.dispose);

      expect(presenter.formatCreatedAt('data-invalida'), 'Data indisponivel');
    });
  });

  test(
    'usa fallback amigavel quando listAnalyses falha com mensagem tecnica do Dio',
    () async {
      final HomeScreenPresenter presenter = createPresenter();
      addTearDown(presenter.dispose);

      when(() => authService.getAccount()).thenAnswer(
        (_) async => RestResponse<AccountDto>(
          statusCode: 200,
          body: const AccountDto(
            name: 'Ada Lovelace',
            email: 'ada@example.com',
          ),
        ),
      );
      when(
        () => intakeService.listAnalyses(limit: 10, isArchived: false),
      ).thenAnswer(
        (_) async => RestResponse<CursorPaginationResponse<AnalysisDto>>(
          statusCode: 404,
          errorMessage:
              'This exception was thrown because the response has a status code of 404 and RequestOptions.validateStatus was configured to throw for this status code.',
        ),
      );

      await presenter.initialize();

      expect(
        presenter.generalError.value,
        'Nao foi possivel carregar as analises agora. Tente novamente.',
      );
    },
  );

  test(
    'preserva mensagem amigavel vinda do backend quando disponivel',
    () async {
      final HomeScreenPresenter presenter = createPresenter();
      addTearDown(presenter.dispose);

      when(() => authService.getAccount()).thenAnswer(
        (_) async => RestResponse<AccountDto>(
          statusCode: 200,
          body: const AccountDto(
            name: 'Ada Lovelace',
            email: 'ada@example.com',
          ),
        ),
      );
      when(
        () => intakeService.listAnalyses(limit: 10, isArchived: false),
      ).thenAnswer(
        (_) async => RestResponse<CursorPaginationResponse<AnalysisDto>>(
          statusCode: 404,
          errorMessage: 'Analises ainda nao disponiveis para esta conta.',
        ),
      );

      await presenter.initialize();

      expect(
        presenter.generalError.value,
        'Analises ainda nao disponiveis para esta conta.',
      );
    },
  );
}
