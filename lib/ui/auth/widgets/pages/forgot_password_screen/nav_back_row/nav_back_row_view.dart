import 'package:flutter/material.dart';

import 'package:animus/theme.dart';

class NavBackRowView extends StatelessWidget {
  final String title;
  final VoidCallback onBack;

  const NavBackRowView({required this.title, required this.onBack, super.key});

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        IconButton(
          onPressed: onBack,
          icon: Icon(Icons.arrow_back, color: tokens.textPrimary, size: 20),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
          visualDensity: VisualDensity.compact,
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            title,
            style: textTheme.labelMedium?.copyWith(
              color: tokens.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
