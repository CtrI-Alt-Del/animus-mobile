import 'package:animus/core/intake/dtos/analysis_dto.dart';
import 'package:animus/core/library/dtos/folder_dto.dart';
import 'package:animus/core/library/interfaces/library_service.dart';
import 'package:animus/core/shared/interfaces/cache_driver.dart';
import 'package:animus/core/shared/interfaces/navigation_driver.dart';
import 'package:animus/core/shared/interfaces/rest_client.dart';
import 'package:animus/core/shared/responses/cursor_pagination_response.dart';
import 'package:animus/core/shared/responses/rest_response.dart';
import 'package:animus/core/shared/types/json.dart';
import 'package:animus/rest/mappers/intake/analysis_mapper.dart';
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

    final Json queryParams = <String, dynamic>{'limit': limit};

    if (cursor != null && cursor.trim().isNotEmpty) {
      queryParams['cursor'] = cursor;
    }

    final RestResponse<Map<String, dynamic>> response = await restClient.get(
      '/intake/analyses/unfoldered',
      queryParams: queryParams,
    );
    return response.mapBody<CursorPaginationResponse<AnalysisDto>>(
      (Json json) =>
          CursorPaginationMapper.toDto<AnalysisDto>(json, AnalysisMapper.toDto),
    );
  }

  @override
  Future<RestResponse<CursorPaginationResponse<AnalysisDto>>>
  listFolderAnalyses({
    required String folderId,
    String? cursor,
    required int limit,
  }) async {
    final RestResponse<CursorPaginationResponse<AnalysisDto>>? authFailure =
        requireAuth<CursorPaginationResponse<AnalysisDto>>();
    if (authFailure != null) {
      return authFailure;
    }

    final Json queryParams = <String, dynamic>{
      'folder_id': folderId,
      'is_archived': false,
      'limit': limit,
    };

    if (cursor != null && cursor.trim().isNotEmpty) {
      queryParams['cursor'] = cursor;
    }

    final RestResponse<Map<String, dynamic>> response = await restClient.get(
      '/intake/analyses',
      queryParams: queryParams,
    );
    return response.mapBody<CursorPaginationResponse<AnalysisDto>>((Json json) {
      final CursorPaginationResponse<AnalysisDto> pagination =
          CursorPaginationMapper.toDto<AnalysisDto>(json, AnalysisMapper.toDto);

      return CursorPaginationResponse<AnalysisDto>(
        items: pagination.items
            .where((AnalysisDto analysis) => analysis.folderId == folderId)
            .toList(growable: false),
        nextCursor: pagination.nextCursor,
      );
    });
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
      '/library/folders/$folderId',
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

  @override
  Future<RestResponse<void>> moveAnalysesToFolder({
    required List<String> analysisIds,
    required String? folderId,
  }) async {
    final RestResponse<void>? authFailure = requireAuth<void>();
    if (authFailure != null) {
      return authFailure;
    }

    final String? normalizedFolderId = folderId?.trim();

    final RestResponse<Map<String, dynamic>> response = await restClient.patch(
      '/intake/analyses/folder',
      body: <String, dynamic>{
        'analysis_ids': analysisIds,
        'folder_id': normalizedFolderId == null || normalizedFolderId.isEmpty
            ? null
            : normalizedFolderId,
      },
    );

    return toVoidResponse(response);
  }

  @override
  Future<RestResponse<void>> archiveAnalyses({
    required List<String> analysisIds,
  }) async {
    final RestResponse<void>? authFailure = requireAuth<void>();
    if (authFailure != null) {
      return authFailure;
    }

    final RestResponse<Map<String, dynamic>> response = await restClient.patch(
      '/intake/analyses/archive',
      body: <String, dynamic>{'analysis_ids': analysisIds},
    );

    return toVoidResponse(response);
  }
}
