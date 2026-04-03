import 'package:animus/app.dart';
import 'package:animus/constants/cache_keys.dart';
import 'package:animus/constants/env.dart';
import 'package:animus/drivers/caches/shared_preferences/shared_preferences_cache_driver.dart';
import 'package:animus/drivers/cache/index.dart';
import 'package:animus/rest/dio/dio_rest_client.dart';
import 'package:animus/rest/services/auth_rest_service.dart';
import 'package:animus/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  final SharedPreferences sharedPreferences =
      await SharedPreferences.getInstance();

  await _validateSessionOnAppLoad(sharedPreferences);

  if (AppTheme.defaultThemeMode == ThemeMode.dark) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const AnimusApp(),
    ),
  );
}

Future<void> _validateSessionOnAppLoad(SharedPreferences preferences) async {
  final String accessToken =
      (preferences.getString(CacheKeys.accessToken) ?? '').trim();
  final String refreshToken =
      (preferences.getString(CacheKeys.refreshToken) ?? '').trim();

  if (accessToken.isEmpty || refreshToken.isEmpty) {
    return;
  }

  final DioRestClient restClient = DioRestClient();
  restClient.setBaseUrl(Env.animusServerAppUrl);

  final AuthRestService authService = AuthRestService(
    restClient: restClient,
    cacheDriver: SharedPreferencesCacheDriver(preferences),
  );

  final response = await authService.getAccount();
  if (response.isFailure) {
    await preferences.remove(CacheKeys.accessToken);
    await preferences.remove(CacheKeys.refreshToken);
  }
}
