import 'package:animus/core/intake/dtos/analysis_document_dto.dart';
import 'package:animus/core/intake/dtos/analysis_dto.dart';
import 'package:animus/core/intake/dtos/analysis_precedent_dto.dart';
import 'package:animus/core/intake/dtos/case_summary_dto.dart';
import 'package:animus/core/intake/dtos/first_instance_analysis_judgment_draft_dto.dart';

class FirstInstanceAnalysisReportDto {
  final AnalysisDto analysis;
  final AnalysisDocumentDto document;
  final CaseSummaryDto caseSummary;
  final List<AnalysisPrecedentDto> precedents;
  final FirstInstanceJudgmentDraftDto judgmentDraft;

  const FirstInstanceAnalysisReportDto({
    required this.analysis,
    required this.document,
    required this.caseSummary,
    required this.precedents,
    required this.judgmentDraft,
  });
}
