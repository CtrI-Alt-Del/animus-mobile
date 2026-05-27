import 'package:animus/core/intake/dtos/second_instance_judgment_draft_dto.dart';
import 'package:animus/core/shared/types/json.dart';

final class SecondInstanceJudgmentDraftMapper {
  const SecondInstanceJudgmentDraftMapper._();

  static SecondInstanceJudgmentDraftDto toDto(Json json) {
    return SecondInstanceJudgmentDraftDto(
      analysisId:
          _toStringValue(json['analysis_id']) ??
          _toStringValue(json['analysisId']) ??
          '',
      report: _toStringValue(json['report']) ?? '',
      meritAnalysis:
          _toStringValue(json['merit_analysis']) ??
          _toStringValue(json['meritAnalysis']) ??
          '',
      precedentAdherenceAnalysis:
          _toStringValue(json['precedent_adherence_analysis']) ??
          _toStringValue(json['precedentAdherenceAnalysis']) ??
          '',
      ruling: _toStringList(json['ruling']),
      preliminaryIssues:
          _toNullableString(json['preliminary_issues']) ??
          _toNullableString(json['preliminaryIssues']),
      noApplicablePrecedentNotice:
          _toNullableString(json['no_applicable_precedent_notice']) ??
          _toNullableString(json['noApplicablePrecedentNotice']),
    );
  }

  static List<String> _toStringList(dynamic value) {
    if (value is String) {
      final String normalized = value.trim();
      return normalized.isEmpty ? const <String>[] : <String>[normalized];
    }

    if (value is! List<dynamic>) {
      return const <String>[];
    }

    return value.map((dynamic item) => item.toString()).toList(growable: false);
  }

  static String? _toNullableString(dynamic value) {
    final String normalized = _toStringValue(value)?.trim() ?? '';
    if (normalized.isEmpty) {
      return null;
    }

    return normalized;
  }

  static String? _toStringValue(dynamic value) {
    return switch (value) {
      String stringValue => stringValue,
      num numberValue => numberValue.toString(),
      _ => null,
    };
  }
}
