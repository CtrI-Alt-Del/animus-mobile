import 'package:animus/core/intake/dtos/analysis_dto.dart';
import 'package:animus/core/library/dtos/folder_dto.dart';
import 'package:animus/core/library/interfaces/library_service.dart';
import 'package:animus/core/shared/interfaces/cache_driver.dart';
import 'package:animus/core/shared/interfaces/navigation_driver.dart';
import 'package:animus/core/shared/interfaces/rest_client.dart';
import 'package:animus/core/shared/responses/cursor_pagination_response.dart';
import 'package:animus/core/shared/responses/rest_response.dart';
import 'package:animus/core/shared/types/json.dart';
import 'package:animus/rest/mappers/library/folder_mapper.dart';
import 'package:animus/rest/mappers/shared/cursor_pagination_mapper.dart';
import 'package:animus/rest/services/service.dart';

class LibraryRestService extends Service implements LibraryService {
  LibraryRestService({
    required RestClient restClient,
    required CacheDriver cacheDriver,
    required NavigationDriver navigationDriver,
  }) : super(restClient, cacheDriver, navigationDriver);

  @override
  Future<RestResponse<CursorPaginationResponse<FolderDto>>> listFolders({
    String? cursor,
    required int limit,
  }) async {
    final RestResponse<CursorPaginationResponse<FolderDto>>? authFailure =
        requireAuth<CursorPaginationResponse<FolderDto>>();
    if (authFailure != null) {
      return authFailure;
    }

    final Json queryParams = <String, dynamic>{'limit': limit};

    if (cursor != null && cursor.trim().isNotEmpty) {
      queryParams['cursor'] = cursor;
    }

    final RestResponse<Map<String, dynamic>> response = await restClient.get(
      '/library/folders',
      queryParams: queryParams,
    );
    return response.mapBody<CursorPaginationResponse<FolderDto>>(
      (Json json) =>
          CursorPaginationMapper.toDto<FolderDto>(json, FolderMapper.toDto),
    );
  }

  @override
  Future<RestResponse<CursorPaginationResponse<AnalysisDto>>>
  listUnfolderedAnalyses({String? cursor, required int limit}) async {
    final RestResponse<CursorPaginationResponse<AnalysisDto>>? authFailure =
        requireAuth<CursorPaginationResponse<AnalysisDto>>();
    if (authFailure != null) {
      return authFailure;
    }

    // TODO(backend): Implementar a rota de listagem de análises sem pasta na API.
    // Retornando mock temporário de sucesso para permitir a visualização das pastas na Biblioteca.
    return RestResponse<CursorPaginationResponse<AnalysisDto>>(
      body: const CursorPaginationResponse<AnalysisDto>(
        items: <AnalysisDto>[],
        nextCursor: null,
      ),
    );
  }

  @override
  Future<RestResponse<FolderDto>> getFolder({required String folderId}) async {
    final RestResponse<FolderDto>? authFailure = requireAuth<FolderDto>();
    if (authFailure != null) {
      return authFailure;
    }

    final RestResponse<Map<String, dynamic>> response = await restClient.get(
      '/library/folders/$folderId',
    );
    return response.mapBody<FolderDto>(FolderMapper.toDto);
  }

  @override
  Future<RestResponse<FolderDto>> createFolder({required String name}) async {
    final RestResponse<FolderDto>? authFailure = requireAuth<FolderDto>();
    if (authFailure != null) {
      return authFailure;
    }

    final RestResponse<Map<String, dynamic>> response = await restClient.post(
      '/library/folders',
      body: <String, dynamic>{'name': name.trim()},
    );
    return response.mapBody<FolderDto>(FolderMapper.toDto);
  }

  @override
  Future<RestResponse<FolderDto>> updateFolderName({
    required String folderId,
    required String name,
  }) async {
    final RestResponse<FolderDto>? authFailure = requireAuth<FolderDto>();
    if (authFailure != null) {
      return authFailure;
    }

    final RestResponse<Map<String, dynamic>> response = await restClient.patch(
      '/library/folders/$folderId/name',
      body: <String, dynamic>{'name': name.trim()},
    );
    return response.mapBody<FolderDto>(FolderMapper.toDto);
  }

  @override
  Future<RestResponse<FolderDto>> archiveFolder({
    required String folderId,
  }) async {
    final RestResponse<FolderDto>? authFailure = requireAuth<FolderDto>();
    if (authFailure != null) {
      return authFailure;
    }

    final RestResponse<Map<String, dynamic>> response = await restClient.patch(
      '/library/folders/$folderId/archive',
    );
    return response.mapBody<FolderDto>(FolderMapper.toDto);
  }
}
