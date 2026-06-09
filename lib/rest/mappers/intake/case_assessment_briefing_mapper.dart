import 'package:animus/core/intake/dtos/case_assessment_briefing_dto.dart';
import 'package:animus/core/intake/dtos/court_dto.dart';
import 'package:animus/core/intake/dtos/legal_area_dto.dart';
import 'package:animus/core/shared/types/json.dart';

final class CaseAssessmentBriefingMapper {
  const CaseAssessmentBriefingMapper._();

  static CaseAssessmentBriefingDto toDto(Json json) {
    return CaseAssessmentBriefingDto(
      analysisId: _toString(json['analysis_id']),
      legalArea: _toLegalArea(json['legal_area']),
      courtJurisdiction: _toCourt(json['court_jurisdiction']),
      mainClaims: _toString(json['main_claims']),
      intendedThesis: _toString(json['intended_thesis']),
    );
  }

  static Json toJson(CaseAssessmentBriefingDto dto) {
    return <String, dynamic>{
      'legal_area': dto.legalArea.value,
      'court_jurisdiction': dto.courtJurisdiction.value.trim(),
      'main_claims': dto.mainClaims.trim(),
      'intended_thesis': dto.intendedThesis.trim(),
    };
  }

  static CourtDto _toCourt(dynamic value) {
    final String normalized = _toString(value).toUpperCase();

    return CourtDto.values.firstWhere(
      (CourtDto court) => court.value == normalized,
      orElse: () => CourtDto.stf,
    );
  }

  static LegalAreaDto _toLegalArea(dynamic value) {
    final String normalized = _toString(value).toUpperCase();

    return LegalAreaDto.values.firstWhere(
      (LegalAreaDto area) => area.value == normalized,
      orElse: () => LegalAreaDto.values.first,
    );
  }

  static String _toString(dynamic value) {
    return (value is String) ? value.trim() : '';
  }
}
