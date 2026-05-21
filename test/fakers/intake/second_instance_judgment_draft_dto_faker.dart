import 'package:animus/core/intake/dtos/second_instance_judgment_draft_dto.dart';

final class SecondInstanceJudgmentDraftDtoFaker {
  const SecondInstanceJudgmentDraftDtoFaker._();

  static SecondInstanceJudgmentDraftDto fake({
    String analysisId = 'analysis-1',
    String report = 'Relatorio da minuta.',
    String meritAnalysis = 'Analise de merito.',
    String precedentAdherenceAnalysis = 'Analise de aderencia ao precedente.',
    List<String> ruling = const <String>['Dar provimento'],
    String? preliminaryIssues = 'Sem preliminares relevantes.',
    String? noApplicablePrecedentNotice,
  }) {
    return SecondInstanceJudgmentDraftDto(
      analysisId: analysisId,
      report: report,
      meritAnalysis: meritAnalysis,
      precedentAdherenceAnalysis: precedentAdherenceAnalysis,
      ruling: ruling,
      preliminaryIssues: preliminaryIssues,
      noApplicablePrecedentNotice: noApplicablePrecedentNotice,
    );
  }
}
