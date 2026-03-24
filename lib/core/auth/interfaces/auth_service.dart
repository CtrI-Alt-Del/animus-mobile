import 'package:animus_mobile/core/auth/dtos/account_dto.dart';
import 'package:animus_mobile/core/shared/responses/rest_response.dart';

abstract class AuthService {
  Future<RestResponse<AccountDto>> signUp({
    required String name,
    required String email,
    required String password,
  });

  Future<RestResponse<void>> resendVerificationEmail({required String email});
}
