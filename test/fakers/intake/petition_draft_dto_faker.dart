import 'package:animus/core/intake/dtos/petition_draft_dto.dart';

final class PetitionDraftDtoFaker {
  const PetitionDraftDtoFaker._();

  static PetitionDraftDto fake({
    String analysisId = 'analysis-1',
    String structuredFacts = 'Fatos estruturados da petição.',
    String legalGrounds = 'Fundamentos jurídicos da petição.',
    String centralThesis = 'Tese central da petição.',
    List<String> requests = const <String>['Pedido 1'],
    List<String> precedentCitations = const <String>['Precedente 1'],
  }) {
    return PetitionDraftDto(
      analysisId: analysisId,
      structuredFacts: structuredFacts,
      legalGrounds: legalGrounds,
      centralThesis: centralThesis,
      requests: requests,
      precedentCitations: precedentCitations,
    );
  }
}
