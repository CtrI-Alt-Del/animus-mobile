import 'package:animus/core/intake/dtos/court_dto.dart';
import 'package:animus/core/intake/dtos/precedent_kind_dto.dart';

class PrecedentIdentifierDto {
  final CourtDto court;
  final PrecedentKindDto kind;
  final int number;

  const PrecedentIdentifierDto({
    required this.court,
    required this.kind,
    required this.number,
  });
}
