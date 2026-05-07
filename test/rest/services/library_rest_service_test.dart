import 'package:animus/constants/cache_keys.dart';
import 'package:animus/core/shared/interfaces/cache_driver.dart';
import 'package:animus/core/shared/interfaces/navigation_driver.dart';
import 'package:animus/core/shared/interfaces/rest_client.dart';
import 'package:animus/core/shared/responses/rest_response.dart';
import 'package:animus/core/shared/types/json.dart';
import 'package:animus/rest/services/library_rest_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRestClient extends Mock implements RestClient {}

class MockCacheDriver extends Mock implements CacheDriver {}

class MockNavigationDriver extends Mock implements NavigationDriver {}

void main() {
  late MockRestClient restClient;
  late MockCacheDriver cacheDriver;
  late MockNavigationDriver navigationDriver;
  late LibraryRestService service;

  setUp(() {
    restClient = MockRestClient();
    cacheDriver = MockCacheDriver();
    navigationDriver = MockNavigationDriver();
    service = LibraryRestService(
      restClient: restClient,
      cacheDriver: cacheDriver,
      navigationDriver: navigationDriver,
    );

    when(() => cacheDriver.get(CacheKeys.accessToken)).thenReturn('access');
    when(() => cacheDriver.get(CacheKeys.refreshToken)).thenReturn('refresh');
  });

  test(
    'listFolderAnalyses envia filtro remoto da pasta e mapeia pagina',
    () async {
      when(
        () => restClient.get(any(), queryParams: any(named: 'queryParams')),
      ).thenAnswer(
        (_) async => RestResponse<Json>(
          body: <String, dynamic>{
            'items': <Json>[
              <String, dynamic>{
                'id': 'analysis-1',
                'name': 'Analise trabalhista',
                'account_id': 'account-1',
                'status': 'completed',
                'summary': 'Resumo',
                'created_at': '2026-05-03T10:00:00.000Z',
                'folder_id': 'folder-1',
                'is_archived': false,
              },
            ],
            'next_cursor': 'next-1',
          },
        ),
      );

      final response = await service.listFolderAnalyses(
        folderId: 'folder-1',
        cursor: 'cursor-1',
        limit: 50,
      );

      expect(response.isSuccessful, isTrue);
      expect(response.body.items.single.id, 'analysis-1');
      expect(response.body.items.single.folderId, 'folder-1');
      expect(response.body.nextCursor, 'next-1');

      final verification = verify(
        () => restClient.get(
          captureAny(),
          queryParams: captureAny(named: 'queryParams'),
        ),
      );
      final captured = verification.captured;
      expect(captured.first, '/intake/analyses');
      expect(captured.last, <String, dynamic>{
        'folder_id': 'folder-1',
        'limit': 50,
        'is_archived': false,
        'cursor': 'cursor-1',
      });
      verify(() => restClient.setHeader('Authorization', 'Bearer access'));
    },
  );

  test(
    'moveAnalysesToFolder envia batch e normaliza destino vazio para Sem pasta',
    () async {
      when(() => restClient.patch(any(), body: any(named: 'body'))).thenAnswer(
        (_) async => RestResponse<Json>(
          body: <String, dynamic>{
            'items': <Json>[
              <String, dynamic>{
                'id': 'analysis-1',
                'name': 'Analise',
                'account_id': 'account-1',
                'status': 'completed',
                'summary': '',
                'created_at': '2026-05-03T10:00:00.000Z',
                'folder_id': null,
              },
            ],
          },
        ),
      );

      final response = await service.moveAnalysesToFolder(
        analysisIds: <String>['analysis-1', 'analysis-2'],
        folderId: '   ',
      );

      expect(response.isSuccessful, isTrue);

      final verification = verify(
        () => restClient.patch(captureAny(), body: captureAny(named: 'body')),
      );
      final captured = verification.captured;
      expect(captured.first, '/intake/analyses/folder');
      expect(captured.last, <String, dynamic>{
        'analysis_ids': <String>['analysis-1', 'analysis-2'],
        'folder_id': null,
      });
    },
  );

  test('archiveAnalyses envia batch de arquivamento', () async {
    when(() => restClient.patch(any(), body: any(named: 'body'))).thenAnswer(
      (_) async => RestResponse<Json>(
        body: <String, dynamic>{
          'data': <Json>[
            <String, dynamic>{
              'id': 'analysis-1',
              'name': 'Analise',
              'account_id': 'account-1',
              'status': 'completed',
              'summary': '',
              'created_at': '2026-05-03T10:00:00.000Z',
              'is_archived': true,
            },
          ],
        },
      ),
    );

    final response = await service.archiveAnalyses(
      analysisIds: <String>['analysis-1'],
    );

    expect(response.isSuccessful, isTrue);

    final verification = verify(
      () => restClient.patch(captureAny(), body: captureAny(named: 'body')),
    );
    final captured = verification.captured;
    expect(captured.first, '/intake/analyses/archive');
    expect(captured.last, <String, dynamic>{
      'analysis_ids': <String>['analysis-1'],
    });
  });

  test('updateFolderName usa endpoint da pasta e envia nome trimado', () async {
    when(() => restClient.patch(any(), body: any(named: 'body'))).thenAnswer(
      (_) async => RestResponse<Json>(
        body: <String, dynamic>{
          'id': 'folder-1',
          'name': 'Trabalhista',
          'analysis_count': 2,
          'account_id': 'account-1',
          'is_archived': false,
        },
      ),
    );

    final response = await service.updateFolderName(
      folderId: 'folder-1',
      name: '  Trabalhista  ',
    );

    expect(response.isSuccessful, isTrue);
    expect(response.body.id, 'folder-1');
    expect(response.body.name, 'Trabalhista');

    final verification = verify(
      () => restClient.patch(captureAny(), body: captureAny(named: 'body')),
    );
    final captured = verification.captured;
    expect(captured.first, '/library/folders/folder-1');
    expect(captured.last, <String, dynamic>{'name': 'Trabalhista'});
  });
}
