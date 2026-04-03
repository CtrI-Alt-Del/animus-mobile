import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:animus/constants/cache_keys.dart';
import 'package:animus/constants/navigation_keys.dart';
import 'package:animus/constants/routes.dart';
import 'package:animus/ui/auth/widgets/pages/check_email_screen/index.dart';
import 'package:animus/ui/auth/widgets/pages/email_confirmation_screen/index.dart';
import 'package:animus/ui/auth/widgets/pages/forgot_password_screen/index.dart';
import 'package:animus/ui/auth/widgets/pages/new_password_screen/index.dart';
import 'package:animus/ui/auth/widgets/pages/profile_screen/index.dart';
import 'package:animus/ui/auth/widgets/pages/sign_in_screen/index.dart';
import 'package:animus/ui/auth/widgets/pages/sign_up_screen/index.dart';
import 'package:animus/ui/intake/widgets/pages/analysis_screen/index.dart';
import 'package:animus/ui/intake/widgets/pages/home_screen/index.dart';
import 'package:animus/ui/shared/widgets/pages/app_shell/index.dart';
import 'package:animus/ui/storage/widgets/pages/library_screen/index.dart';

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: Routes.home,
  redirect: (context, state) async {
    final String path = state.uri.path;
    const Set<String> publicPaths = <String>{
      Routes.signIn,
      Routes.signUp,
      Routes.emailConfirmation,
      Routes.forgotPassword,
      Routes.checkEmail,
      Routes.newPassword,
    };

    if (publicPaths.contains(path)) {
      return null;
    }

    final bool hasValidSession = await _hasLocalSession();
    if (!hasValidSession) {
      return Routes.signIn;
    }

    return null;
  },
  routes: <RouteBase>[
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppShell(navigationShell: navigationShell);
      },
      branches: <StatefulShellBranch>[
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: Routes.home,
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: Routes.library,
              builder: (context, state) => const LibraryScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: Routes.profile,
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: Routes.signIn,
      builder: (context, state) => const SignInScreen(),
    ),
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
    GoRoute(
      path: Routes.forgotPassword,
      builder: (context, state) {
        final String? errorCode = state.uri.queryParameters['errorCode'];
        final String? previousRoute = state.uri.queryParameters['from'];
        return ForgotPasswordScreen(
          initialErrorCode: errorCode,
          previousRoute: previousRoute,
        );
      },
    ),
    GoRoute(
      path: Routes.checkEmail,
      redirect: (context, state) {
        final String? email = state.uri.queryParameters['email'];
        if (email == null || email.trim().isEmpty) {
          return Routes.forgotPassword;
        }
        return null;
      },
      builder: (context, state) {
        final String email = state.uri.queryParameters['email'] ?? '';
        return CheckEmailScreen(email: email);
      },
    ),
    GoRoute(
      path: Routes.newPassword,
      redirect: (context, state) {
        final String? accountId = state.uri.queryParameters['accountId'];
        if (accountId == null || accountId.trim().isEmpty) {
          return Routes.forgotPassword;
        }
        return null;
      },
      builder: (context, state) {
        final String accountId = state.uri.queryParameters['accountId'] ?? '';
        return NewPasswordScreen(accountId: accountId);
      },
    ),
    GoRoute(
      path: Routes.analysis,
      redirect: (context, state) {
        final String? analysisId = state.pathParameters['analysisId'];
        if (analysisId == null || analysisId.trim().isEmpty) {
          return Routes.home;
        }

        return null;
      },
      builder: (context, state) {
        final String analysisId = state.pathParameters['analysisId'] ?? '';
        return AnalysisScreen(analysisId: analysisId);
      },
    ),
  ],
);

Future<bool> _hasLocalSession() async {
  final SharedPreferences preferences = await SharedPreferences.getInstance();
  final String accessToken =
      (preferences.getString(CacheKeys.accessToken) ?? '').trim();
  final String refreshToken =
      (preferences.getString(CacheKeys.refreshToken) ?? '').trim();

  return accessToken.isNotEmpty && refreshToken.isNotEmpty;
}
