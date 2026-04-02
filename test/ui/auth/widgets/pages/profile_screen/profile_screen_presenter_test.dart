import 'dart:async';

import 'package:animus/constants/routes.dart';
import 'package:animus/core/auth/dtos/account_dto.dart';
import 'package:animus/core/auth/interfaces/auth_service.dart';
import 'package:animus/core/shared/interfaces/cache_driver.dart';
import 'package:animus/core/shared/interfaces/navigation_driver.dart';
import 'package:animus/core/shared/responses/rest_response.dart';
import 'package:animus/ui/auth/widgets/pages/profile_screen/profile_screen_presenter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../fakers/auth/account_dto_faker.dart';

class _MockAuthService extends Mock implements AuthService {}

class _MockCacheDriver extends Mock implements CacheDriver {}

class _MockNavigationDriver extends Mock implements NavigationDriver {}

void main() {
  late _MockAuthService authService;
  late _MockCacheDriver cacheDriver;
  late _MockNavigationDriver navigationDriver;

  setUp(() {
    authService = _MockAuthService();
    cacheDriver = _MockCacheDriver();
    navigationDriver = _MockNavigationDriver();

    when(() => cacheDriver.get(any())).thenReturn('access-token');
    when(() => navigationDriver.goTo(any())).thenReturn(null);
  });

  ProfileScreenPresenter createPresenter() {
    return ProfileScreenPresenter(
      authService: authService,
      cacheDriver: cacheDriver,
      navigationDriver: navigationDriver,
    );
  }

  group('initialize', () {
    test('redireciona para sign in quando nao existe token salvo', () async {
      final ProfileScreenPresenter presenter = createPresenter();
      addTearDown(presenter.dispose);

      when(() => cacheDriver.get(any())).thenReturn('   ');

      await presenter.initialize();

      verify(() => navigationDriver.goTo(Routes.signIn)).called(1);
      verifyNever(() => authService.fetchAccount());
    });

    test('carrega conta com sucesso', () async {
      final ProfileScreenPresenter presenter = createPresenter();
      addTearDown(presenter.dispose);

      when(() => authService.fetchAccount()).thenAnswer(
        (_) async => RestResponse<AccountDto>(
          statusCode: 200,
          body: AccountDtoFaker.make(name: 'Ada Lovelace'),
        ),
      );

      await presenter.initialize();

      expect(presenter.isLoadingInitialData.value, isFalse);
      expect(presenter.generalError.value, isNull);
      expect(presenter.hasAccount.value, isTrue);
      expect(presenter.account.value?.name, 'Ada Lovelace');
    });

    test('mantem falha recuperavel e permite nova tentativa', () async {
      final ProfileScreenPresenter presenter = createPresenter();
      int fetchCount = 0;
      addTearDown(presenter.dispose);

      when(() => authService.fetchAccount()).thenAnswer((_) async {
        fetchCount += 1;
        if (fetchCount == 1) {
          return RestResponse<AccountDto>(
            statusCode: 500,
            errorMessage: 'Falha ao carregar perfil',
          );
        }

        return RestResponse<AccountDto>(
          statusCode: 200,
          body: AccountDtoFaker.make(email: 'ada@animus.dev'),
        );
      });

      await presenter.initialize();

      expect(presenter.isLoadingInitialData.value, isFalse);
      expect(presenter.generalError.value, 'Falha ao carregar perfil');
      expect(presenter.hasAccount.value, isFalse);

      await presenter.initialize();

      expect(presenter.generalError.value, isNull);
      expect(presenter.account.value?.email, 'ada@animus.dev');
      verify(() => authService.fetchAccount()).called(2);
    });

    test('ignora chamadas concorrentes e repetidas apos sucesso', () async {
      final ProfileScreenPresenter presenter = createPresenter();
      final Completer<RestResponse<AccountDto>> completer =
          Completer<RestResponse<AccountDto>>();
      addTearDown(presenter.dispose);

      when(
        () => authService.fetchAccount(),
      ).thenAnswer((_) => completer.future);

      final Future<void> firstCall = presenter.initialize();
      final Future<void> secondCall = presenter.initialize();

      expect(presenter.isLoadingInitialData.value, isTrue);

      completer.complete(
        RestResponse<AccountDto>(statusCode: 200, body: AccountDtoFaker.make()),
      );

      await Future.wait(<Future<void>>[firstCall, secondCall]);
      await presenter.initialize();

      verify(() => authService.fetchAccount()).called(1);
    });
  });

  group('display values', () {
    test('deriva initial, name e email a partir da conta', () {
      final ProfileScreenPresenter presenter = createPresenter();
      addTearDown(presenter.dispose);

      presenter.account.value = AccountDtoFaker.make(
        name: '  ada lovelace  ',
        email: '  ada@example.com  ',
      );

      expect(presenter.displayInitial.value, 'A');
      expect(presenter.displayName.value, 'ada lovelace');
      expect(presenter.displayEmail.value, 'ada@example.com');
    });
  });

  group('navigation', () {
    test('navega para home quando destination index e 0', () {
      final ProfileScreenPresenter presenter = createPresenter();
      addTearDown(presenter.dispose);

      presenter.onDestinationSelected(0);

      verify(() => navigationDriver.goTo(Routes.home)).called(1);
    });

    test('ignora destination indices 1 e 2', () {
      final ProfileScreenPresenter presenter = createPresenter();
      addTearDown(presenter.dispose);

      presenter.onDestinationSelected(1);
      presenter.onDestinationSelected(2);

      verifyNever(() => navigationDriver.goTo(any()));
    });
  });
}
