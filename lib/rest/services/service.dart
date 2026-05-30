import 'package:animus/core/shared/interfaces/rest_client.dart';
import 'package:animus/core/shared/responses/rest_response.dart';

abstract class Service {
  final RestClient restClient;

  Service(this.restClient);

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
