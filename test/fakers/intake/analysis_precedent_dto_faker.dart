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
    double applicabilityPercentage = 80,
    String synthesis = 'Sintese explicativa do precedente.',
  }) {
    return AnalysisPrecedentDto(
      analysisId: analysisId,
      precedent: precedent ?? PrecedentDtoFaker.fake(),
      isChosen: isChosen,
      applicabilityPercentage: applicabilityPercentage,
      synthesis: synthesis,
    );
  }
}
