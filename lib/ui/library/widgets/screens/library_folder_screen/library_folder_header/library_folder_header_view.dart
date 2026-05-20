import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:animus/theme.dart';

class LibraryFolderHeaderView extends StatelessWidget {
  final String title;
  final int analysisCount;
  final VoidCallback onBack;
  final VoidCallback onSettings;

  const LibraryFolderHeaderView({
    required this.title,
    required this.analysisCount,
    required this.onBack,
    required this.onSettings,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Row(
      children: <Widget>[
        IconButton(
          onPressed: onBack,
          tooltip: 'Voltar',
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title.trim().isEmpty ? 'Pasta' : title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.fraunces(
                  textStyle: textTheme.titleLarge?.copyWith(
                    color: tokens.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: tokens.surfaceElevated,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: tokens.borderSubtle),
                ),
                child: Text(
                  '$analysisCount análises',
                  style: textTheme.bodySmall?.copyWith(
                    color: tokens.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: onSettings,
          tooltip: 'Configurar pasta',
          icon: const Icon(Icons.tune_rounded),
        ),
      ],
    );
  }
}
