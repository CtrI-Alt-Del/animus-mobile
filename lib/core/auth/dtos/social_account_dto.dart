class SocialAccountDto {
  final String name;
  final String email;
  final String provider;
  final String? id;

  const SocialAccountDto({
    required this.name,
    required this.email,
    required this.provider,
    this.id,
  });
}
