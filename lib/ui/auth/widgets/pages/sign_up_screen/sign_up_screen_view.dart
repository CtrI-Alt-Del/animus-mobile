import 'package:flutter/material.dart';

import 'package:animus/theme.dart';
import 'package:animus/ui/auth/widgets/components/auth_header/index.dart';
import 'package:animus/ui/auth/widgets/pages/sign_up_screen/brand_header/index.dart';
import 'package:animus/ui/auth/widgets/pages/sign_up_screen/sign_up_form/index.dart';
import 'package:animus/ui/auth/widgets/pages/sign_up_screen/top_progress_bar/index.dart';

class SignUpScreenView extends StatelessWidget {
  const SignUpScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;

    return Scaffold(
      backgroundColor: tokens.surfacePage,
      body: Column(
        children: <Widget>[
          const TopProgressBar(),
          Expanded(
            child: SafeArea(
              bottom: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 402),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 30, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          const BrandHeader(),
                          const SizedBox(height: 24),
                          const AuthHeader(
                            title: 'Criar Conta',
                            subtitle: 'Preencha seus dados para comecar',
                          ),
                          const SizedBox(height: 24),
                          const SignUpForm(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
