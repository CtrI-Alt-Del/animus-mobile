import 'package:go_router/go_router.dart';

import 'package:animus/constants/routes.dart';
import 'package:animus/ui/auth/widgets/pages/email_confirmation_screen/index.dart';
import 'package:animus/ui/auth/widgets/pages/sign_up_screen/index.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: Routes.signUp,
  routes: <RouteBase>[
    GoRoute(path: Routes.home, redirect: (context, state) => Routes.signUp),
    GoRoute(
      path: Routes.signUp,
      builder: (context, state) => const SignUpScreen(),
    ),
    GoRoute(
      path: Routes.emailConfirmation,
      redirect: (context, state) {
        final String? email = state.uri.queryParameters['email'];
        if (email == null || email.trim().isEmpty) {
          return Routes.signUp;
        }
        return null;
      },
      builder: (context, state) {
        final String email = state.uri.queryParameters['email'] ?? '';
        return EmailConfirmationScreen(email: email);
      },
    ),
  ],
);
