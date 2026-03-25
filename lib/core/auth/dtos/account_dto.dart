import 'package:animus/core/auth/dtos/social_account_dto.dart';

class AccountDto {
  final String? id;
  final String name;
  final String email;
  final bool isVerified;
  final List<SocialAccountDto> socialAccounts;

  const AccountDto({
    required this.name,
    required this.email,
    this.id,
    this.isVerified = false,
    this.socialAccounts = const <SocialAccountDto>[],
  });
}
