import 'package:animus/core/intake/dtos/analysis_dto.dart';
import 'package:animus/core/intake/dtos/analysis_precedent_dto.dart';
import 'package:animus/core/intake/dtos/petition_dto.dart';
import 'package:animus/core/intake/dtos/petition_summary_dto.dart';

class AnalysisReportDto {
  final AnalysisDto analysis;
  final PetitionDto petition;
  final PetitionSummaryDto summary;
  final List<AnalysisPrecedentDto> precedents;
  final AnalysisPrecedentDto chosenPrecedent;

  const AnalysisReportDto({
    required this.analysis,
    required this.petition,
    required this.summary,
    required this.precedents,
    required this.chosenPrecedent,
  });
}
