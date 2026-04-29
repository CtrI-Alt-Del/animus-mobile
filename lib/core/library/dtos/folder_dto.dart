class FolderDto {
  final String? id;
  final String name;
  final int analysisCount;
  final String accountId;
  final bool isArchived;

  const FolderDto({
    this.id,
    required this.name,
    required this.analysisCount,
    required this.accountId,
    this.isArchived = false,
  });
}
