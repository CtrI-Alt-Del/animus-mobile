import 'package:animus/core/intake/dtos/analysis_petition_dto.dart';
import 'package:animus/core/intake/dtos/case_summary_dto.dart';
import 'package:animus/core/shared/types/json.dart';
import 'package:animus/rest/mappers/intake/case_summary_mapper.dart';
import 'package:animus/rest/mappers/intake/petition_mapper.dart';

final class AnalysisPetitionMapper {
  const AnalysisPetitionMapper._();

  static AnalysisPetitionDto toDto(Json json) {
    final dynamic petitionValue = json['petition'];
    final Json petitionJson = petitionValue is Json ? petitionValue : json;

    final CaseSummaryDto? caseSummary = _resolveCaseSummary(json);

    return AnalysisPetitionDto(
      petition: PetitionMapper.toDto(petitionJson),
      caseSummary: caseSummary,
    );
  }

  static CaseSummaryDto? _resolveCaseSummary(Json json) {
    final dynamic summary = json['summary'];
    if (summary is Json) {
      return CaseSummaryMapper.toDto(summary);
    }

    final dynamic petitionSummary = json['petition_summary'];
    if (petitionSummary is Json) {
      return CaseSummaryMapper.toDto(petitionSummary);
    }

    return null;
  }
}
