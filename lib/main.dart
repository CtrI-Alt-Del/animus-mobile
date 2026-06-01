import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:animus/app.dart';
import 'package:animus/constants/cache_keys.dart';
import 'package:animus/constants/env.dart';
import 'package:animus/core/shared/interfaces/push_notification_driver.dart';
import 'package:animus/rest/dio/auth_token_interceptor.dart';
import 'package:animus/rest/dio/dio_rest_client.dart';
import 'package:animus/rest/services/auth_rest_service.dart';
import 'package:animus/theme.dart';
import 'package:animus/ui/shared/theme/index.dart';
import 'package:animus/drivers/caches/shared_preferences/shared_preferences_cache_driver.dart';
import 'package:animus/drivers/cache/index.dart';
import 'package:animus/drivers/navigation/index.dart';
import 'package:animus/drivers/push-notification-driver/index.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const String envFile = String.fromEnvironment(
    'ENV_FILE',
    defaultValue: '.env',
  );
  await dotenv.load(fileName: envFile);
  const PushNotificationDriver pushNotificationDriver =
      OneSignalPushNotificationDriver();
  await pushNotificationDriver.initialize();

  final SharedPreferences sharedPreferences =
      await SharedPreferences.getInstance();

  await _validateSessionOnAppLoad(sharedPreferences, pushNotificationDriver);

  final ThemeMode initialThemeMode = _resolveInitialThemeMode(
    sharedPreferences,
  );
  SystemChrome.setSystemUIOverlayStyle(
    AppTheme.overlayStyleFor(initialThemeMode),
  );

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        pushNotificationDriverProvider.overrideWithValue(
          pushNotificationDriver,
        ),
      ],
      child: const AnimusApp(),
    ),
  );
}

ThemeMode _resolveInitialThemeMode(SharedPreferences preferences) {
  return ThemeModeNotifier.decode(preferences.getString(CacheKeys.themeMode));
}

Future<void> _validateSessionOnAppLoad(
  SharedPreferences preferences,
  PushNotificationDriver pushNotificationDriver,
) async {
  final String accessToken =
      (preferences.getString(CacheKeys.accessToken) ?? '').trim();
  final String refreshToken =
      (preferences.getString(CacheKeys.refreshToken) ?? '').trim();

  if (accessToken.isEmpty || refreshToken.isEmpty) {
    return;
  }

  final SharedPreferencesCacheDriver cacheDriver = SharedPreferencesCacheDriver(
    preferences,
  );
  final AuthTokenInterceptor authTokenInterceptor = AuthTokenInterceptor(
    cacheDriver: cacheDriver,
    navigationDriver: const GoRouterNavigationDriver(),
    baseUrl: Env.animusServerAppUrl,
  );

  final DioRestClient restClient = DioRestClient(
    interceptors: [authTokenInterceptor],
  );
  restClient.setBaseUrl(Env.animusServerAppUrl);

  final AuthRestService authService = AuthRestService(restClient: restClient);

  final response = await authService.getAccount();
  if (response.isFailure) {
    await preferences.remove(CacheKeys.accessToken);
    await preferences.remove(CacheKeys.refreshToken);
    await pushNotificationDriver.clearUser();
    return;
  }

  final String accountId = (response.body.id ?? '').trim();
  if (accountId.isNotEmpty) {
    await pushNotificationDriver.identifyUser(accountId);
  }
}
