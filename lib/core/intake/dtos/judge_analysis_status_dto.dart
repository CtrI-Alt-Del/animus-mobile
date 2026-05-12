enum JudgeAnalysisStatusDto {
  documentUploaded('DOCUMENT_UPLOADED'),
  extractingPetition('EXTRACTING_PETITION'),
  analyzingCase('ANALYZING_CASE'),
  caseAnalyzed('CASE_ANALYZED'),
  searchingPrecedents('SEARCHING_PRECEDENTS'),
  generatingJudgmentDraft('GENERATING_JUDGMENT_DRAFT'),
  done('DONE'),
  failed('FAILED');

  final String value;
  const JudgeAnalysisStatusDto(this.value);
}
