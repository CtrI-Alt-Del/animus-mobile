class PetitionSummaryDto {
  final String content;
  final List<String> mainPoints;

  const PetitionSummaryDto({required this.content, required this.mainPoints});

  factory PetitionSummaryDto.fromJson(Map<String, dynamic> json) {
    return PetitionSummaryDto(
      content: json['content'] as String,
      mainPoints: List<String>.from(json['main_points'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {'content': content, 'main_points': mainPoints};
  }
}
