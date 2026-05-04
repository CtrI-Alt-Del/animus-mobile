import 'package:animus/core/intake/dtos/analysis_dto.dart';
import 'package:animus/core/library/dtos/folder_dto.dart';
import 'package:animus/core/shared/responses/cursor_pagination_response.dart';
import 'package:animus/core/shared/responses/rest_response.dart';

abstract class LibraryService {
  Future<RestResponse<CursorPaginationResponse<FolderDto>>> listFolders({
    String? cursor,
    required int limit,
  });

  Future<RestResponse<CursorPaginationResponse<AnalysisDto>>>
  listUnfolderedAnalyses({String? cursor, required int limit});

  Future<RestResponse<CursorPaginationResponse<AnalysisDto>>>
  listFolderAnalyses({
    required String folderId,
    String? cursor,
    required int limit,
  });

  Future<RestResponse<FolderDto>> getFolder({required String folderId});

  Future<RestResponse<FolderDto>> createFolder({required String name});

  Future<RestResponse<FolderDto>> updateFolderName({
    required String folderId,
    required String name,
  });

  Future<RestResponse<FolderDto>> archiveFolder({required String folderId});

  Future<RestResponse<void>> moveAnalysesToFolder({
    required List<String> analysisIds,
    required String? folderId,
  });

  Future<RestResponse<void>> archiveAnalyses({
    required List<String> analysisIds,
  });
}
