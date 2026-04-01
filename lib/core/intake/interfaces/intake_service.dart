import 'package:animus/core/intake/dtos/analysis_dto.dart';
import 'package:animus/core/shared/responses/cursor_pagination_response.dart';
import 'package:animus/core/shared/responses/rest_response.dart';

abstract class IntakeService {
  Future<RestResponse<CursorPaginationResponse<AnalysisDto>>> listAnalyses({
    String? cursor,
    required int limit,
    bool isArchived = false,
  });

  Future<RestResponse<AnalysisDto>> createAnalysis({String? folderId});
}
