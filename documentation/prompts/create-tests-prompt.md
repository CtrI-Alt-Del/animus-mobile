# Prompt: Criar Testes

**Objetivo:**
Orientar a criação de testes unitários e de widget padronizados e eficientes, garantindo a integridade da lógica nos Presenters e a fidelidade visual e funcional dos Widgets.

**Entrada:**
*   **Código Fonte:** Arquivo do `Widget` (View) e seu respectivo `Presenter`.

---

## Diretrizes de Execução

### 1. Adesão às Normas do Projeto
*   **Obrigatório:** Siga rigorosamente as diretrizes em `documentation\rules\unit-tests-rules.md`.
*   **Contexto de UI:** Ao testar Widgets, aplique as boas práticas descritas em `documentation/rules/ui-layer-rules.md`.
*   **Subagentes:** Caso mais de um widget ou presenter seja fornecido, delegue a criação dos testes para o subagente passando a comanda e o caminho das rules de `documentation\rules\unit-tests-rules.md`.

### 2. Estrutura e Nomenclatura
*   **Organização:** Crie os testes no diretório `test/` espelhando a estrutura original em `lib/`.
*   **Padrão de Nomes:**
    *   **Views:** `nome_view_test.dart`
    *   **Presenters:** `nome_presenter_test.dart`
    *   *Exemplo:* `lib/ui/home/home_view.dart` ➡️ `test/ui/home/home_view_test.dart`.

### 3. Preparação de Dados (Fakers)
*   **Uso de Fakers:** Utilize classes `Faker` para instanciar DTOs e modelos. Isso garante dados consistentes e facilita a manutenção.
*   **Ação Pró-ativa:** Se o `Faker` para um DTO específico não existir, **crie-o primeiro** em `test/fakers/<modulo>/`.
*   **Localização:** Mantenha os fakers organizados na estrutura de pastas correspondente em `test/fakers/`.

### 4. Estratégia de Teste (Bottom-Up)
*   **Hierarquia de Widgets:** Ao testar um widget que compõe outros sub-widgets, siga a ordem **do mais interno para o mais externo**.
*   **Isolamento:** Garanta que os componentes menores estejam validados antes de testar a integração no componente pai.

### 5. Escopo e Cobertura
*   **Dualidade Widget/Presenter:** Se um componente visual for fornecido, é obrigatório criar testes tanto para a **View** (interações e renderização) quanto para o **Presenter** (lógica de estado).
*   **Componentes Complexos:** Sub-componentes complexos devem possuir seus próprios arquivos de teste dedicados.

### 6. Qualidade e Clean Code
*   **Código Autoexplicativo:** O código de teste deve ser legível por si só. **Não inclua comentários** desnecessários; utilize nomes de testes descritivos.
*   **Mocks:** Utilize `mocktail` para a criação de dublês de teste, seguindo o padrão do projeto.

### 7. Execução de testes

* **Obrigatório:** com `flutter test` execute os testes que foram acabados de criar, verifique se todos passaram. No final de tudo execute todos os testes do projeto para garantir que não houve regressão em nenhum teste.

---

## Workflow Sugerido

1.  **Setup:** Crie o arquivo de teste em `test/` espelhando a estrutura original em `lib/` (ex: `lib/ui/home/home_view.dart` -> `test/ui/home/home_view_test.dart`).
2.  **Mocking:** Configure as dependências necessárias utilizando `mocktail`.
3.  **Implementação:** Escreva os casos de teste cobrindo:
    *   Fluxos de sucesso (Happy Path).
    *   Tratamento de erros e exceções.
    *   Estados de carregamento (Loading) e vazio (Empty), se aplicável.
4.  **Validação:** Execute os testes com `flutter test` para validar a implementação e garantir que não houve regressões.
