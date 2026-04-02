import 'package:animus/core/intake/dtos/analysis_petition_dto.dart';
import 'package:animus/core/intake/dtos/petition_summary_dto.dart';
import 'package:animus/core/shared/types/json.dart';
import 'package:animus/rest/mappers/intake/petition_mapper.dart';
import 'package:animus/rest/mappers/intake/petition_summary_mapper.dart';

final class AnalysisPetitionMapper {
  const AnalysisPetitionMapper._();

  static AnalysisPetitionDto toDto(Json json) {
    final dynamic petitionValue = json['petition'];
    final Json petitionJson = petitionValue is Json ? petitionValue : json;

    final PetitionSummaryDto? summary = _resolveSummary(json);

    return AnalysisPetitionDto(
      petition: PetitionMapper.toDto(petitionJson),
      summary: summary,
    );
  }

  static PetitionSummaryDto? _resolveSummary(Json json) {
    final dynamic summary = json['summary'];
    if (summary is Json) {
      return PetitionSummaryMapper.toDto(summary);
    }

    final dynamic petitionSummary = json['petition_summary'];
    if (petitionSummary is Json) {
      return PetitionSummaryMapper.toDto(petitionSummary);
    }

    return null;
  }
}
