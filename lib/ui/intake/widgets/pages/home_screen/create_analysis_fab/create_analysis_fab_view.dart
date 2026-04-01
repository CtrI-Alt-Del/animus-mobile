import 'package:flutter/material.dart';

import 'package:animus/theme.dart';

class CreateAnalysisFabView extends StatelessWidget {
  static const double _size = 56;

  final bool isLoading;
  final VoidCallback? onPressed;

  const CreateAnalysisFabView({
    required this.isLoading,
    required this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final VoidCallback? effectiveOnPressed = isLoading ? null : onPressed;

    return Tooltip(
      message: isLoading ? 'Criando analise...' : 'Iniciar nova analise',
      child: SizedBox(
        width: _size,
        height: _size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[tokens.accent, tokens.accentStrong],
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: tokens.accent.withValues(alpha: 0.18),
                blurRadius: 16,
                spreadRadius: 0.5,
                offset: Offset.zero,
              ),
            ],
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: effectiveOnPressed,
              customBorder: const CircleBorder(),
              child: Center(
                child: isLoading
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.black,
                          ),
                        ),
                      )
                    : const Icon(Icons.add, color: Colors.black, size: 28),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
