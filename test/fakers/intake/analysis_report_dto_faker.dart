import 'package:animus/core/intake/dtos/analysis_dto.dart';
import 'package:animus/core/intake/dtos/analysis_precedent_dto.dart';
import 'package:animus/core/intake/dtos/analysis_report_dto.dart';
import 'package:animus/core/intake/dtos/analysis_report_filters_dto.dart';
import 'package:animus/core/intake/dtos/court_dto.dart';
import 'package:animus/core/intake/dtos/petition_dto.dart';
import 'package:animus/core/intake/dtos/case_summary_dto.dart';
import 'package:animus/core/intake/dtos/precedent_kind_dto.dart';

import 'analysis_dto_faker.dart';
import 'analysis_precedent_dto_faker.dart';
import 'petition_dto_faker.dart';
import 'petition_summary_dto_faker.dart';

final class AnalysisReportDtoFaker {
  const AnalysisReportDtoFaker._();

  static AnalysisReportDto fake({
    AnalysisDto? analysis,
    PetitionDto? petition,
    CaseSummaryDto? caseSummary,
    AnalysisReportFiltersDto? filters,
    List<AnalysisPrecedentDto>? precedents,
    AnalysisPrecedentDto? chosenPrecedent,
  }) {
    final AnalysisPrecedentDto resolvedChosenPrecedent =
        chosenPrecedent ?? AnalysisPrecedentDtoFaker.fake(isChosen: true);

    return AnalysisReportDto(
      analysis: analysis ?? AnalysisDtoFaker.fake(),
      petition: petition ?? PetitionDtoFaker.fake(),
      caseSummary: caseSummary ?? PetitionSummaryDtoFaker.fake(),
      filters:
          filters ??
          const AnalysisReportFiltersDto(
            limit: 5,
            courts: <CourtDto>[],
            precedentKinds: <PrecedentKindDto>[],
          ),
      precedents: precedents ?? <AnalysisPrecedentDto>[resolvedChosenPrecedent],
      chosenPrecedent: resolvedChosenPrecedent,
    );
  }
}
