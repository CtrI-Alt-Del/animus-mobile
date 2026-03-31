import 'package:animus/core/intake/dtos/analysis_status_dto.dart';

class AnalysisDto {
  final String name;
  final String accountId;
  final AnalysisStatusDto status;
  final String summary;
  final String? folderId;
  final bool isArchived;
  final String? id;

  const AnalysisDto({
    required this.name,
    required this.accountId,
    required this.status,
    required this.summary,
    this.folderId,
    this.isArchived = false,
    this.id,
  });
}
