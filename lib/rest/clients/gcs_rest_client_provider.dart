import 'package:animus/core/shared/interfaces/rest_client.dart';
import 'package:animus/rest/dio/dio_rest_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:animus/constants/env.dart';

final Provider<RestClient> gcsRestClientProvider = Provider<RestClient>((
  Ref ref,
) {
  final DioRestClient client = DioRestClient();
  client.setBaseUrl(Env.gcsUrl);
  return client;
});
