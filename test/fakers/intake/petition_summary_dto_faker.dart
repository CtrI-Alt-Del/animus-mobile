import 'package:animus/core/intake/dtos/petition_summary_dto.dart';

final class PetitionSummaryDtoFaker {
  const PetitionSummaryDtoFaker._();

  static PetitionSummaryDto fake({
    String caseSummary = 'Resumo sintetico do caso.',
    String legalIssue = 'Questao juridica principal.',
    String centralQuestion = 'Pergunta central da peticao.',
    List<String> relevantLaws = const <String>['Art. 5'],
    List<String> keyFacts = const <String>['Fato relevante 1'],
    List<String> searchTerms = const <String>['termo-chave'],
  }) {
    return PetitionSummaryDto(
      caseSummary: caseSummary,
      legalIssue: legalIssue,
      centralQuestion: centralQuestion,
      relevantLaws: relevantLaws,
      keyFacts: keyFacts,
      searchTerms: searchTerms,
    );
  }
}
