import 'package:animus/constants/cache_keys.dart';
import 'package:animus/constants/routes.dart';
import 'package:animus/core/shared/interfaces/rest_client.dart';
import 'package:animus/core/shared/interfaces/cache_driver.dart';
import 'package:animus/core/shared/responses/rest_response.dart';
import 'package:animus/router.dart';

abstract class Service {
  final RestClient restClient;
  final CacheDriver _cacheDriver;

  Service(this.restClient, this._cacheDriver);

  void setAuthHeader() {
    final String accessToken = (_cacheDriver.get(CacheKeys.accessToken) ?? '')
        .trim();
    final String refreshToken = (_cacheDriver.get(CacheKeys.refreshToken) ?? '')
        .trim();

    if (accessToken.isEmpty || refreshToken.isEmpty) {
      restClient.setHeader('Authorization', '');
      appRouter.go(Routes.signIn);
      return;
    }

    restClient.setHeader('Authorization', 'Bearer $accessToken');
  }

  RestResponse<void> toVoidResponse(
    RestResponse<Map<String, dynamic>> response,
  ) {
    if (response.isFailure) {
      return RestResponse<void>(
        statusCode: response.statusCode,
        errorMessage: resolveErrorMessage(response),
        errorBody: response.errorBody,
      );
    }

    return RestResponse<void>(statusCode: response.statusCode);
  }

  String? resolveErrorMessage(RestResponse<Map<String, dynamic>> response) {
    try {
      return response.errorMessage;
    } catch (_) {
      return null;
    }
  }
}
