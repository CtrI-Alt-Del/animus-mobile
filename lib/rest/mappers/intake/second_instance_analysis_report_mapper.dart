import 'package:animus/core/intake/dtos/analysis_precedent_dto.dart';
import 'package:animus/core/intake/dtos/second_instance_analysis_report_dto.dart';
import 'package:animus/core/shared/types/json.dart';

import 'package:animus/rest/mappers/intake/analysis_document_mapper.dart';
import 'package:animus/rest/mappers/intake/analysis_mapper.dart';
import 'package:animus/rest/mappers/intake/analysis_precedent_mapper.dart';
import 'package:animus/rest/mappers/intake/case_summary_mapper.dart';

class SecondInstanceAnalysisReportMapper {
  const SecondInstanceAnalysisReportMapper._();

  static SecondInstanceAnalysisReportDto toDto(Json json) {
    return SecondInstanceAnalysisReportDto(
      analysis: AnalysisMapper.toDto(_toJsonField(json['analysis'])),
      document: AnalysisDocumentMapper.toDto(_toJsonField(json['document'])),
      caseSummary: CaseSummaryMapper.toDto(_toJsonField(json['case_summary'])),
      precedents: _toPrecedents(json['precedents']),
      chosenPrecedent: _toChosenPrecedent(json),
    );
  }

  static AnalysisPrecedentDto? _toChosenPrecedent(Json json) {
    final dynamic value = json['chosen_precedent'];
    if (value is! Json || !_hasValidChosenPrecedent(value)) {
      return null;
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
