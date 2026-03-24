import 'package:flutter/material.dart';

import 'package:animus_mobile/ui/auth/widgets/pages/sign_up_screen/sign_up_form/index.dart';

class SignUpScreenView extends StatelessWidget {
  const SignUpScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05060B),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            const _TopProgressBar(),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 28,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 402),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Text(
                          'Criar Conta',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Preencha seus dados para comecar',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: const Color(0xFF7F8194)),
                        ),
                        const SizedBox(height: 22),
                        const SignUpForm(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopProgressBar extends StatelessWidget {
  const _TopProgressBar();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 2,
      child: Row(
        children: const <Widget>[
          Expanded(child: ColoredBox(color: Color(0xFF5A5CFF))),
          Expanded(child: ColoredBox(color: Color(0xFF1A1C28))),
        ],
      ),
    );
  }
}
