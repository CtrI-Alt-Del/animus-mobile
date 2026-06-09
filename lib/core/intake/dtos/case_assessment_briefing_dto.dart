import 'package:animus/core/intake/dtos/court_dto.dart';
import 'package:animus/core/intake/dtos/legal_area_dto.dart';

class CaseAssessmentBriefingDto {
  final String analysisId;
  final LegalAreaDto legalArea;
  final CourtDto courtJurisdiction;
  final String mainClaims;
  final String intendedThesis;

  const CaseAssessmentBriefingDto({
    required this.analysisId,
    required this.legalArea,
    required this.courtJurisdiction,
    required this.mainClaims,
    required this.intendedThesis,
  });
}
