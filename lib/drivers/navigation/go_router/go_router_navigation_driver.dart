import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:animus/constants/navigation_keys.dart';
import 'package:animus/core/shared/interfaces/navigation_driver.dart';

class GoRouterNavigationDriver implements NavigationDriver {
  const GoRouterNavigationDriver();

  @override
  bool canGoBack() {
    final GoRouter? router = _router;
    return router?.canPop() ?? false;
  }

  @override
  void goBack() {
    final GoRouter? router = _router;
    if (router == null) {
      return;
    }
    if (router.canPop()) {
      router.pop();
    }
  }

  @override
  void goTo(String route, {Object? data}) {
    final GoRouter? router = _router;
    if (router == null) {
      return;
    }
    router.go(route, extra: data);
  }

  @override
  Future<void> pushTo(String route, {Object? data}) async {
    final GoRouter? router = _router;
    if (router == null) {
      return;
    }
    await router.push(route, extra: data);
  }

  GoRouter? get _router {
    final BuildContext? context = rootNavigatorKey.currentContext;
    if (context == null) {
      return null;
    }
    return GoRouter.of(context);
  }
}

final Provider<NavigationDriver> navigationDriverProvider =
    Provider<NavigationDriver>((Ref ref) {
      return const GoRouterNavigationDriver();
    });
