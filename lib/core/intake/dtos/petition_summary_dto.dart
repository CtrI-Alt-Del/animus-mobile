class PetitionSummaryDto {
  final String caseSummary;
  final String legalIssue;
  final String centralQuestion;
  final List<String> relevantLaws;
  final List<String> keyFacts;
  final List<String> searchTerms;

  final String? typeOfAction;
  final String? jurisdictionIssue;
  final String? standingIssue;
  final List<String> secondaryLegalIssues;
  final List<String> alternativeQuestions;
  final List<String> requestedRelief;
  final List<String> proceduralIssues;
  final List<String> excludedOrAccessoryTopics;

  PetitionSummaryDto({
    required this.caseSummary,
    required this.legalIssue,
    required this.centralQuestion,
    required this.relevantLaws,
    required this.keyFacts,
    required this.searchTerms,
    this.typeOfAction,
    this.jurisdictionIssue,
    this.standingIssue,
    required this.secondaryLegalIssues,
    required this.alternativeQuestions,
    required this.requestedRelief,
    required this.proceduralIssues,
    required this.excludedOrAccessoryTopics,
  });
}
