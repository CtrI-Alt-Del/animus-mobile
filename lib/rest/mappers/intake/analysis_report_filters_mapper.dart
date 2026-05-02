import 'package:animus/core/intake/dtos/analysis_report_filters_dto.dart';
import 'package:animus/core/intake/dtos/court_dto.dart';
import 'package:animus/core/intake/dtos/precedent_kind_dto.dart';
import 'package:animus/core/shared/types/json.dart';

final class AnalysisReportFiltersMapper {
  const AnalysisReportFiltersMapper._();

  static AnalysisReportFiltersDto toDto(Json json) {
    return AnalysisReportFiltersDto(
      limit: _toRequiredLimit(json['limit']),
      courts: _toCourts(json['courts']),
      precedentKinds: _toPrecedentKinds(json['precedent_kinds']),
    );
  }

  static List<CourtDto> _toCourts(dynamic value) {
    if (value is! List<dynamic>) {
      return const <CourtDto>[];
    }

    final List<CourtDto> courts = <CourtDto>[];
    for (final dynamic item in value) {
      if (item is! String) {
        continue;
      }

      final String normalized = item.trim().toUpperCase();
      for (final CourtDto court in CourtDto.values) {
        if (court.value == normalized) {
          courts.add(court);
          break;
        }
      }
    }

    return courts.toList(growable: false);
  }

  static List<PrecedentKindDto> _toPrecedentKinds(dynamic value) {
    if (value is! List<dynamic>) {
      return const <PrecedentKindDto>[];
    }

    final List<PrecedentKindDto> kinds = <PrecedentKindDto>[];
    for (final dynamic item in value) {
      if (item is! String) {
        continue;
      }

      final String normalized = item.trim().toUpperCase();
      for (final PrecedentKindDto kind in PrecedentKindDto.values) {
        if (kind.value == normalized) {
          kinds.add(kind);
          break;
        }
      }
    }

    return kinds.toList(growable: false);
  }

  static int _toRequiredLimit(dynamic value) {
    final int? limit = _toInt(value);
    if (limit == null || limit <= 0) {
      throw const FormatException(
        'Invalid analysis report filters payload: limit must be a positive integer.',
      );
    }

    return limit;
  }

  static int? _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num && value % 1 == 0) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value.trim());
    }

    return null;
  }
}
