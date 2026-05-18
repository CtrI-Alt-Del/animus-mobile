import 'package:animus/core/intake/dtos/case_summary_dto.dart';
import 'package:animus/core/intake/dtos/petition_dto.dart';

class AnalysisPetitionDto {
  final PetitionDto petition;
  final CaseSummaryDto? caseSummary;

  const AnalysisPetitionDto({required this.petition, this.caseSummary});
}
