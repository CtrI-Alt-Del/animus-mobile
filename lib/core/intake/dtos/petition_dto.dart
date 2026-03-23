import 'package:animus_mobile/core/intake/dtos/petition_document_dto.dart';

class PetitionDto {
  final String? id;
  final String analysisId;
  final String uploadedAt;
  final PetitionDocumentDto document;

  const PetitionDto({
    this.id,
    required this.analysisId,
    required this.uploadedAt,
    required this.document,
  });
}
