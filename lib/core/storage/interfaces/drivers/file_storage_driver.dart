import 'dart:io';

import 'package:animus_mobile/core/storage/dtos/upload_url_dto.dart';

abstract class FileStorageDriver {
  String getFileUrl(String filePath);
  Future<void> uploadFile(File file, UploadUrlDto uploadUrl);
  Future<void> uploadFiles(List<File> files, List<UploadUrlDto> uploadUrls);
  Future<File> downloadFile(String filePath);
}
