# Diretrizes para Testes Unitários e de Widget

Este documento descreve as práticas, padrões e convenções adotadas para testes automatizados no projeto, baseando-se na análise dos testes existentes (ex: `products-list`).

## 1. Tecnologias e Dependências

As principais bibliotecas utilizadas para testes são:

*   **flutter_test**: Framework padrão de testes do Flutter.
*   **mocktail**: Para criação de mocks estritos, stubs e verificações.
*   **flutter_riverpod**: Para injeção de dependência e controle de estado nos testes.
*   **signals_flutter**: Para gerenciamento de estado reativo (testar valores de `Signal`).
*   **network_image_mock**: Para lidar com `Image.network` em testes de widget sem fazer requisições reais.
*   **shadcn_flutter**: Biblioteca de UI utilizada (os testes devem envolver componentes com `ShadcnApp` se necessário).

## 2. Convenções de Nomenclatura

*   **Arquivos de Teste**: Devem terminar com `_test.dart` e estar espelhados na pasta `test/` seguindo a mesma estrutura de diretórios de `lib/`.
    *   Exemplo: `lib/.../product_list_view.dart` -> `test/.../product_list_view_test.dart`.
*   **Classes de Mock**: Devem ser prefixadas com `Mock` e estender `Mock` (do mocktail) e implementar a classe/interface original.
    *   Exemplo: `class MockProductsListPresenter extends Mock implements ProductsListPresenter {}`.
*   **Descrições de Teste**: Devem seguir o padrão "should [comportamento esperado] when [cenário/contexto]" (em inglês) ou descrever claramente o comportamento.
    *   Exemplo: `'should show skeletons when initial loading'`.

## 3. Estrutura dos Testes

### 3.1. Configuração (Setup)

*   Utilize o `setUp` para instanciar mocks e definir comportamentos padrão (stubs) que se repetem entre os testes.
*   Declaração de variáveis no escopo do `main` ou `group` e inicialização no `setUp`.

```dart
late MockProductsListPresenter presenter;

setUp(() {
  presenter = MockProductsListPresenter();
  // Configuração padrão de signals e métodos
  when(() => presenter.isLoading).thenReturn(signal(false));
  when(() => presenter.products).thenReturn(signal([]));
  // ...
});
```

### 3.2. Agrupamento

*   Utilize `group('NomeDaClasse/Funcionalidade', () { ... })` para organizar testes relacionados, especialmente em testes unitários de lógica (Presenters/Controllers).

## 4. Testes de Widget

### 4.1. Setup do Widget

*   Crie uma função auxiliar `createWidget` (ou similar) para encapsular a configuração do ambiente do widget (Providers, Theme, App Wrapper).
*   Use `ProviderScope` para sobrescrever providers reais por mocks.

```dart
Widget createWidget() {
  return ShadcnApp(
    home: ProviderScope(
      overrides: [
        presenterProvider.overrideWithValue(presenter) // Injeção do Mock
      ],
      child: const ProductListView(),
    ),
  );
}
```

### 4.2. Mocks de Imagens de Rede

*   Sempre envolva o `pumpWidget` com `mockNetworkImagesFor` se o widget ou seus filhos renderizarem imagens da internet.

```dart
await mockNetworkImagesFor(() async {
  await tester.pumpWidget(createWidget());
});
```

### 4.3. Asserções e Interações

*   Verifique a presença de widgets por tipo (`find.byType`) ou texto (`find.text`).
*   Verifique a ausência de widgets (`findsNothing`) para garantir que estados incorretos não estão visíveis.
*   Simule interações do usuário:
    *   **Tap**: `await tester.tap(...)`
    *   **Scroll**: `await tester.drag(...)`
    *   **Pull to Refresh**: `await tester.fling(...)` e aguarde a animação (`pump`).
*   Verifique se métodos do Presenter/Controller foram chamados usando `verify`.

## 5. Testes Unitários (Presenters/Logic)

### 5.1. Testando Signals e Estado

*   Ao testar classes que usam `Signals`, verifique o valor atual do sinal (`.value`).
*   Use `when(...).thenReturn(signal(valor))` para stubs de propriedades do tipo Signal.
*   Para métodos assíncronos que não retornam valor (void), use `.thenAnswer((_) async {})`.

### 5.2. Testando Inicialização Assíncrona

*   Se a lógica de inicialização é executada no construtor ou logo após a instância, pode ser necessário aguardar um ciclo de evento (`Future.delayed(Duration.zero)`) para que as promessas se resolvam antes de fazer asserções.

```dart
final presenter = ProductsListPresenter(service);
// Aguarda execução inicial
await Future.delayed(Duration.zero); 
expect(presenter.products.value, isNotEmpty);
```

### 5.3. Fakers

*   Utilize classes `Faker` (como `ProductFaker`) para gerar dados de teste (DTOs), evitando a criação manual de objetos complexos e tornando os testes mais limpos.

### 5.4. Verificação de Comportamento

*   Utilize `verify(() => mock.metodo()).called(n)` para garantir que dependências (serviços, repositórios) foram chamadas corretamente.
*   Utilize `verifyNever(() => mock.metodo())` para garantir que fluxos incorretos não foram acionados.
