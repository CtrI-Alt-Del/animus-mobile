import 'package:animus/core/shared/interfaces/cache_driver.dart';
import 'package:animus/core/shared/interfaces/rest_client.dart';
import 'package:animus/core/shared/responses/rest_response.dart';
import 'package:animus/rest/services/intake_rest_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCacheDriver extends Mock implements CacheDriver {}

class _MockRestClient extends Mock implements RestClient {}

void main() {
  late _MockCacheDriver cacheDriver;
  late _MockRestClient restClient;
  late IntakeRestService service;

  setUp(() {
    cacheDriver = _MockCacheDriver();
    restClient = _MockRestClient();
    when(() => cacheDriver.get(any())).thenReturn('access-token');
    service = IntakeRestService(
      restClient: restClient,
      cacheDriver: cacheDriver,
    );
  });

  group('listAnalyses', () {
    test(
      'busca analises em /intake/analyses com header e query params',
      () async {
        when(
          () => restClient.setHeader('Authorization', 'Bearer access-token'),
        ).thenReturn(null);
        when(
          () => restClient.get(
            '/intake/analyses',
            queryParams: <String, dynamic>{
              'limit': 10,
              'is_archived': false,
              'cursor': 'cursor-1',
            },
          ),
        ).thenAnswer(
          (_) async => RestResponse<Map<String, dynamic>>(
            statusCode: 200,
            body: <String, dynamic>{
              'items': <Map<String, dynamic>>[
                <String, dynamic>{
                  'id': 'analysis-1',
                  'name': 'Analise 1',
                  'account_id': 'account-1',
                  'status': 'completed',
                  'summary': 'Resumo',
                  'created_at': '2026-01-01T00:00:00Z',
                  'is_archived': false,
                },
              ],
              'next_cursor': 'cursor-2',
            },
          ),
        );

        final response = await service.listAnalyses(
          limit: 10,
          cursor: 'cursor-1',
        );

        expect(response.statusCode, 200);
        expect(response.body.items, hasLength(1));
        expect(response.body.items.first.id, 'analysis-1');
        expect(response.body.nextCursor, 'cursor-2');
        verify(
          () => restClient.setHeader('Authorization', 'Bearer access-token'),
        ).called(1);
        verify(
          () => restClient.get(
            '/intake/analyses',
            queryParams: <String, dynamic>{
              'limit': 10,
              'is_archived': false,
              'cursor': 'cursor-1',
            },
          ),
        ).called(1);
      },
    );

    test('nao envia cursor vazio', () async {
      when(
        () => restClient.setHeader('Authorization', 'Bearer access-token'),
      ).thenReturn(null);
      when(
        () => restClient.get(
          '/intake/analyses',
          queryParams: <String, dynamic>{'limit': 5, 'is_archived': true},
        ),
      ).thenAnswer(
        (_) async => RestResponse<Map<String, dynamic>>(
          statusCode: 200,
          body: <String, dynamic>{'items': <Map<String, dynamic>>[]},
        ),
      );

      final response = await service.listAnalyses(
        limit: 5,
        cursor: '   ',
        isArchived: true,
      );

      expect(response.statusCode, 200);
      expect(response.body.items, isEmpty);
      expect(response.body.nextCursor, isNull);
      verify(
        () => restClient.get(
          '/intake/analyses',
          queryParams: <String, dynamic>{'limit': 5, 'is_archived': true},
        ),
      ).called(1);
    });
  });

  group('createAnalysis', () {
    test(
      'cria analise em /intake/analyses com body vazio quando nao ha pasta',
      () async {
        when(
          () => restClient.setHeader('Authorization', 'Bearer access-token'),
        ).thenReturn(null);
        when(
          () => restClient.post('/intake/analyses', body: <String, dynamic>{}),
        ).thenAnswer(
          (_) async => RestResponse<Map<String, dynamic>>(
            statusCode: 201,
            body: <String, dynamic>{
              'id': 'analysis-1',
              'name': 'Analise 1',
              'account_id': 'account-1',
              'status': 'processing',
              'summary': '',
              'created_at': '2026-01-01T00:00:00Z',
              'is_archived': false,
            },
          ),
        );

        final response = await service.createAnalysis();

        expect(response.statusCode, 201);
        expect(response.body.id, 'analysis-1');
        verify(
          () => restClient.post('/intake/analyses', body: <String, dynamic>{}),
        ).called(1);
      },
    );

    test('envia folder_id quando pasta e informada', () async {
      when(
        () => restClient.setHeader('Authorization', 'Bearer access-token'),
      ).thenReturn(null);
      when(
        () => restClient.post(
          '/intake/analyses',
          body: <String, dynamic>{'folder_id': 'folder-1'},
        ),
      ).thenAnswer(
        (_) async => RestResponse<Map<String, dynamic>>(
          statusCode: 201,
          body: <String, dynamic>{
            'id': 'analysis-2',
            'name': 'Analise 2',
            'account_id': 'account-1',
            'status': 'processing',
            'summary': '',
            'created_at': '2026-01-01T00:00:00Z',
            'folder_id': 'folder-1',
            'is_archived': false,
          },
        ),
      );

      final response = await service.createAnalysis(folderId: ' folder-1 ');

      expect(response.statusCode, 201);
      expect(response.body.folderId, 'folder-1');
      verify(
        () => restClient.post(
          '/intake/analyses',
          body: <String, dynamic>{'folder_id': 'folder-1'},
        ),
      ).called(1);
    });
  });
}
