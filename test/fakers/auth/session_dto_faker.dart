import 'package:animus/core/auth/dtos/session_dto.dart';
import 'package:animus/core/auth/dtos/token_dto.dart';

final class SessionDtoFaker {
  const SessionDtoFaker._();

  static SessionDto fake({
    String accessTokenValue = 'access-token',
    String accessTokenExpiresAt = '2026-12-31T23:59:59Z',
    String refreshTokenValue = 'refresh-token',
    String refreshTokenExpiresAt = '2027-12-31T23:59:59Z',
  }) {
    return SessionDto(
      accessToken: TokenDto(
        value: accessTokenValue,
        expiresAt: accessTokenExpiresAt,
      ),
      refreshToken: TokenDto(
        value: refreshTokenValue,
        expiresAt: refreshTokenExpiresAt,
      ),
    );
  }

  static List<SessionDto> fakeMany([int count = 3]) {
    return List<SessionDto>.generate(count, (int index) {
      final int item = index + 1;
      return fake(
        accessTokenValue: 'access-token-$item',
        refreshTokenValue: 'refresh-token-$item',
      );
    });
  }
}
