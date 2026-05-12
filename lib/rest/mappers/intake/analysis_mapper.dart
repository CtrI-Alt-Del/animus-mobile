import 'package:animus/core/intake/dtos/analysis_dto.dart';
import 'package:animus/core/intake/dtos/analysis_status_dto.dart';
import 'package:animus/core/intake/dtos/analysis_type_dto.dart';
import 'package:animus/core/intake/dtos/judge_analysis_status_dto.dart';
import 'package:animus/core/intake/dtos/lawyer_analysis_status_dto.dart';
import 'package:animus/core/shared/types/json.dart';

final class AnalysisMapper {
  const AnalysisMapper._();

  static AnalysisDto toDto(Json json) {
    final AnalysisTypeDto type = _toType((json['type'] as String?) ?? '');

    return AnalysisDto(
      id: json['id'] as String?,
      name: (json['name'] as String?) ?? '',
      accountId: (json['account_id'] as String?) ?? '',
      type: type,
      status: _toStatus(type: type, value: (json['status'] as String?) ?? ''),
      summary: (json['summary'] as String?) ?? '',
      createdAt:
          (json['created_at'] as String?) ??
          (json['createdAt'] as String?) ??
          '',
      folderId: json['folder_id'] as String?,
      isArchived: (json['is_archived'] as bool?) ?? false,
    );
  }

  static AnalysisTypeDto _toType(String value) {
    return AnalysisTypeDto.values.firstWhere(
      (AnalysisTypeDto type) => type.value == value,
      orElse: () => AnalysisTypeDto.lawyer,
    );
  }

  static AnalysisStatusDto _toStatus({
    required AnalysisTypeDto type,
    required String value,
  }) {
    if (type == AnalysisTypeDto.judge) {
      final JudgeAnalysisStatusDto status = JudgeAnalysisStatusDto.values
          .firstWhere(
            (JudgeAnalysisStatusDto item) => item.value == value,
            orElse: () => JudgeAnalysisStatusDto.documentUploaded,
          );

      return AnalysisStatusDto.judge(status);
    }

    final LawyerAnalysisStatusDto status = LawyerAnalysisStatusDto.values
        .firstWhere(
          (LawyerAnalysisStatusDto item) => item.value == value,
          orElse: () => LawyerAnalysisStatusDto.documentUploaded,
        );

    return AnalysisStatusDto.lawyer(status);
  }
}
