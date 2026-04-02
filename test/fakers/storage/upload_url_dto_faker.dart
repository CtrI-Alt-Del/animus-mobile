import 'package:animus/core/storage/dtos/upload_url_dto.dart';

final class UploadUrlDtoFaker {
  const UploadUrlDtoFaker._();

  static UploadUrlDto fake({
    String url = 'https://storage.googleapis.com/upload-url',
    String token = 'upload-token',
    String filePath = 'uploads/petitions/petition-1.pdf',
  }) {
    return UploadUrlDto(url: url, token: token, filePath: filePath);
  }
}
