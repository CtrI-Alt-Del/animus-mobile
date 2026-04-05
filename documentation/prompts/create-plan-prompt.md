---
description: Criar um plano de implementação a partir de um documento de spec técnica, alinhado à arquitetura e regras do Animus Mobile, com ênfase em maximizar a paralelização do trabalho entre desenvolvedores.
---

# Prompt: Criar Plano

**Objetivo principal:** Criar um plano de implementação a partir de um documento de spec técnica, alinhado à arquitetura e regras do Animus Mobile, **decompondo o trabalho de forma que o maior número de tarefas possível seja executado em paralelo por desenvolvedores distintos.**

## Contexto do projeto

- **Stack**: Flutter/Dart.
- **Arquitetura**: camadas inspiradas em Clean Architecture com MVP na UI.
- **Camadas**: Core (`lib/core`), Rest (`lib/rest`), Drivers (`lib/drivers`), UI (`lib/ui`).
- **DI/Estado**: Riverpod + Signals.

## Entrada

- Caminho do arquivo do documento de spec técnica (Markdown).

---

## Diretrizes de execução

### 1. Leitura obrigatória antes de planejar

**1.1 Leitura da spec e das regras**

- Leia a spec técnica na íntegra antes de qualquer decomposição.
- Leia o índice de regras em `documentation/rules/rules.md`.
- Identifique quais regras por camada são relevantes e leia-as:
  - `documentation/rules/core-layer-rules.md`
  - `documentation/rules/rest-layer-rules.md`
  - `documentation/rules/drivers-layer-rules.md`
  - `documentation/rules/ui-layer-rules.md`
  - `documentation/rules/code-conventions-rules.md`

**1.2 Mapeamento superficial da codebase**

Use **Serena** para identificar, sem leitura profunda:

- Se os principais artefatos citados na spec (interfaces, DTOs, telas) **já existem** ou precisam ser **criados do zero** — isso impacta o planejamento de dependências.
- Se algum arquivo existente precisará ser **modificado** (não apenas consumido).

> O objetivo é mapear o que existe, não ler implementações. Leitura profunda de código é responsabilidade do `implement-plan`.

---

### 2. Análise de dependências (faça isso antes de escrever qualquer tarefa)

Antes de listar fases e tarefas, responda explicitamente:

1. **Quais artefatos do `core` são pré-requisito para `rest`, `drivers` e `ui`?**
   - DTOs, interfaces e tipos de resposta que precisam existir antes de qualquer outra camada avançar.
2. **Quais partes da `rest` e `drivers` são independentes entre si?**
   - Services, mappers e adaptadores que não compartilham contrato e podem ser desenvolvidos em paralelo.
3. **Quais widgets/telas da `ui` podem ser construídos em paralelo?**
   - Telas que consomem contratos distintos do `core` e não dependem umas das outras.
4. **Existe alguma tarefa de `ui` que pode ser iniciada com um mock/stub do contrato, sem aguardar a implementação real da `rest`?**
   - Se sim, marque-a como paralelizável com a fase de `rest`.

> Essa análise é o insumo principal para o Mapa de Paralelização. Não pule esta etapa.

---

### 3. Decomposição atômica

- Quebre o trabalho em **fases** e **tarefas**.
- Cada **fase** representa uma etapa macro de entrega.
- Cada **tarefa** é uma unidade de trabalho executável por **um único desenvolvedor**, com resultado observável e verificável.
- **Prefira tarefas pequenas:** uma tarefa nunca deve bloquear outra desnecessariamente. Se for possível separar sem perda de coesão, separe.

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

1. **Core (`lib/core`)**: DTOs, Entidades, Interfaces e tipos de resposta — estes são os contratos que desbloqueiam todas as outras camadas.
2. **Rest (`lib/rest`)**: Services, Mappers e RestClient — implementam os contratos do `core`.
3. **Drivers (`lib/drivers`)**: adaptadores de infraestrutura (env, storage, navegação) — implementam contratos do `core`, independentes da `rest`.
4. **UI (`lib/ui`)**: Presenters (MVP), Widgets e Telas — consomem contratos do `core`; podem ser iniciados com stub se a `rest` ainda não estiver pronta.

> `rest` e `drivers` são **independentes entre si** e podem sempre rodar em paralelo após o `core` estar estável.

---

### 6. Dependências explícitas por tarefa

Para cada tarefa, indique claramente:

- **Depende de:** qual tarefa ou artefato precisa existir antes (ex: `Interface IAuthService` da Fase 1).
- **Desbloqueia:** quais tarefas ficam liberadas após sua conclusão.

Exemplo:
```
- [ ] Criar interface `IAuthService` em `lib/core/auth/interfaces/`
  - Depende de: —
  - Desbloqueia: "Implementar AuthRestService" (F2) e "Criar AuthPresenter" (F3)
```

---

### 7. Identificação de gargalos

Após montar o mapa, identifique explicitamente os **gargalos do plano**: tarefas ou fases que bloqueiam múltiplos outros fluxos e que, portanto, devem ser priorizadas e finalizadas o mais cedo possível.

```
## ⚠️ Gargalos identificados

- **[Nome da tarefa/fase]**: bloqueia X tarefas; deve ser a primeira a ser iniciada.
```

---

### 8. Geração do arquivo de saída (obrigatório)

Salve o plano como um arquivo Markdown no mesmo diretório da spec, com o nome `plan.md`:

```
documentation/features/<modulo>/specs/plan.md
```

O arquivo deve seguir **exatamente** a estrutura abaixo:

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

### Telas/widgets de `ui` paralelizáveis
- <lista>

### Tarefas de `ui` iniciáveis com stub
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
  - Artefato: `lib/core/<modulo>/<arquivo>.dart`
  - Depende de: —
  - Desbloqueia: F2-T1, F3-T1

- [ ] **F1-T2** — <Descrição da tarefa>
  - Camada: `core`
  - Artefato: `lib/core/<modulo>/<arquivo>.dart`
  - Depende de: F1-T1
  - Desbloqueia: F2-T2

### F2 — <Objetivo da fase>

- [ ] **F2-T1** — <Descrição da tarefa>
  - Camada: `rest`
  - Artefato: `lib/rest/<modulo>/<arquivo>.dart`
  - Depende de: F1-T1
  - Desbloqueia: F4-T1

---

## Pendências

- <Descrição da pendência, impacto e ação sugerida> (ou "Nenhuma")
```

> O arquivo `plan.md` é o documento de entrada do prompt `implement-plan`. Garanta que ele esteja completo e sem seções vazias antes de salvar.

---

## Saída esperada

1. **Análise de dependências** (Seção 2) respondida explicitamente.
2. **Mapa de Paralelização** com todas as fases preenchidas:

   | Fase | Objetivo | Depende de | Pode rodar em paralelo com |
   |------|----------|------------|----------------------------|
   | F1   | \<definir\> | -        | -                          |
   | F2   | \<definir\> | F1       | F3                         |

3. **Lista de gargalos** identificados.
4. **Lista de fases** com objetivo claro.
5. **Lista de tarefas por fase** com dependências explícitas, o que cada tarefa desbloqueia e checklist de progresso.
6. **Arquivo `plan.md`** salvo em `documentation/features/<modulo>/specs/plan.md`.