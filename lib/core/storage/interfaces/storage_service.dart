import 'package:animus/core/storage/dtos/upload_url_dto.dart';

abstract class StorageService {
  Future<UploadUrlDto> getUploadUrl(String filePath);
  Future<String> getDownloadUrl(String filePath);
  Future<void> deleteFile(String filePath);
  Future<List<String>> listFiles({String? prefix});
}
