import 'package:animus_mobile/core/auth/dtos/session_dto.dart';
import 'package:animus_mobile/core/shared/responses/rest_response.dart';

abstract class AuthService {
  Future<RestResponse<SessionDto>> signIn({
    required String email,
    required String password,
  });
}
