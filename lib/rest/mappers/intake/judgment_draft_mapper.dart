import 'package:animus/core/intake/dtos/first_instance_analysis_judgment_draft_dto.dart';
import 'package:animus/core/shared/types/json.dart';

final class JudgmentDraftMapper {
  const JudgmentDraftMapper._();

  static FirstInstanceJudgmentDraftDto toDto(Json json) {
    return FirstInstanceJudgmentDraftDto(
      content: (json['content'] as String?) ?? '',
    );
  }
}
