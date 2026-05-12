import 'package:animus/core/intake/dtos/judge_analysis_status_dto.dart';
import 'package:animus/core/intake/dtos/lawyer_analysis_status_dto.dart';

class AnalysisStatusDto {
  final String value;

  const AnalysisStatusDto(this.value);

  static const AnalysisStatusDto waitingPetition = AnalysisStatusDto(
    'WAITING_PETITION',
  );
  static const AnalysisStatusDto petitionUploaded = AnalysisStatusDto(
    'PETITION_UPLOADED',
  );
  static const AnalysisStatusDto analyzingPetition = AnalysisStatusDto(
    'ANALYZING_PETITION',
  );
  static const AnalysisStatusDto petitionAnalyzed = AnalysisStatusDto(
    'PETITION_ANALYZED',
  );
  static const AnalysisStatusDto searchingPrecedents = AnalysisStatusDto(
    'SEARCHING_PRECEDENTS',
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

  static const List<AnalysisStatusDto> values = <AnalysisStatusDto>[
    waitingPetition,
    petitionUploaded,
    analyzingPetition,
    petitionAnalyzed,
    searchingPrecedents,
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
  ];

  factory AnalysisStatusDto.lawyer(LawyerAnalysisStatusDto value) {
    switch (value) {
      case LawyerAnalysisStatusDto.documentUploaded:
        return petitionUploaded;
      case LawyerAnalysisStatusDto.analyzingCase:
        return analyzingCase;
      case LawyerAnalysisStatusDto.caseAnalyzed:
        return petitionAnalyzed;
      case LawyerAnalysisStatusDto.searchingPrecedents:
        return searchingPrecedents;
      case LawyerAnalysisStatusDto.generatingPetitionDraft:
        return generatingPetitionDraft;
      case LawyerAnalysisStatusDto.done:
        return done;
      case LawyerAnalysisStatusDto.failed:
        return failed;
    }
  }

  factory AnalysisStatusDto.judge(JudgeAnalysisStatusDto value) {
    switch (value) {
      case JudgeAnalysisStatusDto.documentUploaded:
        return petitionUploaded;
      case JudgeAnalysisStatusDto.extractingPetition:
        return extractingPetition;
      case JudgeAnalysisStatusDto.analyzingCase:
        return analyzingCase;
      case JudgeAnalysisStatusDto.caseAnalyzed:
        return caseAnalyzed;
      case JudgeAnalysisStatusDto.searchingPrecedents:
        return searchingPrecedents;
      case JudgeAnalysisStatusDto.generatingJudgmentDraft:
        return generatingJudgmentDraft;
      case JudgeAnalysisStatusDto.done:
        return done;
      case JudgeAnalysisStatusDto.failed:
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
