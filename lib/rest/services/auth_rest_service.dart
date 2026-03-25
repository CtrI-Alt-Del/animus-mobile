import 'package:animus/core/auth/dtos/account_dto.dart';
import 'package:animus/core/auth/dtos/session_dto.dart';
import 'package:animus/core/auth/interfaces/auth_service.dart';
import 'package:animus/core/shared/interfaces/rest_client.dart';
import 'package:animus/core/shared/responses/rest_response.dart';
import 'package:animus/rest/mappers/auth/account_mapper.dart';
import 'package:animus/rest/mappers/auth/session_mapper.dart';

class AuthRestService implements AuthService {
  final RestClient _restClient;

  const AuthRestService({required RestClient restClient})
    : _restClient = restClient;

  @override
  Future<RestResponse<AccountDto>> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _restClient.post(
      '/auth/sign-up',
      body: <String, dynamic>{
        'name': name,
        'email': email,
        'password': password,
      },
    );

    return response.mapBody<AccountDto>(AccountMapper.toDto);
  }

  @override
  Future<RestResponse<void>> resendVerificationEmail({
    required String email,
  }) async {
    final response = await _restClient.post(
      '/auth/resend-verification-email',
      body: <String, dynamic>{'email': email},
    );

    if (response.isFailure) {
      String? errorMessage;
      try {
        errorMessage = response.errorMessage;
      } catch (_) {
        errorMessage = null;
      }

      return RestResponse<void>(
        statusCode: response.statusCode,
        errorMessage: errorMessage,
        errorBody: response.errorBody,
      );
    }

    return RestResponse<void>(statusCode: response.statusCode);
  }

  @override
  Future<RestResponse<SessionDto>> verifyEmail({
    required String email,
    required String otp,
  }) async {
    final response = await _restClient.post(
      '/auth/verify-email',
      body: <String, dynamic>{'email': email, 'otp': otp},
    );

    return response.mapBody<SessionDto>(SessionMapper.toDto);
  }
}
