import 'dart:io';

import 'package:animus/core/storage/dtos/upload_url_dto.dart';

abstract class FileStorageDriver {
  Future<void> uploadFile(
    File file,
    UploadUrlDto uploadUrl, {
    void Function(int sentBytes, int totalBytes)? onProgress,
  });

  Uri getFileUrl(String url);
}
