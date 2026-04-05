import 'package:animus/core/intake/dtos/analysis_precedent_dto.dart';
import 'package:animus/core/shared/types/json.dart';
import 'package:animus/rest/mappers/intake/precedent_mapper.dart';

final class AnalysisPrecedentMapper {
  const AnalysisPrecedentMapper._();

  static AnalysisPrecedentDto toDto(Json json) {
    final dynamic precedentValue = json['precedent'];
    final Json precedentJson = precedentValue is Json
        ? precedentValue
        : <String, dynamic>{};

    return AnalysisPrecedentDto(
      analysisId: (json['analysis_id'] as String?) ?? '',
      precedent: PrecedentMapper.toDto(precedentJson),
      isChosen: (json['is_chosen'] as bool?) ?? false,
      applicabilityPercentage: _toDouble(json['applicability_percentage']),
      synthesis: (json['synthesis'] as String?) ?? '',
    );
  }

  static double _toDouble(dynamic value) {
    if (value is double) {
      return value;
    }

    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value) ?? 0;
    }

    return 0;
  }
}
