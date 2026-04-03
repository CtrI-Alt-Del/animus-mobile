import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';

import 'package:animus/ui/shared/widgets/components/app_bottom_navigation/index.dart';

class AppShellView extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShellView({required this.navigationShell, super.key});

  @override
  Widget build(BuildContext context) {
    final int currentIndex = navigationShell.currentIndex;

    return Scaffold(
      body: TweenAnimationBuilder<double>(
        key: ValueKey<int>(currentIndex),
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
        child: navigationShell,
        builder: (BuildContext context, double value, Widget? child) {
          final double opacity = value.clamp(0.0, 1.0);
          final double slideOffset = (1 - value) * 8;

          return Opacity(
            opacity: opacity,
            child: Transform.translate(
              offset: Offset(slideOffset, 0),
              child: child,
            ),
          );
        },
      ),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: currentIndex,
        onDestinationSelected: (int index) {
          navigationShell.goBranch(index);
        },
      ),
    );
  }
}
