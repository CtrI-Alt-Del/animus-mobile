import 'dart:async';

import 'package:dio/dio.dart';

import 'package:animus/constants/cache_keys.dart';
import 'package:animus/constants/routes.dart';
import 'package:animus/core/shared/interfaces/cache_driver.dart';
import 'package:animus/core/shared/interfaces/navigation_driver.dart';
import 'package:animus/core/shared/types/json.dart';
import 'package:animus/rest/mappers/auth/session_mapper.dart';

class AuthTokenInterceptor extends Interceptor {
  static const String _accessTokenExtraKey = 'auth_access_token';
  static const String _retryExtraKey = 'auth_retry_attempted';
  static const Set<String> _publicEndpoints = <String>{
    '/auth/sign-in',
    '/auth/sign-up',
    '/auth/sign-up/google',
    '/auth/password/forgot',
    '/auth/password/resend-reset-otp',
    '/auth/password/verify-reset-otp',
    '/auth/password/reset',
    '/auth/resend-verification-email',
    '/auth/verify-email',
    '/auth/refresh',
  };

  final CacheDriver _cacheDriver;
  final NavigationDriver _navigationDriver;
  final Dio _refreshAndRetryDio;

  Completer<void>? _refreshCompleter;

  AuthTokenInterceptor({
    required CacheDriver cacheDriver,
    required NavigationDriver navigationDriver,
    required String baseUrl,
  }) : _cacheDriver = cacheDriver,
       _navigationDriver = navigationDriver,
       _refreshAndRetryDio = Dio(
         BaseOptions(baseUrl: baseUrl, listFormat: ListFormat.multi),
       );

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final String? accessToken = _readAccessToken();

    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
      options.extra[_accessTokenExtraKey] = accessToken;
    }

    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final RequestOptions requestOptions = err.requestOptions;

    if (_isPublicEndpoint(requestOptions) ||
        !_shouldHandleAsUnauthorized(err)) {
      return handler.next(err);
    }

    if (requestOptions.extra[_retryExtraKey] == true) {
      return handler.next(err);
    }

    final String? requestAccessToken =
        requestOptions.extra[_accessTokenExtraKey];
    final String? currentAccessToken = _readAccessToken();

    if (requestAccessToken != null &&
        currentAccessToken != null &&
        currentAccessToken != requestAccessToken) {
      final _RetryRequestResult retriedRequestResult = await _retryRequest(
        requestOptions,
        currentAccessToken,
      );

      if (retriedRequestResult.response != null) {
        return handler.resolve(retriedRequestResult.response!);
      }

      if (retriedRequestResult.error != null) {
        return handler.next(retriedRequestResult.error!);
      }

      return handler.next(err);
    }

    final String? refreshedAccessToken = await _refreshAccessTokenWithMutex();

    if (refreshedAccessToken == null) {
      return handler.next(err);
    }

    final _RetryRequestResult retriedRequestResult = await _retryRequest(
      requestOptions,
      refreshedAccessToken,
    );

    if (retriedRequestResult.response != null) {
      return handler.resolve(retriedRequestResult.response!);
    }

    if (retriedRequestResult.error != null) {
      return handler.next(retriedRequestResult.error!);
    }

    return handler.next(err);
  }

  Future<String?> _refreshAccessTokenWithMutex() async {
    if (_refreshCompleter != null) {
      await _refreshCompleter!.future;
      return _readAccessToken();
    }

    final Completer<void> completer = Completer<void>();
    _refreshCompleter = completer;

    try {
      final String? refreshToken = _readRefreshToken();

      if (refreshToken == null) {
        await _clearSessionAndRedirectToSignIn();
        return null;
      }

      final Response<dynamic> response = await _refreshAndRetryDio.post(
        '/auth/refresh',
        data: <String, String>{'refresh_token': refreshToken},
      );

      if (response.statusCode != 200 || response.data is! Json) {
        await _clearSessionAndRedirectToSignIn();
        return null;
      }

      final sessionDto = SessionMapper.toDto(response.data as Json);
      final String newAccessToken = sessionDto.accessToken.value.trim();
      final String newRefreshToken = sessionDto.refreshToken.value.trim();

      if (newAccessToken.isEmpty || newRefreshToken.isEmpty) {
        await _clearSessionAndRedirectToSignIn();
        return null;
      }

      _cacheDriver.set(CacheKeys.accessToken, newAccessToken);
      _cacheDriver.set(CacheKeys.refreshToken, newRefreshToken);

      return newAccessToken;
    } on DioException catch (error) {
      final int? statusCode = error.response?.statusCode;

      if (statusCode == 401 || statusCode == 403 || statusCode == null) {
        await _clearSessionAndRedirectToSignIn();
        return null;
      }

      await _clearSessionAndRedirectToSignIn();
      return null;
    } catch (_) {
      await _clearSessionAndRedirectToSignIn();
      return null;
    } finally {
      completer.complete();
      _refreshCompleter = null;
    }
  }

  Future<_RetryRequestResult> _retryRequest(
    RequestOptions requestOptions,
    String accessToken,
  ) async {
    try {
      final Map<String, dynamic> headers = <String, dynamic>{
        ...requestOptions.headers,
        'Authorization': 'Bearer $accessToken',
      };

      final Map<String, dynamic> extra = <String, dynamic>{
        ...requestOptions.extra,
        _accessTokenExtraKey: accessToken,
        _retryExtraKey: true,
      };

      final RequestOptions retriedRequestOptions = requestOptions.copyWith(
        headers: headers,
        extra: extra,
      );

      final Response<dynamic> response = await _refreshAndRetryDio
          .fetch<dynamic>(retriedRequestOptions);
      return _RetryRequestResult(response: response);
    } on DioException catch (error) {
      return _RetryRequestResult(response: error.response, error: error);
    } catch (_) {
      return const _RetryRequestResult();
    }
  }

  bool _isPublicEndpoint(RequestOptions options) {
    final String normalizedPath = _normalizePath(options.path);
    return _publicEndpoints.contains(normalizedPath);
  }

  String _normalizePath(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Uri.parse(path).path;
    }

    return path;
  }

  String? _readAccessToken() {
    final String? cachedToken = _cacheDriver.get(CacheKeys.accessToken)?.trim();
    if (cachedToken == null || cachedToken.isEmpty) {
      return null;
    }

    if (cachedToken.toLowerCase().startsWith('bearer ')) {
      final String normalizedToken = cachedToken.substring(7).trim();
      if (normalizedToken.isEmpty) {
        return null;
      }

      return normalizedToken;
    }

    return cachedToken;
  }

  String? _readRefreshToken() {
    final String? token = _cacheDriver.get(CacheKeys.refreshToken)?.trim();
    if (token == null || token.isEmpty) {
      return null;
    }

    return token;
  }

  Future<void> _clearSessionAndRedirectToSignIn() async {
    _cacheDriver.delete(CacheKeys.accessToken);
    _cacheDriver.delete(CacheKeys.refreshToken);
    _navigationDriver.goTo(Routes.signIn);
  }

  bool _shouldHandleAsUnauthorized(DioException error) {
    final int? statusCode = error.response?.statusCode;
    if (statusCode == 401) {
      return true;
    }

    if (statusCode != 422) {
      return false;
    }

    return _isMissingAuthorizationHeader(error.response?.data);
  }

  bool _isMissingAuthorizationHeader(dynamic data) {
    if (data is! Json) {
      return false;
    }

    final dynamic detail = data['detail'];
    if (detail is! List<dynamic>) {
      return false;
    }

    for (final dynamic item in detail) {
      if (item is! Json) {
        continue;
      }

      final dynamic loc = item['loc'];
      if (loc is! List<dynamic>) {
        continue;
      }

      final bool hasHeader = loc.contains('header');
      final bool hasAuthorization = loc.contains('authorization');
      if (hasHeader && hasAuthorization) {
        return true;
      }
    }

    return false;
  }
}

class _RetryRequestResult {
  final Response<dynamic>? response;
  final DioException? error;

  const _RetryRequestResult({this.response, this.error});
}
