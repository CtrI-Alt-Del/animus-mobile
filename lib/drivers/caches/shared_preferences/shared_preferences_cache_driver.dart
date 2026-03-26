import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:animus/core/shared/interfaces/cache_driver.dart';
import 'package:shared_preferences/shared_preferences.dart';

final Provider<SharedPreferences> sharedPreferencesProvider =
    Provider<SharedPreferences>((Ref ref) {
      throw UnimplementedError(
        'sharedPreferencesProvider must be overridden in main.dart',
      );
    });

final Provider<CacheDriver> cacheDriverProvider = Provider<CacheDriver>((
  Ref ref,
) {
  final SharedPreferences preferences = ref.watch(sharedPreferencesProvider);
  return SharedPreferencesCacheDriver(preferences);
});

class SharedPreferencesCacheDriver implements CacheDriver {
  final SharedPreferences _preferences;

  const SharedPreferencesCacheDriver(this._preferences);

  @override
  String? get(String key) {
    return _preferences.getString(key);
  }

  @override
  void set(String key, String value) {
    unawaited(_preferences.setString(key, value));
  }

  @override
  void delete(String key) {
    unawaited(_preferences.remove(key));
  }
}
