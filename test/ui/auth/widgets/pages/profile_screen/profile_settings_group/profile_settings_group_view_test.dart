import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:animus/theme.dart';
import 'package:animus/ui/auth/widgets/pages/profile_screen/profile_settings_group/profile_settings_group_view.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );
  }

  ProfileSettingsGroupView buildGroup({
    required bool isDarkThemeEnabled,
    required VoidCallback onThemeTap,
  }) {
    return ProfileSettingsGroupView(
      isDarkThemeEnabled: isDarkThemeEnabled,
      appVersionLabel: 'v1.0.0',
      onEditNameTap: () {},
      onChangePasswordTap: () {},
      onArchivedAnalysesTap: () {},
      onThemeTap: onThemeTap,
    );
  }

  group('ProfileSettingsGroupView theme tile', () {
    testWidgets('renders the theme tile', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrap(buildGroup(isDarkThemeEnabled: true, onThemeTap: () {})),
      );

      expect(find.text('Tema'), findsOneWidget);
    });

    testWidgets('invokes onThemeTap when the theme tile is tapped', (
      WidgetTester tester,
    ) async {
      int taps = 0;

      await tester.pumpWidget(
        wrap(buildGroup(isDarkThemeEnabled: true, onThemeTap: () => taps++)),
      );

      await tester.tap(find.text('Tema'));
      await tester.pump();

      expect(taps, 1);
    });

    testWidgets('builds for the disabled (light) theme state', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrap(buildGroup(isDarkThemeEnabled: false, onThemeTap: () {})),
      );

      expect(find.text('Tema'), findsOneWidget);
    });
  });
}
