class AnalysisDocumentDto {
  final String analysisId;
  final String uploadedAt;
  final String filePath;
  final String name;

  const AnalysisDocumentDto({
    required this.analysisId,
    required this.uploadedAt,
    required this.filePath,
    required this.name,
  });
}
