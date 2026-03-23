import 'package:flutter/material.dart';

const Color _amber = Color(0xFFFFB547);
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

@immutable
final class AppThemeTokens extends ThemeExtension<AppThemeTokens> {
  const AppThemeTokens({
    required this.surfacePage,
    required this.surfaceCard,
    required this.surfaceElevated,
    required this.borderSubtle,
    required this.borderStrong,
    required this.textMuted,
    required this.textTertiary,
    required this.success,
    required this.successDark,
    required this.warning,
    required this.danger,
    required this.dangerDark,
    required this.primaryGradient,
  });

  final Color surfacePage;
  final Color surfaceCard;
  final Color surfaceElevated;
  final Color borderSubtle;
  final Color borderStrong;
  final Color textMuted;
  final Color textTertiary;
  final Color success;
  final Color successDark;
  final Color warning;
  final Color danger;
  final Color dangerDark;
  final LinearGradient primaryGradient;

  @override
  AppThemeTokens copyWith({
    Color? surfacePage,
    Color? surfaceCard,
    Color? surfaceElevated,
    Color? borderSubtle,
    Color? borderStrong,
    Color? textMuted,
    Color? textTertiary,
    Color? success,
    Color? successDark,
    Color? warning,
    Color? danger,
    Color? dangerDark,
    LinearGradient? primaryGradient,
  }) {
    return AppThemeTokens(
      surfacePage: surfacePage ?? this.surfacePage,
      surfaceCard: surfaceCard ?? this.surfaceCard,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      borderStrong: borderStrong ?? this.borderStrong,
      textMuted: textMuted ?? this.textMuted,
      textTertiary: textTertiary ?? this.textTertiary,
      success: success ?? this.success,
      successDark: successDark ?? this.successDark,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      dangerDark: dangerDark ?? this.dangerDark,
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
      textMuted: Color.lerp(textMuted, other.textMuted, t) ?? textMuted,
      textTertiary:
          Color.lerp(textTertiary, other.textTertiary, t) ?? textTertiary,
      success: Color.lerp(success, other.success, t) ?? success,
      successDark: Color.lerp(successDark, other.successDark, t) ?? successDark,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      danger: Color.lerp(danger, other.danger, t) ?? danger,
      dangerDark: Color.lerp(dangerDark, other.dangerDark, t) ?? dangerDark,
      primaryGradient:
          LinearGradient.lerp(primaryGradient, other.primaryGradient, t) ??
          primaryGradient,
    );
  }
}

final class AppTheme {
  const AppTheme._();

  static const AppThemeTokens tokens = AppThemeTokens(
    surfacePage: _bgPage,
    surfaceCard: _bgCard,
    surfaceElevated: _bgElevated,
    borderSubtle: _borderSubtle,
    borderStrong: _borderStrong,
    textMuted: _textMuted,
    textTertiary: _textTertiary,
    success: _green,
    successDark: _greenDark,
    warning: _amber,
    danger: _coral,
    dangerDark: _coralDark,
    primaryGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: <Color>[_indigo, _indigoDark],
    ),
  );

  static final ThemeData light = _buildTheme();

  static ThemeData _buildTheme() {
    const ColorScheme colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: _indigo,
      onPrimary: _white,
      secondary: _green,
      onSecondary: _bgPage,
      error: _redError,
      onError: _white,
      surface: _bgCard,
      onSurface: _textPrimary,
    );

    final TextTheme textTheme = _buildTextTheme(
      ThemeData(brightness: Brightness.dark),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _bgPage,
      canvasColor: _bgPage,
      cardColor: _bgCard,
      dividerColor: _borderSubtle,
      disabledColor: _textTertiary,
      splashFactory: NoSplash.splashFactory,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      iconTheme: const IconThemeData(color: _textPrimary),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: _textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Fraunces',
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
          color: _textPrimary,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _bgElevated,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: _textPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: _borderSubtle),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _bgCard,
        hintStyle: textTheme.bodyLarge?.copyWith(color: _textTertiary),
        labelStyle: textTheme.bodyMedium?.copyWith(color: _textSecondary),
        floatingLabelStyle: textTheme.bodyMedium?.copyWith(color: _textPrimary),
        prefixIconColor: _textTertiary,
        suffixIconColor: _textTertiary,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: _inputBorder(),
        enabledBorder: _inputBorder(),
        focusedBorder: _inputBorder(color: _indigo),
        errorBorder: _inputBorder(color: _redError),
        focusedErrorBorder: _inputBorder(color: _redError),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _indigo,
          foregroundColor: _white,
          disabledBackgroundColor: _borderSubtle,
          disabledForegroundColor: _textSecondary,
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
          foregroundColor: _textPrimary,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          side: const BorderSide(color: _borderSubtle),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _textSecondary,
          textStyle: textTheme.labelMedium,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0x186366F1),
        disabledColor: _borderSubtle,
        selectedColor: const Color(0x186366F1),
        secondarySelectedColor: const Color(0x186366F1),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        labelStyle: textTheme.labelSmall?.copyWith(color: _textPrimary),
        secondaryLabelStyle: textTheme.labelSmall?.copyWith(
          color: _textPrimary,
        ),
        brightness: Brightness.dark,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      cardTheme: CardThemeData(
        color: _bgCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: _borderSubtle),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: _bgElevated,
        selectedItemColor: _textPrimary,
        unselectedItemColor: _textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      extensions: const <ThemeExtension<dynamic>>[tokens],
    );
  }

  static TextTheme _buildTextTheme(ThemeData baseTheme) {
    final TextTheme base = baseTheme.textTheme.apply(
      bodyColor: _textPrimary,
      displayColor: _textPrimary,
    );

    return base.copyWith(
      displayLarge: _serif(base.displayLarge, 32, FontWeight.w600, -0.8),
      displayMedium: _serif(base.displayMedium, 28, FontWeight.w500, -0.8),
      displaySmall: _serif(base.displaySmall, 24, FontWeight.w600, -0.5),
      headlineLarge: _serif(base.headlineLarge, 28, FontWeight.w500, -0.8),
      headlineMedium: _serif(base.headlineMedium, 24, FontWeight.w600, -0.5),
      headlineSmall: _serif(base.headlineSmall, 18, FontWeight.w600, -0.3),
      titleLarge: _sans(base.titleLarge, 20, FontWeight.w700, -0.2),
      titleMedium: _sans(base.titleMedium, 18, FontWeight.w600, -0.2),
      titleSmall: _sans(base.titleSmall, 16, FontWeight.w600, 0),
      bodyLarge: _sans(base.bodyLarge, 16, FontWeight.w400, 0),
      bodyMedium: _sans(base.bodyMedium, 12, FontWeight.w400, 0),
      bodySmall: _sans(base.bodySmall, 10, FontWeight.w400, 0),
      labelLarge: _sans(base.labelLarge, 16, FontWeight.w700, 0),
      labelMedium: _sans(base.labelMedium, 12, FontWeight.w500, 0),
      labelSmall: _sans(base.labelSmall, 10, FontWeight.w600, 0),
    );
  }

  static TextStyle _serif(
    TextStyle? base,
    double size,
    FontWeight weight,
    double letterSpacing,
  ) {
    return (base ?? const TextStyle()).copyWith(
      fontFamily: 'Fraunces',
      fontSize: size,
      fontWeight: weight,
      letterSpacing: letterSpacing,
      color: _textPrimary,
    );
  }

  static TextStyle _sans(
    TextStyle? base,
    double size,
    FontWeight weight,
    double letterSpacing,
  ) {
    return (base ?? const TextStyle()).copyWith(
      fontFamily: 'DM Sans',
      fontSize: size,
      fontWeight: weight,
      letterSpacing: letterSpacing,
      color: _textPrimary,
    );
  }

  static OutlineInputBorder _inputBorder({Color color = _borderSubtle}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color),
    );
  }
}
