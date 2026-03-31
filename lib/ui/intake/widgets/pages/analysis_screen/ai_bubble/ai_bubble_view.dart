import 'package:flutter/material.dart';

import 'package:animus/theme.dart';

class AiBubbleView extends StatelessWidget {
  final String? message;
  final bool isTyping;
  final String? footerText;

  const AiBubbleView({
    this.message,
    required this.isTyping,
    this.footerText,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: tokens.surfaceElevated,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: tokens.borderSubtle),
          ),
          child: Icon(Icons.auto_awesome, color: tokens.accent, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: tokens.surfaceCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: tokens.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (message != null && message!.isNotEmpty)
                  Text(
                    message!,
                    style: textTheme.bodyMedium?.copyWith(
                      color: tokens.textPrimary,
                      height: 1.45,
                    ),
                  ),
                if (isTyping) ...<Widget>[
                  if (message != null && message!.isNotEmpty)
                    const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      _TypingDot(color: tokens.accent),
                      const SizedBox(width: 6),
                      _TypingDot(color: tokens.accent.withValues(alpha: 0.7)),
                      const SizedBox(width: 6),
                      _TypingDot(color: tokens.accent.withValues(alpha: 0.45)),
                    ],
                  ),
                ],
                if (footerText != null && footerText!.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 12),
                  Text(
                    footerText!,
                    style: textTheme.bodySmall?.copyWith(
                      color: tokens.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TypingDot extends StatelessWidget {
  final Color color;

  const _TypingDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
