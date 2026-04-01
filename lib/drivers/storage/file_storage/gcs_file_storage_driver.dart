import 'dart:io';

import 'package:animus/constants/env.dart';
import 'package:animus/core/shared/interfaces/rest_client.dart';
import 'package:animus/core/storage/dtos/upload_url_dto.dart';
import 'package:animus/core/storage/interfaces/drivers/file_storage_driver.dart';

class GcsFileStorageDriver implements FileStorageDriver {
  final RestClient _restClient;

  const GcsFileStorageDriver({required RestClient restClient})
    : _restClient = restClient;

  @override
  Future<void> uploadFile(
    File file,
    UploadUrlDto uploadUrl, {
    void Function(int sentBytes, int totalBytes)? onProgress,
  }) async {
    final int totalBytes = await file.length();
    onProgress?.call(0, totalBytes);

    final String uploadUrlValue = _resolveUploadUrl(uploadUrl.url);

    await _restClient.put(
      uploadUrlValue,
      body: file.openRead(),
      headers: <String, dynamic>{
        HttpHeaders.contentTypeHeader: _resolveContentType(file.path),
        HttpHeaders.contentLengthHeader: totalBytes.toString(),
      },
    );

    onProgress?.call(totalBytes, totalBytes);
  }

  @override
  Uri getFileUrl(String filePath) {
    return Uri.parse('${Env.gcsUrl}/$filePath');
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

  String _resolveUploadUrl(String url) {
    final Uri uri = Uri.parse(url);
    if (uri.host != 'localhost') {
      return url;
    }

    return uri.replace(host: '10.0.2.2').toString();
  }
}
