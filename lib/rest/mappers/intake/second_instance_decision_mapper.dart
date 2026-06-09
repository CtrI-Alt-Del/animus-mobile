import 'package:animus/core/intake/dtos/second_instance_decision_dto.dart';
import 'package:animus/core/shared/types/json.dart';

final class SecondInstanceDecisionMapper {
  const SecondInstanceDecisionMapper._();

  static SecondInstanceDecisionDto toDto(Json json) {
    return SecondInstanceDecisionDto(
      analysisId:
          (json['analysis_id'] as String?) ??
          (json['analysisId'] as String?) ??
          '',
      description: (json['description'] as String?) ?? '',
    );
  }
}
