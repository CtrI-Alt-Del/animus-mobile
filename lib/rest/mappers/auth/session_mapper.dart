import 'package:animus/core/auth/dtos/session_dto.dart';
import 'package:animus/core/auth/dtos/token_dto.dart';
import 'package:animus/core/shared/types/json.dart';

final class SessionMapper {
  const SessionMapper._();

  static SessionDto toDto(Json json) {
    return SessionDto(
      accessToken: _toTokenDto(json['access_token']),
      refreshToken: _toTokenDto(json['refresh_token']),
    );
  }

  static TokenDto _toTokenDto(dynamic value) {
    if (value is String) {
      return TokenDto(value: value, expiresAt: '');
    }

    if (value is Json) {
      final String tokenValue =
          (value['value'] as String?) ?? (value['token'] as String?) ?? '';
      final String expiresAt =
          (value['expires_at'] as String?) ??
          (value['expiresAt'] as String?) ??
          '';
      return TokenDto(value: tokenValue, expiresAt: expiresAt);
    }

    return const TokenDto(value: '', expiresAt: '');
  }
}
