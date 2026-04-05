import 'package:animus/core/intake/dtos/analysis_precedent_classification_level_dto.dart';
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
      classificationLevel: _toClassificationLevel(
        value: json['classification_level'],
        applicabilityPercentage: _toDouble(json['applicability_percentage']),
      ),
    );
  }

  static AnalysisPrecedentClassificationLevelDto _toClassificationLevel({
    required dynamic value,
    required double applicabilityPercentage,
  }) {
    if (value is String) {
      for (final AnalysisPrecedentClassificationLevelDto level
          in AnalysisPrecedentClassificationLevelDto.values) {
        if (level.value == value) {
          return level;
        }
      }
    }

    if (applicabilityPercentage >= 85) {
      return AnalysisPrecedentClassificationLevelDto.applicable;
    }

    if (applicabilityPercentage >= 70) {
      return AnalysisPrecedentClassificationLevelDto.possiblyApplicable;
    }

    return AnalysisPrecedentClassificationLevelDto.notApplicable;
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
