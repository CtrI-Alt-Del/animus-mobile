import 'package:animus/core/shared/responses/rest_response.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RestResponse.mapBody', () {
    test('preserva statusCode, errorMessage e errorBody em falhas', () {
      final RestResponse<Map<String, dynamic>> response =
          RestResponse<Map<String, dynamic>>(
            statusCode: 422,
            errorMessage: 'Erro de validacao',
            errorBody: <String, dynamic>{
              'detail': <Map<String, dynamic>>[
                <String, dynamic>{
                  'loc': <String>['body', 'email'],
                  'msg': 'Invalido',
                },
              ],
            },
          );

      final RestResponse<String> mapped = response.mapBody<String>((
        Map<String, dynamic> body,
      ) {
        return body['id'] as String;
      });

      expect(mapped.isFailure, isTrue);
      expect(mapped.statusCode, 422);
      expect(mapped.errorMessage, 'Erro de validacao');
      expect(mapped.errorBody, response.errorBody);
    });
  });
}
