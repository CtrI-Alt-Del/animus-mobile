import 'package:animus/core/intake/dtos/analysis_dto.dart';
import 'package:animus/core/intake/dtos/petition_dto.dart';
import 'package:animus/core/intake/dtos/petition_summary_dto.dart';
import 'package:animus/core/intake/interfaces/intake_service.dart';
import 'package:animus/core/shared/interfaces/cache_driver.dart';
import 'package:animus/core/shared/interfaces/rest_client.dart';
import 'package:animus/core/shared/responses/rest_response.dart';
import 'package:animus/rest/mappers/intake/analysis_mapper.dart';
import 'package:animus/rest/mappers/intake/petition_mapper.dart';
import 'package:animus/rest/mappers/intake/petition_summary_mapper.dart';
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
    _setAuthorizationHeader();

    final Json queryParams = <String, dynamic>{
      'limit': limit,
      'is_archived': isArchived,
    };

    if (cursor != null && cursor.trim().isNotEmpty) {
      queryParams['cursor'] = cursor;
    }

    final response = await _restClient.get(
      '/intake/analyses',
      queryParams: queryParams,
    );
    return response.mapBody<CursorPaginationResponse<AnalysisDto>>(
      _toCursorPaginationResponse,
    );
  }

  @override
  Future<RestResponse<AnalysisDto>> createAnalysis({String? folderId}) async {
    _setAuthorizationHeader();

    final String? normalizedFolderId = folderId?.trim();
    final Object body = normalizedFolderId == null || normalizedFolderId.isEmpty
        ? <String, dynamic>{}
        : <String, dynamic>{'folder_id': normalizedFolderId};

    final response = await _restClient.post('/intake/analyses', body: body);
    return response.mapBody<AnalysisDto>(AnalysisMapper.toDto);
  }

  CursorPaginationResponse<AnalysisDto> _toCursorPaginationResponse(Json json) {
    final dynamic itemsValue = json['items'] ?? json['data'];
    final List<AnalysisDto> items = _toAnalyses(itemsValue);
    final String? nextCursor = _toNextCursor(json);

    return CursorPaginationResponse<AnalysisDto>(
      items: items,
      nextCursor: nextCursor,
    );
  }

  List<AnalysisDto> _toAnalyses(dynamic value) {
    if (value is! List<dynamic>) {
      return const <AnalysisDto>[];
    }

    return value.whereType<Json>().map(AnalysisMapper.toDto).toList();
  }

  String? _toNextCursor(Json json) {
    final dynamic nextCursor = json['next_cursor'] ?? json['nextCursor'];
    if (nextCursor is String && nextCursor.trim().isNotEmpty) {
      return nextCursor;
    }

    return null;
  }

  @override
  Future<RestResponse<PetitionDto>> createPetition({
    required PetitionDto petition,
  }) async {
    await setAuthHeader();

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
    await setAuthHeader();

    final RestResponse<Map<String, dynamic>> response = await restClient.get(
      '/intake/analyses/$analysisId',
    );

    return response.mapBody<AnalysisDto>(AnalysisMapper.toDto);
  }

  @override
  Future<RestResponse<PetitionDto>> getAnalysisPetition({
    required String analysisId,
  }) async {
    await setAuthHeader();

    final RestResponse<Map<String, dynamic>> response = await restClient.get(
      '/intake/analyses/$analysisId/petition',
    );

    return response.mapBody<PetitionDto>(PetitionMapper.toDto);
  }

  @override
  Future<RestResponse<PetitionSummaryDto>> getPetitionSummary({
    required String petitionId,
  }) async {
    await setAuthHeader();

    final RestResponse<Map<String, dynamic>> response = await restClient.get(
      '/intake/petitions/$petitionId/summary',
    );

    return response.mapBody<PetitionSummaryDto>(PetitionSummaryMapper.toDto);
  }

  @override
  Future<RestResponse<PetitionSummaryDto>> summarizePetition({
    required String petitionId,
  }) async {
    await setAuthHeader();

    final RestResponse<Map<String, dynamic>> response = await restClient.post(
      '/intake/petitions/$petitionId/summary',
    );

    return response.mapBody<PetitionSummaryDto>(PetitionSummaryMapper.toDto);
  }
}
