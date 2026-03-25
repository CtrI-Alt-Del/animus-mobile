import 'package:flutter/material.dart';

import 'package:animus/router.dart';
import 'package:animus/theme.dart';

class AnimusApp extends StatelessWidget {
  const AnimusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Animus',
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: AppTheme.defaultThemeMode,
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
    );
  }
}
