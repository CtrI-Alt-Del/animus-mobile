import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';

import 'package:animus/ui/shared/widgets/components/app_bottom_navigation/index.dart';

class AppShellView extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShellView({required this.navigationShell, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: navigationShell.currentIndex,
        onDestinationSelected: (int index) {
          navigationShell.goBranch(index);
        },
      ),
    );
  }
}
