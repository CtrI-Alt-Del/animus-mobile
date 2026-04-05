import 'package:animus/core/intake/dtos/precedent_dto.dart';

class AnalysisPrecedentDto {
  final String analysisId;
  final PrecedentDto precedent;
  final bool isChosen;
  final double applicabilityPercentage;
  final String synthesis;

  const AnalysisPrecedentDto({
    required this.analysisId,
    required this.precedent,
    required this.isChosen,
    required this.applicabilityPercentage,
    required this.synthesis,
  });
}
