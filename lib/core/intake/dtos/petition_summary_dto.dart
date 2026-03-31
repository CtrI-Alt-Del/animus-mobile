class PetitionSummaryDto {
  final String caseSummary;
  final String legalIssue;
  final String centralQuestion;
  final List<String> relevantLaws;
  final List<String> keyFacts;
  final List<String> searchTerms;

  PetitionSummaryDto({
    required this.caseSummary,
    required this.legalIssue,
    required this.centralQuestion,
    required this.relevantLaws,
    required this.keyFacts,
    required this.searchTerms,
  });
}
