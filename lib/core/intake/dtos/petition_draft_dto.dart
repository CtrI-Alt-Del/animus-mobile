class PetitionDraftDto {
  final String analysisId;
  final String structuredFacts;
  final String legalGrounds;
  final String centralThesis;
  final List<String> requests;
  final List<String> precedentCitations;

  const PetitionDraftDto({
    required this.analysisId,
    required this.structuredFacts,
    required this.legalGrounds,
    required this.centralThesis,
    required this.requests,
    required this.precedentCitations,
  });
}
