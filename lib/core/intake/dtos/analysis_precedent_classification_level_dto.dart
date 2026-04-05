enum AnalysisPrecedentClassificationLevelDto {
  applicable('APPLICABLE'),
  possiblyApplicable('POSSIBLY_APPLICABLE'),
  notApplicable('NOT_APPLICABLE');

  final String value;
  const AnalysisPrecedentClassificationLevelDto(this.value);
}
