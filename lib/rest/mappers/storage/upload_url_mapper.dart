import 'package:animus/core/shared/types/json.dart';
import 'package:animus/core/storage/dtos/upload_url_dto.dart';

final class UploadUrlMapper {
  const UploadUrlMapper._();

  static UploadUrlDto toDto(Json json) {
    return UploadUrlDto(
      url: (json['url'] as String?) ?? '',
      token: (json['token'] as String?) ?? '',
      filePath: (json['file_path'] as String?) ?? '',
    );
  }
}
