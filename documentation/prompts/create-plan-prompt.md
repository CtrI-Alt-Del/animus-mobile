# Prompt: Criar Plano (Equiny Mobile)

**Objetivo principal** Criar um plano de implementacao a partir de um documento de spec técnica, alinhado a arquitetura e regras do Equiny Mobile.

## Contexto do projeto

- **Stack**: Flutter/Dart.
- **Arquitetura**: camadas inspiradas em Clean Architecture com MVP na UI.
- **Camadas**: Core (`lib/core`), Rest (`lib/rest`), Drivers (`lib/drivers`), UI (`lib/ui`).
- **DI/Estado**: Riverpod + Signals.

## Entrada

- Caminho do arquivo do documento de spec técnica (Markdown).

## Diretrizes de execucao

1. **Entendimento dos padrões do projeto**
   - Leia as regras de projeto que estão relacionadas com a spec técnica em `documentation/rules/rules.md`.

1. **Decomposicao atomica**
   - Quebre o trabalho em **fases** e **tarefas**.
   - Cada **fase** deve representar uma etapa macro do plano.
   - Cada **tarefa** deve ser uma unidade de trabalho executavel, com resultado observavel.

2. **Mapa de dependencias (obrigatorio)**
   - Inclua uma tabela com as fases, suas dependencias e o que pode rodar em paralelo.

   | Fase | Objetivo | Depende de | Pode rodar em paralelo com |
   | --- | --- | --- | --- |
   | F1 | <definir> | - | - |
   | F2 | <definir> | F1 | - |

3. **Ordem de execucao (bottom-up)**
   - Defina as tarefas seguindo rigorosamente a hierarquia de dependencias, nesta ordem:
     1. **Core (`lib/core`)**: `DTOs`, Entidades, Interfaces e Tipos de resposta.
     2. **Rest (`lib/rest`)**: RestClient, Services, Mappers e Adapters (ex.: Dio).
     3. **Drivers (`lib/drivers`)**: infra externa e configuracoes (ex.: env, storage).
     4. **UI (`lib/ui`)**: Presenters (MVP), Widgets e Telas.

4. **Dependencias explicitas**
   - Se uma tarefa exige outra (ex.: Presenter depende de Interface/Core), a tarefa dependente deve aparecer depois e referenciar explicitamente a dependencia.

5. **Tracking de progresso**
   - Adicione um checklist para cada tarefa para facilitar o tracking do progresso da implementação.


## Saida esperada

- Uma lista de fases (com objetivo).
- Uma lista de tarefas por fase, com dependencias explicitas.
- A tabela de dependencias das fases.
