import 'package:animus/theme.dart';
import 'package:flutter/material.dart';

class SectionHeaderView extends StatelessWidget {
  final String label;

  const SectionHeaderView({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Text(
      label,
      style: textTheme.titleSmall?.copyWith(
        color: tokens.accent,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
