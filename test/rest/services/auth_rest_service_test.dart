import 'package:animus/core/shared/interfaces/rest_client.dart';
import 'package:animus/core/shared/responses/rest_response.dart';
import 'package:animus/rest/services/auth_rest_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRestClient extends Mock implements RestClient {}

void main() {
  late _MockRestClient restClient;
  late AuthRestService service;

  setUp(() {
    restClient = _MockRestClient();
    service = AuthRestService(restClient: restClient);
  });

  group('signIn', () {
    test('envia payload correto e mapeia a sessao', () async {
      when(
        () => restClient.post(
          '/auth/sign-in',
          body: <String, dynamic>{
            'email': 'ada@example.com',
            'password': 'Password1',
          },
        ),
      ).thenAnswer(
        (_) async => RestResponse<Map<String, dynamic>>(
          statusCode: 200,
          body: <String, dynamic>{
            'access_token': <String, dynamic>{
              'value': 'access-token',
              'expires_at': '2026-12-31T23:59:59Z',
            },
            'refresh_token': <String, dynamic>{
              'value': 'refresh-token',
              'expires_at': '2027-12-31T23:59:59Z',
            },
          },
        ),
      );

      final response = await service.signIn(
        email: 'ada@example.com',
        password: 'Password1',
      );

      expect(response.statusCode, 200);
      expect(response.body.accessToken.value, 'access-token');
      expect(response.body.refreshToken.value, 'refresh-token');
      verify(
        () => restClient.post(
          '/auth/sign-in',
          body: <String, dynamic>{
            'email': 'ada@example.com',
            'password': 'Password1',
          },
        ),
      ).called(1);
    });

    test('preserva falhas do rest client', () async {
      final RestResponse<Map<String, dynamic>> failure =
          RestResponse<Map<String, dynamic>>(
            statusCode: 401,
            errorMessage: 'E-mail ou senha incorretos.',
            errorBody: <String, dynamic>{
              'message': 'E-mail ou senha incorretos.',
            },
          );
      when(
        () => restClient.post('/auth/sign-in', body: any(named: 'body')),
      ).thenAnswer((_) async => failure);

      final response = await service.signIn(
        email: 'ada@example.com',
        password: 'Password1',
      );

      expect(response.isFailure, isTrue);
      expect(response.statusCode, 401);
      expect(response.errorMessage, 'E-mail ou senha incorretos.');
      expect(response.errorBody, failure.errorBody);
    });
  });

  group('signUp', () {
    test('envia payload correto e mapeia a conta', () async {
      when(
        () => restClient.post(
          '/auth/sign-up',
          body: <String, dynamic>{
            'name': 'Ada Lovelace',
            'email': 'ada@example.com',
            'password': 'Password1',
          },
        ),
      ).thenAnswer(
        (_) async => RestResponse<Map<String, dynamic>>(
          statusCode: 201,
          body: <String, dynamic>{
            'id': 'account-1',
            'name': 'Ada Lovelace',
            'email': 'ada@example.com',
            'is_verified': true,
            'social_accounts': <Map<String, dynamic>>[],
          },
        ),
      );

      final response = await service.signUp(
        name: 'Ada Lovelace',
        email: 'ada@example.com',
        password: 'Password1',
      );

      expect(response.statusCode, 201);
      expect(response.body.id, 'account-1');
      expect(response.body.name, 'Ada Lovelace');
      verify(
        () => restClient.post(
          '/auth/sign-up',
          body: <String, dynamic>{
            'name': 'Ada Lovelace',
            'email': 'ada@example.com',
            'password': 'Password1',
          },
        ),
      ).called(1);
    });

    test('preserva falhas do rest client', () async {
      final RestResponse<Map<String, dynamic>> failure =
          RestResponse<Map<String, dynamic>>(
            statusCode: 409,
            errorMessage: 'E-mail ja cadastrado',
            errorBody: <String, dynamic>{'message': 'E-mail ja cadastrado'},
          );
      when(
        () => restClient.post('/auth/sign-up', body: any(named: 'body')),
      ).thenAnswer((_) async => failure);

      final response = await service.signUp(
        name: 'Ada Lovelace',
        email: 'ada@example.com',
        password: 'Password1',
      );

      expect(response.isFailure, isTrue);
      expect(response.statusCode, 409);
      expect(response.errorMessage, 'E-mail ja cadastrado');
      expect(response.errorBody, failure.errorBody);
    });
  });

  group('signInWithGoogle', () {
    test('envia payload correto e mapeia a sessao', () async {
      when(
        () => restClient.post(
          '/auth/sign-up/google',
          body: <String, dynamic>{'id_token': 'google-id-token'},
        ),
      ).thenAnswer(
        (_) async => RestResponse<Map<String, dynamic>>(
          statusCode: 200,
          body: <String, dynamic>{
            'access_token': <String, dynamic>{
              'value': 'access-token',
              'expires_at': '2026-12-31T23:59:59Z',
            },
            'refresh_token': <String, dynamic>{
              'value': 'refresh-token',
              'expires_at': '2027-12-31T23:59:59Z',
            },
          },
        ),
      );

      final response = await service.signInWithGoogle(
        idToken: 'google-id-token',
      );

      expect(response.statusCode, 200);
      expect(response.body.accessToken.value, 'access-token');
      expect(response.body.refreshToken.value, 'refresh-token');
      verify(
        () => restClient.post(
          '/auth/sign-up/google',
          body: <String, dynamic>{'id_token': 'google-id-token'},
        ),
      ).called(1);
    });

    test('preserva falhas do rest client', () async {
      final RestResponse<Map<String, dynamic>> failure =
          RestResponse<Map<String, dynamic>>(
            statusCode: 401,
            errorMessage: 'Token Google invalido.',
            errorBody: <String, dynamic>{'message': 'Token Google invalido.'},
          );
      when(
        () => restClient.post('/auth/sign-up/google', body: any(named: 'body')),
      ).thenAnswer((_) async => failure);

      final response = await service.signInWithGoogle(
        idToken: 'google-id-token',
      );

      expect(response.isFailure, isTrue);
      expect(response.statusCode, 401);
      expect(response.errorMessage, 'Token Google invalido.');
      expect(response.errorBody, failure.errorBody);
    });
  });

  group('verifyEmail', () {
    test('envia payload correto e mapeia a sessao', () async {
      when(
        () => restClient.post(
          '/auth/verify-email',
          body: <String, dynamic>{'email': 'ada@example.com', 'otp': '123456'},
        ),
      ).thenAnswer(
        (_) async => RestResponse<Map<String, dynamic>>(
          statusCode: 200,
          body: <String, dynamic>{
            'access_token': <String, dynamic>{
              'value': 'access-token',
              'expires_at': '2026-12-31T23:59:59Z',
            },
            'refresh_token': <String, dynamic>{
              'value': 'refresh-token',
              'expires_at': '2027-12-31T23:59:59Z',
            },
          },
        ),
      );

      final response = await service.verifyEmail(
        email: 'ada@example.com',
        otp: '123456',
      );

      expect(response.body.accessToken.value, 'access-token');
      expect(response.body.refreshToken.value, 'refresh-token');
      verify(
        () => restClient.post(
          '/auth/verify-email',
          body: <String, dynamic>{'email': 'ada@example.com', 'otp': '123456'},
        ),
      ).called(1);
    });

    test('preserva falhas do rest client', () async {
      final RestResponse<Map<String, dynamic>> failure =
          RestResponse<Map<String, dynamic>>(
            statusCode: 422,
            errorMessage: 'Codigo invalido',
            errorBody: <String, dynamic>{'message': 'Codigo invalido'},
          );
      when(
        () => restClient.post('/auth/verify-email', body: any(named: 'body')),
      ).thenAnswer((_) async => failure);

      final response = await service.verifyEmail(
        email: 'ada@example.com',
        otp: '123456',
      );

      expect(response.isFailure, isTrue);
      expect(response.statusCode, 422);
      expect(response.errorMessage, 'Codigo invalido');
      expect(response.errorBody, failure.errorBody);
    });
  });

  group('resendVerificationEmail', () {
    test('envia payload correto', () async {
      when(
        () => restClient.post(
          '/auth/resend-verification-email',
          body: <String, dynamic>{'email': 'ada@example.com'},
        ),
      ).thenAnswer(
        (_) async => RestResponse<Map<String, dynamic>>(
          statusCode: 204,
          body: <String, dynamic>{},
        ),
      );

      final response = await service.resendVerificationEmail(
        email: 'ada@example.com',
      );

      expect(response.isSuccessful, isTrue);
      expect(response.statusCode, 204);
      verify(
        () => restClient.post(
          '/auth/resend-verification-email',
          body: <String, dynamic>{'email': 'ada@example.com'},
        ),
      ).called(1);
    });

    test('preserva falhas do rest client', () async {
      final RestResponse<Map<String, dynamic>> failure =
          RestResponse<Map<String, dynamic>>(
            statusCode: 500,
            errorMessage: 'Falha ao reenviar',
            errorBody: <String, dynamic>{'message': 'Falha ao reenviar'},
          );
      when(
        () => restClient.post(
          '/auth/resend-verification-email',
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => failure);

      final response = await service.resendVerificationEmail(
        email: 'ada@example.com',
      );

      expect(response.isFailure, isTrue);
      expect(response.statusCode, 500);
      expect(response.errorMessage, 'Falha ao reenviar');
      expect(response.errorBody, failure.errorBody);
    });
  });
}
