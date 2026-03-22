import 'package:animus_mobile/core/intake/dtos/petition_document_dto.dart';

class PetitionDto {
  final String analysisId;
  final String uploadedAt;
  final PetitionDocumentDto document;
  final String? id;

  const PetitionDto({
    required this.analysisId,
    required this.uploadedAt,
    required this.document,
    this.id,
  });
}
