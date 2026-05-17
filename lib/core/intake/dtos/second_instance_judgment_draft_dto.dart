class SecondInstanceJudgmentDraftDto {
  final String analysisId;
  final String report;
  final String meritAnalysis;
  final String precedentAdherenceAnalysis;
  final List<String> ruling;
  final String? preliminaryIssues;
  final String? noApplicablePrecedentNotice;

  const SecondInstanceJudgmentDraftDto({
    required this.analysisId,
    required this.report,
    required this.meritAnalysis,
    required this.precedentAdherenceAnalysis,
    required this.ruling,
    this.preliminaryIssues,
    this.noApplicablePrecedentNotice,
  });
}
