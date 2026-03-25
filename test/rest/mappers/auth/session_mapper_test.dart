import 'package:animus/rest/mappers/auth/session_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mapeia access_token e refresh_token para SessionDto', () {
    final Map<String, dynamic> json = <String, dynamic>{
      'access_token': <String, dynamic>{
        'value': 'access-token',
        'expires_at': '2026-12-31T23:59:59Z',
      },
      'refresh_token': <String, dynamic>{
        'value': 'refresh-token',
        'expires_at': '2027-12-31T23:59:59Z',
      },
    };

    final session = SessionMapper.toDto(json);

    expect(session.accessToken.value, 'access-token');
    expect(session.accessToken.expiresAt, '2026-12-31T23:59:59Z');
    expect(session.refreshToken.value, 'refresh-token');
    expect(session.refreshToken.expiresAt, '2027-12-31T23:59:59Z');
  });
}
