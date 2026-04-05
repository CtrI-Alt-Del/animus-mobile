import 'package:animus/core/intake/dtos/precedent_identifier_dto.dart';

class PrecedentDto {
  final PrecedentIdentifierDto identifier;
  final String synthesis;
  final String status;
  final String enunciation;
  final String thesis;
  final String lastUpdatedInPangeaAt;
  final String? id;

  const PrecedentDto({
    required this.identifier,
    required this.synthesis,
    required this.status,
    required this.enunciation,
    required this.thesis,
    required this.lastUpdatedInPangeaAt,
    this.id,
  });
}
