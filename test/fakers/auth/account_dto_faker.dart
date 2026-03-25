import 'package:animus/core/auth/dtos/account_dto.dart';
import 'package:animus/core/auth/dtos/social_account_dto.dart';

final class AccountDtoFaker {
  const AccountDtoFaker._();

  static AccountDto make({
    String? id = 'account-1',
    String name = 'Ada Lovelace',
    String email = 'ada@example.com',
    bool isVerified = false,
    List<SocialAccountDto> socialAccounts = const <SocialAccountDto>[
      SocialAccountDto(
        id: 'social-1',
        provider: 'google',
        name: 'Ada Lovelace',
        email: 'ada@example.com',
      ),
    ],
  }) {
    return AccountDto(
      id: id,
      name: name,
      email: email,
      isVerified: isVerified,
      socialAccounts: socialAccounts,
    );
  }
}
