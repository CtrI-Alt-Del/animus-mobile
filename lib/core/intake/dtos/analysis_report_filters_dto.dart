import 'package:animus/core/intake/dtos/court_dto.dart';
import 'package:animus/core/intake/dtos/precedent_kind_dto.dart';

class AnalysisReportFiltersDto {
  final int limit;
  final List<CourtDto> courts;
  final List<PrecedentKindDto> precedentKinds;

  const AnalysisReportFiltersDto({
    required this.limit,
    required this.courts,
    required this.precedentKinds,
  });
}
