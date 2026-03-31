import 'package:animus/core/intake/dtos/petition_summary_dto.dart';
import 'package:animus/core/shared/types/json.dart';

final class PetitionSummaryMapper {
  const PetitionSummaryMapper._();

  static PetitionSummaryDto toDto(Json json) {
    return PetitionSummaryDto(
      caseSummary: (json['case_summary'] as String?) ?? '',
      legalIssue: (json['legal_issue'] as String?) ?? '',
      centralQuestion: (json['central_question'] as String?) ?? '',
      relevantLaws: _toStringList(json['relevant_laws']),
      keyFacts: _toStringList(json['key_facts']),
      searchTerms: _toStringList(json['search_terms']),
    );
  }

  static List<String> _toStringList(dynamic value) {
    if (value is! List<dynamic>) {
      return const <String>[];
    }

    return value.whereType<String>().toList();
  }
}
