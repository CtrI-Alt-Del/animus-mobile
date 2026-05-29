enum CaseAssessmentAnalysisStatusDto {
  waitingDocumentUpload('WAITING_DOCUMENT_UPLOAD'),
  documentUploaded('DOCUMENT_UPLOADED'),
  analyzingCase('ANALYZING_CASE'),
  caseAnalyzed('CASE_ANALYZED'),
  searchingPrecedents('SEARCHING_PRECEDENTS'),
  analyzingPrecedentsSimilarity('ANALYZING_PRECEDENTS_SIMILARITY'),
  analyzingPrecedentsApplicability('ANALYZING_PRECEDENTS_APPLICABILITY'),
  generatingPetitionDraft('GENERATING_PETITION_DRAFT'),
  done('DONE'),
  failed('FAILED');

  final String value;
  const CaseAssessmentAnalysisStatusDto(this.value);
}
