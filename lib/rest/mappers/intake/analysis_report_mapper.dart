import 'package:animus/core/intake/dtos/analysis_precedent_dto.dart';
import 'package:animus/core/intake/dtos/analysis_report_dto.dart';
import 'package:animus/core/shared/types/json.dart';

import 'package:animus/rest/mappers/intake/analysis_mapper.dart';
import 'package:animus/rest/mappers/intake/analysis_precedent_mapper.dart';
import 'package:animus/rest/mappers/intake/petition_mapper.dart';
import 'package:animus/rest/mappers/intake/petition_summary_mapper.dart';

final class AnalysisReportMapper {
  const AnalysisReportMapper._();

  static AnalysisReportDto toDto(Json json) {
    return AnalysisReportDto(
      analysis: AnalysisMapper.toDto(_toJsonField(json['analysis'])),
      petition: PetitionMapper.toDto(_toJsonField(json['petition'])),
      summary: PetitionSummaryMapper.toDto(_toJsonField(json['summary'])),
      precedents: _toPrecedents(json['precedents']),
      chosenPrecedent: _toChosenPrecedent(json),
    );
  }

  static AnalysisPrecedentDto _toChosenPrecedent(Json json) {
    final dynamic value = json['chosen_precedent'];
    if (value is! Json || !_hasValidChosenPrecedent(value)) {
      throw const FormatException(
        'Invalid analysis report payload: chosen_precedent is required.',
      );
    }

    return AnalysisPrecedentMapper.toDto(value);
  }

  static List<AnalysisPrecedentDto> _toPrecedents(dynamic value) {
    if (value is! List<dynamic>) {
      return const <AnalysisPrecedentDto>[];
    }

    return value
        .whereType<Json>()
        .map(AnalysisPrecedentMapper.toDto)
        .toList(growable: false);
  }

  static Json _toJsonField(dynamic value) {
    if (value is Json) {
      return value;
    }

    return <String, dynamic>{};
  }

  static bool _hasValidChosenPrecedent(Json chosenPrecedent) {
    final dynamic precedentValue = chosenPrecedent['precedent'];
    if (precedentValue is! Json) {
      return false;
    }

    final dynamic identifierValue = precedentValue['identifier'];
    if (identifierValue is Json) {
      return identifierValue['court'] is String &&
          identifierValue['kind'] is String &&
          identifierValue['number'] != null;
    }

    return precedentValue['court'] is String &&
        precedentValue['kind'] is String &&
        precedentValue['number'] != null;
  }
}
