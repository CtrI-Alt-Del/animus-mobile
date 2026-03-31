import 'dart:io';

import 'package:dio/dio.dart';

import 'package:animus/core/storage/dtos/upload_url_dto.dart';
import 'package:animus/core/storage/interfaces/drivers/file_storage_driver.dart';

class GcsFileStorageDriver implements FileStorageDriver {
  final Dio _dio;

  GcsFileStorageDriver({Dio? dio}) : _dio = dio ?? Dio();

  @override
  Future<void> uploadFile(
    File file,
    UploadUrlDto uploadUrl, {
    void Function(int sentBytes, int totalBytes)? onProgress,
  }) async {
    await _dio.put<void>(
      uploadUrl.url,
      data: file.openRead(),
      options: Options(
        headers: <String, dynamic>{
          HttpHeaders.contentLengthHeader: await file.length(),
          HttpHeaders.contentTypeHeader: _resolveContentType(file.path),
        },
      ),
      onSendProgress: onProgress,
    );
  }

  String _resolveContentType(String path) {
    final String lowerPath = path.toLowerCase();
    if (lowerPath.endsWith('.pdf')) {
      return 'application/pdf';
    }

    if (lowerPath.endsWith('.docx')) {
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    }

    return 'application/octet-stream';
  }
}
