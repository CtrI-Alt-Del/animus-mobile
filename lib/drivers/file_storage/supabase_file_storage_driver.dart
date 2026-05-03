import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:animus/core/storage/dtos/upload_url_dto.dart';
import 'package:animus/core/storage/interfaces/drivers/file_storage_driver.dart';

class SupabaseFileStorageDriver implements FileStorageDriver {
  final SupabaseClient _supabaseClient;
  final String _bucketName;

  const SupabaseFileStorageDriver({
    required SupabaseClient supabaseClient,
    required String bucketName,
  }) : _supabaseClient = supabaseClient,
       _bucketName = bucketName;

  @override
  Future<void> uploadFile(
    File file,
    UploadUrlDto uploadUrl, {
    void Function(int sentBytes, int totalBytes)? onProgress,
  }) async {
    final ({String bucketName, String path}) target = _resolveUploadTarget(
      uploadUrl,
    );
    final int totalBytes = await file.length();

    onProgress?.call(0, totalBytes);

    await _supabaseClient.storage
        .from(target.bucketName)
        .uploadToSignedUrl(
          target.path,
          uploadUrl.token,
          file,
          FileOptions(contentType: _resolveContentType(file.path)),
        );

    onProgress?.call(totalBytes, totalBytes);
  }

  @override
  Future<File?> getFile(String filePath) async {
    final ({String bucketName, String path}) target = _resolveFileTarget(
      filePath,
    );

    try {
      final List<int> bytes = await _supabaseClient.storage
          .from(target.bucketName)
          .download(target.path);

      final String fileName = target.path.split('/').last;
      final String tempPath = '${Directory.systemTemp.path}/$fileName';
      final File file = File(tempPath);
      await file.writeAsBytes(bytes, flush: true);
      return file;
    } catch (_) {
      return null;
    }
  }

  @override
  Uri getFileUrl(String filePath) {
    final ({String bucketName, String path}) target = _resolveFileTarget(
      filePath,
    );

    final String publicUrl = _supabaseClient.storage
        .from(target.bucketName)
        .getPublicUrl(target.path);

    return Uri.parse(publicUrl);
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

  ({String bucketName, String path}) _resolveUploadTarget(
    UploadUrlDto uploadUrl,
  ) {
    final Uri uploadUri = Uri.parse(uploadUrl.url);
    final List<String> pathSegments = uploadUri.pathSegments;
    final int signSegmentIndex = pathSegments.indexOf('sign');

    if (signSegmentIndex != -1 && pathSegments.length > signSegmentIndex + 2) {
      return (
        bucketName: pathSegments[signSegmentIndex + 1],
        path: pathSegments.sublist(signSegmentIndex + 2).join('/'),
      );
    }

    return _resolveFileTarget(uploadUrl.filePath);
  }

  ({String bucketName, String path}) _resolveFileTarget(String filePath) {
    final String normalizedPath = filePath.trim().replaceFirst(
      RegExp(r'^/+'),
      '',
    );

    if (normalizedPath.startsWith('$_bucketName/')) {
      return (
        bucketName: _bucketName,
        path: normalizedPath.substring(_bucketName.length + 1),
      );
    }

    return (bucketName: _bucketName, path: normalizedPath);
  }
}
