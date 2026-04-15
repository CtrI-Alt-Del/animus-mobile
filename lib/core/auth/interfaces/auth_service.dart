import 'package:animus/core/auth/dtos/account_dto.dart';
import 'package:animus/core/auth/dtos/session_dto.dart';
import 'package:animus/core/shared/responses/rest_response.dart';

abstract class AuthService {
  Future<RestResponse<AccountDto>> getAccount();

  Future<RestResponse<AccountDto>> updateAccount({required String name});

  Future<RestResponse<void>> forgotPassword({required String email});

  Future<RestResponse<void>> resendResetPasswordOtp({required String email});

  Future<RestResponse<String>> verifyResetPasswordOtp({
    required String email,
    required String otp,
  });

  Future<RestResponse<void>> resetPassword({
    required String resetContext,
    required String newPassword,
  });

  Future<RestResponse<SessionDto>> signIn({
    required String email,
    required String password,
  });

  Future<RestResponse<SessionDto>> signInWithGoogle({required String idToken});

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
