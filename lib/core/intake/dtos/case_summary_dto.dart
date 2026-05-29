class CaseSummaryDto {
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

  const CaseSummaryDto({
    required this.caseSummary,
    required this.legalIssue,
    required this.centralQuestion,
    required this.relevantLaws,
    required this.keyFacts,
    required this.searchTerms,
    this.typeOfAction,
    this.jurisdictionIssue,
    this.standingIssue,
    this.secondaryLegalIssues = const <String>[],
    this.alternativeQuestions = const <String>[],
    this.requestedRelief = const <String>[],
    this.proceduralIssues = const <String>[],
    this.excludedOrAccessoryTopics = const <String>[],
  });
}
