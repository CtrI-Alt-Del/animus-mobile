import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'sign_up_screen_presenter.dart';

class SignUpScreenView extends ConsumerWidget {
  const SignUpScreenView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SignUpScreenPresenter presenter = ref.watch(signUpScreenPresenterProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Criar conta')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: presenter.formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Cadastro no Animus',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Preencha os dados para criar sua conta.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: presenter.nameController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Nome completo',
                        border: OutlineInputBorder(),
                      ),
                      validator: presenter.validateName,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: presenter.emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'E-mail',
                        border: OutlineInputBorder(),
                      ),
                      validator: presenter.validateEmail,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: presenter.passwordController,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => presenter.submit(context),
                      decoration: const InputDecoration(
                        labelText: 'Senha',
                        border: OutlineInputBorder(),
                      ),
                      validator: presenter.validatePassword,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () => presenter.submit(context),
                      child: const Text('Cadastrar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
