# Prompt: Implementar Spec

**Objetivo:**
Executar o plano de implementação técnica de forma iterativa, organizada e validada, garantindo qualidade e integração contínua.

**Entrada:**
*   Documento de Spec técnica aprovado/finalizado.

**Diretrizes de Execução:**

1.  **Validação de Diretrizes e Arquitetura:**
    Antes de iniciar a implementação, certifique-se de que compreende as diretrizes e a estrutura do projeto:
    *   **Visão macro do projeto:** `documentation\overview.md`
    *   **Arquitetura:** `documentation\architecture.md`
    *   **Padronização de Código:** `documentation\code-conventions-guidelines.md`
    *   **Diretrizes de Camadas:**
        *   **Core:** `documentation\core-layer-rules.md`
        *   **UI:** `documentation\ui-layer-rules.md`
        *   **REST:** `documentation\rest-layer-rules.md`
        *   **Drivers:** `documentation\drivers-layer-rules.md`

2.  **Planejamento e Tarefas:**
    *   Caso já tenha sido realizado o planejamento e a definição de tarefas prévias, leve-as em consideração durante a implementação e ignore os passos 3 e 4.

3.  **Decomposição Atômica:**
    * Divida o plano de implementação em fases e tarefas atômicas.
    * Cada fase deve resultar em um código compilável e funcional isoladamente.

3.  **Ordem de Execução (Bottom-Up):**
    Implemente as tarefas seguindo rigorosamente a hierarquia de dependências:
    1.  **Core:** DTOs e interfaces.
    2.  **Rest:** Implementações de interfaces de serviços Rest.
    2.  **Drivers:** Implementações de interfaces de drivers.
    3.  **State Management:** Stores (Signals), Presenters, Controllers.
    4.  **Interface de Usuário:** Views e Widgets.
    *   **Regra:** Nunca implemente um componente consumidor (ex: Widget) antes de implementar a lógica/dados que ele consome.

4.  **Ciclo de Qualidade e Verificação (Por Tarefa):**
    Ao finalizar a codificação de *cada micro-tarefa*, execute os passos de validação ANTES de passar para a próxima usando o MCP de dart:
    *   **Formatação:** Execute `dart format .`
    *   **Análise Estática:** Execute `flutter analyze`.
    *   **Análise de Testes:** Execute `flutter test`.
    *   **Critério de Aceite:** Corrija imediatamente quaisquer erros ou recomendações do linter, também corrija erros de testes. Não avance com código "sujo".

6.  **Consistência de Padrões:**
    *   **Camada UI:** 
        *   Sempre que criar um widget interno, crie uma pasta dedicada para ele dentro da estrutura do widget pai.
        *   Sempre use o padrão MVP (Model-View-Presenter) para a criação de widgets.
        *   **Importante:** Utilize exclusivamente o `shadcn_flutter` para componentes de interface, evitando o uso de `Material UI`.

