import 'package:animus/core/intake/dtos/petition_draft_dto.dart';
import 'package:animus/core/shared/types/json.dart';

final class PetitionDraftMapper {
  const PetitionDraftMapper._();

  static PetitionDraftDto toDto(Json json) {
    return PetitionDraftDto(
      analysisId: (json['analysis_id'] as String?) ?? '',
      structuredFacts: (json['structured_facts'] as String?) ?? '',
      legalGrounds: (json['legal_grounds'] as String?) ?? '',
      centralThesis: (json['central_thesis'] as String?) ?? '',
      requests: _toStringList(json['requests']),
      precedentCitations: _toStringList(json['precedent_citations']),
    );
  }

  static List<String> _toStringList(dynamic value) {
    if (value is! List<dynamic>) {
      return const <String>[];
    }

    return value
        .whereType<String>()
        .map((String item) => item.trim())
        .where((String item) => item.isNotEmpty)
        .toList(growable: false);
  }
}
