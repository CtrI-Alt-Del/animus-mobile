import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Dark palette
const Color _amber = Color(0xFFFBE26D);
const Color _amberStrong = Color(0xFFC4A535);
const Color _bgCard = Color(0xFF16161A);
const Color _bgElevated = Color(0xFF1A1A1E);
const Color _bgPage = Color(0xFF0B0B0E);
const Color _borderStrong = Color(0xFF3A3A40);
const Color _borderSubtle = Color(0xFF2A2A2E);
const Color _coral = Color(0xFFE85A4F);
const Color _coralDark = Color(0xFFDC2626);
const Color _green = Color(0xFF32D583);
const Color _greenDark = Color(0xFF059669);
const Color _indigo = Color(0xFF6366F1);
const Color _indigoDark = Color(0xFF4F46E5);
const Color _redError = Color(0xFFEF4444);
const Color _textMuted = Color(0xFF8E8E93);
const Color _textPrimary = Color(0xFFFAFAF9);
const Color _textSecondary = Color(0xFF6B6B70);
const Color _textTertiary = Color(0xFF4A4A50);
const Color _white = Color(0xFFFFFFFF);
const Color _scrim = Color(0x99000000);

// Light palette (provisional — defined by the developer, see ANI-108 spec).
const Color _lAmber = Color(0xFFC4A535);
const Color _lAmberStrong = Color(0xFF9C8226);
const Color _lBgCard = Color(0xFFFFFFFF);
const Color _lBgElevated = Color(0xFFEFEFEC);
const Color _lBgPage = Color(0xFFF7F7F5);
const Color _lBorderStrong = Color(0xFFC9C9C2);
const Color _lBorderSubtle = Color(0xFFE2E2DD);
const Color _lCoral = Color(0xFFD23B2F);
const Color _lCoralDark = Color(0xFFB91C1C);
const Color _lGreen = Color(0xFF15A862);
const Color _lGreenDark = Color(0xFF047857);
const Color _lTextMuted = Color(0xFF6B6B70);
const Color _lTextPrimary = Color(0xFF1A1A1E);
const Color _lTextSecondary = Color(0xFF5A5A60);
const Color _lTextTertiary = Color(0xFFA0A0A6);
const Color _lWarning = Color(0xFFB7902A);
const Color _lScrim = Color(0x66000000);

@immutable
final class AppThemeTokens extends ThemeExtension<AppThemeTokens> {
  const AppThemeTokens({
    required this.surfacePage,
    required this.surfaceCard,
    required this.surfaceElevated,
    required this.borderSubtle,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textTertiary,
    required this.accent,
    required this.accentStrong,
    required this.white,
    required this.success,
    required this.successDark,
    required this.warning,
    required this.danger,
    required this.dangerDark,
    required this.scrim,
    required this.primaryGradient,
  });

  final Color surfacePage;
  final Color surfaceCard;
  final Color surfaceElevated;
  final Color borderSubtle;
  final Color borderStrong;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textTertiary;
  final Color accent;
  final Color accentStrong;
  final Color white;
  final Color success;
  final Color successDark;
  final Color warning;
  final Color danger;
  final Color dangerDark;
  final Color scrim;
  final LinearGradient primaryGradient;

  @override
  AppThemeTokens copyWith({
    Color? surfacePage,
    Color? surfaceCard,
    Color? surfaceElevated,
    Color? borderSubtle,
    Color? borderStrong,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? textTertiary,
    Color? accent,
    Color? accentStrong,
    Color? white,
    Color? success,
    Color? successDark,
    Color? warning,
    Color? danger,
    Color? dangerDark,
    Color? scrim,
    LinearGradient? primaryGradient,
  }) {
    return AppThemeTokens(
      surfacePage: surfacePage ?? this.surfacePage,
      surfaceCard: surfaceCard ?? this.surfaceCard,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      borderStrong: borderStrong ?? this.borderStrong,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      textTertiary: textTertiary ?? this.textTertiary,
      accent: accent ?? this.accent,
      accentStrong: accentStrong ?? this.accentStrong,
      white: white ?? this.white,
      success: success ?? this.success,
      successDark: successDark ?? this.successDark,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      dangerDark: dangerDark ?? this.dangerDark,
      scrim: scrim ?? this.scrim,
      primaryGradient: primaryGradient ?? this.primaryGradient,
    );
  }

  @override
  AppThemeTokens lerp(ThemeExtension<AppThemeTokens>? other, double t) {
    if (other is! AppThemeTokens) {
      return this;
    }

    return AppThemeTokens(
      surfacePage: Color.lerp(surfacePage, other.surfacePage, t) ?? surfacePage,
      surfaceCard: Color.lerp(surfaceCard, other.surfaceCard, t) ?? surfaceCard,
      surfaceElevated:
          Color.lerp(surfaceElevated, other.surfaceElevated, t) ??
          surfaceElevated,
      borderSubtle:
          Color.lerp(borderSubtle, other.borderSubtle, t) ?? borderSubtle,
      borderStrong:
          Color.lerp(borderStrong, other.borderStrong, t) ?? borderStrong,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t) ?? textPrimary,
      textSecondary:
          Color.lerp(textSecondary, other.textSecondary, t) ?? textSecondary,
      textMuted: Color.lerp(textMuted, other.textMuted, t) ?? textMuted,
      textTertiary:
          Color.lerp(textTertiary, other.textTertiary, t) ?? textTertiary,
      accent: Color.lerp(accent, other.accent, t) ?? accent,
      accentStrong:
          Color.lerp(accentStrong, other.accentStrong, t) ?? accentStrong,
      white: Color.lerp(white, other.white, t) ?? white,
      success: Color.lerp(success, other.success, t) ?? success,
      successDark: Color.lerp(successDark, other.successDark, t) ?? successDark,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      danger: Color.lerp(danger, other.danger, t) ?? danger,
      dangerDark: Color.lerp(dangerDark, other.dangerDark, t) ?? dangerDark,
      scrim: Color.lerp(scrim, other.scrim, t) ?? scrim,
      primaryGradient:
          LinearGradient.lerp(primaryGradient, other.primaryGradient, t) ??
          primaryGradient,
    );
  }
}

final class AppTheme {
  const AppTheme._();

  static const ThemeMode defaultThemeMode = ThemeMode.dark;

  static const LinearGradient _primaryGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[_indigo, _indigoDark],
  );

  static const AppThemeTokens tokens = AppThemeTokens(
    surfacePage: _bgPage,
    surfaceCard: _bgCard,
    surfaceElevated: _bgElevated,
    borderSubtle: _borderSubtle,
    borderStrong: _borderStrong,
    textPrimary: _textPrimary,
    textSecondary: _textSecondary,
    textMuted: _textMuted,
    textTertiary: _textTertiary,
    accent: _amber,
    accentStrong: _amberStrong,
    white: _white,
    success: _green,
    successDark: _greenDark,
    warning: _amber,
    danger: _coral,
    dangerDark: _coralDark,
    scrim: _scrim,
    primaryGradient: _primaryGradient,
  );

  static const AppThemeTokens lightTokens = AppThemeTokens(
    surfacePage: _lBgPage,
    surfaceCard: _lBgCard,
    surfaceElevated: _lBgElevated,
    borderSubtle: _lBorderSubtle,
    borderStrong: _lBorderStrong,
    textPrimary: _lTextPrimary,
    textSecondary: _lTextSecondary,
    textMuted: _lTextMuted,
    textTertiary: _lTextTertiary,
    accent: _lAmber,
    accentStrong: _lAmberStrong,
    white: _white,
    success: _lGreen,
    successDark: _lGreenDark,
    warning: _lWarning,
    danger: _lCoral,
    dangerDark: _lCoralDark,
    scrim: _lScrim,
    primaryGradient: _primaryGradient,
  );

  static final ThemeData dark = _buildTheme(
    brightness: Brightness.dark,
    tokens: tokens,
  );

  static final ThemeData light = _buildTheme(
    brightness: Brightness.light,
    tokens: lightTokens,
  );

  /// Status bar / navigation bar overlay style for the given [ThemeMode].
  static SystemUiOverlayStyle overlayStyleFor(ThemeMode mode) {
    final bool isLight = mode == ThemeMode.light;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isLight ? Brightness.dark : Brightness.light,
      statusBarBrightness: isLight ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: isLight ? _lBgPage : _bgPage,
      systemNavigationBarIconBrightness: isLight
          ? Brightness.dark
          : Brightness.light,
    );
  }

  static ThemeData _buildTheme({
    required Brightness brightness,
    required AppThemeTokens tokens,
  }) {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: _indigo,
      brightness: brightness,
      primary: _indigo,
      secondary: tokens.success,
      error: _redError,
      surface: tokens.surfaceCard,
      onSurface: tokens.textPrimary,
    );

    final TextTheme textTheme = _buildTextTheme(
      ThemeData(brightness: brightness),
      tokens.textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: tokens.surfacePage,
      canvasColor: tokens.surfacePage,
      cardColor: tokens.surfaceCard,
      dividerColor: tokens.borderSubtle,
      disabledColor: tokens.textTertiary,
      splashFactory: NoSplash.splashFactory,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      iconTheme: IconThemeData(color: tokens.textPrimary),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: tokens.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
          color: tokens.textPrimary,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: tokens.surfaceElevated,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: tokens.textPrimary,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: tokens.borderSubtle),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.surfaceCard,
        hintStyle: textTheme.bodyLarge?.copyWith(color: tokens.textTertiary),
        labelStyle: textTheme.bodyMedium?.copyWith(color: tokens.textSecondary),
        floatingLabelStyle: textTheme.bodyMedium?.copyWith(
          color: tokens.textPrimary,
        ),
        prefixIconColor: tokens.textTertiary,
        suffixIconColor: tokens.textTertiary,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: _inputBorder(tokens.borderSubtle),
        enabledBorder: _inputBorder(tokens.borderSubtle),
        focusedBorder: _inputBorder(_indigo),
        errorBorder: _inputBorder(_redError),
        focusedErrorBorder: _inputBorder(_redError),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _indigo,
          foregroundColor: _white,
          disabledBackgroundColor: tokens.borderSubtle,
          disabledForegroundColor: tokens.textSecondary,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: tokens.textPrimary,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          side: BorderSide(color: tokens.borderSubtle),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: tokens.textSecondary,
          textStyle: textTheme.labelMedium,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: _indigo.withValues(alpha: 0.09),
        disabledColor: tokens.borderSubtle,
        selectedColor: _indigo.withValues(alpha: 0.09),
        secondarySelectedColor: _indigo.withValues(alpha: 0.09),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        labelStyle: textTheme.labelSmall?.copyWith(color: tokens.textPrimary),
        secondaryLabelStyle: textTheme.labelSmall?.copyWith(
          color: tokens.textPrimary,
        ),
        brightness: brightness,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      cardTheme: CardThemeData(
        color: tokens.surfaceCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: tokens.borderSubtle),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: tokens.surfaceElevated,
        selectedItemColor: tokens.textPrimary,
        unselectedItemColor: tokens.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      extensions: <ThemeExtension<dynamic>>[tokens],
    );
  }

  static TextTheme _buildTextTheme(ThemeData baseTheme, Color color) {
    final TextTheme base = baseTheme.textTheme.apply(
      bodyColor: color,
      displayColor: color,
    );

    return base.copyWith(
      displayLarge: _serif(base.displayLarge, 56, FontWeight.w600, -1.2, color),
      displayMedium: _serif(
        base.displayMedium,
        48,
        FontWeight.w500,
        -1.0,
        color,
      ),
      displaySmall: _serif(base.displaySmall, 40, FontWeight.w600, -0.8, color),
      headlineLarge: _serif(
        base.headlineLarge,
        36,
        FontWeight.w500,
        -0.8,
        color,
      ),
      headlineMedium: _serif(
        base.headlineMedium,
        32,
        FontWeight.w600,
        -0.6,
        color,
      ),
      headlineSmall: _serif(
        base.headlineSmall,
        28,
        FontWeight.w600,
        -0.4,
        color,
      ),
      titleLarge: _sans(base.titleLarge, 26, FontWeight.w700, -0.3, color),
      titleMedium: _sans(base.titleMedium, 22, FontWeight.w600, -0.2, color),
      titleSmall: _sans(base.titleSmall, 20, FontWeight.w600, 0.0, color),
      bodyLarge: _sans(base.bodyLarge, 22, FontWeight.w400, 0.0, color),
      bodyMedium: _sans(base.bodyMedium, 16, FontWeight.w400, 0.0, color),
      bodySmall: _sans(base.bodySmall, 14, FontWeight.w400, 0.0, color),
      labelLarge: _sans(base.labelLarge, 18, FontWeight.w700, 0.0, color),
      labelMedium: _sans(base.labelMedium, 16, FontWeight.w500, 0.0, color),
      labelSmall: _sans(base.labelSmall, 14, FontWeight.w600, 0.0, color),
    );
  }

  static TextStyle _serif(
    TextStyle? base,
    double size,
    FontWeight weight,
    double letterSpacing,
    Color color,
  ) {
    return (base ?? const TextStyle()).copyWith(
      fontSize: size,
      fontWeight: weight,
      letterSpacing: letterSpacing,
      color: color,
    );
  }

  static TextStyle _sans(
    TextStyle? base,
    double size,
    FontWeight weight,
    double letterSpacing,
    Color color,
  ) {
    return (base ?? const TextStyle()).copyWith(
      fontSize: size,
      fontWeight: weight,
      letterSpacing: letterSpacing,
      color: color,
    );
  }

  static OutlineInputBorder _inputBorder(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color),
    );
  }
}
