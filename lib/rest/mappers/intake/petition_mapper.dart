import 'package:animus/core/intake/dtos/petition_document_dto.dart';
import 'package:animus/core/intake/dtos/petition_dto.dart';
import 'package:animus/core/shared/types/json.dart';

final class PetitionMapper {
  const PetitionMapper._();

  static PetitionDto toDto(Json json) {
    final Json document = json['document'] is Json
        ? json['document'] as Json
        : <String, dynamic>{};

    return PetitionDto(
      id: json['id'] as String?,
      analysisId: (json['analysis_id'] as String?) ?? '',
      uploadedAt: (json['uploaded_at'] as String?) ?? '',
      document: PetitionDocumentDto(
        filePath: (document['file_path'] as String?) ?? '',
        name: (document['name'] as String?) ?? '',
      ),
    );
  }

  static Json toJson(PetitionDto dto) {
    return <String, dynamic>{
      'analysis_id': dto.analysisId,
      'uploaded_at': dto.uploadedAt,
      'document': <String, dynamic>{
        'file_path': dto.document.filePath,
        'name': dto.document.name,
      },
    };
  }
}
