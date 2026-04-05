import 'dart:io';

import 'package:animus/constants/cache_keys.dart';
import 'package:animus/constants/routes.dart';
import 'package:animus/core/shared/interfaces/cache_driver.dart';
import 'package:animus/core/shared/interfaces/navigation_driver.dart';
import 'package:animus/core/shared/interfaces/rest_client.dart';
import 'package:animus/core/shared/responses/rest_response.dart';

abstract class Service {
  final RestClient restClient;
  final CacheDriver _cacheDriver;
  final NavigationDriver _navigationDriver;

  Service(this.restClient, this._cacheDriver, this._navigationDriver);

  bool setAuthHeader() {
    try {
      final String accessToken = (_cacheDriver.get(CacheKeys.accessToken) ?? '')
          .trim();
      final String refreshToken =
          (_cacheDriver.get(CacheKeys.refreshToken) ?? '').trim();

      if (accessToken.isEmpty || refreshToken.isEmpty) {
        restClient.setHeader('Authorization', '');
        _navigationDriver.goTo(Routes.signIn);
        return false;
      }

      restClient.setHeader('Authorization', 'Bearer $accessToken');
      return true;
    } catch (_) {
      restClient.setHeader('Authorization', '');
      _navigationDriver.goTo(Routes.signIn);
      return false;
    }
  }

  RestResponse<T>? requireAuth<T>() {
    if (setAuthHeader()) {
      return null;
    }

    return unauthorizedResponse<T>();
  }

  RestResponse<T> unauthorizedResponse<T>() {
    return RestResponse<T>(
      statusCode: HttpStatus.unauthorized,
      errorMessage: 'Authentication required.',
    );
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
