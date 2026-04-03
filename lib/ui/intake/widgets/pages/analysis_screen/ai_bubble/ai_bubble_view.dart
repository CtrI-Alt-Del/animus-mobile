import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:animus/theme.dart';
import 'package:animus/ui/intake/widgets/pages/analysis_screen/ai_bubble/typing_dot/index.dart';

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
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: tokens.surfaceElevated,
                borderRadius: BorderRadius.circular(17),
                border: Border.all(color: tokens.borderSubtle),
              ),
              child: Icon(Icons.auto_awesome, color: tokens.accent, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: tokens.surfaceCard,
                  borderRadius: BorderRadius.circular(14),
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
                          TypingDot(color: tokens.accent, delay: Duration.zero),
                          const SizedBox(width: 6),
                          TypingDot(
                            color: tokens.accent.withValues(alpha: 0.7),
                            delay: const Duration(milliseconds: 140),
                          ),
                          const SizedBox(width: 6),
                          TypingDot(
                            color: tokens.accent.withValues(alpha: 0.45),
                            delay: const Duration(milliseconds: 280),
                          ),
                        ],
                      ),
                    ],
                    if (footerText != null &&
                        footerText!.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 12),
                      Text(
                        footerText!,
                        style: textTheme.bodyMedium?.copyWith(
                          color: tokens.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        )
        .animate()
        .fadeIn(duration: 260.ms)
        .slideY(
          begin: 0.08,
          end: 0,
          duration: 260.ms,
          curve: Curves.easeOutCubic,
        );
  }
}
