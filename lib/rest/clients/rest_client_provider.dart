import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:animus/constants/env.dart';
import 'package:animus/core/shared/interfaces/rest_client.dart';
import 'package:animus/rest/dio/auth_token_interceptor.dart';
import 'package:animus/rest/dio/dio_rest_client.dart';
import 'package:animus/drivers/cache/index.dart';
import 'package:animus/drivers/navigation/index.dart';

final Provider<RestClient> restClientProvider = Provider<RestClient>((Ref ref) {
  final client = DioRestClient(
    interceptors: <Interceptor>[
      AuthTokenInterceptor(
        cacheDriver: ref.watch(cacheDriverProvider),
        navigationDriver: ref.watch(navigationDriverProvider),
        baseUrl: Env.animusServerAppUrl,
      ),
    ],
  );
  client.setBaseUrl(Env.animusServerAppUrl);
  return client;
});
