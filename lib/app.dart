import 'package:animus_mobile/router.dart';
import 'package:animus_mobile/theme.dart';
import 'package:flutter/material.dart';

class AnimusApp extends StatelessWidget {
  const AnimusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Animus',
      theme: AppTheme.dark,
      routerConfig: appRouter,
    );
  }
}
