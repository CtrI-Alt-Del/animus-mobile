import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:animus/constants/routes.dart';
import 'package:animus/theme.dart';

class EmailConfirmationScreenView extends ConsumerWidget {
  final String email;

  const EmailConfirmationScreenView({required this.email, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;

    return Scaffold(
      backgroundColor: tokens.surfacePage,
      appBar: AppBar(
        backgroundColor: tokens.surfacePage,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: tokens.textPrimary),
          onPressed: () => context.go(Routes.signIn),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: 24),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: tokens.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.mark_email_unread_outlined,
                  color: tokens.accent,
                  size: 32,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Confirme seu e-mail',
                style: Theme.of(
                  context,
                ).textTheme.headlineMedium?.copyWith(color: tokens.textPrimary),
              ),
              const SizedBox(height: 12),
              RichText(
                text: TextSpan(
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: tokens.textSecondary),
                  children: <InlineSpan>[
                    const TextSpan(
                      text: 'Enviamos um link de confirmação para ',
                    ),
                    TextSpan(
                      text: email,
                      style: TextStyle(
                        color: tokens.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: tokens.surfaceCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: tokens.borderSubtle),
                ),
                child: Row(
                  children: <Widget>[
                    Icon(Icons.info_outline, color: tokens.accent, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Verifique sua caixa de entrada e clique no link para ativar sua conta.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: tokens.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () => context.go(Routes.signIn),
                child: const Text('Voltar para o login'),
              ),
              const Spacer(),
              Center(
                child: TextButton(
                  onPressed: () => context.go(Routes.signIn),
                  child: Text(
                    'Já confirmou? Entrar',
                    style: TextStyle(color: tokens.accent),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
