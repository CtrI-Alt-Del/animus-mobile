import 'dart:io';

import 'package:animus/core/intake/dtos/analysis_dto.dart';
import 'package:animus/core/intake/dtos/analysis_precedent_dto.dart';
import 'package:animus/core/intake/dtos/analysis_precedents_search_filters_dto.dart';
import 'package:animus/core/intake/dtos/analysis_report_dto.dart';
import 'package:animus/core/intake/dtos/analysis_status_dto.dart';
import 'package:animus/core/intake/dtos/petition_dto.dart';
import 'package:animus/core/intake/dtos/petition_summary_dto.dart';
import 'package:animus/core/intake/dtos/precedent_identifier_dto.dart';
import 'package:animus/core/intake/interfaces/intake_service.dart';
import 'package:animus/core/shared/interfaces/cache_driver.dart';
import 'package:animus/core/shared/interfaces/navigation_driver.dart';
import 'package:animus/core/shared/interfaces/rest_client.dart';
import 'package:animus/core/shared/responses/cursor_pagination_response.dart';
import 'package:animus/core/shared/responses/list_response.dart';
import 'package:animus/core/shared/responses/rest_response.dart';
import 'package:animus/core/shared/types/json.dart';
import 'package:animus/rest/mappers/intake/analysis_report_mapper.dart';
import 'package:animus/rest/mappers/intake/analysis_precedent_mapper.dart';
import 'package:animus/rest/mappers/intake/analysis_mapper.dart';
import 'package:animus/rest/mappers/intake/petition_mapper.dart';
import 'package:animus/rest/mappers/intake/petition_summary_mapper.dart';
import 'package:animus/rest/mappers/shared/cursor_pagination_mapper.dart';
import 'package:animus/rest/services/service.dart';

class IntakeRestService extends Service implements IntakeService {
  IntakeRestService({
    required RestClient restClient,
    required CacheDriver cacheDriver,
    required NavigationDriver navigationDriver,
  }) : super(restClient, cacheDriver, navigationDriver);

  @override
  Future<RestResponse<CursorPaginationResponse<AnalysisDto>>> listAnalyses({
    String? cursor,
    required int limit,
    bool isArchived = false,
  }) async {
    final RestResponse<CursorPaginationResponse<AnalysisDto>>? authFailure =
        requireAuth<CursorPaginationResponse<AnalysisDto>>();
    if (authFailure != null) {
      return authFailure;
    }

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
    final RestResponse<AnalysisDto>? authFailure = requireAuth<AnalysisDto>();
    if (authFailure != null) {
      return authFailure;
    }

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
    final RestResponse<PetitionDto>? authFailure = requireAuth<PetitionDto>();
    if (authFailure != null) {
      return authFailure;
    }

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
    final RestResponse<AnalysisDto>? authFailure = requireAuth<AnalysisDto>();
    if (authFailure != null) {
      return authFailure;
    }

    final RestResponse<Map<String, dynamic>> response = await restClient.get(
      '/intake/analyses/$analysisId',
    );

    return response.mapBody<AnalysisDto>(AnalysisMapper.toDto);
  }

  @override
  Future<RestResponse<AnalysisReportDto>> getAnalysisReport({
    required String analysisId,
  }) async {
    final RestResponse<AnalysisReportDto>? authFailure =
        requireAuth<AnalysisReportDto>();
    if (authFailure != null) {
      return authFailure;
    }

    final RestResponse<Map<String, dynamic>> response = await restClient.get(
      '/intake/analyses/$analysisId/report',
    );

    if (response.isFailure) {
      return RestResponse<AnalysisReportDto>(
        statusCode: response.statusCode,
        errorMessage: resolveErrorMessage(response),
        errorBody: response.errorBody,
      );
    }

    try {
      return RestResponse<AnalysisReportDto>(
        body: AnalysisReportMapper.toDto(response.body),
        statusCode: response.statusCode,
      );
    } on FormatException catch (error) {
      return RestResponse<AnalysisReportDto>(
        statusCode: HttpStatus.badGateway,
        errorMessage: error.message,
        errorBody: response.errorBody,
      );
    }
  }

  @override
  Future<RestResponse<AnalysisDto>> renameAnalysis({
    required String analysisId,
    required String name,
  }) async {
    final RestResponse<AnalysisDto>? authFailure = requireAuth<AnalysisDto>();
    if (authFailure != null) {
      return authFailure;
    }

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
    final RestResponse<AnalysisDto>? authFailure = requireAuth<AnalysisDto>();
    if (authFailure != null) {
      return authFailure;
    }

    final RestResponse<Map<String, dynamic>> response = await restClient.patch(
      '/intake/analyses/$analysisId/archive',
    );

    return response.mapBody<AnalysisDto>(AnalysisMapper.toDto);
  }

  @override
  Future<RestResponse<PetitionDto>> getAnalysisPetition({
    required String analysisId,
  }) async {
    final RestResponse<PetitionDto>? authFailure = requireAuth<PetitionDto>();
    if (authFailure != null) {
      return authFailure;
    }

    final RestResponse<Map<String, dynamic>> response = await restClient.get(
      '/intake/analyses/$analysisId/petition',
    );

    return response.mapBody<PetitionDto>(PetitionMapper.toDto);
  }

  @override
  Future<RestResponse<PetitionSummaryDto>> getPetitionSummary({
    required String petitionId,
  }) async {
    final RestResponse<PetitionSummaryDto>? authFailure =
        requireAuth<PetitionSummaryDto>();
    if (authFailure != null) {
      return authFailure;
    }

    final RestResponse<Map<String, dynamic>> response = await restClient.get(
      '/intake/petitions/$petitionId/summary',
    );

    return response.mapBody<PetitionSummaryDto>(PetitionSummaryMapper.toDto);
  }

  @override
  Future<RestResponse<void>> summarizePetition({
    required String petitionId,
  }) async {
    final RestResponse<void>? authFailure = requireAuth<void>();
    if (authFailure != null) {
      return authFailure;
    }

    final RestResponse<Map<String, dynamic>> response = await restClient.post(
      '/intake/petitions/$petitionId/summary',
    );

    return toVoidResponse(response);
  }

  @override
  Future<RestResponse<void>> searchAnalysisPrecedents({
    required String analysisId,
    required AnalysisPrecedentsSearchFiltersDto filters,
  }) async {
    final RestResponse<void>? authFailure = requireAuth<void>();
    if (authFailure != null) {
      return authFailure;
    }

    final Json body = <String, dynamic>{
      'courts': filters.courts
          .map((court) => court.value)
          .toList(growable: false),
      'precedent_kinds': filters.precedentKinds
          .map((kind) => kind.value)
          .toList(growable: false),
      'limit': filters.limit,
    };

    final RestResponse<Map<String, dynamic>> response = await restClient.post(
      '/intake/analyses/$analysisId/precedents/search',
      body: body,
    );

    return toVoidResponse(response);
  }

  @override
  Future<RestResponse<ListResponse<AnalysisPrecedentDto>>>
  listAnalysisPrecedents({required String analysisId}) async {
    final RestResponse<ListResponse<AnalysisPrecedentDto>>? authFailure =
        requireAuth<ListResponse<AnalysisPrecedentDto>>();
    if (authFailure != null) {
      return authFailure;
    }

    final RestResponse<Map<String, dynamic>> response = await restClient.get(
      '/intake/analyses/$analysisId/precedents',
    );

    return response.mapBody<ListResponse<AnalysisPrecedentDto>>((Json json) {
      final dynamic itemsValue =
          json['items'] ?? json['precedents'] ?? json['data'];

      return ListResponse<AnalysisPrecedentDto>(
        items: _toAnalysisPrecedents(itemsValue),
      );
    });
  }

  static List<AnalysisPrecedentDto> _toAnalysisPrecedents(dynamic value) {
    if (value is! List<dynamic>) {
      return <AnalysisPrecedentDto>[];
    }

    return value
        .whereType<Json>()
        .map(AnalysisPrecedentMapper.toDto)
        .toList(growable: false);
  }

  @override
  Future<RestResponse<AnalysisStatusDto>> chooseAnalysisPrecedent({
    required String analysisId,
    required PrecedentIdentifierDto identifier,
  }) async {
    final RestResponse<AnalysisStatusDto>? authFailure =
        requireAuth<AnalysisStatusDto>();
    if (authFailure != null) {
      return authFailure;
    }

    final RestResponse<Map<String, dynamic>> response = await restClient.patch(
      '/intake/analyses/$analysisId/precedents/choose',
      queryParams: <String, dynamic>{
        'court': identifier.court.value,
        'kind': identifier.kind.value,
        'number': identifier.number,
      },
    );

    return response.mapBody<AnalysisStatusDto>((Json json) {
      final String statusValue =
          (json['status'] ?? json['analysis_status'] ?? json['value'] ?? '')
              .toString();

      return AnalysisStatusDto.values.firstWhere(
        (AnalysisStatusDto status) => status.value == statusValue,
        orElse: () => AnalysisStatusDto.waitingPrecedentChoice,
      );
    });
  }
}
