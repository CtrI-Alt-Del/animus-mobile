import 'package:animus/core/intake/dtos/court_dto.dart';
import 'package:animus/core/intake/dtos/precedent_kind_dto.dart';

class AnalysisPrecedentsSearchFiltersDto {
  final List<CourtDto> courts;
  final List<PrecedentKindDto> precedentKinds;
  final int limit;

  const AnalysisPrecedentsSearchFiltersDto({
    required this.courts,
    required this.precedentKinds,
    required this.limit,
  });
}
