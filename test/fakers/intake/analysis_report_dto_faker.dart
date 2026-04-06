import 'package:animus/core/intake/dtos/analysis_dto.dart';
import 'package:animus/core/intake/dtos/analysis_precedent_dto.dart';
import 'package:animus/core/intake/dtos/analysis_report_dto.dart';
import 'package:animus/core/intake/dtos/petition_dto.dart';
import 'package:animus/core/intake/dtos/petition_summary_dto.dart';

import 'analysis_dto_faker.dart';
import 'analysis_precedent_dto_faker.dart';
import 'petition_dto_faker.dart';
import 'petition_summary_dto_faker.dart';

final class AnalysisReportDtoFaker {
  const AnalysisReportDtoFaker._();

  static AnalysisReportDto fake({
    AnalysisDto? analysis,
    PetitionDto? petition,
    PetitionSummaryDto? summary,
    List<AnalysisPrecedentDto>? precedents,
    AnalysisPrecedentDto? chosenPrecedent,
  }) {
    final AnalysisPrecedentDto resolvedChosenPrecedent =
        chosenPrecedent ?? AnalysisPrecedentDtoFaker.fake(isChosen: true);

    return AnalysisReportDto(
      analysis: analysis ?? AnalysisDtoFaker.fake(),
      petition: petition ?? PetitionDtoFaker.fake(),
      summary: summary ?? PetitionSummaryDtoFaker.fake(),
      precedents: precedents ?? <AnalysisPrecedentDto>[resolvedChosenPrecedent],
      chosenPrecedent: resolvedChosenPrecedent,
    );
  }
}
