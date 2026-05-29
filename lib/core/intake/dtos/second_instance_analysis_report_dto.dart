import 'package:animus/core/intake/dtos/analysis_document_dto.dart';
import 'package:animus/core/intake/dtos/analysis_dto.dart';
import 'package:animus/core/intake/dtos/analysis_precedent_dto.dart';
import 'package:animus/core/intake/dtos/case_summary_dto.dart';
import 'package:animus/core/intake/dtos/second_instance_judgment_draft_dto.dart';

class SecondInstanceAnalysisReportDto {
  final AnalysisDto analysis;
  final AnalysisDocumentDto document;
  final CaseSummaryDto caseSummary;
  final List<AnalysisPrecedentDto> precedents;
  final SecondInstanceJudgmentDraftDto judgmentDraft;

  const SecondInstanceAnalysisReportDto({
    required this.analysis,
    required this.document,
    required this.caseSummary,
    required this.precedents,
    required this.judgmentDraft,
  });
}
