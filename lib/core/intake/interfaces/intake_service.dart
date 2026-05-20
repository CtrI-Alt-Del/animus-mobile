import 'package:animus/core/intake/dtos/analysis_dto.dart';
import 'package:animus/core/intake/dtos/analysis_document_dto.dart';
import 'package:animus/core/intake/dtos/analysis_precedent_dto.dart';
import 'package:animus/core/intake/dtos/analysis_precedents_search_filters_dto.dart';
import 'package:animus/core/intake/dtos/analysis_status_dto.dart';
import 'package:animus/core/intake/dtos/analysis_type_dto.dart';
import 'package:animus/core/intake/dtos/case_assessment_analysis_report_dto.dart';
import 'package:animus/core/intake/dtos/case_summary_dto.dart';
import 'package:animus/core/intake/dtos/first_instance_analysis_report_dto.dart';
import 'package:animus/core/intake/dtos/judgment_draft_dto.dart';
import 'package:animus/core/intake/dtos/petition_draft_dto.dart';
import 'package:animus/core/intake/dtos/precedent_identifier_dto.dart';
import 'package:animus/core/intake/dtos/second_instance_analysis_report_dto.dart';
import 'package:animus/core/intake/dtos/second_instance_judgment_draft_dto.dart';
import 'package:animus/core/shared/responses/cursor_pagination_response.dart';
import 'package:animus/core/shared/responses/list_response.dart';
import 'package:animus/core/shared/responses/rest_response.dart';

abstract class IntakeService {
  Future<RestResponse<CursorPaginationResponse<AnalysisDto>>> listAnalyses({
    String? cursor,
    required int limit,
    bool isArchived = false,
    String search = '',
  });

  Future<RestResponse<AnalysisDto>> createAnalysis({
    required AnalysisTypeDto type,
    String? folderId,
  });

  Future<RestResponse<List<AnalysisDto>>> listProcessingAnalyses();

  Future<RestResponse<AnalysisStatusDto>> updateAnalysisStatus({
    required String analysisId,
    required AnalysisStatusDto status,
  });

  Future<RestResponse<AnalysisStatusDto>> getAnalysisStatus({
    required String analysisId,
  }) => throw UnimplementedError();

  Future<RestResponse<AnalysisDto>> getAnalysis({required String analysisId});

  Future<RestResponse<AnalysisDocumentDto>> createAnalysisDocument({
    required String analysisId,
    required AnalysisDocumentDto document,
  }) => throw UnimplementedError();

  Future<RestResponse<AnalysisDocumentDto>> getAnalysisDocument({
    required String analysisId,
  }) => throw UnimplementedError();

  Future<RestResponse<SecondInstanceAnalysisReportDto>>
  getSecondInstanceAnalysisReport({required String analysisId});

  Future<RestResponse<CaseAssessmentAnalysisReportDto>>
  getCaseAssessmentAnalysisReport({required String analysisId});

  Future<RestResponse<FirstInstanceAnalysisReportDto>>
  getFirstInstanceAnalysisReport({required String analysisId});

  Future<RestResponse<AnalysisDto>> renameAnalysis({
    required String analysisId,
    required String name,
  });

  Future<RestResponse<AnalysisDto>> archiveAnalysis({
    required String analysisId,
  });

  Future<RestResponse<AnalysisDto>> unarchiveAnalysis({
    required String analysisId,
  });

  Future<RestResponse<CaseSummaryDto>> getCaseSummary({
    required String analysisId,
  });

  Future<RestResponse<PetitionDraftDto>> getPetitionDraft({
    required String analysisId,
  });

  Future<RestResponse<JudgmentDraftDto>> getJudgmentDraft({
    required String analysisId,
  });

  Future<RestResponse<void>> triggerFirstInstanceCaseSummarization({
    required String analysisId,
  }) => throw UnimplementedError();

  Future<RestResponse<void>> triggerSecondInstanceCaseSummarization({
    required String analysisId,
  });

  Future<RestResponse<void>> triggerSecondInstanceJudgmentDraftGeneration({
    required String analysisId,
  });

  Future<RestResponse<SecondInstanceJudgmentDraftDto>>
  getSecondInstanceJudgmentDraft({required String analysisId});

  Future<RestResponse<void>> searchAnalysisPrecedents({
    required String analysisId,
    required AnalysisPrecedentsSearchFiltersDto filters,
  });

  Future<RestResponse<ListResponse<AnalysisPrecedentDto>>>
  listAnalysisPrecedents({required String analysisId});

  Future<RestResponse<AnalysisStatusDto>> chooseAnalysisPrecedent({
    required String analysisId,
    required PrecedentIdentifierDto identifier,
  });

  Future<RestResponse<AnalysisStatusDto>> unchooseAnalysisPrecedent({
    required String analysisId,
    required PrecedentIdentifierDto identifier,
  }) => throw UnimplementedError();
}
