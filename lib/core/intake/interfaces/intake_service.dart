import 'package:animus/core/intake/dtos/analysis_dto.dart';
import 'package:animus/core/intake/dtos/analysis_precedent_dto.dart';
import 'package:animus/core/intake/dtos/analysis_precedents_search_filters_dto.dart';
import 'package:animus/core/intake/dtos/analysis_report_dto.dart';
import 'package:animus/core/intake/dtos/analysis_status_dto.dart';
import 'package:animus/core/intake/dtos/petition_dto.dart';
import 'package:animus/core/intake/dtos/petition_summary_dto.dart';
import 'package:animus/core/intake/dtos/precedent_identifier_dto.dart';
import 'package:animus/core/shared/responses/cursor_pagination_response.dart';
import 'package:animus/core/shared/responses/list_response.dart';
import 'package:animus/core/shared/responses/rest_response.dart';

abstract class IntakeService {
  Future<RestResponse<CursorPaginationResponse<AnalysisDto>>> listAnalyses({
    String? cursor,
    required int limit,
    bool isArchived = false,
  });

  Future<RestResponse<AnalysisDto>> createAnalysis({String? folderId});

  Future<RestResponse<PetitionDto>> createPetition({
    required PetitionDto petition,
  });

  Future<RestResponse<AnalysisDto>> getAnalysis({required String analysisId});

  Future<RestResponse<AnalysisReportDto>> getAnalysisReport({
    required String analysisId,
  });

  Future<RestResponse<AnalysisDto>> renameAnalysis({
    required String analysisId,
    required String name,
  });

  Future<RestResponse<AnalysisDto>> archiveAnalysis({
    required String analysisId,
  });

  Future<RestResponse<PetitionDto>> getAnalysisPetition({
    required String analysisId,
  });

  Future<RestResponse<PetitionSummaryDto>> getPetitionSummary({
    required String petitionId,
  });

  Future<RestResponse<void>> summarizePetition({required String petitionId});

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
}
