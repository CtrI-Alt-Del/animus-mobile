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
    final String uploadUrlValue = _resolveUploadUrl(uploadUrl.url);

    await _restClient.put(
      uploadUrlValue,
      body: file.openRead(),
      headers: <String, dynamic>{
        HttpHeaders.contentTypeHeader: _resolveContentType(file.path),
        HttpHeaders.contentLengthHeader: (await file.length()).toString(),
      },
      onSendProgress: onProgress,
    );
  }

  @override
  Uri getFileUrl(String filePath) {
    return Uri.parse('${Env.gcsDownloadUrl}/$filePath');
  }

  @override
  Future<File?> getFile(String filePath) async {
    final Uri fileUri = getFileUrl(filePath);
    final HttpClient httpClient = HttpClient();

    try {
      final HttpClientRequest request = await httpClient.getUrl(fileUri);
      final HttpClientResponse response = await request.close();

      if (response.statusCode >= HttpStatus.badRequest) {
        return null;
      }

      final List<int> bytes = await response.fold<List<int>>(<int>[], (
        List<int> previous,
        List<int> element,
      ) {
        previous.addAll(element);
        return previous;
      });

      final String fileName = filePath.split('/').last;
      final String tempPath = '${Directory.systemTemp.path}/$fileName';
      final File file = File(tempPath);
      await file.writeAsBytes(bytes, flush: true);
      return file;
    } catch (_) {
      return null;
    } finally {
      httpClient.close(force: true);
    }
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
