import 'package:flutter_test/flutter_test.dart';
import 'package:animus_mobile/ui/auth/widgets/pages/sign_up_screen/sign_up_screen_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  Widget createWidget() {
    return const ProviderScope(
      child: MaterialApp(home: SignUpScreenView()),
    );
  }

  testWidgets('renderiza campos e botao de cadastro', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createWidget());

    expect(find.text('Criar conta'), findsOneWidget);
    expect(find.text('Nome completo'), findsOneWidget);
    expect(find.text('E-mail'), findsOneWidget);
    expect(find.text('Senha'), findsOneWidget);
    expect(find.text('Cadastrar'), findsOneWidget);
  });
}
