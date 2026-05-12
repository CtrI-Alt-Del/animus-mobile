enum LawyerAnalysisStatusDto {
  documentUploaded('DOCUMENT_UPLOADED'),
  analyzingCase('ANALYZING_CASE'),
  caseAnalyzed('CASE_ANALYZED'),
  searchingPrecedents('SEARCHING_PRECEDENTS'),
  generatingPetitionDraft('GENERATING_PETITION_DRAFT'),
  done('DONE'),
  failed('FAILED');

  final String value;
  const LawyerAnalysisStatusDto(this.value);
}
