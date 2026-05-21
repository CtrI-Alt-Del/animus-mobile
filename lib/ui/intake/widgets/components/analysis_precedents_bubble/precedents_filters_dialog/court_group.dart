import 'package:animus/core/intake/dtos/court_dto.dart';

class CourtGroup {
  final String title;
  final List<CourtDto> courts;

  const CourtGroup({required this.title, required this.courts});
}
