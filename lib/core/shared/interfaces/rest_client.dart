import 'package:animus/core/shared/responses/rest_response.dart';
import 'package:animus/core/shared/types/json.dart';

abstract class RestClient {
  Future<RestResponse<Json>> get(
    String path, {
    Json? queryParams,
    Json? headers,
  });
  Future<RestResponse<Json>> post(
    String path, {
    Object? body,
    Json? queryParams,
    Json? headers,
  });
  Future<RestResponse<Json>> put(
    String path, {
    Object? body,
    Json? queryParams,
    Json? headers,
  });
  Future<RestResponse<Json>> patch(
    String path, {
    Object? body,
    Json? queryParams,
    Json? headers,
  });
  Future<RestResponse<Json>> delete(
    String path, {
    Object? body,
    Json? queryParams,
    Json? headers,
  });
  String getBaseUrl();
  void setBaseUrl(String baseUrl);
  void setHeader(String key, String value);
}
