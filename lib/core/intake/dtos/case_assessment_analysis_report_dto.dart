import 'package:animus/core/intake/dtos/analysis_document_dto.dart';
import 'package:animus/core/intake/dtos/analysis_dto.dart';
import 'package:animus/core/intake/dtos/analysis_precedent_dto.dart';
import 'package:animus/core/intake/dtos/case_assessment_briefing_dto.dart';
import 'package:animus/core/intake/dtos/case_summary_dto.dart';
import 'package:animus/core/intake/dtos/petition_draft_dto.dart';

class CaseAssessmentAnalysisReportDto {
  final AnalysisDto analysis;
  final List<AnalysisDocumentDto> documents;
  final CaseSummaryDto caseSummary;
  final CaseAssessmentBriefingDto briefing;
  final List<AnalysisPrecedentDto> precedents;
  final PetitionDraftDto petitionDraft;

  const CaseAssessmentAnalysisReportDto({
    required this.analysis,
    required this.documents,
    required this.caseSummary,
    required this.briefing,
    required this.precedents,
    required this.petitionDraft,
  });
}
