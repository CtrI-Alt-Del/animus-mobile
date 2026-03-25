import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:animus/core/shared/interfaces/cache_driver.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef CacheDriverFactory = Future<CacheDriver> Function();

final Provider<CacheDriverFactory> cacheDriverFactoryProvider =
    Provider<CacheDriverFactory>((Ref ref) {
      return SharedPreferencesCacheDriver.create;
    });

class SharedPreferencesCacheDriver implements CacheDriver {
  final SharedPreferences _preferences;

  const SharedPreferencesCacheDriver._(this._preferences);

  static Future<SharedPreferencesCacheDriver> create() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    return SharedPreferencesCacheDriver._(preferences);
  }

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
