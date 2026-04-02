import 'package:flutter/material.dart';

import 'package:animus/theme.dart';
import 'package:animus/ui/intake/widgets/pages/analysis_screen/dot_grid_background/dot_grid_painter/index.dart';

class DotGridBackgroundView extends StatelessWidget {
  const DotGridBackgroundView({super.key});

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;

    return IgnorePointer(child: DotGridPainter(dotColor: tokens.textTertiary));
  }
}
