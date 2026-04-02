import 'package:animus/core/intake/dtos/analysis_dto.dart';
import 'package:animus/core/intake/dtos/petition_dto.dart';
import 'package:animus/core/intake/dtos/petition_summary_dto.dart';
import 'package:animus/core/intake/interfaces/intake_service.dart';
import 'package:animus/core/shared/interfaces/cache_driver.dart';
import 'package:animus/core/shared/interfaces/rest_client.dart';
import 'package:animus/core/shared/responses/cursor_pagination_response.dart';
import 'package:animus/core/shared/responses/rest_response.dart';
import 'package:animus/core/shared/types/json.dart';
import 'package:animus/rest/mappers/intake/analysis_mapper.dart';
import 'package:animus/rest/mappers/intake/petition_mapper.dart';
import 'package:animus/rest/mappers/intake/petition_summary_mapper.dart';
import 'package:animus/rest/mappers/shared/cursor_pagination_mapper.dart';
import 'package:animus/rest/services/service.dart';

class IntakeRestService extends Service implements IntakeService {
  IntakeRestService({
    required RestClient restClient,
    required CacheDriver cacheDriver,
  }) : super(restClient, cacheDriver);

  @override
  Future<RestResponse<CursorPaginationResponse<AnalysisDto>>> listAnalyses({
    String? cursor,
    required int limit,
    bool isArchived = false,
  }) async {
    setAuthHeader();

    final Json queryParams = <String, dynamic>{
      'limit': limit,
      'is_archived': isArchived,
    };

    if (cursor != null && cursor.trim().isNotEmpty) {
      queryParams['cursor'] = cursor;
    }

    final response = await restClient.get(
      '/intake/analyses',
      queryParams: queryParams,
    );
    return response.mapBody<CursorPaginationResponse<AnalysisDto>>(
      (Json json) =>
          CursorPaginationMapper.toDto<AnalysisDto>(json, AnalysisMapper.toDto),
    );
  }

  @override
  Future<RestResponse<AnalysisDto>> createAnalysis({String? folderId}) async {
    setAuthHeader();

    final String? normalizedFolderId = folderId?.trim();
    final Object body = normalizedFolderId == null || normalizedFolderId.isEmpty
        ? <String, dynamic>{}
        : <String, dynamic>{'folder_id': normalizedFolderId};

    final response = await restClient.post('/intake/analyses', body: body);
    return response.mapBody<AnalysisDto>(AnalysisMapper.toDto);
  }

  @override
  Future<RestResponse<PetitionDto>> createPetition({
    required PetitionDto petition,
  }) async {
    setAuthHeader();

    final RestResponse<Map<String, dynamic>> response = await restClient.post(
      '/intake/petitions',
      body: PetitionMapper.toJson(petition),
    );

    return response.mapBody<PetitionDto>(PetitionMapper.toDto);
  }

  @override
  Future<RestResponse<AnalysisDto>> getAnalysis({
    required String analysisId,
  }) async {
    setAuthHeader();

    final RestResponse<Map<String, dynamic>> response = await restClient.get(
      '/intake/analyses/$analysisId',
    );

    return response.mapBody<AnalysisDto>(AnalysisMapper.toDto);
  }

  @override
  Future<RestResponse<AnalysisDto>> renameAnalysis({
    required String analysisId,
    required String name,
  }) async {
    setAuthHeader();

    final String normalizedName = name.trim();

    final RestResponse<Map<String, dynamic>> response = await restClient.patch(
      '/intake/analyses/$analysisId/name',
      body: <String, dynamic>{'name': normalizedName},
    );

    return response.mapBody<AnalysisDto>(AnalysisMapper.toDto);
  }

  @override
  Future<RestResponse<AnalysisDto>> archiveAnalysis({
    required String analysisId,
  }) async {
    setAuthHeader();

    final RestResponse<Map<String, dynamic>> response = await restClient.patch(
      '/intake/analyses/$analysisId/archive',
    );

    return response.mapBody<AnalysisDto>(AnalysisMapper.toDto);
  }

  @override
  Future<RestResponse<PetitionDto>> getAnalysisPetition({
    required String analysisId,
  }) async {
    setAuthHeader();

    final RestResponse<Map<String, dynamic>> response = await restClient.get(
      '/intake/analyses/$analysisId/petition',
    );

    return response.mapBody<PetitionDto>(PetitionMapper.toDto);
  }

  @override
  Future<RestResponse<PetitionSummaryDto>> getPetitionSummary({
    required String petitionId,
  }) async {
    setAuthHeader();

    final RestResponse<Map<String, dynamic>> response = await restClient.get(
      '/intake/petitions/$petitionId/summary',
    );

    return response.mapBody<PetitionSummaryDto>(PetitionSummaryMapper.toDto);
  }

  @override
  Future<RestResponse<PetitionSummaryDto>> summarizePetition({
    required String petitionId,
  }) async {
    setAuthHeader();

    final RestResponse<Map<String, dynamic>> response = await restClient.post(
      '/intake/petitions/$petitionId/summary',
    );

    return response.mapBody<PetitionSummaryDto>(PetitionSummaryMapper.toDto);
  }
}
