import 'package:animus/theme.dart';
import 'package:flutter/material.dart';

class NewFolderButtonView extends StatelessWidget {
  final VoidCallback onTap;

  const NewFolderButtonView({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: tokens.accent),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.create_new_folder_outlined,
                size: 18,
                color: tokens.accent,
              ),
              const SizedBox(width: 6),
              Text(
                'Nova',
                style: textTheme.labelMedium?.copyWith(
                  color: tokens.accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
