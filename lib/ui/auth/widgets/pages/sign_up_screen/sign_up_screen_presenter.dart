import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SignUpScreenPresenter {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
  }

  String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Informe seu nome.';
    }

    return null;
  }

  String? validateEmail(String? value) {
    final String sanitized = value?.trim() ?? '';

    if (sanitized.isEmpty || !sanitized.contains('@')) {
      return 'Informe um e-mail valido.';
    }

    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.length < 8) {
      return 'A senha precisa ter no minimo 8 caracteres.';
    }

    return null;
  }

  void submit(BuildContext context) {
    final FormState? form = formKey.currentState;

    if (form == null || !form.validate()) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cadastro pronto para integracao com backend.'),
      ),
    );
  }
}

final signUpScreenPresenterProvider =
    Provider.autoDispose<SignUpScreenPresenter>((Ref ref) {
      final SignUpScreenPresenter presenter = SignUpScreenPresenter();
      ref.onDispose(presenter.dispose);
      return presenter;
    });
