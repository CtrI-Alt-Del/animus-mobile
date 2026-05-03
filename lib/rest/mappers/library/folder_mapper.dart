import 'package:animus/core/library/dtos/folder_dto.dart';
import 'package:animus/core/shared/types/json.dart';

class FolderMapper {
  FolderMapper._();

  static FolderDto toDto(Json json) {
    return FolderDto(
      id: json['id'] as String?,
      name: json['name'] as String? ?? '',
      analysisCount: json['analysis_count'] as int? ?? 0,
      accountId: json['account_id'] as String? ?? '',
      isArchived: json['is_archived'] as bool? ?? false,
    );
  }

  static Json toJson(FolderDto dto) {
    return <String, dynamic>{
      'id': dto.id,
      'name': dto.name,
      'analysis_count': dto.analysisCount,
      'account_id': dto.accountId,
      'is_archived': dto.isArchived,
    };
  }
}
