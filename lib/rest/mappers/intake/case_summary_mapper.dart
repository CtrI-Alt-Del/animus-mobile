import 'package:animus/core/intake/dtos/case_summary_dto.dart';
import 'package:animus/core/shared/types/json.dart';

final class CaseSummaryMapper {
  const CaseSummaryMapper._();

  static CaseSummaryDto toDto(Json json) {
    final dynamic excludedOrAccessoryTopicsRaw =
        json['excluded_or_accessory_topics'] ??
        json['excluded_or_acessory_topics'];

    return CaseSummaryDto(
      caseSummary: _toString(json['case_summary']),
      legalIssue: _toString(json['legal_issue']),
      centralQuestion: _toString(json['central_question']),
      relevantLaws: _toStringList(json['relevant_laws']),
      keyFacts: _toStringList(json['key_facts']),
      searchTerms: _toStringList(json['search_terms']),
      typeOfAction: _toNullableString(json['type_of_action']),
      jurisdictionIssue: _toNullableString(json['jurisdiction_issue']),
      standingIssue: _toNullableString(json['standing_issue']),
      secondaryLegalIssues: _toStringList(json['secondary_legal_issues']),
      alternativeQuestions: _toStringList(json['alternative_questions']),
      requestedRelief: _toStringList(json['requested_relief']),
      proceduralIssues: _toStringList(json['procedural_issues']),
      excludedOrAccessoryTopics: _toStringList(excludedOrAccessoryTopicsRaw),
    );
  }

  static String _toString(dynamic value) {
    return (value is String) ? value.trim() : '';
  }

  static String? _toNullableString(dynamic value) {
    final String normalizedValue = _toString(value);
    return normalizedValue.isEmpty ? null : normalizedValue;
  }

  static List<String> _toStringList(dynamic value) {
    if (value is! List<dynamic>) {
      return const <String>[];
    }

    return value
        .whereType<String>()
        .map((String item) => item.trim())
        .where((String item) => item.isNotEmpty)
        .toList();
  }
}
