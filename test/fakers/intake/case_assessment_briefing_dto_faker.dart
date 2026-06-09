import 'package:animus/core/intake/dtos/case_assessment_briefing_dto.dart';
import 'package:animus/core/intake/dtos/court_dto.dart';
import 'package:animus/core/intake/dtos/legal_area_dto.dart';

final class CaseAssessmentBriefingDtoFaker {
  const CaseAssessmentBriefingDtoFaker._();

  static CaseAssessmentBriefingDto fake({
    String analysisId = 'analysis-1',
    LegalAreaDto legalArea = LegalAreaDto.civil,
    CourtDto courtJurisdiction = CourtDto.tjsp,
    String mainClaims = 'Pedido principal do caso.',
    String intendedThesis = 'Tese juridica pretendida.',
  }) {
    return CaseAssessmentBriefingDto(
      analysisId: analysisId,
      legalArea: legalArea,
      courtJurisdiction: courtJurisdiction,
      mainClaims: mainClaims,
      intendedThesis: intendedThesis,
    );
  }
}
