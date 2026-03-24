import 'dart:io';

import 'package:animus_mobile/core/storage/dtos/upload_url_dto.dart';

abstract class FileStorageDriver {
  String getFileUrl(String filePath);
  Future<void> uploadFile(File file, UploadUrlDto uploadUrl);
  Future<void> uploadFiles(Map<File, UploadUrlDto> uploads);
  Future<File> downloadFile(String filePath);
}
