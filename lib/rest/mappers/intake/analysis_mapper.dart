import 'package:animus/core/intake/dtos/analysis_dto.dart';
import 'package:animus/core/shared/types/json.dart';

final class AnalysisMapper {
  const AnalysisMapper._();

  static AnalysisDto toDto(Json json) {
    return AnalysisDto(
      id: json['id'] as String?,
      name: (json['name'] as String?) ?? '',
      accountId: (json['account_id'] as String?) ?? '',
      status: (json['status'] as String?) ?? '',
      summary: (json['summary'] as String?) ?? '',
      createdAt:
          (json['created_at'] as String?) ??
          (json['createdAt'] as String?) ??
          '',
      folderId: json['folder_id'] as String?,
      isArchived: (json['is_archived'] as bool?) ?? false,
    );
  }
}
