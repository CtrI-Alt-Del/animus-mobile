import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:animus/constants/cache_keys.dart';
import 'package:animus/core/shared/interfaces/cache_driver.dart';
import 'package:animus/drivers/caches/shared_preferences/shared_preferences_cache_driver.dart';
import 'package:animus/theme.dart';
import 'package:animus/ui/shared/theme/index.dart';

class _InMemoryCacheDriver implements CacheDriver {
  final Map<String, String> _store = <String, String>{};

  @override
  String? get(String key) => _store[key];

  @override
  void set(String key, String value) => _store[key] = value;

  @override
  void delete(String key) => _store.remove(key);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _InMemoryCacheDriver cache;

  ProviderContainer buildContainer() {
    return ProviderContainer(
      overrides: [cacheDriverProvider.overrideWithValue(cache)],
    );
  }

  setUp(() {
    cache = _InMemoryCacheDriver();
  });

  group('ThemeModeNotifier', () {
    test('defaults to dark when no preference is stored', () {
      final ProviderContainer container = buildContainer();
      addTearDown(container.dispose);

      expect(container.read(themeModeProvider), ThemeMode.dark);
      expect(AppTheme.defaultThemeMode, ThemeMode.dark);
    });

    test('loads the persisted light preference', () {
      cache.set(CacheKeys.themeMode, 'light');

      final ProviderContainer container = buildContainer();
      addTearDown(container.dispose);

      expect(container.read(themeModeProvider), ThemeMode.light);
    });

    test('loads the persisted dark preference', () {
      cache.set(CacheKeys.themeMode, 'dark');

      final ProviderContainer container = buildContainer();
      addTearDown(container.dispose);

      expect(container.read(themeModeProvider), ThemeMode.dark);
    });

    test('falls back to dark when the stored value is invalid', () {
      cache.set(CacheKeys.themeMode, 'rainbow');

      final ProviderContainer container = buildContainer();
      addTearDown(container.dispose);

      expect(container.read(themeModeProvider), ThemeMode.dark);
    });

    test('toggle switches dark -> light and persists it', () {
      final ProviderContainer container = buildContainer();
      addTearDown(container.dispose);

      expect(container.read(themeModeProvider), ThemeMode.dark);

      container.read(themeModeProvider.notifier).toggle();

      expect(container.read(themeModeProvider), ThemeMode.light);
      expect(cache.get(CacheKeys.themeMode), 'light');
    });

    test('toggle switches light -> dark and persists it', () {
      cache.set(CacheKeys.themeMode, 'light');

      final ProviderContainer container = buildContainer();
      addTearDown(container.dispose);

      expect(container.read(themeModeProvider), ThemeMode.light);

      container.read(themeModeProvider.notifier).toggle();

      expect(container.read(themeModeProvider), ThemeMode.dark);
      expect(cache.get(CacheKeys.themeMode), 'dark');
    });

    test('setMode persists the selected mode', () {
      final ProviderContainer container = buildContainer();
      addTearDown(container.dispose);

      container.read(themeModeProvider.notifier).setMode(ThemeMode.light);

      expect(container.read(themeModeProvider), ThemeMode.light);
      expect(cache.get(CacheKeys.themeMode), 'light');
    });

    test('setMode is a no-op when the mode is unchanged', () {
      final ProviderContainer container = buildContainer();
      addTearDown(container.dispose);

      // Default is dark; setting dark again should not write to cache.
      container.read(themeModeProvider.notifier).setMode(ThemeMode.dark);

      expect(container.read(themeModeProvider), ThemeMode.dark);
      expect(cache.get(CacheKeys.themeMode), isNull);
    });
  });

  group('cache driver round-trip for the theme key', () {
    test('persists and clears the theme mode value', () {
      final _InMemoryCacheDriver driver = _InMemoryCacheDriver();
      driver.set(CacheKeys.themeMode, 'light');
      expect(driver.get(CacheKeys.themeMode), 'light');
      driver.delete(CacheKeys.themeMode);
      expect(driver.get(CacheKeys.themeMode), isNull);
    });
  });
}
