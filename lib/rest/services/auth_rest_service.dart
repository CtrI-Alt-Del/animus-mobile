import 'package:animus/core/auth/dtos/account_dto.dart';
import 'package:animus/core/auth/dtos/session_dto.dart';
import 'package:animus/core/auth/interfaces/auth_service.dart';
import 'package:animus/core/shared/interfaces/cache_driver.dart';
import 'package:animus/core/shared/interfaces/navigation_driver.dart';
import 'package:animus/core/shared/interfaces/rest_client.dart';
import 'package:animus/core/shared/responses/rest_response.dart';
import 'package:animus/rest/mappers/auth/account_mapper.dart';
import 'package:animus/rest/mappers/auth/session_mapper.dart';
import 'package:animus/rest/services/service.dart';

class AuthRestService extends Service implements AuthService {
  AuthRestService({
    required RestClient restClient,
    required CacheDriver cacheDriver,
    required NavigationDriver navigationDriver,
  }) : super(restClient, cacheDriver, navigationDriver);

  @override
  Future<RestResponse<AccountDto>> getAccount() async {
    final RestResponse<AccountDto>? authFailure = requireAuth<AccountDto>();
    if (authFailure != null) {
      return authFailure;
    }

    final response = await restClient.get('/auth/account');
    return response.mapBody<AccountDto>(AccountMapper.toDto);
  }

  @override
  Future<RestResponse<AccountDto>> updateAccount({required String name}) async {
    final RestResponse<AccountDto>? authFailure = requireAuth<AccountDto>();
    if (authFailure != null) {
      return authFailure;
    }

    final response = await restClient.patch(
      '/auth/account',
      body: <String, dynamic>{'name': name},
    );

    return response.mapBody<AccountDto>(AccountMapper.toDto);
  }

  @override
  Future<RestResponse<void>> forgotPassword({required String email}) async {
    final response = await restClient.post(
      '/auth/password/forgot',
      body: <String, dynamic>{'email': email},
    );

    return toVoidResponse(response);
  }

  @override
  Future<RestResponse<void>> resendResetPasswordOtp({
    required String email,
  }) async {
    final response = await restClient.post(
      '/auth/password/resend-reset-otp',
      body: <String, dynamic>{'email': email},
    );

    return toVoidResponse(response);
  }

  @override
  Future<RestResponse<void>> resetPassword({
    required String resetContext,
    required String newPassword,
  }) async {
    final response = await restClient.post(
      '/auth/password/reset',
      body: <String, dynamic>{
        'reset_context': resetContext,
        'new_password': newPassword,
      },
    );

    return toVoidResponse(response);
  }

  @override
  Future<RestResponse<SessionDto>> signIn({
    required String email,
    required String password,
  }) async {
    final response = await restClient.post(
      '/auth/sign-in',
      body: <String, dynamic>{'email': email, 'password': password},
    );

    return response.mapBody<SessionDto>(SessionMapper.toDto);
  }

  @override
  Future<RestResponse<SessionDto>> signInWithGoogle({
    required String idToken,
  }) async {
    final response = await restClient.post(
      '/auth/sign-up/google',
      body: <String, dynamic>{'id_token': idToken},
    );

    return response.mapBody<SessionDto>(SessionMapper.toDto);
  }

  @override
  Future<RestResponse<AccountDto>> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await restClient.post(
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
  Future<RestResponse<String>> verifyResetPasswordOtp({
    required String email,
    required String otp,
  }) async {
    final response = await restClient.post(
      '/auth/password/verify-reset-otp',
      body: <String, dynamic>{'email': email, 'otp': otp},
    );

    if (response.isFailure) {
      return RestResponse<String>(
        statusCode: response.statusCode,
        errorMessage: resolveErrorMessage(response),
        errorBody: response.errorBody,
      );
    }

    String? resetContext;

    try {
      final dynamic body = response.body;
      final dynamic rawResetContext = body['reset_context'];
      if (rawResetContext is String && rawResetContext.isNotEmpty) {
        resetContext = rawResetContext;
      }
    } catch (_) {
      resetContext = null;
    }

    if (resetContext == null) {
      return RestResponse<String>(
        statusCode: response.statusCode,
        errorMessage: 'Invalid verify reset otp response.',
        errorBody: response.errorBody,
      );
    }

    return RestResponse<String>(
      body: resetContext,
      statusCode: response.statusCode,
    );
  }

  @override
  Future<RestResponse<void>> resendVerificationEmail({
    required String email,
  }) async {
    final response = await restClient.post(
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
    final response = await restClient.post(
      '/auth/verify-email',
      body: <String, dynamic>{'email': email, 'otp': otp},
    );

    return response.mapBody<SessionDto>(SessionMapper.toDto);
  }
}
