import 'package:flutter/material.dart';

import 'package:animus/theme.dart';

const Color _profilePanelColor = Color(0xFF1E1E24);
const Color _profilePanelBorderColor = Color(0x33FBE26D);
const Color _profileAvatarInnerColor = Color(0xFF2A2A3E);

class ProfileAccountCardView extends StatelessWidget {
  final String initial;
  final String name;
  final String email;

  const ProfileAccountCardView({
    required this.initial,
    required this.name,
    required this.email,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: _profilePanelColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _profilePanelBorderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: <Widget>[
            Container(
              width: 56,
              height: 56,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[tokens.accent, tokens.accentStrong],
                ),
              ),
              child: CircleAvatar(
                backgroundColor: _profileAvatarInnerColor,
                child: Text(
                  initial,
                  style: textTheme.titleLarge?.copyWith(
                    color: tokens.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleSmall?.copyWith(
                      color: tokens.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: tokens.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
