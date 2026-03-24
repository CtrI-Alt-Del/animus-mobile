import 'package:shadcn_flutter/shadcn_flutter.dart';

import 'package:animus_mobile/router.dart';
import 'package:animus_mobile/theme.dart';

class AnimusApp extends StatelessWidget {
  const AnimusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ShadcnApp.router(
      title: 'Animus',
      theme: AppTheme.light,
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
    );
  }
}
