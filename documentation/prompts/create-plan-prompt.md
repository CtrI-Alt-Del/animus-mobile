---
description: Criar um plano de implementação a partir de um documento de spec técnica, alinhado à arquitetura e regras do Animus Mobile, com ênfase em maximizar a paralelização do trabalho entre desenvolvedores.
---

# Prompt: Criar Plano

**Objetivo principal:** Criar um plano de implementação a partir de um documento de spec técnica, alinhado à arquitetura e regras do Animus Mobile, **decompondo o trabalho de forma que o maior número de tarefas possível seja executado em paralelo por desenvolvedores distintos.**

## Contexto do projeto

- **Stack**: Flutter / Dart.
- **Arquitetura**: Clean Architecture + Ports and Adapters, com MVP na camada de UI.
- **Camadas**: UI (`lib/ui/`), Core (`lib/core/`), Rest (`lib/rest/`), Drivers (`lib/drivers/`), Constants (`lib/constants/`).
- **DI**: Riverpod para composição de dependências.
- **Estado local reativo**: Signals em presenters da UI.
- **Navegação**: `go_router`.

## Entrada

- Caminho do arquivo do documento de spec técnica (Markdown).

> ⚠️ **Regra crítica:** Não leia desnecessariamente os arquivos referenciados *dentro* da spec (ex.: arquivos de código da codebase mencionados nas seções "O que já existe?" ou "O que deve ser criado?"). A spec já foi validada — confie nos contratos e artefatos descritos nela. Leitura de código existente só é permitida quando um artefato for ambíguo ou ausente na spec.

---

## Diretrizes de execução

### 1. Leitura obrigatória antes de planejar

**1.1 Leitura da spec e das regras**

- Leia a spec técnica na íntegra antes de qualquer decomposição.
- Leia o índice de regras em `documentation/rules/rules.md`.
- Identifique quais regras por camada são relevantes e leia-as:
  - `documentation/rules/ui-layer-rules.md`
  - `documentation/rules/core-layer-rules.md`
  - `documentation/rules/rest-layer-rules.md`
  - `documentation/rules/drivers-layer-rules.md`
  - `documentation/rules/code-conventions-rules.md`

**1.2 Mapeamento superficial da codebase (quando necessário)**

Use **Serena** para identificar, sem leitura profunda:

- Se os principais artefatos citados na spec (DTOs, contratos, presenters, services, drivers, widgets, rotas) **já existem** ou precisam ser **criados do zero** — isso impacta o planejamento de dependências.
- Se algum arquivo existente precisará ser **modificado** (não apenas consumido).

> O objetivo é mapear o que existe, não ler implementações. Leitura profunda de código é responsabilidade do `implement-plan`.

---

### 2. Análise de dependências (faça isso antes de escrever qualquer tarefa)

Antes de listar fases e tarefas, responda explicitamente:

1. **Quais artefatos do `core` são pré-requisito para `rest`, `drivers` e `ui`?**
   - DTOs, interfaces, respostas tipadas, enums, erros de domínio e contratos que precisam existir antes de outras camadas avançarem.
2. **Quais partes de `rest` e `drivers` são independentes entre si?**
   - Services HTTP, mappers e adaptadores de plataforma que não compartilham contrato e podem ser desenvolvidos em paralelo.
3. **Quais presenters/widgets/screens da camada `ui` podem ser construídos em paralelo?**
   - Fluxos de tela que consomem contratos distintos do `core` e não dependem uns dos outros.
4. **Existe alguma tarefa de UI que pode ser iniciada com stub/fake do contrato do `core`, sem aguardar a implementação real de `rest` ou `drivers`?**
   - Se sim, marque-a como paralelizável com as fases de infraestrutura.
5. **Existe impacto em navegação, rotas, estado compartilhado, cache local ou integrações de plataforma?**
   - Indique se isso bloqueia outras tarefas ou se pode ser preparado em paralelo.

> Essa análise é o insumo principal para o Mapa de Paralelização. Não pule esta etapa.

---

### 3. Decomposição atômica

- Quebre o trabalho em **fases** e **tarefas**.
- Cada **fase** representa uma etapa macro de entrega.
- Cada **tarefa** é uma unidade de trabalho executável por **um único desenvolvedor**, com resultado observável e verificável.
- **Prefira tarefas pequenas:** uma tarefa nunca deve bloquear outra desnecessariamente. Se for possível separar sem perda de coesão, separe.
- **Não inclua tarefas de teste, validação manual ou cobertura automatizada no plano.** Se houver riscos de validação, registre-os apenas em **Pendências**.

---

### 4. Mapa de Paralelização (obrigatório)

Este é o artefato central do plano. Deve responder: **o que pode rodar ao mesmo tempo e o que genuinamente bloqueia quem.**

| Fase | Objetivo | Depende de | Pode rodar em paralelo com |
|------|----------|------------|----------------------------|
| F1   | \<definir\> | -        | -                          |
| F2   | \<definir\> | F1       | F3                         |
| F3   | \<definir\> | F1       | F2                         |
| F4   | \<definir\> | F2, F3   | -                          |

**Regras do mapa:**

- Uma fase só pode depender de outra se há um artefato concreto (interface, DTO, contrato) que precisa existir antes.
- Se duas fases consomem contratos distintos do `core`, elas **devem** ser marcadas como paralelizáveis.
- Se uma fase puder ser iniciada com um stub/mock enquanto a implementação real não está pronta, indique isso explicitamente com a nota `(pode iniciar com stub de <artefato>)`.

---

### 5. Ordem de execução bottom-up (dentro de cada fase)

Ao detalhar as tarefas de uma fase, siga a hierarquia de dependências arquiteturais:

1. **Core (`lib/core/`)**: DTOs, contratos, respostas tipadas, enums e erros de domínio — estes são os contratos que desbloqueiam as demais camadas.
2. **Rest (`lib/rest/`)**: Services HTTP, clients, requests, responses e mappers — implementam contratos do `core` para integração com a API.
3. **Drivers (`lib/drivers/`)**: Adaptadores de plataforma e infraestrutura local (cache, auth social, deep links, package info, navegação, links externos etc.) — implementam contratos do `core` ou suportam a `ui` via fronteiras explícitas.
4. **UI (`lib/ui/`)**: Presenters, screens, widgets e componentes — consomem contratos do `core` e dependências providas por `rest` e `drivers`; podem avançar com stubs/fakes quando os contratos já estiverem definidos.
5. **Constants (`lib/constants/`)**: rotas, chaves, envs e valores semânticos compartilhados — podem ser criadas cedo quando forem pré-requisito de outras camadas.
6. **Router/App wiring (`lib/router.dart`, `lib/app.dart`, `lib/main.dart`)**: registro de rotas, composição final e bootstrap — devem acontecer após os fluxos principais estarem estáveis.

> `rest` e `drivers` são **independentes entre si** e podem rodar em paralelo após o `core` estar estável. A `ui` pode iniciar com stubs/fakes quando os contratos do `core` já estiverem claros.

---

### 6. Dependências explícitas por tarefa

Para cada tarefa, indique claramente:

- **Depende de:** qual tarefa ou artefato precisa existir antes (ex.: `Contrato IntakeService` da Fase 1).
- **Desbloqueia:** quais tarefas ficam liberadas após sua conclusão.

Exemplo:
```
- [ ] Criar contrato `IntakeService` em `lib/core/intake/services/intake_service.dart`
  - Depende de: —
  - Desbloqueia: "Implementar IntakeRestService" (F2-T1) e "Criar AnalysisScreenPresenter" (F3-T1)
```

---

### 7. Identificação de gargalos

Após montar o mapa, identifique explicitamente os **gargalos do plano**: tarefas ou fases que bloqueiam múltiplos outros fluxos e que, portanto, devem ser priorizadas e finalizadas o mais cedo possível.

```
## ⚠️ Gargalos identificados

- **[Nome da tarefa/fase]**: bloqueia X tarefas; deve ser a primeira a ser iniciada.
```

---

### 8. Formato da saída (obrigatório)

> ⚠️ **Regra crítica:** Não salve o plano em um arquivo `plan.md`. Responda diretamente no chat, seguindo a estrutura abaixo.

O plano deve seguir **exatamente** esta estrutura:

```markdown
---
title: Plano de Implementação — <Nome da Feature>
spec: [link relativo para a spec]
created_at: <data yyyy-mm-dd>
status: open
---

---

## Análise de Dependências

### Artefatos do `core` que desbloqueiam outras camadas
- <lista>

### Partes de `rest` e `drivers` independentes entre si
- <lista>

### Presenters/widgets/screens paralelizáveis
- <lista>

### Tarefas iniciáveis com stub
- <lista> (ou "Nenhuma")

---

## ⚠️ Gargalos identificados

- **<Fase/Tarefa>**: bloqueia <N> tarefas; deve ser iniciada primeiro.

---

## Mapa de Paralelização

| Fase | Objetivo | Depende de | Pode rodar em paralelo com |
|------|----------|------------|----------------------------|
| F1   | <definir> | -         | -                          |
| F2   | <definir> | F1        | F3                         |

---

## Fases e Tarefas

### F1 — <Objetivo da fase>

- [ ] **F1-T1** — <Descrição da tarefa>
  - Camada: `core`
  - Artefato: `lib/core/<contexto>/<arquivo>.dart`
  - Depende de: —
  - Desbloqueia: F2-T1, F3-T1

- [ ] **F1-T2** — <Descrição da tarefa>
  - Camada: `core`
  - Artefato: `lib/core/<contexto>/<arquivo>.dart`
  - Depende de: F1-T1
  - Desbloqueia: F2-T2

### F2 — <Objetivo da fase>

- [ ] **F2-T1** — <Descrição da tarefa>
  - Camada: `rest` | `drivers` | `ui`
  - Artefato: `lib/<camada>/<contexto>/<arquivo>.dart`
  - Depende de: F1-T1
  - Desbloqueia: F4-T1

---

## Pendências

- <Descrição da pendência, impacto e ação sugerida> (ou "Nenhuma")
```

---

## Saída esperada

1. **Análise de dependências** (Seção 2) respondida explicitamente.
2. **Mapa de Paralelização** com todas as fases preenchidas.
3. **Lista de gargalos** identificados.
4. **Lista de fases** com objetivo claro.
5. **Lista de tarefas por fase** com dependências explícitas, o que cada tarefa desbloqueia e checklist de progresso.

---

## Regras adicionais para o Animus Mobile

- Prefira fases orientadas a **contratos do `core`**, depois **adaptadores (`rest`/`drivers`)**, depois **presenters/widgets/screens**.
- Ao planejar UI, trate **Presenter** e **View** como artefatos distintos quando isso permitir paralelização real.
- Não inclua tarefas de teste no plano, nem para `ui` nem para qualquer outra camada. Se houver risco em `core`, `rest`, `drivers` ou `ui`, registre em **Pendências** ou **Riscos**, sem criar tarefa de teste.
- Quando houver integração com API, explicite separadamente tarefas de:
  - contrato no `core`
  - implementação no `rest`
  - consumo na `ui`
- Quando houver integração de plataforma, explicite separadamente tarefas de:
  - contrato no `core` (se aplicável)
  - implementação no `drivers`
  - consumo na `ui`
- Se a spec envolver navegação, inclua tarefas específicas para `go_router` e para o ponto de entrada afetado (`lib/router.dart`, `lib/app.dart` ou `lib/main.dart`).
- Se a spec envolver estado compartilhado, identifique se a composição deve ocorrer com Riverpod, Signals ou ambos.
