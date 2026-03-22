import 'package:animus_mobile/core/auth/dtos/social_account_dto.dart';

class AccountDto {
  final String name;
  final String email;
  final String password;
  final String? id;
  final bool isVerified;
  final bool isActive;
  final List<SocialAccountDto>? socialAccounts;

  const AccountDto({
    required this.name,
    required this.email,
    required this.password,
    this.id,
    this.isVerified = false,
    this.isActive = true,
    this.socialAccounts,
  });
}
