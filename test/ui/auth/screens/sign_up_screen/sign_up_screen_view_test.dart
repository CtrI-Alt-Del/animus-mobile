import 'package:flutter_test/flutter_test.dart';
import 'package:animus_mobile/ui/auth/widgets/pages/sign_up_screen/index.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('renderiza campos e botao de cadastro', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SignUpScreen()));

    expect(find.text('Criar conta'), findsOneWidget);
    expect(find.text('Nome completo'), findsOneWidget);
    expect(find.text('E-mail'), findsOneWidget);
    expect(find.text('Senha'), findsOneWidget);
    expect(find.text('Cadastrar'), findsOneWidget);
  });
}
