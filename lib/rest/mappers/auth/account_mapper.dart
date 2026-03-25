import 'package:animus/core/auth/dtos/account_dto.dart';
import 'package:animus/core/auth/dtos/social_account_dto.dart';
import 'package:animus/core/shared/types/json.dart';

final class AccountMapper {
  const AccountMapper._();

  static AccountDto toDto(Json json) {
    return AccountDto(
      id: json['id'] as String?,
      name: (json['name'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      isVerified: (json['is_verified'] as bool?) ?? false,
      socialAccounts: _toSocialAccounts(json['social_accounts']),
    );
  }

  static List<SocialAccountDto> _toSocialAccounts(dynamic value) {
    if (value is! List<dynamic>) {
      return const <SocialAccountDto>[];
    }

    return value.whereType<Json>().map(_toSocialAccount).toList();
  }

  static SocialAccountDto _toSocialAccount(Json json) {
    return SocialAccountDto(
      id: json['id'] as String?,
      provider: (json['provider'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
    );
  }
}
