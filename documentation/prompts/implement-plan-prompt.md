---
description: Implementar no codebase um plano de implementação derivado de uma spec técnica, seguindo a arquitetura e diretrizes do Animus Mobile.
---

# Prompt: Implementar Plano (Animus Mobile)

**Objetivo principal:** Implementar no codebase um plano de implementação derivado de uma spec técnica, seguindo a arquitetura e diretrizes do Animus Mobile, **respeitando rigorosamente a ordem de fases e tarefas definidas no plano para maximizar a paralelização e evitar retrabalho.**

## Entrada

- Caminho do arquivo `plan.md` (Markdown) **ou**, se não houver plano, caminho da spec técnica (Markdown).

> O `plan.md` pode estar **novo** (nenhuma tarefa iniciada) ou **em andamento** (execução anterior parcialmente concluída). O prompt deve lidar com ambos os casos — veja Seção 1.1.

---

## Diretrizes de execução

### 1. Pre-check (obrigatório)

**1.1 Leitura do plano e detecção de estado**

- Leia o `plan.md` na íntegra antes de escrever qualquer linha de código.
- Identifique: escopo, fases, mapa de paralelização, gargalos, critérios de aceite, riscos e pendências.
- Se o documento estiver incompleto, não invente: crie uma seção `Pendências` e avance apenas com defaults seguros.

**Detecte o estado atual do plano** inspecionando os checkboxes e anotações das tarefas:

| Condição no `plan.md` | Ação |
|---|---|
| Todas as tarefas com `- [ ]` sem anotação | Plano novo — inicialize o tracking e comece pela primeira tarefa. |
| Alguma tarefa com `- [x]` ou `⚠️ bloqueado` | Plano em andamento — **retome a partir da primeira tarefa `- [ ]` não bloqueada**. |
| Todas as tarefas com `- [x]` | Plano concluído — informe e não reexecute. |

Ao retomar um plano em andamento:
- Trate tarefas `- [x]` como **já concluídas** — não as reimplemente.
- Verifique se os artefatos registrados em tarefas `- [x]` realmente existem na codebase antes de prosseguir; se estiverem ausentes, marque a tarefa como reaberta e reimplemente.
- Tarefas `⚠️ bloqueado` só devem ser retomadas se o bloqueio foi resolvido — confirme antes de avançar.

**1.2 Leitura da codebase existente**

Use **Serena** para localizar implementações similares nas mesmas camadas impactadas — use-as como referência de padrão e nomenclatura.

> Não assuma que um arquivo existe ou tem determinada assinatura sem verificar na codebase. Implementar com base em suposições gera conflitos e retrabalho.

**1.3 Leitura das regras das camadas impactadas**

Antes de implementar qualquer camada, leia as regras correspondentes em `documentation/rules/`:

- `documentation/rules/core-layer-rules.md`
- `documentation/rules/rest-layer-rules.md`
- `documentation/rules/drivers-layer-rules.md`
- `documentation/rules/ui-layer-rules.md`
- `documentation/rules/code-conventions-rules.md`

> Leia apenas as regras das camadas que serão tocadas nesta execução. Não pule esta etapa — padrões existentes devem ser preservados.

---

### 2. Inicialização do tracking (obrigatório)

O `plan.md` é a fonte de verdade do progresso — os checkboxes das tarefas são o tracking. Não existe lista separada.

**Se o plano for novo**, use a todo tool para espelhar todas as tarefas do `plan.md` antes de iniciar, com os identificadores exatos (ex: `F1-T1`). A todo tool é auxiliar — o estado canônico sempre vive no `plan.md`.

**Se o plano estiver em andamento**, sincronize a todo tool com o estado atual do `plan.md`:
- Tarefas `- [x]` → marque como `done` na todo tool.
- Tarefas `⚠️ bloqueado` → marque como `blocked` na todo tool.
- Tarefas `- [ ]` restantes → marque como `pending` na todo tool.

A cada mudança de estado, atualize **ambos** em sincronia: primeiro o `plan.md`, depois a todo tool.

> Nunca inicie uma nova tarefa sem ter atualizado o `plan.md` e a todo tool com o estado da tarefa atual.

---

### 3. Ordem de execução e paralelização (obrigatório)

**Respeite o mapa de paralelização do plano.** Cada fase só pode ser iniciada quando todas as suas dependências estiverem concluídas.

Dentro de cada fase, siga a hierarquia bottom-up:

1. **Core (`lib/core`)**: DTOs, Entidades, Interfaces e tipos de resposta — estes contratos desbloqueiam todas as outras camadas.
2. **Rest (`lib/rest`)**: Services, Mappers e RestClient — implementam contratos do `core`.
3. **Drivers (`lib/drivers`)**: adaptadores de infraestrutura (env, storage, navegação) — implementam contratos do `core`, independentes da `rest`.
4. **UI (`lib/ui`)**: Presenters (MVP), Widgets e Telas — consomem contratos do `core`.

> `rest` e `drivers` são independentes entre si e podem ser implementados em paralelo após o `core` estabilizar. Nunca implemente um consumidor (ex: Widget, Service) antes do contrato (interface, DTO) que ele consome.

**Cada fase é implementada por um subagent — sem exceção**

Independentemente de a fase ser paralela ou sequencial, **cada fase do plano deve ser delegada a um subagent dedicado**. O agente orquestrador não implementa código diretamente — seu papel é coordenar, passar contexto e consolidar resultados.

- **Fases paralelizáveis** (coluna "Pode rodar em paralelo com" preenchida): dispare os subagents simultaneamente.
- **Fases sequenciais** (sem paralelismo): dispare um subagent por vez, aguardando a conclusão antes de avançar.

**Contexto obrigatório no prompt de cada subagent:**

- O escopo exato da fase: lista de tarefas, artefatos esperados e dependências.
- Os contratos do `core` que a fase consome (interfaces, DTOs, tipos de resposta) — mesmo que ainda não implementados, forneça as assinaturas definidas na spec para que o subagent possa trabalhar sem aguardar outra fase.
- O conteúdo das **regras das camadas impactadas** pela fase (`documentation/rules/<camada>-layer-rules.md`) — não assuma que o subagent lerá por conta própria.
- Os arquivos existentes na codebase relevantes para a fase, localizados com Serena no pre-check (Seção 1.2).
- O estado atual do `plan.md` — para que o subagent saiba o que já foi concluído e atualize apenas as tarefas da sua fase.
- Instrução explícita para: atualizar o `plan.md` (checkboxes + artefatos) e rodar o ciclo de qualidade (`dart format .`, `flutter analyze`, `flutter test`) ao concluir cada tarefa.

**Após a conclusão de cada subagent**, o orquestrador deve:

1. Verificar se o `plan.md` foi atualizado corretamente pelo subagent.
2. Sincronizar a todo tool com o novo estado do `plan.md`.
3. Confirmar que os artefatos declarados pelo subagent existem na codebase antes de disparar a próxima fase.

> Subagents não compartilham contexto entre si. Todo o conhecimento necessário para executar a fase deve ser passado explicitamente no prompt de despacho. Um subagent sem contexto suficiente vai adivinhar — e adivinhar gera retrabalho.

---

### 4. Ciclo de implementação por tarefa

Para cada tarefa do plano:

1. **Marque como `in_progress`** na todo tool antes de começar.
2. **Localize código existente semelhante** antes de criar algo novo — use Serena.
3. **Implemente a mudança mínima** que entrega o resultado observável descrito na tarefa.
4. **Não acople camadas**: UI não acessa API diretamente; `core` não conhece `rest`, `drivers` ou Flutter.
5. **Preserve padrões existentes**: nomenclatura, organização de pastas, providers, presenters.
6. **Ao concluir a tarefa**, execute o ciclo de qualidade (Seção 5) antes de avançar.
7. **Atualize o `plan.md`** com `- [x]` e os artefatos gerados (Seção 7).
8. **Marque como `done`** na todo tool.

---

### 5. Ciclo de qualidade (obrigatório por tarefa)

Ao finalizar cada tarefa, rode os checks abaixo e corrija falhas **antes de avançar para a próxima tarefa**:

```bash
# Formatação
dart format .

# Análise estática
flutter analyze

# Testes
flutter test
```

> Não avance com o projeto quebrado. Erros de análise estática e falhas de teste devem ser corrigidos imediatamente.

---

### 6. Identificação de bloqueios

Se uma tarefa não puder ser implementada por dependência externa, ambiguidade ou lacuna na spec:

- Sinalize `⚠️ bloqueado` na linha da tarefa no `plan.md` e registre o motivo na seção `Pendências`.
- Marque como `blocked` na todo tool.
- Avance para a próxima tarefa **não bloqueada** do plano.
- Não invente contratos ou comportamentos para contornar o bloqueio.

---

### 7. Atualização contínua do `plan.md` (obrigatório)

O arquivo `plan.md` é o documento vivo do progresso. Ele deve ser atualizado **a cada mudança de estado de uma tarefa** — não apenas ao final da execução.

**Ao iniciar uma tarefa**, sinalize na linha da tarefa:
```markdown
- [ ] **[em andamento]** F1-T1 — <Descrição>
```

**Ao concluir uma tarefa**, marque o checklist e registre os artefatos gerados:
```markdown
- [x] **F1-T1** — Criar interface `IAuthService`
  - Artefatos: `lib/core/auth/interfaces/i_auth_service.dart` *(novo)*
  - Concluído em: <data>
```

**Ao bloquear uma tarefa**, registre o motivo diretamente na seção `Pendências` do `plan.md` e sinalize na linha da tarefa:
```markdown
- [ ] **F2-T3** — Implementar `AuthRestService` ⚠️ bloqueado
  - Motivo: contrato `IAuthService` ainda não finalizado (F1-T2 pendente)
```

**Ao concluir todas as fases**, atualize o status no cabeçalho do `plan.md`:
```markdown
Atualize o frontmatter: `status: open` → `status: closed`
```

**Ao identificar divergências** entre a implementação e a spec (decisões de design, ajustes de contrato, comportamentos não previstos), registre-as em uma seção `Divergências` no `plan.md`:
```markdown
## Divergências em relação à Spec

- **F2-T2:** `AuthMapper` foi separado em dois arquivos para manter SRP — decisão tomada durante a implementação.
```

> O `plan.md` deve ser legível como um log de progresso. Qualquer pessoa que abrir o arquivo no meio da execução deve conseguir entender imediatamente o que foi feito, o que está em andamento e o que está bloqueado.

---

### 8. Reporte final

Ao concluir todas as tarefas (ou ao ser bloqueado), produza um reporte com:

```markdown
## Reporte de Implementação

### Tarefas concluídas
- [x] <F1-T1 — Descrição> — arquivos criados/alterados: `lib/caminho/arquivo.dart`

### Tarefas pendentes / bloqueadas
- [ ] <F2-T3 — Descrição> — motivo: <descrição do bloqueio>

### Divergências em relação à spec
- <Descrição da divergência e decisão tomada> (ou "Nenhuma")

### Próximos passos
- <Lista de ações necessárias para desbloqueio ou continuidade>
```

---

## Saída esperada

- Implementação completa (ou parcial, se bloqueada) do plano no codebase.
- `plan.md` atualizado com checkboxes, artefatos gerados, bloqueios e divergências refletindo o estado real.
- Todo tool sincronizada com o estado final de cada tarefa.
- Reporte final com arquivos reais criados/alterados, bloqueios justificados e próximos passos.