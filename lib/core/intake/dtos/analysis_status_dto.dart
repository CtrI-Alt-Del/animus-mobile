import 'package:animus/core/intake/dtos/case_assessment_analysis_status_dto.dart';
import 'package:animus/core/intake/dtos/first_instance_analysis_status_dto.dart';
import 'package:animus/core/intake/dtos/second_instance_analysis_status_dto.dart';

class AnalysisStatusDto {
  final String value;

  const AnalysisStatusDto(this.value);

  static const AnalysisStatusDto waitingPetition = AnalysisStatusDto(
    'WAITING_PETITION',
  );
  static const AnalysisStatusDto petitionUploaded = AnalysisStatusDto(
    'PETITION_UPLOADED',
  );
  static const AnalysisStatusDto waitingDocumentUpload = AnalysisStatusDto(
    'WAITING_DOCUMENT_UPLOAD',
  );
  static const AnalysisStatusDto documentUploaded = AnalysisStatusDto(
    'DOCUMENT_UPLOADED',
  );
  static const AnalysisStatusDto analyzingPetition = AnalysisStatusDto(
    'ANALYZING_PETITION',
  );
  static const AnalysisStatusDto searchingPrecedents = AnalysisStatusDto(
    'SEARCHING_PRECEDENTS',
  );
  static const AnalysisStatusDto precedentsSearched = AnalysisStatusDto(
    'PRECEDENTS_SEARCHED',
  );
  static const AnalysisStatusDto analyzingPrecedentsSimilarity =
      AnalysisStatusDto('ANALYZING_PRECEDENTS_SIMILARITY');
  static const AnalysisStatusDto analyzingPrecedentsApplicability =
      AnalysisStatusDto('ANALYZING_PRECEDENTS_APPLICABILITY');
  static const AnalysisStatusDto generatingSynthesis = AnalysisStatusDto(
    'GENERATING_SYNTHESIS',
  );
  static const AnalysisStatusDto waitingPrecedentChoice = AnalysisStatusDto(
    'WAITING_PRECEDENT_CHOISE',
  );
  static const AnalysisStatusDto precedentChosen = AnalysisStatusDto(
    'PRECEDENT_CHOSED',
  );
  static const AnalysisStatusDto failed = AnalysisStatusDto('FAILED');
  static const AnalysisStatusDto done = AnalysisStatusDto('DONE');
  static const AnalysisStatusDto extractingPetition = AnalysisStatusDto(
    'EXTRACTING_PETITION',
  );
  static const AnalysisStatusDto analyzingCase = AnalysisStatusDto(
    'ANALYZING_CASE',
  );
  static const AnalysisStatusDto caseAnalyzed = AnalysisStatusDto(
    'CASE_ANALYZED',
  );
  static const AnalysisStatusDto generatingPetitionDraft = AnalysisStatusDto(
    'GENERATING_PETITION_DRAFT',
  );
  static const AnalysisStatusDto generatingJudgmentDraft = AnalysisStatusDto(
    'GENERATING_JUDGMENT_DRAFT',
  );
  static const AnalysisStatusDto petitionNotFound = AnalysisStatusDto(
    'PETITION_NOT_FOUND',
  );

  static const List<AnalysisStatusDto> values = <AnalysisStatusDto>[
    waitingPetition,
    petitionUploaded,
    waitingDocumentUpload,
    documentUploaded,
    analyzingPetition,
    searchingPrecedents,
    precedentsSearched,
    analyzingPrecedentsSimilarity,
    analyzingPrecedentsApplicability,
    generatingSynthesis,
    waitingPrecedentChoice,
    precedentChosen,
    failed,
    done,
    extractingPetition,
    analyzingCase,
    caseAnalyzed,
    generatingPetitionDraft,
    generatingJudgmentDraft,
    petitionNotFound,
  ];

  factory AnalysisStatusDto.caseAssessment(
    CaseAssessmentAnalysisStatusDto value,
  ) {
    switch (value) {
      case CaseAssessmentAnalysisStatusDto.waitingDocumentUpload:
        return waitingDocumentUpload;
      case CaseAssessmentAnalysisStatusDto.documentUploaded:
        return documentUploaded;
      case CaseAssessmentAnalysisStatusDto.analyzingCase:
        return analyzingCase;
      case CaseAssessmentAnalysisStatusDto.caseAnalyzed:
        return caseAnalyzed;
      case CaseAssessmentAnalysisStatusDto.searchingPrecedents:
        return searchingPrecedents;
      case CaseAssessmentAnalysisStatusDto.analyzingPrecedentsSimilarity:
        return analyzingPrecedentsSimilarity;
      case CaseAssessmentAnalysisStatusDto.analyzingPrecedentsApplicability:
        return analyzingPrecedentsApplicability;
      case CaseAssessmentAnalysisStatusDto.generatingSynthesis:
        return generatingSynthesis;
      case CaseAssessmentAnalysisStatusDto.generatingPetitionDraft:
        return generatingPetitionDraft;
      case CaseAssessmentAnalysisStatusDto.precedentsSearched:
        return precedentsSearched;
      case CaseAssessmentAnalysisStatusDto.done:
        return done;
      case CaseAssessmentAnalysisStatusDto.failed:
        return failed;
    }
  }

  factory AnalysisStatusDto.firstInstance(
    FirstInstanceAnalysisStatusDto value,
  ) {
    switch (value) {
      case FirstInstanceAnalysisStatusDto.waitingDocumentUpload:
        return waitingPetition;
      case FirstInstanceAnalysisStatusDto.documentUploaded:
        return petitionUploaded;
      case FirstInstanceAnalysisStatusDto.analyzingCase:
        return analyzingPetition;
      case FirstInstanceAnalysisStatusDto.caseAnalyzed:
        return caseAnalyzed;
      case FirstInstanceAnalysisStatusDto.searchingPrecedents:
        return searchingPrecedents;
      case FirstInstanceAnalysisStatusDto.analyzingPrecedentsSimilarity:
        return analyzingPrecedentsSimilarity;
      case FirstInstanceAnalysisStatusDto.analyzingPrecedentsApplicability:
        return analyzingPrecedentsApplicability;
      case FirstInstanceAnalysisStatusDto.generatingSynthesis:
        return generatingSynthesis;
      case FirstInstanceAnalysisStatusDto.done:
        return precedentChosen;
      case FirstInstanceAnalysisStatusDto.failed:
        return failed;
    }
  }

  factory AnalysisStatusDto.secondInstance(
    SecondInstanceAnalysisStatusDto value,
  ) {
    switch (value) {
      case SecondInstanceAnalysisStatusDto.waitingDocumentUpload:
        return waitingDocumentUpload;
      case SecondInstanceAnalysisStatusDto.documentUploaded:
        return documentUploaded;
      case SecondInstanceAnalysisStatusDto.extractingPetition:
        return extractingPetition;
      case SecondInstanceAnalysisStatusDto.analyzingCase:
        return analyzingCase;
      case SecondInstanceAnalysisStatusDto.caseAnalyzed:
        return caseAnalyzed;
      case SecondInstanceAnalysisStatusDto.searchingPrecedents:
        return searchingPrecedents;
      case SecondInstanceAnalysisStatusDto.precedentsSearched:
        return precedentsSearched;
      case SecondInstanceAnalysisStatusDto.analyzingPrecedentsSimilarity:
        return analyzingPrecedentsSimilarity;
      case SecondInstanceAnalysisStatusDto.analyzingPrecedentsApplicability:
        return analyzingPrecedentsApplicability;
      case SecondInstanceAnalysisStatusDto.generatingJudgmentDraft:
        return generatingJudgmentDraft;
      case SecondInstanceAnalysisStatusDto.generatingSynthesis:
        return generatingSynthesis;
      case SecondInstanceAnalysisStatusDto.petitionNotFound:
        return petitionNotFound;
      case SecondInstanceAnalysisStatusDto.done:
        return done;
      case SecondInstanceAnalysisStatusDto.failed:
        return failed;
    }
  }

  @override
  bool operator ==(Object other) {
    return other is AnalysisStatusDto && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;
}
