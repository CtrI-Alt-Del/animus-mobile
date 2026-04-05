import 'package:animus/core/intake/dtos/analysis_precedent_classification_level_dto.dart';
import 'package:animus/core/intake/dtos/precedent_dto.dart';

class AnalysisPrecedentDto {
  final String analysisId;
  final PrecedentDto precedent;
  final bool isChosen;
  final double applicabilityPercentage;
  final String synthesis;
  final AnalysisPrecedentClassificationLevelDto classificationLevel;

  const AnalysisPrecedentDto({
    required this.analysisId,
    required this.precedent,
    required this.isChosen,
    required this.applicabilityPercentage,
    required this.synthesis,
    required this.classificationLevel,
  });
}
