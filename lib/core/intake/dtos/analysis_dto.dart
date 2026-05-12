import 'package:animus/core/intake/dtos/analysis_status_dto.dart';
import 'package:animus/core/intake/dtos/analysis_type_dto.dart';

class AnalysisDto {
  final String name;
  final String accountId;
  final AnalysisTypeDto type;
  final AnalysisStatusDto status;
  final String summary;
  final String createdAt;
  final String? folderId;
  final bool isArchived;
  final String? id;

  const AnalysisDto({
    required this.name,
    required this.accountId,
    required this.type,
    required this.status,
    required this.summary,
    required this.createdAt,
    this.folderId,
    this.isArchived = false,
    this.id,
  });
}
