import 'package:animus/core/auth/interfaces/auth_service.dart';
import 'package:animus/core/shared/interfaces/cache_driver.dart';
import 'package:animus/core/intake/interfaces/intake_service.dart';
import 'package:animus/core/shared/interfaces/navigation_driver.dart';
import 'package:animus/core/shared/interfaces/rest_client.dart';
import 'package:animus/core/storage/interfaces/storage_service.dart';
import 'package:animus/drivers/caches/shared_preferences/shared_preferences_cache_driver.dart';
import 'package:animus/drivers/navigation/index.dart';
import 'package:animus/rest/dio/dio_rest_client.dart';
import 'package:animus/rest/services/auth_rest_service.dart';
import 'package:animus/rest/services/intake_rest_service.dart';
import 'package:animus/rest/services/storage_rest_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final Provider<AuthService> authServiceProvider = Provider<AuthService>((
  Ref ref,
) {
  final RestClient restClient = ref.watch(restClientProvider);
  final CacheDriver cacheDriver = ref.watch(cacheDriverProvider);
  final NavigationDriver navigationDriver = ref.watch(navigationDriverProvider);
  return AuthRestService(
    restClient: restClient,
    cacheDriver: cacheDriver,
    navigationDriver: navigationDriver,
  );
});

final Provider<IntakeService> intakeServiceProvider = Provider<IntakeService>((
  Ref ref,
) {
  final RestClient restClient = ref.watch(restClientProvider);
  final CacheDriver cacheDriver = ref.watch(cacheDriverProvider);
  final NavigationDriver navigationDriver = ref.watch(navigationDriverProvider);
  return IntakeRestService(
    restClient: restClient,
    cacheDriver: cacheDriver,
    navigationDriver: navigationDriver,
  );
});

final Provider<StorageService> storageServiceProvider =
    Provider<StorageService>((Ref ref) {
      final RestClient restClient = ref.watch(restClientProvider);
      final CacheDriver cacheDriver = ref.watch(cacheDriverProvider);
      final NavigationDriver navigationDriver = ref.watch(
        navigationDriverProvider,
      );
      return StorageRestService(
        restClient: restClient,
        cacheDriver: cacheDriver,
        navigationDriver: navigationDriver,
      );
    });
