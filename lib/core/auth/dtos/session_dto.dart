import 'package:animus/core/auth/dtos/token_dto.dart';

class SessionDto {
  final TokenDto accessToken;
  final TokenDto refreshToken;

  const SessionDto({required this.accessToken, required this.refreshToken});
}
