import 'package:animus/rest/mappers/auth/account_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mapeia id, name, email, is_verified e social_accounts', () {
    final Map<String, dynamic> json = <String, dynamic>{
      'id': 'account-1',
      'name': 'Ada Lovelace',
      'email': 'ada@example.com',
      'is_verified': true,
      'social_accounts': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'social-1',
          'provider': 'google',
          'name': 'Ada Lovelace',
          'email': 'ada@gmail.com',
        },
      ],
    };

    final account = AccountMapper.toDto(json);

    expect(account.id, 'account-1');
    expect(account.name, 'Ada Lovelace');
    expect(account.email, 'ada@example.com');
    expect(account.isVerified, isTrue);
    expect(account.socialAccounts, hasLength(1));
    expect(account.socialAccounts.single.id, 'social-1');
    expect(account.socialAccounts.single.provider, 'google');
    expect(account.socialAccounts.single.name, 'Ada Lovelace');
    expect(account.socialAccounts.single.email, 'ada@gmail.com');
  });
}
