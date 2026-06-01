import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:animus/constants/cache_keys.dart';
import 'package:animus/core/shared/interfaces/cache_driver.dart';
import 'package:animus/drivers/caches/shared_preferences/shared_preferences_cache_driver.dart';
import 'package:animus/theme.dart';

const String _lightValue = 'light';
const String _darkValue = 'dark';

/// Holds the active [ThemeMode], restoring it from and persisting it to the
/// local cache via the [CacheDriver] port. Defaults to
/// [AppTheme.defaultThemeMode] (dark) when no preference is stored.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  /// Decodes a stored theme-mode string into a [ThemeMode], falling back to
  /// [AppTheme.defaultThemeMode] for unknown/null values. Shared with
  /// `main.dart` so cold-start resolution and the provider stay in sync.
  static ThemeMode decode(String? value) {
    switch (value) {
      case _lightValue:
        return ThemeMode.light;
      case _darkValue:
        return ThemeMode.dark;
      default:
        return AppTheme.defaultThemeMode;
    }
  }

  /// Encodes a [ThemeMode] into its persisted string representation.
  static String encode(ThemeMode mode) {
    return mode == ThemeMode.light ? _lightValue : _darkValue;
  }

  CacheDriver get _cacheDriver => ref.read(cacheDriverProvider);

  @override
  ThemeMode build() {
    final ThemeMode mode = _readStoredMode();
    _applyOverlay(mode);
    return mode;
  }

  ThemeMode _readStoredMode() {
    try {
      return decode(_cacheDriver.get(CacheKeys.themeMode));
    } catch (_) {
      // Cache driver may be unavailable (e.g. in widget tests without an
      // override). Fall back to the default theme mode in that case.
      return AppTheme.defaultThemeMode;
    }
  }

  /// Switches between dark and light, updating the state and persisting it.
  void toggle() {
    final ThemeMode next = state == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    setMode(next);
  }

  /// Sets and persists [mode] explicitly.
  void setMode(ThemeMode mode) {
    if (mode == state) {
      return;
    }
    state = mode;
    try {
      _cacheDriver.set(CacheKeys.themeMode, encode(mode));
    } catch (_) {
      // Cache driver may be unavailable (e.g. in widget tests without an
      // override). The in-memory state is still updated above.
    }
    _applyOverlay(mode);
  }

  void _applyOverlay(ThemeMode mode) {
    SystemChrome.setSystemUIOverlayStyle(AppTheme.overlayStyleFor(mode));
  }
}

final NotifierProvider<ThemeModeNotifier, ThemeMode> themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);
