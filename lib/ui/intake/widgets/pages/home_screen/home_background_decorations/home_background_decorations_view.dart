import 'package:flutter/material.dart';

import 'package:animus/theme.dart';
import 'package:animus/ui/intake/widgets/pages/home_screen/home_background_decorations/radial_glow/index.dart';

class HomeBackgroundDecorationsView extends StatelessWidget {
  final AppThemeTokens tokens;

  const HomeBackgroundDecorationsView({required this.tokens, super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        RadialGlow(
          size: const Size(201, 160),
          top: -6,
          right: -10,
          color: tokens.accent.withValues(alpha: 0.12),
        ),
        RadialGlow(
          size: const Size(236, 304),
          top: 128,
          left: -52,
          color: tokens.accent.withValues(alpha: 0.08),
        ),
        RadialGlow(
          size: const Size(102, 180),
          right: -8,
          bottom: 112,
          color: tokens.accent.withValues(alpha: 0.06),
        ),
      ],
    );
  }
}
