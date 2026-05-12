import 'package:animus/core/intake/dtos/analysis_precedent_dto.dart';
import 'package:animus/core/intake/dtos/lawer_analysis_report_dto.dart';
import 'package:animus/core/shared/types/json.dart';

import 'package:animus/rest/mappers/intake/analysis_document_mapper.dart';
import 'package:animus/rest/mappers/intake/analysis_mapper.dart';
import 'package:animus/rest/mappers/intake/analysis_precedent_mapper.dart';
import 'package:animus/rest/mappers/intake/case_summary_mapper.dart';
import 'package:animus/rest/mappers/intake/petition_draft_mapper.dart';

final class LawerAnalysisReportMapper {
  const LawerAnalysisReportMapper._();

  static LawerAnalysisReportDto toDto(Json json) {
    return LawerAnalysisReportDto(
      analysis: AnalysisMapper.toDto(_toJsonField(json['analysis'])),
      document: AnalysisDocumentMapper.toDto(_toJsonField(json['document'])),
      caseSummary: CaseSummaryMapper.toDto(_toJsonField(json['case_summary'])),
      precedents: _toPrecedents(json['precedents']),
      petitionDraft: PetitionDraftMapper.toDto(
        _toJsonField(json['petition_draft']),
      ),
    );
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
}
