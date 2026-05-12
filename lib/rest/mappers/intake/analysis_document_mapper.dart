import 'package:animus/core/intake/dtos/analysis_document_dto.dart';
import 'package:animus/core/shared/types/json.dart';

final class AnalysisDocumentMapper {
  const AnalysisDocumentMapper._();

  static AnalysisDocumentDto toDto(Json json) {
    return AnalysisDocumentDto(
      analysisId: (json['analysis_id'] as String?) ?? '',
      uploadedAt: (json['uploaded_at'] as String?) ?? '',
      filePath: (json['file_path'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
    );
  }
}
