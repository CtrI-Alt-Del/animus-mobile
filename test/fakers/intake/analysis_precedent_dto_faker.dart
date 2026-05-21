import 'package:animus/core/intake/dtos/analysis_precedent_applicability_level_dto.dart';
import 'package:animus/core/intake/dtos/analysis_precedent_dto.dart';
import 'package:animus/core/intake/dtos/court_dto.dart';
import 'package:animus/core/intake/dtos/precedent_dto.dart';
import 'package:animus/core/intake/dtos/precedent_identifier_dto.dart';
import 'package:animus/core/intake/dtos/precedent_kind_dto.dart';

final class PrecedentIdentifierDtoFaker {
  const PrecedentIdentifierDtoFaker._();

  static PrecedentIdentifierDto fake({
    CourtDto court = CourtDto.trt7,
    PrecedentKindDto kind = PrecedentKindDto.nt,
    int number = 100,
  }) {
    return PrecedentIdentifierDto(court: court, kind: kind, number: number);
  }
}

final class PrecedentDtoFaker {
  const PrecedentDtoFaker._();

  static PrecedentDto fake({
    PrecedentIdentifierDto? identifier,
    String synthesis = 'Sintese do precedente.',
    String status = 'AVAILABLE',
    String enunciation = 'Enunciado do precedente.',
    String thesis = 'Tese do precedente.',
    String lastUpdatedInPangeaAt = '2026-04-01T00:00:00Z',
    String? id = 'precedent-1',
  }) {
    return PrecedentDto(
      identifier: identifier ?? PrecedentIdentifierDtoFaker.fake(),
      synthesis: synthesis,
      status: status,
      enunciation: enunciation,
      thesis: thesis,
      lastUpdatedInPangeaAt: lastUpdatedInPangeaAt,
      id: id,
    );
  }
}

final class AnalysisPrecedentDtoFaker {
  const AnalysisPrecedentDtoFaker._();

  static AnalysisPrecedentDto fake({
    String analysisId = 'analysis-1',
    PrecedentDto? precedent,
    bool isChosen = false,
    bool isManuallyAdded = false,
    double similarityScore = 80,
    String synthesis = 'Sintese explicativa do precedente.',
    int? finalRank,
    AnalysisPrecedentApplicabilityLevelDto? applicabilityLevel,
  }) {
    final AnalysisPrecedentApplicabilityLevelDto resolvedApplicabilityLevel =
        applicabilityLevel ?? _fromScore(similarityScore);

    return AnalysisPrecedentDto(
      analysisId: analysisId,
      precedent: precedent ?? PrecedentDtoFaker.fake(),
      isChosen: isChosen,
      synthesis: synthesis,
      similarityScore: similarityScore,
      finalRank: finalRank ?? 1,
      applicabilityLevel: resolvedApplicabilityLevel,
      isManuallyAdded: isManuallyAdded,
    );
  }

  static AnalysisPrecedentApplicabilityLevelDto _fromScore(
    double similarityScore,
  ) {
    if (similarityScore >= 85) {
      return AnalysisPrecedentApplicabilityLevelDto.applicable;
    }

    if (similarityScore >= 70) {
      return AnalysisPrecedentApplicabilityLevelDto.possiblyApplicable;
    }

    return AnalysisPrecedentApplicabilityLevelDto.notApplicable;
  }
}
