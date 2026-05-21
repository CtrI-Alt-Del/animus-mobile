import 'package:animus/core/intake/dtos/analysis_dto.dart';
import 'package:animus/core/intake/dtos/analysis_document_dto.dart';
import 'package:animus/core/intake/dtos/analysis_precedent_dto.dart';
import 'package:animus/core/intake/dtos/case_summary_dto.dart';
import 'package:animus/core/intake/dtos/first_instance_analysis_report_dto.dart';
import 'package:animus/core/intake/dtos/first_instance_analysis_judgment_draft_dto.dart';

import 'analysis_dto_faker.dart';
import 'analysis_precedent_dto_faker.dart';
import 'petition_summary_dto_faker.dart';

final class AnalysisDocumentDtoFaker {
  const AnalysisDocumentDtoFaker._();

  static AnalysisDocumentDto fake({
    String analysisId = 'analysis-1',
    String uploadedAt = '2026-04-02T12:00:00Z',
    String filePath = 'uploads/analyses/analysis-1.pdf',
    String name = 'analysis.pdf',
  }) {
    return AnalysisDocumentDto(
      analysisId: analysisId,
      uploadedAt: uploadedAt,
      filePath: filePath,
      name: name,
    );
  }
}

final class JudgmentDraftDtoFaker {
  const JudgmentDraftDtoFaker._();

  static FirstInstanceJudgmentDraftDto fake({
    String content = 'Minuta de julgamento',
  }) {
    return FirstInstanceJudgmentDraftDto(content: content);
  }
}

final class FirstInstanceAnalysisReportDtoFaker {
  const FirstInstanceAnalysisReportDtoFaker._();

  static FirstInstanceAnalysisReportDto fake({
    AnalysisDto? analysis,
    AnalysisDocumentDto? document,
    CaseSummaryDto? caseSummary,
    List<AnalysisPrecedentDto>? precedents,
    FirstInstanceJudgmentDraftDto? judgmentDraft,
  }) {
    final AnalysisDto resolvedAnalysis = analysis ?? AnalysisDtoFaker.fake();
    final AnalysisPrecedentDto chosenPrecedent = AnalysisPrecedentDtoFaker.fake(
      isChosen: true,
    );

    return FirstInstanceAnalysisReportDto(
      analysis: resolvedAnalysis,
      document:
          document ??
          AnalysisDocumentDtoFaker.fake(
            analysisId: resolvedAnalysis.id ?? 'analysis-1',
          ),
      caseSummary: caseSummary ?? PetitionSummaryDtoFaker.fake(),
      precedents: precedents ?? <AnalysisPrecedentDto>[chosenPrecedent],
      judgmentDraft: judgmentDraft ?? JudgmentDraftDtoFaker.fake(),
    );
  }
}
