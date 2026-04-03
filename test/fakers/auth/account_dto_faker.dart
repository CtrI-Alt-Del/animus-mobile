import 'package:animus/core/auth/dtos/account_dto.dart';
import 'package:animus/core/auth/dtos/social_account_dto.dart';

final class AccountDtoFaker {
  const AccountDtoFaker._();

  static AccountDto fake({
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

  static List<AccountDto> fakeMany([int count = 3]) {
    return List<AccountDto>.generate(count, (int index) {
      final int item = index + 1;
      return fake(
        id: 'account-$item',
        name: 'Ada Lovelace $item',
        email: 'ada$item@example.com',
      );
    });
  }
}
