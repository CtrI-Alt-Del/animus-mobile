class UploadUrlDto {
  final String url;
  final String token;
  final String filePath;

  const UploadUrlDto({
    required this.url,
    required this.token,
    required this.filePath,
  });
}
