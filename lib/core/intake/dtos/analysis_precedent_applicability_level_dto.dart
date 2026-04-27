enum AnalysisPrecedentApplicabilityLevelDto {
  notApplicable(0),
  possiblyApplicable(1),
  applicable(2);

  final int value;

  const AnalysisPrecedentApplicabilityLevelDto(this.value);
}
