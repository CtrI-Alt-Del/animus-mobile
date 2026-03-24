import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:animus_mobile/core/auth/dtos/account_dto.dart';
import 'package:animus_mobile/core/auth/interfaces/auth_service.dart';
import 'package:animus_mobile/core/shared/interfaces/rest_client.dart';
import 'package:animus_mobile/core/shared/responses/rest_response.dart';
import 'package:animus_mobile/rest/dio/dio_rest_client.dart';
import 'package:animus_mobile/rest/mappers/auth/account_mapper.dart';

final Provider<AuthService> authServiceProvider = Provider<AuthService>((
  Ref ref,
) {
  final RestClient restClient = ref.watch(restClientProvider);
  return AuthRestService(restClient: restClient);
});

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
      body: AccountMapper.toSignUpJson(
        name: name,
        email: email,
        password: password,
      ),
    );

    return response.mapBody<AccountDto>(AccountMapper.toDto);
  }

  @override
  Future<RestResponse<void>> resendVerificationEmail({
    required String email,
  }) async {
    final response = await _restClient.post(
      '/auth/resend-verification-email',
      body: AccountMapper.toResendVerificationEmailJson(email: email),
    );

    if (response.isFailure) {
      final String fallbackErrorMessage =
          response.errorBody?['message'] as String? ??
          'Request failed with status ${response.statusCode}';
      return RestResponse<void>(
        statusCode: response.statusCode,
        errorMessage: fallbackErrorMessage,
        errorBody: response.errorBody,
      );
    }

    return RestResponse<void>(statusCode: response.statusCode);
  }
}
