import 'package:animus/core/intake/dtos/court_dto.dart';
import 'package:animus/core/intake/dtos/precedent_dto.dart';
import 'package:animus/core/intake/dtos/precedent_identifier_dto.dart';
import 'package:animus/core/intake/dtos/precedent_kind_dto.dart';
import 'package:animus/core/shared/types/json.dart';

final class PrecedentMapper {
  const PrecedentMapper._();

  static PrecedentDto toDto(Json json) {
    final dynamic identifierValue = json['identifier'];
    final Json identifierJson = identifierValue is Json
        ? identifierValue
        : <String, dynamic>{};

    return PrecedentDto(
      id: json['id'] as String?,
      identifier: PrecedentIdentifierDto(
        court: _toCourt(identifierJson['court'] ?? json['court']),
        kind: _toPrecedentKind(identifierJson['kind'] ?? json['kind']),
        number: _toNumber(identifierJson['number'] ?? json['number']),
      ),
      synthesis: (json['synthesis'] as String?) ?? '',
      status: (json['status'] as String?) ?? '',
      enunciation: (json['enunciation'] as String?) ?? '',
      thesis: (json['thesis'] as String?) ?? '',
      lastUpdatedInPangeaAt:
          (json['last_updated_in_pangea_at'] as String?) ??
          (json['lastUpdatedInPangeaAt'] as String?) ??
          '',
    );
  }

  static CourtDto _toCourt(dynamic value) {
    final String normalized = (value as String? ?? '').trim().toUpperCase();

    return CourtDto.values.firstWhere(
      (CourtDto court) => court.value == normalized,
      orElse: () => CourtDto.stf,
    );
  }

  static PrecedentKindDto _toPrecedentKind(dynamic value) {
    final String normalized = (value as String? ?? '').trim().toUpperCase();

    return PrecedentKindDto.values.firstWhere(
      (PrecedentKindDto kind) => kind.value == normalized,
      orElse: () => PrecedentKindDto.sum,
    );
  }

  static int _toNumber(dynamic value) {
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
}
