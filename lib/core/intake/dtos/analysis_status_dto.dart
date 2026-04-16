enum AnalysisStatusDto {
  waitingPetition('WAITING_PETITION'),
  petitionUploaded('PETITION_UPLOADED'),
  analyzingPetition('ANALYZING_PETITION'),
  petitionAnalyzed('PETITION_ANALYZED'),
  searchingPrecedents('SEARCHING_PRECEDENTS'),
  analyzingPrecedentsSimilarity('ANALYZING_PRECEDENTS_SIMILARITY'),
  analyzingPrecedentsApplicability('ANALYZING_PRECEDENTS_APPLICABILITY'),
  generatingSynthesis('GENERATING_SYNTHESIS'),
  waitingPrecedentChoice('WAITING_PRECEDENT_CHOISE'),
  precedentChosen('PRECEDENT_CHOSED'),
  failed('FAILED');

  final String value;
  const AnalysisStatusDto(this.value);
}
