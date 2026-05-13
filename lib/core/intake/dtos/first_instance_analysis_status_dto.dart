enum FirstInstanceAnalysisStatusDto {
  waitingDocumentUpload('WAITING_DOCUMENT_UPLOAD'),
  documentUploaded('DOCUMENT_UPLOADED'),
  analyzingCase('ANALYZING_CASE'),
  caseAnalyzed('CASE_ANALYZED'),
  searchingPrecedents('SEARCHING_PRECEDENTS'),
  analyzingPrecedentsSimilarity('ANALYZING_PRECEDENTS_SIMILARITY'),
  analyzingPrecedentsApplicability('ANALYZING_PRECEDENTS_APPLICABILITY'),
  done('DONE'),
  failed('FAILED');

  final String value;
  const FirstInstanceAnalysisStatusDto(this.value);
}
