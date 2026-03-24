import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

final class AppTheme {
  const AppTheme._();

  static final shadcn.ThemeData light = shadcn.ThemeData(
    typography: const shadcn.Typography.geist(),
    radius: 0.8,
  );
}
