import 'package:animus/core/intake/dtos/petition_draft_dto.dart';
import 'package:animus/core/shared/types/json.dart';

final class PetitionDraftMapper {
  const PetitionDraftMapper._();

  static PetitionDraftDto toDto(Json json) {
    return PetitionDraftDto(
      analysisId: (json['analysis_id'] as String?) ?? '',
      content: (json['content'] as String?) ?? '',
    );
  }
}
