import 'package:animus/core/auth/dtos/account_dto.dart';
import 'package:animus/theme.dart';
import 'package:animus/ui/auth/widgets/pages/profile_screen/profile_screen_presenter.dart';
import 'package:animus/ui/auth/widgets/pages/profile_screen/profile_screen_view.dart';
import 'package:animus/ui/shared/widgets/components/app_bottom_navigation/app_bottom_navigation_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:signals_flutter/signals_flutter.dart';

class _MockProfileScreenPresenter extends Mock
    implements ProfileScreenPresenter {}

void main() {
  late _MockProfileScreenPresenter presenter;

  setUp(() {
    presenter = _MockProfileScreenPresenter();
    when(() => presenter.initialize()).thenAnswer((_) async {});
    when(() => presenter.onDestinationSelected(any())).thenReturn(null);
    when(() => presenter.dispose()).thenReturn(null);
    when(() => presenter.isLoadingInitialData).thenReturn(signal<bool>(false));
    when(() => presenter.generalError).thenReturn(signal<String?>(null));
    when(() => presenter.account).thenReturn(signal<AccountDto?>(null));
    when(() => presenter.hasAccount).thenReturn(signal<bool>(true));
    when(() => presenter.displayInitial).thenReturn(signal<String>('A'));
    when(
      () => presenter.displayName,
    ).thenReturn(signal<String>('Ada Lovelace'));
    when(
      () => presenter.displayEmail,
    ).thenReturn(signal<String>('ada@example.com'));
  });

  testWidgets('renderiza loading inicial', (WidgetTester tester) async {
    when(() => presenter.hasAccount).thenReturn(signal<bool>(false));
    when(() => presenter.isLoadingInitialData).thenReturn(signal<bool>(true));

    await tester.pumpWidget(_createWidget(presenter));
    await tester.pump();

    expect(find.text('Perfil'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('renderiza erro inicial com retry', (WidgetTester tester) async {
    when(() => presenter.hasAccount).thenReturn(signal<bool>(false));
    when(
      () => presenter.generalError,
    ).thenReturn(signal<String?>('Falha ao carregar perfil'));

    await tester.pumpWidget(_createWidget(presenter));
    await tester.pump();
    clearInteractions(presenter);

    expect(find.text('Falha ao carregar perfil'), findsOneWidget);
    expect(find.text('Tentar novamente'), findsOneWidget);

    await tester.tap(find.text('Tentar novamente'));
    await tester.pump();

    verify(() => presenter.initialize()).called(1);
  });

  testWidgets('renderiza conteudo principal do perfil', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_createWidget(presenter));
    await tester.pump();

    expect(find.text('Perfil'), findsOneWidget);
    expect(find.text('Ada Lovelace'), findsOneWidget);
    expect(find.text('ada@example.com'), findsOneWidget);
    expect(find.text('Editar Nome'), findsOneWidget);
    expect(find.text('Alterar Senha'), findsOneWidget);
    expect(find.text('Tema'), findsOneWidget);
    expect(find.text('Sobre o App'), findsOneWidget);
    expect(find.text('Deletar Conta'), findsOneWidget);
    expect(find.text('Sair da Conta'), findsOneWidget);
    expect(find.text('HOME'), findsOneWidget);
    expect(find.text('BIBLIOTECA'), findsOneWidget);
    expect(find.text('PERFIL'), findsOneWidget);

    final AppBottomNavigationView bottomNavigation = tester.widget(
      find.byType(AppBottomNavigationView),
    );
    expect(bottomNavigation.currentIndex, 2);
  });
}

Widget _createWidget(_MockProfileScreenPresenter presenter) {
  return ProviderScope(
    overrides: [profileScreenPresenterProvider.overrideWithValue(presenter)],
    child: MaterialApp(theme: AppTheme.dark, home: const ProfileScreenView()),
  );
}
