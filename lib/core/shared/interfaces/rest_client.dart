import 'package:animus_mobile/core/shared/responses/rest_response.dart';
import 'package:animus_mobile/core/shared/types/json.dart';

abstract class RestClient {
  Future<RestResponse<Json>> get(String path, {Json? queryParams});
  Future<RestResponse<Json>> post(
    String path, {
    Object? body,
    Json? queryParams,
  });
  Future<RestResponse<Json>> put(
    String path, {
    Object? body,
    Json? queryParams,
  });
  Future<RestResponse<Json>> patch(
    String path, {
    Object? body,
    Json? queryParams,
  });
  Future<RestResponse<Json>> delete(
    String path, {
    Object? body,
    Json? queryParams,
  });
  String getBaseUrl();
  void setBaseUrl(String baseUrl);
  void setHeader(String key, String value);
}
