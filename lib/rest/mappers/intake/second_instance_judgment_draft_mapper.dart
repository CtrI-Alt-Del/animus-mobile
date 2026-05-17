import 'package:animus/core/intake/dtos/second_instance_judgment_draft_dto.dart';
import 'package:animus/core/shared/types/json.dart';

final class SecondInstanceJudgmentDraftMapper {
  const SecondInstanceJudgmentDraftMapper._();

  static SecondInstanceJudgmentDraftDto toDto(Json json) {
    return SecondInstanceJudgmentDraftDto(
      analysisId:
          (json['analysis_id'] as String?) ??
          (json['analysisId'] as String?) ??
          '',
      report: (json['report'] as String?) ?? '',
      meritAnalysis: (json['merit_analysis'] as String?) ?? '',
      precedentAdherenceAnalysis:
          (json['precedent_adherence_analysis'] as String?) ?? '',
      ruling: _toStringList(json['ruling']),
      preliminaryIssues: _toNullableString(json['preliminary_issues']),
      noApplicablePrecedentNotice: _toNullableString(
        json['no_applicable_precedent_notice'],
      ),
    );
  }

  static List<String> _toStringList(dynamic value) {
    if (value is! List<dynamic>) {
      return const <String>[];
    }

    return value.map((dynamic item) => item.toString()).toList(growable: false);
  }

  static String? _toNullableString(dynamic value) {
    final String normalized = (value as String? ?? '').trim();
    if (normalized.isEmpty) {
      return null;
    }

    return normalized;
  }
}
