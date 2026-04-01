import 'package:animus/core/intake/dtos/analysis_dto.dart';

final class AnalysisDtoFaker {
  const AnalysisDtoFaker._();

  static AnalysisDto make({
    String? id = 'analysis-1',
    String name = 'Analise de precedente',
    String accountId = 'account-1',
    String status = 'completed',
    String summary = 'Resumo gerado.',
    String createdAt = '2026-03-31T10:00:00Z',
    String? folderId,
    bool isArchived = false,
  }) {
    return AnalysisDto(
      id: id,
      name: name,
      accountId: accountId,
      status: status,
      summary: summary,
      createdAt: createdAt,
      folderId: folderId,
      isArchived: isArchived,
    );
  }
}
