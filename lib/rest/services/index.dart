import 'package:animus/core/auth/interfaces/auth_service.dart';
import 'package:animus/core/shared/interfaces/rest_client.dart';
import 'package:animus/rest/dio/dio_rest_client.dart';
import 'package:animus/rest/services/auth_rest_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final Provider<AuthService> authServiceProvider = Provider<AuthService>((
  Ref ref,
) {
  final RestClient restClient = ref.watch(restClientProvider);
  return AuthRestService(restClient: restClient);
});
