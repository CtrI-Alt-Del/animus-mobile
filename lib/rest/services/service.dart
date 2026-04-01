import 'package:animus/constants/cache_keys.dart';
import 'package:animus/core/shared/interfaces/rest_client.dart';
import 'package:animus/core/shared/interfaces/cache_driver.dart';

abstract class Service {
  final RestClient restClient;
  final CacheDriver _cacheDriver;

  Service(this.restClient, this._cacheDriver);

  Future<void> setAuthHeader() {
    final String? accessToken = _cacheDriver.get(CacheKeys.accessToken);
    if (accessToken != null) {
      restClient.setHeader('Authorization', 'Bearer $accessToken');
    }

    return Future<void>.value();
  }
}
