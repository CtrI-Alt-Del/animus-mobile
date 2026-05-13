enum SecondInstanceAnalysisStatusDto {
  waitingDocumentUpload('WAITING_DOCUMENT_UPLOAD'),
  documentUploaded('DOCUMENT_UPLOADED'),
  extractingPetition('EXTRACTING_PETITION'),
  analyzingCase('ANALYZING_CASE'),
  caseAnalyzed('CASE_ANALYZED'),
  searchingPrecedents('SEARCHING_PRECEDENTS'),
  analyzingPrecedentsSimilarity('ANALYZING_PRECEDENTS_SIMILARITY'),
  analyzingPrecedentsApplicability('ANALYZING_PRECEDENTS_APPLICABILITY'),
  generatingJudgmentDraft('GENERATING_JUDGMENT_DRAFT'),
  done('DONE'),
  failed('FAILED');

  final String value;
  const SecondInstanceAnalysisStatusDto(this.value);
}
