import 'package:animus/core/intake/dtos/analysis_precedent_applicability_level_dto.dart';
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
      synthesis: (json['synthesis'] as String?) ?? '',
      similarityScore: _toSimilarityScore(json),
      finalRank: _toInt(json['final_rank']),
      applicabilityLevel: _toApplicabilityLevel(
        value: json['applicability_level'] ?? json['classification_level'],
        similarityScore: _toSimilarityScore(json),
      ),
    );
  }

  static AnalysisPrecedentApplicabilityLevelDto _toApplicabilityLevel({
    required dynamic value,
    required double similarityScore,
  }) {
    if (value is int) {
      return _fromInt(value);
    }

    if (value is num) {
      return _fromInt(value.toInt());
    }

    if (value is String) {
      final String normalizedValue = value.trim().toUpperCase();
      final int? parsed = int.tryParse(value);
      if (parsed != null) {
        return _fromInt(parsed);
      }

      for (final AnalysisPrecedentApplicabilityLevelDto level
          in AnalysisPrecedentApplicabilityLevelDto.values) {
        if (_legacyLevelValue(level) == normalizedValue) {
          return level;
        }
      }
    }

    if (similarityScore >= 85) {
      return AnalysisPrecedentApplicabilityLevelDto.applicable;
    }

    if (similarityScore >= 70) {
      return AnalysisPrecedentApplicabilityLevelDto.possiblyApplicable;
    }

    return AnalysisPrecedentApplicabilityLevelDto.notApplicable;
  }

  static double _toSimilarityScore(Json json) {
    final double explicitScore = _toDouble(json['similarity_score']);
    if (explicitScore > 0) {
      return explicitScore.clamp(0, 100);
    }

    return _toDouble(json['similarity_percentage']).clamp(0, 100);
  }

  static AnalysisPrecedentApplicabilityLevelDto _fromInt(int value) {
    switch (value.clamp(0, 2)) {
      case 2:
        return AnalysisPrecedentApplicabilityLevelDto.applicable;
      case 1:
        return AnalysisPrecedentApplicabilityLevelDto.possiblyApplicable;
      case 0:
      default:
        return AnalysisPrecedentApplicabilityLevelDto.notApplicable;
    }
  }

  static String _legacyLevelValue(
    AnalysisPrecedentApplicabilityLevelDto level,
  ) {
    switch (level) {
      case AnalysisPrecedentApplicabilityLevelDto.notApplicable:
        return 'NOT_APPLICABLE';
      case AnalysisPrecedentApplicabilityLevelDto.possiblyApplicable:
        return 'POSSIBLY_APPLICABLE';
      case AnalysisPrecedentApplicabilityLevelDto.applicable:
        return 'APPLICABLE';
    }
  }

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value) ?? 0;
    }

    return 0;
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
