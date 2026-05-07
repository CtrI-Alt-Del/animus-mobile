import 'package:flutter/material.dart';

import 'package:animus/theme.dart';
import 'package:animus/ui/intake/widgets/pages/home_screen/home_background_decorations/radial_glow/index.dart';

class LibraryFolderBackgroundView extends StatelessWidget {
  final AppThemeTokens tokens;

  const LibraryFolderBackgroundView({required this.tokens, super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        RadialGlow(
          size: const Size(236, 220),
          top: -34,
          right: -72,
          color: tokens.accent.withValues(alpha: 0.14),
        ),
        RadialGlow(
          size: const Size(210, 240),
          top: 112,
          left: -88,
          color: tokens.accent.withValues(alpha: 0.08),
        ),
        RadialGlow(
          size: const Size(180, 200),
          right: -44,
          bottom: 120,
          color: tokens.accent.withValues(alpha: 0.06),
        ),
      ],
    );
  }
}
