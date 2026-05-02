import 'package:animus/core/intake/dtos/analysis_precedent_applicability_level_dto.dart';
import 'package:animus/core/intake/dtos/precedent_dto.dart';

class AnalysisPrecedentDto {
  final String analysisId;
  final PrecedentDto precedent;
  final bool isChosen;
  final String synthesis;
  final double similarityScore;
  final int finalRank;
  final AnalysisPrecedentApplicabilityLevelDto applicabilityLevel;

  const AnalysisPrecedentDto({
    required this.analysisId,
    required this.precedent,
    required this.isChosen,
    required this.synthesis,
    required this.similarityScore,
    required this.finalRank,
    required this.applicabilityLevel,
  });
}
