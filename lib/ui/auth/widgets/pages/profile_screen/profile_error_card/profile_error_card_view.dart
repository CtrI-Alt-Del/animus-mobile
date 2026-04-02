import 'package:flutter/material.dart';

import 'package:animus/theme.dart';
import 'package:animus/ui/auth/widgets/pages/email_confirmation_screen/message_box/index.dart';

const Color _profileErrorSurfaceColor = Color(0xFF1E1E24);
const Color _profileErrorBorderColor = Color(0x33FBE26D);

class ProfileErrorCardView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ProfileErrorCardView({
    required this.message,
    required this.onRetry,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: _profileErrorSurfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _profileErrorBorderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            MessageBox(message: message, color: tokens.danger),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}
