class FolderDto {
  final String name;
  final String accountId;
  final bool isArchived;
  final String? id;

  const FolderDto({
    required this.name,
    required this.accountId,
    this.isArchived = false,
    this.id,
  });
}
