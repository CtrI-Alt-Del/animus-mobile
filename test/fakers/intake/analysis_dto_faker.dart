import 'package:animus/core/intake/dtos/analysis_dto.dart';
import 'package:animus/core/intake/dtos/analysis_status_dto.dart';
import 'package:animus/core/intake/dtos/analysis_type_dto.dart';

final class AnalysisStatusDtoFaker {
  const AnalysisStatusDtoFaker._();

  static AnalysisStatusDto fake({
    AnalysisStatusDto status = AnalysisStatusDto.caseAnalyzed,
  }) {
    return status;
  }

  static List<AnalysisStatusDto> fakeMany([int count = 3]) {
    return List<AnalysisStatusDto>.generate(
      count,
      (int index) =>
          AnalysisStatusDto.values[index % AnalysisStatusDto.values.length],
    );
  }
}

final class AnalysisDtoFaker {
  const AnalysisDtoFaker._();

  static AnalysisDto fake({
    String? id = 'analysis-1',
    String name = 'Analise de precedente',
    String accountId = 'account-1',
    AnalysisTypeDto type = AnalysisTypeDto.firstInstance,
    AnalysisStatusDto status = AnalysisStatusDto.caseAnalyzed,
    String summary = 'Resumo gerado.',
    String createdAt = '2026-03-31T10:00:00Z',
    String? folderId,
    bool isArchived = false,
  }) {
    return AnalysisDto(
      id: id,
      name: name,
      accountId: accountId,
      type: type,
      status: status,
      summary: summary,
      createdAt: createdAt,
      folderId: folderId,
      isArchived: isArchived,
    );
  }

  static List<AnalysisDto> fakeMany([int count = 3]) {
    return List<AnalysisDto>.generate(count, (int index) {
      final int item = index + 1;
      return fake(id: 'analysis-$item', name: 'Analise de precedente $item');
    });
  }
}
