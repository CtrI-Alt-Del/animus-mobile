import 'package:animus/theme.dart';
import 'package:animus/ui/shared/widgets/components/app_bottom_navigation/app_bottom_navigation_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renderiza labels na ordem HOME BIBLIOTECA PERFIL', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_createWidget());

    expect(find.text('HOME'), findsOneWidget);
    expect(find.text('BIBLIOTECA'), findsOneWidget);
    expect(find.text('PERFIL'), findsOneWidget);

    final double homeX = tester.getTopLeft(find.text('HOME')).dx;
    final double libraryX = tester.getTopLeft(find.text('BIBLIOTECA')).dx;
    final double profileX = tester.getTopLeft(find.text('PERFIL')).dx;

    expect(homeX, lessThan(libraryX));
    expect(libraryX, lessThan(profileX));
  });

  testWidgets('dispara callback com indices corretos', (
    WidgetTester tester,
  ) async {
    final List<int> tappedIndices = <int>[];

    await tester.pumpWidget(
      _createWidget(onDestinationSelected: tappedIndices.add),
    );

    await tester.tap(find.text('HOME'));
    await tester.pump();
    await tester.tap(find.text('BIBLIOTECA'));
    await tester.pump();
    await tester.tap(find.text('PERFIL'));
    await tester.pump();

    expect(tappedIndices, <int>[0, 1, 2]);
  });

  testWidgets('usa icone preenchido no destino ativo', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_createWidget(currentIndex: 2));

    expect(find.byIcon(Icons.home_outlined), findsOneWidget);
    expect(find.byIcon(Icons.folder_outlined), findsOneWidget);
    expect(find.byIcon(Icons.person), findsOneWidget);
    expect(find.byIcon(Icons.person_outline), findsNothing);
  });
}

Widget _createWidget({
  int currentIndex = 0,
  ValueChanged<int>? onDestinationSelected,
}) {
  return MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(
      bottomNavigationBar: AppBottomNavigationView(
        currentIndex: currentIndex,
        onDestinationSelected: onDestinationSelected ?? (_) {},
      ),
    ),
  );
}
