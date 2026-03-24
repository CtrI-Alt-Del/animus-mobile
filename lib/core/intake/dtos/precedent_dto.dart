class PrecedentDto {
  final String court;
  final int number;
  final String synthesis;
  final String kind;
  final String status;
  final String title;
  final String enunciation;
  final String thesis;
  final String lastUpdatedInPangeaAt;
  final String? id;

  const PrecedentDto({
    required this.court,
    required this.number,
    required this.synthesis,
    required this.kind,
    required this.status,
    required this.title,
    required this.enunciation,
    required this.thesis,
    required this.lastUpdatedInPangeaAt,
    this.id,
  });
}
