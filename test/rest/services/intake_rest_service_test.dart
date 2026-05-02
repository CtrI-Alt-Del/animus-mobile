import 'dart:io';

import 'package:animus/core/shared/interfaces/cache_driver.dart';
import 'package:animus/core/shared/interfaces/navigation_driver.dart';
import 'package:animus/core/shared/interfaces/rest_client.dart';
import 'package:animus/core/shared/responses/rest_response.dart';
import 'package:animus/rest/services/intake_rest_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRestClient extends Mock implements RestClient {}

class _MockCacheDriver extends Mock implements CacheDriver {}

class _MockNavigationDriver extends Mock implements NavigationDriver {}

void main() {
  late _MockRestClient restClient;
  late _MockCacheDriver cacheDriver;
  late _MockNavigationDriver navigationDriver;
  late IntakeRestService service;

  setUp(() {
    restClient = _MockRestClient();
    cacheDriver = _MockCacheDriver();
    navigationDriver = _MockNavigationDriver();
    service = IntakeRestService(
      restClient: restClient,
      cacheDriver: cacheDriver,
      navigationDriver: navigationDriver,
    );

    when(() => cacheDriver.get(any())).thenReturn('token');
    when(() => restClient.setHeader(any(), any())).thenReturn(null);
  });

  group('getAnalysisReport', () {
    test('returns badGateway when report mapper fails', () async {
      when(
        () => restClient.get('/intake/analyses/analysis-1/report'),
      ).thenAnswer(
        (_) async => RestResponse<Map<String, dynamic>>(
          statusCode: HttpStatus.ok,
          body: <String, dynamic>{
            'analysis': <String, dynamic>{'id': 'analysis-1'},
            'petition': <String, dynamic>{},
            'summary': <String, dynamic>{},
            'precedents': <Map<String, dynamic>>[],
            'chosen_precedent': <String, dynamic>{
              'precedent': <String, dynamic>{
                'court': 'STF',
                'kind': 'SUM',
                'number': 1,
              },
            },
          },
        ),
      );

      final response = await service.getAnalysisReport(
        analysisId: 'analysis-1',
      );

      expect(response.isFailure, isTrue);
      expect(response.statusCode, HttpStatus.badGateway);
      expect(response.errorMessage, contains('filters is required'));
      verify(
        () => restClient.setHeader('Authorization', 'Bearer token'),
      ).called(1);
    });
  });
}
