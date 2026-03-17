import 'package:example/constants/routes.dart';
import 'package:example/ui/auth/widgets/pages/sign_up_screen/index.dart';
import 'package:go_router/go_router.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: Routes.signUp,
  routes: <RouteBase>[
    GoRoute(
      path: Routes.home,
      redirect: (context, state) => Routes.signUp,
    ),
    GoRoute(
      path: Routes.signUp,
      builder: (context, state) => const ExamplePage(
        title: 'Sign Up',
      ),
    ),
  ],
);
