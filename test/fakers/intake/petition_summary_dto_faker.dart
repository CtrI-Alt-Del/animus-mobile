import 'package:animus/core/intake/dtos/case_summary_dto.dart';

final class PetitionSummaryDtoFaker {
  const PetitionSummaryDtoFaker._();

  static CaseSummaryDto fake({
    String caseSummary = 'Resumo sintetico do caso.',
    String legalIssue = 'Questao juridica principal.',
    String centralQuestion = 'Pergunta central da peticao.',
    List<String> relevantLaws = const <String>['Art. 5'],
    List<String> keyFacts = const <String>['Fato relevante 1'],
    List<String> searchTerms = const <String>['termo-chave'],
    String? typeOfAction,
    String? jurisdictionIssue,
    String? standingIssue,
    List<String> secondaryLegalIssues = const <String>[],
    List<String> alternativeQuestions = const <String>[],
    List<String> requestedRelief = const <String>[],
    List<String> proceduralIssues = const <String>[],
    List<String> excludedOrAccessoryTopics = const <String>[],
  }) {
    return CaseSummaryDto(
      caseSummary: caseSummary,
      legalIssue: legalIssue,
      centralQuestion: centralQuestion,
      relevantLaws: relevantLaws,
      keyFacts: keyFacts,
      searchTerms: searchTerms,
      typeOfAction: typeOfAction,
      jurisdictionIssue: jurisdictionIssue,
      standingIssue: standingIssue,
      secondaryLegalIssues: secondaryLegalIssues,
      alternativeQuestions: alternativeQuestions,
      requestedRelief: requestedRelief,
      proceduralIssues: proceduralIssues,
      excludedOrAccessoryTopics: excludedOrAccessoryTopics,
    );
  }
}

final class CaseSummaryDtoFaker {
  const CaseSummaryDtoFaker._();

  static CaseSummaryDto fake({
    String caseSummary = 'Resumo sintetico do caso.',
    String legalIssue = 'Questao juridica principal.',
    String centralQuestion = 'Pergunta central da peticao.',
    List<String> relevantLaws = const <String>['Art. 5'],
    List<String> keyFacts = const <String>['Fato relevante 1'],
    List<String> searchTerms = const <String>['termo-chave'],
    String? typeOfAction,
    String? jurisdictionIssue,
    String? standingIssue,
    List<String> secondaryLegalIssues = const <String>[],
    List<String> alternativeQuestions = const <String>[],
    List<String> requestedRelief = const <String>[],
    List<String> proceduralIssues = const <String>[],
    List<String> excludedOrAccessoryTopics = const <String>[],
  }) {
    return PetitionSummaryDtoFaker.fake(
      caseSummary: caseSummary,
      legalIssue: legalIssue,
      centralQuestion: centralQuestion,
      relevantLaws: relevantLaws,
      keyFacts: keyFacts,
      searchTerms: searchTerms,
      typeOfAction: typeOfAction,
      jurisdictionIssue: jurisdictionIssue,
      standingIssue: standingIssue,
      secondaryLegalIssues: secondaryLegalIssues,
      alternativeQuestions: alternativeQuestions,
      requestedRelief: requestedRelief,
      proceduralIssues: proceduralIssues,
      excludedOrAccessoryTopics: excludedOrAccessoryTopics,
    );
  }
}
