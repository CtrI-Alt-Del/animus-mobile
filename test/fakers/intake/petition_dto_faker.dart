import 'package:animus/core/intake/dtos/petition_document_dto.dart';
import 'package:animus/core/intake/dtos/petition_dto.dart';

final class PetitionDocumentDtoFaker {
  const PetitionDocumentDtoFaker._();

  static PetitionDocumentDto fake({
    String filePath = 'uploads/petitions/petition-1.pdf',
    String name = 'petition.pdf',
  }) {
    return PetitionDocumentDto(filePath: filePath, name: name);
  }
}

final class PetitionDtoFaker {
  const PetitionDtoFaker._();

  static PetitionDto fake({
    String? id = 'petition-1',
    String analysisId = 'analysis-1',
    String uploadedAt = '2026-04-02T12:00:00Z',
    PetitionDocumentDto? document,
  }) {
    return PetitionDto(
      id: id,
      analysisId: analysisId,
      uploadedAt: uploadedAt,
      document: document ?? PetitionDocumentDtoFaker.fake(),
    );
  }
}
