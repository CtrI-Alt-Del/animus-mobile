import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:animus_mobile/constants/env.dart';
import 'package:animus_mobile/core/shared/interfaces/rest_client.dart';
import 'package:animus_mobile/core/shared/responses/rest_response.dart';
import 'package:animus_mobile/core/shared/types/json.dart';

typedef QueryParams = Map<String, dynamic>;

final Provider<RestClient> restClientProvider = Provider<RestClient>((Ref ref) {
  final DioRestClient client = DioRestClient();
  client.setBaseUrl(Env.animusServerAppUrl);
  return client;
});

class DioRestClient implements RestClient {
  final Dio _dio;

  DioRestClient() : _dio = Dio(BaseOptions(listFormat: ListFormat.multi));

  @override
  Future<RestResponse<Json>> get(
    String path, {
    QueryParams? queryParams,
  }) async {
    return _send(() => _dio.get(path, queryParameters: queryParams));
  }

  @override
  Future<RestResponse<Json>> post(
    String path, {
    Object? body,
    Json? queryParams,
  }) async {
    return _send(
      () => _dio.post(path, data: body, queryParameters: queryParams),
    );
  }

  @override
  Future<RestResponse<Json>> put(
    String path, {
    Object? body,
    Json? queryParams,
  }) async {
    return _send(
      () => _dio.put(path, data: body, queryParameters: queryParams),
    );
  }

  @override
  Future<RestResponse<Json>> patch(
    String path, {
    Object? body,
    Json? queryParams,
  }) async {
    return _send(
      () => _dio.patch(path, data: body, queryParameters: queryParams),
    );
  }

  @override
  Future<RestResponse<Json>> delete(
    String path, {
    Object? body,
    Json? queryParams,
  }) async {
    return _send(
      () => _dio.delete(path, data: body, queryParameters: queryParams),
    );
  }

  @override
  String getBaseUrl() {
    return _dio.options.baseUrl;
  }

  @override
  void setBaseUrl(String baseUrl) {
    _dio.options.baseUrl = baseUrl;
  }

  @override
  void setHeader(String key, String value) {
    _dio.options.headers[key] = value;
  }

  Future<RestResponse<Json>> _send(
    Future<Response<dynamic>> Function() request,
  ) async {
    try {
      final Response<dynamic> response = await request();
      final dynamic data = response.data;
      final Json? body = data is Json
          ? data
          : data is List
          ? <String, dynamic>{'items': data}
          : null;
      return RestResponse<Json>(body: body, statusCode: response.statusCode);
    } on DioException catch (error) {
      final dynamic data = error.response?.data;
      final Json? errorBody = data is Json ? data : null;
      final String? errorMessage = _resolveErrorMessage(error, errorBody);
      return RestResponse<Json>(
        statusCode: error.response?.statusCode,
        errorMessage: errorMessage,
        errorBody: errorBody,
      );
    } catch (error) {
      return RestResponse<Json>(
        statusCode: HttpStatus.internalServerError,
        errorMessage: error.toString(),
      );
    }
  }

  String? _resolveErrorMessage(DioException error, Json? errorBody) {
    if (errorBody == null) {
      return error.message;
    }

    final dynamic title = errorBody['title'];
    final dynamic message = errorBody['message'];

    if (title is String && message is String && message.isNotEmpty) {
      return message;
    }

    if (message is String && message.isNotEmpty) {
      return message;
    }

    return error.message;
  }
}
