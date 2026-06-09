import 'dart:io';

import 'package:animus/core/intake/dtos/analysis_dto.dart';
import 'package:animus/core/intake/dtos/analysis_document_dto.dart';
import 'package:animus/core/intake/dtos/analysis_precedent_dto.dart';
import 'package:animus/core/intake/dtos/analysis_precedents_search_filters_dto.dart';
import 'package:animus/core/intake/dtos/analysis_status_dto.dart';
import 'package:animus/core/intake/dtos/analysis_type_dto.dart';
import 'package:animus/core/intake/dtos/case_assessment_briefing_dto.dart';
import 'package:animus/core/intake/dtos/case_assessment_analysis_report_dto.dart';
import 'package:animus/core/intake/dtos/case_summary_dto.dart';
import 'package:animus/core/intake/dtos/first_instance_analysis_report_dto.dart';
import 'package:animus/core/intake/dtos/petition_draft_dto.dart';
import 'package:animus/core/intake/dtos/precedent_dto.dart';
import 'package:animus/core/intake/dtos/precedent_identifier_dto.dart';
import 'package:animus/core/intake/dtos/second_instance_analysis_report_dto.dart';
import 'package:animus/core/intake/dtos/second_instance_decision_dto.dart';
import 'package:animus/core/intake/dtos/second_instance_judgment_draft_dto.dart';
import 'package:animus/core/intake/interfaces/intake_service.dart';
import 'package:animus/core/shared/interfaces/rest_client.dart';
import 'package:animus/core/shared/responses/cursor_pagination_response.dart';
import 'package:animus/core/shared/responses/list_response.dart';
import 'package:animus/core/shared/responses/rest_response.dart';
import 'package:animus/core/shared/types/json.dart';
import 'package:animus/rest/mappers/intake/analysis_precedent_mapper.dart';
import 'package:animus/rest/mappers/intake/analysis_document_mapper.dart';
import 'package:animus/rest/mappers/intake/analysis_mapper.dart';
import 'package:animus/rest/mappers/intake/case_assessment_briefing_mapper.dart';
import 'package:animus/rest/mappers/intake/case_assessment_analysis_report_mapper.dart';
import 'package:animus/rest/mappers/intake/case_summary_mapper.dart';
import 'package:animus/rest/mappers/intake/first_instance_analysis_report_mapper.dart';
import 'package:animus/rest/mappers/intake/petition_draft_mapper.dart';
import 'package:animus/rest/mappers/intake/precedent_mapper.dart';
import 'package:animus/rest/mappers/intake/second_instance_analysis_report_mapper.dart';
import 'package:animus/rest/mappers/intake/second_instance_decision_mapper.dart';
import 'package:animus/rest/mappers/intake/second_instance_judgment_draft_mapper.dart';
import 'package:animus/rest/mappers/shared/cursor_pagination_mapper.dart';
import 'package:animus/rest/services/service.dart';

class IntakeRestService extends Service implements IntakeService {
  IntakeRestService({required RestClient restClient}) : super(restClient);

  @override
  Future<RestResponse<CursorPaginationResponse<AnalysisDto>>> listAnalyses({
    String? cursor,
    required int limit,
    bool isArchived = false,
    String search = '',
  }) async {
    final Json queryParams = <String, dynamic>{
      'limit': limit,
      'is_archived': isArchived,
    };

    if (cursor != null && cursor.trim().isNotEmpty) {
      queryParams['cursor'] = cursor;
    }

    final String trimmedSearch = search.trim();
    if (trimmedSearch.isNotEmpty) {
      queryParams['search'] = trimmedSearch;
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
  Future<RestResponse<AnalysisDto>> createAnalysis({
    required AnalysisTypeDto type,
    String? folderId,
  }) async {
    final String? normalizedFolderId = folderId?.trim();
    final Json body = <String, dynamic>{'type': type.value};

    if (normalizedFolderId != null && normalizedFolderId.isNotEmpty) {
      body['folder_id'] = normalizedFolderId;
    }

    final response = await restClient.post('/intake/analyses', body: body);
    return response.mapBody<AnalysisDto>(AnalysisMapper.toDto);
  }

  @override
  Future<RestResponse<List<AnalysisDto>>> listProcessingAnalyses() async {
    final RestResponse<Map<String, dynamic>> response = await restClient.get(
      '/intake/analyses/processing',
    );

    return response.mapBody<List<AnalysisDto>>((Json json) {
      final dynamic itemsValue =
          json['items'] ?? json['analyses'] ?? json['data'];
      if (itemsValue is! List<dynamic>) {
        return const <AnalysisDto>[];
      }

      return itemsValue
          .whereType<Json>()
          .map(AnalysisMapper.toDto)
          .toList(growable: false);
    });
  }

  @override
  Future<RestResponse<AnalysisStatusDto>> updateAnalysisStatus({
    required String analysisId,
    required AnalysisStatusDto status,
  }) async {
    final RestResponse<Map<String, dynamic>> response = await restClient.patch(
      '/intake/analyses/$analysisId/status',
      body: <String, dynamic>{'status': status.value},
    );

    return response.mapBody<AnalysisStatusDto>(_mapAnalysisStatus);
  }

  @override
  Future<RestResponse<AnalysisDto>> getAnalysis({
    required String analysisId,
  }) async {
    final RestResponse<Map<String, dynamic>> response = await restClient.get(
      '/intake/analyses/$analysisId',
    );

    return response.mapBody<AnalysisDto>(AnalysisMapper.toDto);
  }

  @override
  Future<RestResponse<AnalysisDocumentDto>> createAnalysisDocument({
    required String analysisId,
    required AnalysisDocumentDto document,
  }) async {
    final RestResponse<Map<String, dynamic>> response = await restClient.post(
      '/intake/analyses/$analysisId/documents',
      body: <String, dynamic>{
        'uploaded_at': document.uploadedAt,
        'file_path': document.filePath,
        'name': document.name,
      },
    );

    return response.mapBody<AnalysisDocumentDto>(AnalysisDocumentMapper.toDto);
  }

  @override
  Future<RestResponse<AnalysisDocumentDto>> getAnalysisDocument({
    required String analysisId,
  }) async {
    final RestResponse<Map<String, dynamic>> response = await restClient.get(
      '/intake/analyses/$analysisId/documents',
    );

    return response.mapBody<AnalysisDocumentDto>(AnalysisDocumentMapper.toDto);
  }

  @override
  Future<RestResponse<CaseAssessmentBriefingDto>> submitCaseAssessmentBriefing({
    required String analysisId,
    required CaseAssessmentBriefingDto briefing,
  }) async {
    final RestResponse<Map<String, dynamic>> response = await restClient.post(
      '/intake/analyses/$analysisId/case-assessment-briefing',
      body: CaseAssessmentBriefingMapper.toJson(briefing),
    );

    return response.mapBody<CaseAssessmentBriefingDto>(
      CaseAssessmentBriefingMapper.toDto,
    );
  }

  @override
  Future<RestResponse<CaseAssessmentBriefingDto>> getCaseAssessmentBriefing({
    required String analysisId,
  }) async {
    final RestResponse<Map<String, dynamic>> response = await restClient.get(
      '/intake/analyses/$analysisId/case-assessment-briefing',
    );

    return response.mapBody<CaseAssessmentBriefingDto>(
      CaseAssessmentBriefingMapper.toDto,
    );
  }

  @override
  Future<RestResponse<SecondInstanceDecisionDto>> createSecondInstanceDecision({
    required String analysisId,
    required String description,
  }) async {
    final RestResponse<Map<String, dynamic>> response = await restClient.post(
      '/intake/analyses/$analysisId/second-instance-decision',
      body: <String, dynamic>{'description': description},
    );

    return response.mapBody<SecondInstanceDecisionDto>(
      SecondInstanceDecisionMapper.toDto,
    );
  }

  @override
  Future<RestResponse<SecondInstanceDecisionDto>> getSecondInstanceDecision({
    required String analysisId,
  }) async {
    final RestResponse<Map<String, dynamic>> response = await restClient.get(
      '/intake/analyses/$analysisId/second-instance-decision',
    );

    return response.mapBody<SecondInstanceDecisionDto>(
      SecondInstanceDecisionMapper.toDto,
    );
  }

  @override
  Future<RestResponse<void>> removeAnalysisDocument({
    required String analysisId,
    required String filePath,
  }) async {
    final RestResponse<Map<String, dynamic>> response = await restClient.delete(
      '/intake/analyses/$analysisId/documents',
      queryParams: <String, dynamic>{'file_path': filePath},
    );

    return response;
  }

  @override
  Future<RestResponse<SecondInstanceAnalysisReportDto>>
  getSecondInstanceAnalysisReport({required String analysisId}) async {
    final RestResponse<Map<String, dynamic>> response = await restClient.get(
      '/intake/analyses/$analysisId/reports/second-instance',
    );

    if (response.isFailure) {
      return RestResponse<SecondInstanceAnalysisReportDto>(
        statusCode: response.statusCode,
        errorMessage: resolveErrorMessage(response),
        errorBody: response.errorBody,
      );
    }

    try {
      return RestResponse<SecondInstanceAnalysisReportDto>(
        body: SecondInstanceAnalysisReportMapper.toDto(response.body),
        statusCode: response.statusCode,
      );
    } on FormatException catch (error) {
      return RestResponse<SecondInstanceAnalysisReportDto>(
        statusCode: HttpStatus.badGateway,
        errorMessage: error.message,
        errorBody: response.errorBody,
      );
    }
  }

  @override
  Future<RestResponse<CaseAssessmentAnalysisReportDto>>
  getCaseAssessmentAnalysisReport({required String analysisId}) async {
    final RestResponse<Map<String, dynamic>> response = await restClient.get(
      '/intake/analyses/$analysisId/reports/case-assessment',
    );

    if (response.isFailure) {
      return RestResponse<CaseAssessmentAnalysisReportDto>(
        statusCode: response.statusCode,
        errorMessage: resolveErrorMessage(response),
        errorBody: response.errorBody,
      );
    }

    try {
      return RestResponse<CaseAssessmentAnalysisReportDto>(
        body: CaseAssessmentAnalysisReportMapper.toDto(response.body),
        statusCode: response.statusCode,
      );
    } on FormatException catch (error) {
      return RestResponse<CaseAssessmentAnalysisReportDto>(
        statusCode: HttpStatus.badGateway,
        errorMessage: error.message,
        errorBody: response.errorBody,
      );
    }
  }

  @override
  Future<RestResponse<FirstInstanceAnalysisReportDto>>
  getFirstInstanceAnalysisReport({required String analysisId}) async {
    final RestResponse<Map<String, dynamic>> response = await restClient.get(
      '/intake/analyses/$analysisId/reports/first-instance',
    );

    if (response.isFailure) {
      return RestResponse<FirstInstanceAnalysisReportDto>(
        statusCode: response.statusCode,
        errorMessage: resolveErrorMessage(response),
        errorBody: response.errorBody,
      );
    }

    try {
      return RestResponse<FirstInstanceAnalysisReportDto>(
        body: FirstInstanceAnalysisReportMapper.toDto(response.body),
        statusCode: response.statusCode,
      );
    } on FormatException catch (error) {
      return RestResponse<FirstInstanceAnalysisReportDto>(
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
    final String normalizedName = name.trim();

    final RestResponse<Map<String, dynamic>> response = await restClient.patch(
      '/intake/analyses/$analysisId/name',
      body: <String, dynamic>{'name': normalizedName},
    );

    return response.mapBody<AnalysisDto>(AnalysisMapper.toDto);
  }

  @override
  Future<RestResponse<List<AnalysisDto>>> archiveAnalysis({
    required String analysisId,
  }) async {
    final RestResponse<Map<String, dynamic>> response = await restClient.patch(
      '/intake/analyses/archive',
      body: <String, dynamic>{
        'analysis_ids': <String>[analysisId],
      },
    );

    return response.mapBody<List<AnalysisDto>>((Json json) {
      final dynamic itemsValue = json['items'];
      if (itemsValue is! List<dynamic>) {
        return const <AnalysisDto>[];
      }

      return itemsValue
          .whereType<Json>()
          .map(AnalysisMapper.toDto)
          .toList(growable: false);
    });
  }

  @override
  Future<RestResponse<AnalysisDto>> unarchiveAnalysis({
    required String analysisId,
  }) async {
    final RestResponse<Map<String, dynamic>> response = await restClient.patch(
      '/intake/analyses/$analysisId/unarchive',
    );

    return response.mapBody<AnalysisDto>(AnalysisMapper.toDto);
  }

  @override
  Future<RestResponse<CaseSummaryDto>> getCaseSummary({
    required String analysisId,
  }) async {
    final RestResponse<Map<String, dynamic>> response = await restClient.get(
      '/intake/analyses/$analysisId/case-summaries',
    );

    return response.mapBody<CaseSummaryDto>(CaseSummaryMapper.toDto);
  }

  @override
  Future<RestResponse<PetitionDraftDto>> getPetitionDraft({
    required String analysisId,
  }) async {
    final RestResponse<Map<String, dynamic>> response = await restClient.get(
      '/intake/analyses/$analysisId/petition-drafts',
    );

    return response.mapBody<PetitionDraftDto>(PetitionDraftMapper.toDto);
  }

  @override
  Future<RestResponse<PetitionDraftDto>> updatePetitionDraft({
    required String analysisId,
    required PetitionDraftDto draft,
  }) async {
    final RestResponse<Map<String, dynamic>> response = await restClient.put(
      '/intake/analyses/$analysisId/petition-drafts',
      body: <String, dynamic>{
        'structured_facts': draft.structuredFacts,
        'legal_grounds': draft.legalGrounds,
        'central_thesis': draft.centralThesis,
        'requests': draft.requests,
        'precedent_citations': draft.precedentCitations,
      },
    );

    return response.mapBody<PetitionDraftDto>(PetitionDraftMapper.toDto);
  }

  @override
  Future<RestResponse<AnalysisDocumentDto>> exportPetitionDraft({
    required String analysisId,
  }) async {
    final RestResponse<Map<String, dynamic>> response = await restClient.post(
      '/intake/analyses/$analysisId/petition-drafts/export',
    );

    return response.mapBody<AnalysisDocumentDto>(AnalysisDocumentMapper.toDto);
  }

  @override
  Future<RestResponse<AnalysisDocumentDto>> exportJudgmentDraft({
    required String analysisId,
  }) async {
    final RestResponse<Map<String, dynamic>> response = await restClient.post(
      '/intake/analyses/$analysisId/second-instance-judgment-drafts/docx',
    );

    return response.mapBody<AnalysisDocumentDto>(AnalysisDocumentMapper.toDto);
  }

  @override
  Future<RestResponse<void>> triggerFirstInstanceCaseSummarization({
    required String analysisId,
  }) async {
    final RestResponse<Map<String, dynamic>> response = await restClient.post(
      '/intake/analyses/$analysisId/case-summaries/first-instance',
    );

    return toVoidResponse(response);
  }

  @override
  Future<RestResponse<void>> triggerCaseAssessmentCaseSummarization({
    required String analysisId,
  }) async {
    final RestResponse<Map<String, dynamic>> response = await restClient.post(
      '/intake/analyses/$analysisId/case-summaries/case-assessment',
    );

    return toVoidResponse(response);
  }

  @override
  Future<RestResponse<void>> triggerSecondInstanceCaseSummarization({
    required String analysisId,
  }) async {
    final RestResponse<Map<String, dynamic>> response = await restClient.post(
      '/intake/analyses/$analysisId/case-summaries/second-instance',
    );

    return toVoidResponse(response);
  }

  @override
  Future<RestResponse<void>> triggerSecondInstanceJudgmentDraftGeneration({
    required String analysisId,
  }) async {
    final RestResponse<Map<String, dynamic>> response = await restClient.post(
      '/intake/analyses/$analysisId/second-instance-judgment-drafts',
    );

    return toVoidResponse(response);
  }

  @override
  Future<RestResponse<void>> triggerPetitionDraftGeneration({
    required String analysisId,
  }) async {
    final RestResponse<Map<String, dynamic>> response = await restClient.post(
      '/intake/analyses/$analysisId/petition-drafts',
    );

    return toVoidResponse(response);
  }

  @override
  Future<RestResponse<void>> regeneratePetitionDraft({
    required String analysisId,
    required String comments,
  }) async {
    final RestResponse<Map<String, dynamic>> response = await restClient.post(
      '/intake/analyses/$analysisId/petition-drafts/regenerate',
      body: <String, dynamic>{'comments': comments.trim()},
    );

    return toVoidResponse(response);
  }

  @override
  Future<RestResponse<void>> regenerateJudgmentDraft({
    required String analysisId,
    required String comments,
  }) async {
    final RestResponse<Map<String, dynamic>> response = await restClient.post(
      '/intake/analyses/$analysisId/judgment-drafts/regenerate',
      body: <String, dynamic>{'comments': comments.trim()},
    );

    return toVoidResponse(response);
  }

  @override
  Future<RestResponse<SecondInstanceJudgmentDraftDto>>
  getSecondInstanceJudgmentDraft({required String analysisId}) async {
    final RestResponse<Map<String, dynamic>> response = await restClient.get(
      '/intake/analyses/$analysisId/second-instance-judgment-drafts',
    );

    return response.mapBody<SecondInstanceJudgmentDraftDto>(
      SecondInstanceJudgmentDraftMapper.toDto,
    );
  }

  @override
  Future<RestResponse<SecondInstanceJudgmentDraftDto>>
  updateSecondInstanceJudgmentDraft({
    required String analysisId,
    required SecondInstanceJudgmentDraftDto dto,
  }) async {
    final Json body = <String, dynamic>{
      'analysis_id': dto.analysisId,
      'report': dto.report,
      'merit_analysis': dto.meritAnalysis,
      'precedent_adherence_analysis': dto.precedentAdherenceAnalysis,
      'ruling': dto.ruling,
      'preliminary_issues': dto.preliminaryIssues,
      'no_applicable_precedent_notice': dto.noApplicablePrecedentNotice,
    };

    final RestResponse<Map<String, dynamic>> response = await restClient.put(
      '/intake/analyses/$analysisId/second-instance-judgment-drafts',
      body: body,
    );

    return response.mapBody<SecondInstanceJudgmentDraftDto>(
      SecondInstanceJudgmentDraftMapper.toDto,
    );
  }

  @override
  Future<RestResponse<void>> searchAnalysisPrecedents({
    required String analysisId,
    required AnalysisPrecedentsSearchFiltersDto filters,
  }) async {
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
    final RestResponse<Map<String, dynamic>> response = await restClient.patch(
      '/intake/analyses/$analysisId/precedents/choose',
      queryParams: <String, dynamic>{
        'court': identifier.court.value,
        'kind': identifier.kind.value,
        'number': identifier.number,
      },
    );

    return response.mapBody<AnalysisStatusDto>(_mapAnalysisStatus);
  }

  @override
  Future<RestResponse<PrecedentDto>> getPrecedent({
    required PrecedentIdentifierDto identifier,
  }) async {
    final RestResponse<Map<String, dynamic>> response = await restClient.get(
      '/intake/precedents',
      queryParams: <String, dynamic>{
        'court': identifier.court.value,
        'kind': identifier.kind.value,
        'number': identifier.number,
      },
    );

    return response.mapBody<PrecedentDto>(PrecedentMapper.toDto);
  }

  @override
  Future<RestResponse<AnalysisPrecedentDto>> addAnalysisPrecedent({
    required String analysisId,
    required PrecedentIdentifierDto identifier,
  }) async {
    final RestResponse<Map<String, dynamic>> response = await restClient.post(
      '/intake/analyses/$analysisId/precedents',
      body: <String, dynamic>{
        'court': identifier.court.value,
        'kind': identifier.kind.value,
        'number': identifier.number,
      },
    );

    return response.mapBody<AnalysisPrecedentDto>(
      AnalysisPrecedentMapper.toDto,
    );
  }

  @override
  Future<RestResponse<AnalysisStatusDto>> unchooseAnalysisPrecedent({
    required String analysisId,
    required PrecedentIdentifierDto identifier,
  }) async {
    final RestResponse<Map<String, dynamic>> response = await restClient.patch(
      '/intake/analyses/$analysisId/precedents/unchoose',
      queryParams: <String, dynamic>{
        'court': identifier.court.value,
        'kind': identifier.kind.value,
        'number': identifier.number,
      },
    );

    return response.mapBody<AnalysisStatusDto>(_mapAnalysisStatus);
  }

  @override
  Future<RestResponse<AnalysisStatusDto>> getAnalysisStatus({
    required String analysisId,
  }) async {
    final RestResponse<Map<String, dynamic>> response = await restClient.get(
      '/intake/analyses/$analysisId/status',
    );

    return response.mapBody<AnalysisStatusDto>(_mapAnalysisStatus);
  }

  static AnalysisStatusDto _mapAnalysisStatus(Json json) {
    final String statusValue =
        (json['status'] ?? json['analysis_status'] ?? json['value'] ?? '')
            .toString();

    return AnalysisStatusDto.values.firstWhere(
      (AnalysisStatusDto status) => status.value == statusValue,
      orElse: () => AnalysisStatusDto.waitingPrecedentChoice,
    );
  }
}
