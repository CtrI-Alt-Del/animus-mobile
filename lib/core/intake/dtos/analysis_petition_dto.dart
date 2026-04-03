import 'package:animus/core/intake/dtos/petition_dto.dart';
import 'package:animus/core/intake/dtos/petition_summary_dto.dart';

class AnalysisPetitionDto {
  final PetitionDto petition;
  final PetitionSummaryDto? summary;

  const AnalysisPetitionDto({required this.petition, this.summary});
}
