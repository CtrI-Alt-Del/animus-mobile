import 'package:animus/core/intake/dtos/judgment_draft_dto.dart';
import 'package:animus/core/shared/types/json.dart';

final class JudgmentDraftMapper {
  const JudgmentDraftMapper._();

  static JudgmentDraftDto toDto(Json json) {
    return JudgmentDraftDto(content: (json['content'] as String?) ?? '');
  }
}
