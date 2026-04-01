import 'package:animus/core/auth/dtos/account_dto.dart';
import 'package:animus/core/auth/dtos/session_dto.dart';
import 'package:animus/core/shared/responses/rest_response.dart';

abstract class AuthService {
  Future<RestResponse<AccountDto>> fetchAccount();

  Future<RestResponse<SessionDto>> signIn({
    required String email,
    required String password,
  });

  Future<RestResponse<AccountDto>> signUp({
    required String name,
    required String email,
    required String password,
  });

  Future<RestResponse<void>> resendVerificationEmail({required String email});

  Future<RestResponse<SessionDto>> verifyEmail({
    required String email,
    required String otp,
  });
}
