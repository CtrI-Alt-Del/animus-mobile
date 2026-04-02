import 'package:animus/core/intake/dtos/analysis_dto.dart';
import 'package:animus/core/intake/dtos/analysis_status_dto.dart';
import 'package:animus/core/shared/types/json.dart';

final class AnalysisMapper {
  const AnalysisMapper._();

  static AnalysisDto toDto(Json json) {
    return AnalysisDto(
      id: json['id'] as String?,
      name: (json['name'] as String?) ?? '',
      accountId: (json['account_id'] as String?) ?? '',
      status: _toStatus((json['status'] as String?) ?? ''),
      summary: (json['summary'] as String?) ?? '',
      folderId: json['folder_id'] as String?,
      isArchived: (json['is_archived'] as bool?) ?? false,
    );
  }

  static AnalysisStatusDto _toStatus(String value) {
    return AnalysisStatusDto.values.firstWhere(
      (AnalysisStatusDto status) => status.value == value,
      orElse: () => AnalysisStatusDto.waitingPetition,
    );
  }
}
