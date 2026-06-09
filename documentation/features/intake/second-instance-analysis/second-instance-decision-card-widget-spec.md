---
title: Formulário de descrição da decisão — Segunda Instância (mobile)
prd: https://joaogoliveiragarcia.atlassian.net/wiki/spaces/ANM/pages/49348609
ticket: pendente
status: open
last_updated_at: 2026-06-05
---

# 1. Objetivo

Implementar na tela `SecondInstanceAnalysisScreenView` o formulário de descrição da decisão do juiz, introduzindo uma nova etapa obrigatória entre `CASE_ANALYZED` e `SEARCHING_PRECEDENTS`. A entrega cria o DTO `SecondInstanceDecisionDto`, estende `IntakeService` com `createSecondInstanceDecision` e `getSecondInstanceDecision`, adiciona o status `decisionSubmitted` nos enums do mobile, cria dois widgets internos (`SecondInstanceDecisionCard` para preview inline e `SecondInstanceDecisionDialog` para edição fullscreen), ajusta o presenter da tela para gerenciar o novo estado e bloqueia o CTA "Buscar precedentes" até que a decisão esteja submetida, permitindo edição posterior sem resetar precedentes ou minuta já existentes.

---

# 2. Escopo

## 2.1 In-scope

- Criar `SecondInstanceDecisionDto` em `lib/core/intake/dtos/`.
- Adicionar `decisionSubmitted` em `SecondInstanceAnalysisStatusDto` e `AnalysisStatusDto`.
- Estender `IntakeService` com `createSecondInstanceDecision(...)` e `getSecondInstanceDecision(...)`.
- Implementar os dois endpoints em `IntakeRestService`.
- Criar `SecondInstanceDecisionMapper` em `lib/rest/mappers/intake/`.
- Criar widget interno `SecondInstanceDecisionCard` com preview da descrição e CTA para abrir edição.
- Criar widget interno `SecondInstanceDecisionDialog` fullscreen com campo de texto multiline e CTA de confirmação.
- Ajustar `SecondInstanceAnalysisScreenPresenter` para gerenciar `decision`, `isSubmittingDecision`, `createDecision(...)` e reentrada.
- Ajustar `canSearchPrecedents` para exigir `decision != null`.
- Estender `SecondInstanceAnalysisReportDto` com campo `decision: SecondInstanceDecisionDto?`.
- Ajustar `SecondInstanceAnalysisReportMapper` para mapear o campo `decision`.
- Permitir edição da descrição em qualquer status posterior sem resetar precedentes ou minuta.

## 2.2 Out-of-scope

- Criar ou alterar endpoints no server (o `POST /intake/analyses/{analysis_id}/second-instance-decision` e o `GET` correspondente são responsabilidade de ticket server separado).
- Alterar o fluxo de upload, análise do caso, busca de precedentes ou geração da minuta.
- Alterar os fluxos `CASE_ASSESSMENT` ou `FIRST_INSTANCE`.
- Edição inline da minuta de sentença.
- Exportação de PDF ou DOCX.
- Alterações no `design/animus.pen`.
- Testes automatizados.

---

# 3. Requisitos

## 3.1 Funcionais

- Ao atingir `CASE_ANALYZED`, a tela deve exibir o `SecondInstanceDecisionCard` em estado vazio logo abaixo do `CaseSummaryCard`.
- O card vazio deve exibir texto placeholder orientativo e CTA "Descrever decisão" que abre o `SecondInstanceDecisionDialog`.
- O `SecondInstanceDecisionDialog` deve exibir um `TextField` multiline sem limite de linhas visíveis, com hint "Descreva a orientação da sua decisão..." e CTA "Confirmar".
- O CTA "Confirmar" deve estar desabilitado enquanto o campo estiver vazio (após trim).
- Ao confirmar, o presenter deve chamar `IntakeService.createSecondInstanceDecision(analysisId, description)`.
- Em sucesso (`201`), o presenter deve popular `decision` com o DTO retornado e avançar o status local para `decisionSubmitted` quando o status atual for `caseAnalyzed`.
- Se o status atual já for posterior a `decisionSubmitted` (já existem precedentes ou minuta), a edição não deve alterar o status local.
- Após confirmação bem-sucedida, o dialog deve fechar e o card deve transicionar para estado preenchido.
- O card preenchido deve exibir preview truncado da `description` (máximo 4 linhas visíveis) e ícone de edição que reabre o dialog preenchido.
- O CTA "Buscar precedentes" na `AnalysisActionBar` deve ficar **desabilitado** enquanto `decision == null`.
- Ao reabrir a tela em status `>= decisionSubmitted`, o presenter deve carregar a decisão via `IntakeService.getSecondInstanceDecision(analysisId)` e popular `decision`.
- Em falha de rede no `createSecondInstanceDecision`, o dialog deve permanecer aberto e exibir erro inline sem perder o texto digitado.
- Em falha de rede no `getSecondInstanceDecision` durante reentrada, o presenter deve exibir `generalError` e permitir retry via `load()`.
- Fechar o dialog (back, tap fora) sem confirmar deve descartar alterações não salvas.

## 3.2 Não funcionais

- **Performance:** timeout local de **10 segundos** por chamada remota, alinhado ao padrão do presenter atual.
- **Acessibilidade:** o `TextField` do dialog deve ter label/hint claro e foco inicial automático ao abrir.
- **Segurança:** a descrição não deve ser persistida em cache local; circula apenas no request.
- **Arquitetura:** a `View` não monta payload nem acessa `RestClient`; o presenter consome `IntakeService`.
- **Arquitetura:** payload `{ description }` é montado na camada REST (`IntakeRestService`), não na UI.

---

# 4. O que já existe?

## Core

- **`IntakeService`** (`lib/core/intake/interfaces/intake_service.dart`) — contrato central de intake; já possui endpoints de análise, documento, resumo, precedentes e minutas.
- **`AnalysisStatusDto`** (`lib/core/intake/dtos/analysis_status_dto.dart`) — enum compartilhado de status; já contém `caseAnalyzed`, `searchingPrecedents`, `done`, `failed`.
- **`SecondInstanceAnalysisStatusDto`** (`lib/core/intake/dtos/second_instance_analysis_status_dto.dart`) — enum específico de 2ª instância.
- **`SecondInstanceAnalysisReportDto`** (`lib/core/intake/dtos/second_instance_analysis_report_dto.dart`) — DTO do relatório agregado; contém `analysis`, `document`, `caseSummary`, `precedents`, `judgmentDraft`.
- **`RestResponse<T>`** (`lib/core/shared/responses/rest_response.dart`) — wrapper de resposta usado por todos os contratos remotos.

## REST

- **`IntakeRestService`** (`lib/rest/services/intake_rest_service.dart`) — implementação REST de `IntakeService`; local onde os novos endpoints serão adicionados.
- **`SecondInstanceAnalysisReportMapper`** (`lib/rest/mappers/intake/second_instance_analysis_report_mapper.dart`) — mapper do relatório agregado; deve ser estendido para `decision`.
- **`Service`** (`lib/rest/services/service.dart`) — base com helpers de conversão de resposta.

## UI

- **`SecondInstanceAnalysisScreenView`** (`lib/ui/intake/widgets/pages/second_instance_analysis_screen/second_instance_analysis_screen_view.dart`) — tela alvo; hoje exibe `CaseSummaryCard` → `AnalysisPrecedentsBubble` sem etapa intermediária.
- **`SecondInstanceAnalysisScreenPresenter`** (`lib/ui/intake/widgets/pages/second_instance_analysis_screen/second_instance_analysis_screen_presenter.dart`) — presenter da tela; já gerencia `status`, `caseSummary`, `judgmentDraft`, `precedentsReady`, `generalError`, `isManagingAnalysis`.
- **`secondInstanceAnalysisScreenPresenterProvider`** — provider Riverpod do presenter.
- **`CaseSummaryCard`** (`lib/ui/intake/widgets/components/case_summary_card/`) — card de resumo do caso, referência visual do posicionamento.
- **`AnalysisPrecedentsBubble`** (`lib/ui/intake/widgets/components/analysis_precedents_bubble/`) — componente de precedentes que aparecerá após o card de decisão.
- **`JudgmentDraftDialog`** (`lib/ui/intake/widgets/pages/second_instance_analysis_screen/judgment_draft_dialog/judgment_draft_dialog_view.dart`) — referência de dialog fullscreen para a minuta; padrão visual a seguir.
- **`JudgmentDraftCard`** (`lib/ui/intake/widgets/pages/second_instance_analysis_screen/judgment_draft_card/judgment_draft_card_view.dart`) — referência de card com preview truncado e CTA para abrir dialog.
- **`AnalysisActionBar`** (`lib/ui/intake/widgets/components/analysis_action_bar/`) — barra inferior com CTAs primário e secundário.
- **`AppThemeTokens`** (`lib/theme.dart`) — tokens visuais usados em todos os componentes.

## Server (contratos existentes)

- **`POST /intake/analyses/{analysis_id}/second-instance-decision`** → `201` → `SecondInstanceDecisionDto` — controller já implementado com `CreateSecondInstanceDecisionUseCase`, body `{ description: str }`, validação de ownership via `IntakePipe`.
- **`GET /intake/analyses/{analysis_id}/second-instance-decision`** → `200` → `SecondInstanceDecisionDto` — controller já implementado para leitura da decisão existente.
- **`SecondInstanceDecisionDto`** (server) — DTO com `description` e `analysis_id`.
- **`SecondInstanceDecisionsRepository`** (server) — port de persistência já implementado.

---

# 5. O que deve ser criado?

## Camada Core (DTOs)

### `SecondInstanceDecisionDto` *(novo arquivo)*

- **Localização:** `lib/core/intake/dtos/second_instance_decision_dto.dart`
- **Atributos:**
  - `final String analysisId`
  - `final String description`
- **Factory `fromJson`:** não aplicável; parsing pertence à camada REST.

## Camada Core (Interfaces)

### Extensão de `IntakeService` *(arquivo existente)*

- **Localização:** `lib/core/intake/interfaces/intake_service.dart`
- **Novos métodos:**
  - `Future<RestResponse<SecondInstanceDecisionDto>> createSecondInstanceDecision({required String analysisId, required String description})` — cria ou atualiza a descrição da decisão.
  - `Future<RestResponse<SecondInstanceDecisionDto>> getSecondInstanceDecision({required String analysisId})` — lê a decisão existente.

## Camada REST (Mappers)

### `SecondInstanceDecisionMapper` *(novo arquivo)*

- **Localização:** `lib/rest/mappers/intake/second_instance_decision_mapper.dart`
- **Métodos:**
  - `SecondInstanceDecisionDto toDto(Map<String, dynamic> json)` — mapeia `analysis_id` e `description` para `SecondInstanceDecisionDto`.

## Camada REST (Services)

### Extensão de `IntakeRestService` *(arquivo existente)*

- **Localização:** `lib/rest/services/intake_rest_service.dart`
- **Novos métodos:**
  - `createSecondInstanceDecision(...)` — `POST /intake/analyses/{analysis_id}/second-instance-decision` com body `{ "description": description }`, mapeia resposta `201` via `SecondInstanceDecisionMapper.toDto`.
  - `getSecondInstanceDecision(...)` — `GET /intake/analyses/{analysis_id}/second-instance-decision`, mapeia resposta via `SecondInstanceDecisionMapper.toDto`.

## Camada UI (Presenter)

### Extensão de `SecondInstanceAnalysisScreenPresenter` *(arquivo existente)*

- **Localização:** `lib/ui/intake/widgets/pages/second_instance_analysis_screen/second_instance_analysis_screen_presenter.dart`

**Novos signals:**

- `Signal<SecondInstanceDecisionDto?> decision` — `null` até o juiz submeter ou até a reentrada carregar a decisão existente.
- `Signal<bool> isSubmittingDecision` — `true` durante o `POST`.

**Computeds ajustados:**

- `canSearchPrecedents` — adicionar condição: requer `decision.value != null`.
- Novo `canEditDecision` — `true` quando `status.value` for `>= caseAnalyzed` e `isSubmittingDecision.value == false`.

**Novos métodos:**

- `Future<void> createDecision(String description)` — valida trim, chama `IntakeService.createSecondInstanceDecision(analysisId: analysisId, description: description)`. Em sucesso: popula `decision`, avança status local para `decisionSubmitted` se status atual for `caseAnalyzed`; se status já for posterior, mantém inalterado. Em falha: retorna o `errorMessage` para o dialog exibir inline.
- `Future<bool> _loadDecision()` — chamado dentro de `load()` quando `status >= decisionSubmitted`. Chama `IntakeService.getSecondInstanceDecision(analysisId: analysisId)`. Em sucesso: popula `decision`, retorna `true`. Em falha com `404`: mantém `decision` como `null`, retorna `true` (não bloqueia). Em falha geral: aplica `generalError`, retorna `false`.

**Ajuste em `load()`:**

- Após carregar `caseSummary`, se `status >= decisionSubmitted`, chamar `_loadDecision()`.
- A ordem de carregamento fica: `status → document → caseSummary → decision → precedents → judgmentDraft`.

## Camada UI (Widgets Internos)

### `SecondInstanceDecisionCard` *(novo arquivo em pasta nova)*

- **Localização:** `lib/ui/intake/widgets/pages/second_instance_analysis_screen/second_instance_decision_card/`
- **Arquivos:** `second_instance_decision_card_view.dart`, `index.dart`
- **Base class:** `StatelessWidget`
- **Props:**
  - `required SecondInstanceDecisionDto? decision`
  - `required bool isSubmitting`
  - `required VoidCallback onOpenDialog`
- **Estados visuais:**
  - **Vazio** (`decision == null`): container com `surfaceCard`, `borderRadius: 16`, `border: borderSubtle`, ícone `Icons.description_outlined` + texto "Descreva a orientação da sua decisão para guiar a busca de precedentes" em `bodySmall`/`textMuted` + `TextButton("Descrever decisão", onPressed: onOpenDialog)`.
  - **Preenchido** (`decision != null`): mesmo container, com `Text(decision.description, maxLines: 4, overflow: TextOverflow.ellipsis)` em `bodySmall`/`textPrimary` + `IconButton(Icons.edit_outlined, onPressed: onOpenDialog)` alinhado ao topo direito.
  - **Loading** (`isSubmitting == true`): CTA desabilitado com `SizedBox(CircularProgressIndicator)`.

### `SecondInstanceDecisionDialog` *(novo arquivo em pasta nova)*

- **Localização:** `lib/ui/intake/widgets/pages/second_instance_analysis_screen/second_instance_decision_dialog/`
- **Arquivos:** `second_instance_decision_dialog_view.dart`, `second_instance_decision_dialog_presenter.dart`, `index.dart`
- **Base class `View`:** `StatefulWidget` (instancia e descarta o presenter local).
- **Props da `View`:**
  - `required String analysisId`
  - `required SecondInstanceDecisionDto? initialDecision` — preenche o campo ao abrir para edição.
  - `required Future<String?> Function(String description) onConfirm` — callback do presenter da tela; retorna `null` em sucesso ou mensagem de erro.

**`SecondInstanceDecisionDialogPresenter` (presenter local):**

- **Dependências injetadas:** nenhuma (presenter local de UI).
- **Estado (`signals`):**
  - `Signal<String> description` — texto atual do campo; inicializado com `initialDecision?.description ?? ''`.
  - `Signal<bool> isSubmitting` — loading do confirm.
  - `Signal<String?> errorMessage` — erro inline retornado pelo callback.
- **Computeds:**
  - `canConfirm` — `description.value.trim().isNotEmpty && !isSubmitting.value`.
- **Métodos:**
  - `void updateDescription(String value)` — atualiza `description.value` e limpa `errorMessage`.
  - `Future<void> confirm(BuildContext context)` — se `!canConfirm`, retorna. Seta `isSubmitting = true`, chama `onConfirm(description.value.trim())`. Se retorno for `null` (sucesso), `Navigator.pop(context)`. Se retorno for mensagem, seta `errorMessage`. Seta `isSubmitting = false`.
  - `void dispose()` — cleanup.

**Estrutura visual do `SecondInstanceDecisionDialog`:**

- `Dialog` fullscreen (referência: `JudgmentDraftDialog`).
- `AppBar` com título "Descrição da decisão" e `IconButton(Icons.close)` que faz `Navigator.pop`.
- `Padding` com `TextField`:
  - `maxLines: null` (multiline expansível)
  - `decoration: InputDecoration(hintText: "Descreva a orientação da sua decisão...")`
  - `onChanged: presenter.updateDescription`
  - Valor inicial: `presenter.description.value`
- `errorMessage != null` → `Text(errorMessage, style: bodySmall/error)` abaixo do campo.
- Botão fixo na parte inferior: `FilledButton("Confirmar", onPressed: canConfirm ? presenter.confirm : null)` com `SizedBox(CircularProgressIndicator)` quando `isSubmitting`.

---

# 6. O que deve ser modificado?

## Core

- **Arquivo:** `lib/core/intake/dtos/analysis_status_dto.dart`
- **Mudança:** adicionar `decisionSubmitted` ao enum, mapeando de `DECISION_SUBMITTED`.

- **Arquivo:** `lib/core/intake/dtos/second_instance_analysis_status_dto.dart`
- **Mudança:** adicionar `decisionSubmitted` ao enum.

- **Arquivo:** `lib/core/intake/dtos/second_instance_analysis_report_dto.dart`
- **Mudança:** adicionar campo `final SecondInstanceDecisionDto? decision`.

## REST

- **Arquivo:** `lib/rest/mappers/intake/analysis_mapper.dart`
- **Mudança:** aceitar `DECISION_SUBMITTED` no mapeamento de status.

- **Arquivo:** `lib/rest/mappers/intake/second_instance_analysis_report_mapper.dart`
- **Mudança:** mapear campo `decision` usando `SecondInstanceDecisionMapper.toDto` quando presente.

## UI

- **Arquivo:** `lib/ui/intake/widgets/pages/second_instance_analysis_screen/second_instance_analysis_screen_view.dart`
- **Mudança:** inserir `SecondInstanceDecisionCard` entre `CaseSummaryCard` e `AnalysisPrecedentsBubble`. O card deve ser renderizado quando `status >= caseAnalyzed`. Conectar `onOpenDialog` para abrir `SecondInstanceDecisionDialog`. Passar `decision`, `isSubmittingDecision` e callback `createDecision` do presenter.

- **Arquivo:** `lib/ui/intake/widgets/pages/second_instance_analysis_screen/second_instance_analysis_screen_presenter.dart`
- **Mudança:** adicionar signals `decision` e `isSubmittingDecision`, ajustar `canSearchPrecedents`, implementar `createDecision(...)` e `_loadDecision()`, ajustar `load()` para carregar decisão na reentrada.

---

# 7. O que deve ser removido?

**Não aplicável.**

---

# 8. Decisões Técnicas e Trade-offs

- **Decisão:** o formulário aparece como card inline na tela, expandível para dialog fullscreen.
- **Alternativas consideradas:** formulário apenas inline com auto-save; tela separada dedicada ao formulário.
- **Motivo da escolha:** card dá visibilidade imediata ao estado do campo no fluxo da tela, enquanto o dialog oferece espaço adequado para texto longo sem competir visualmente com os outros cards.
- **Impactos / trade-offs:** dois widgets para uma única funcionalidade (card + dialog), mas alinhado ao padrão já usado por `JudgmentDraftCard` + `JudgmentDraftDialog`.

- **Decisão:** usar `POST` (não `PUT`) alinhado ao controller server existente que retorna `201`.
- **Alternativas consideradas:** `PUT` semântico para idempotência.
- **Motivo da escolha:** o server já usa `POST` + `CreateSecondInstanceDecisionUseCase` com semântica de create-or-replace; manter alinhamento evita divergência.
- **Impactos / trade-offs:** `POST` retornando `201` mesmo na atualização pode parecer semanticamente impreciso, mas o server trata internamente.

- **Decisão:** edição posterior não reseta status, precedentes ou minuta.
- **Alternativas consideradas:** resetar para `DECISION_SUBMITTED` e forçar nova busca de precedentes.
- **Motivo da escolha:** o server já consome a `description` internamente nos jobs downstream; o juiz decide quando quer rebuscar ou regerar. Resetar criaria fricção desnecessária e perda de trabalho.
- **Impactos / trade-offs:** a description pode ficar dessincronizada com precedentes/minuta gerados com uma versão anterior, mas o juiz tem controle para rebuscar/regerar quando quiser.

- **Decisão:** presenter local no dialog (não provider Riverpod).
- **Alternativas consideradas:** provider global para o dialog.
- **Motivo da escolha:** ciclo de vida do presenter coincide com o ciclo de vida do dialog; não precisa de dependências injetadas. Mesmo padrão de `ProfileUpdateNameDialogPresenter` e `CreateAnalysisTypeDialogPresenter`.
- **Impactos / trade-offs:** sem injeção de dependência no dialog, o callback de confirmação é passado como prop pela tela.

- **Decisão:** o CTA "Buscar precedentes" fica bloqueado até `decision != null` (obrigatório).
- **Alternativas consideradas:** permitir pular a etapa e buscar sem descrição.
- **Motivo da escolha:** alinhamento com o PRD RF 08 que define a descrição como orientação obrigatória para a busca e geração.
- **Impactos / trade-offs:** adiciona uma etapa obrigatória no fluxo, mas garante qualidade da busca e da minuta gerada.

---

# 9. Diagramas e Referências

### Fluxo de dados

```text
SecondInstanceDecisionCard
  -> onOpenDialog
  -> SecondInstanceDecisionDialog
      -> SecondInstanceDecisionDialogPresenter (local)
          -> onConfirm(description)
              -> SecondInstanceAnalysisScreenPresenter.createDecision(description)
                  -> IntakeService.createSecondInstanceDecision(analysisId, description)
                      -> IntakeRestService
                          -> RestClient POST /intake/analyses/{id}/second-instance-decision
                  <- SecondInstanceDecisionDto
                  -> decision.value = dto
                  -> status.value = decisionSubmitted (se status == caseAnalyzed)
              <- null (sucesso) ou errorMessage (falha)
          -> Navigator.pop (sucesso) ou errorMessage (falha)
```

### Hierarquia de widgets atualizada

```text
SecondInstanceAnalysisScreenView
  Scaffold > SafeArea > Stack
    DotGridBackground
    Column
      AnalysisHeader
      SingleChildScrollView
        AiBubble
        DocumentFileBubble
        ProcessingBubble
        PetitionNotFoundState
        MessageBox
        CaseSummaryCard
        SecondInstanceDecisionCard        ← NOVO
        AnalysisPrecedentsBubble
        GenerateJudgmentDraftCard
        JudgmentDraftCard (preview)
        JudgmentDraftDialog (fullscreen)
        SecondInstanceDecisionDialog      ← NOVO (fullscreen, aberto sob demanda)
      AnalysisActionBar
```

### Mapeamento de status atualizado

```text
WAITING_DOCUMENT_UPLOAD            → WaitingDocument
DOCUMENT_UPLOADED                  → DocumentReady
EXTRACTING_PETITION / ANALYZING_CASE → ProcessingCase
CASE_ANALYZED                      → CaseSummary + DecisionCard (vazio)
                                     CTA "Buscar precedentes" DISABLED
DECISION_SUBMITTED                 → CaseSummary + DecisionCard (preenchido)
                                     CTA "Buscar precedentes" ENABLED
SEARCHING_PRECEDENTS               → PrecedentsProcessing + DecisionCard (read/edit)
PRECEDENTS_SEARCHED                → PrecedentsReady + DecisionCard (read/edit)
ANALYZING_PRECEDENTS_SIMILARITY    → PrecedentsProcessing + DecisionCard (read/edit)
ANALYZING_PRECEDENTS_APPLICABILITY → PrecedentsReady + DecisionCard (read/edit)
GENERATING_JUDGMENT_DRAFT          → JudgmentDraftProcessing + DecisionCard (read/edit)
GENERATING_SYNTHESIS               → JudgmentDraftProcessing + DecisionCard (read/edit)
DONE                               → JudgmentDraftReady + DecisionCard (read/edit)
FAILED                             → Failed (retry contextual) + DecisionCard (se existir)
```

### Comportamento de edição por status

```text
Status atual                  | Juiz edita descrição          | Resultado
------------------------------|-------------------------------|-----------------------------------
CASE_ANALYZED                 | POST → cria decision          | Status → DECISION_SUBMITTED
DECISION_SUBMITTED            | POST → atualiza description   | Status permanece DECISION_SUBMITTED
PRECEDENTS_SEARCHED           | POST → atualiza description   | Status permanece, precedentes mantidos
DONE                          | POST → atualiza description   | Status permanece, minuta mantida
```

### Referências

- `lib/core/intake/interfaces/intake_service.dart` — contrato a estender.
- `lib/rest/services/intake_rest_service.dart` — implementação REST a estender.
- `lib/ui/intake/widgets/pages/second_instance_analysis_screen/` — tela alvo.
- `lib/ui/intake/widgets/pages/second_instance_analysis_screen/judgment_draft_card/` — referência visual para o card.
- `lib/ui/intake/widgets/pages/second_instance_analysis_screen/judgment_draft_dialog/` — referência visual para o dialog fullscreen.
- `lib/ui/intake/widgets/pages/home_screen/create_analysis_type_dialog/` — referência de dialog com presenter local.
- `documentation/rules/ui-layer-rules.md` — regras de camada UI.
- `documentation/rules/core-layer-rules.md` — regras de camada core.
- `documentation/rules/rest-layer-rules.md` — regras de camada REST.
- `https://joaogoliveiragarcia.atlassian.net/wiki/spaces/ANM/pages/49348609` — PRD RF 08.

---

# 10. Pendências / Dúvidas

- **Descrição da pendência:** o status `DECISION_SUBMITTED` ainda não existe no `SecondInstanceAnalysisStatusValue` do server (enum atual em `src/animus/core/intake/domain/structures/second_instance_analysis_status.py`).
- **Impacto na implementação:** o `CreateSecondInstanceDecisionUseCase` precisa avançar a análise para esse status; sem ele no enum, o server lança `ValidationError`.
- **Ação sugerida:** adicionar `DECISION_SUBMITTED` ao enum e ao factory method `create_as_decision_submitted()` no server antes da integração mobile.
- **Status:** confirmado — enum será atualizado no server.

---

# 11. Restrições

- A `View` não deve conter lógica de negócio; toda orquestração fica no `Presenter`.
- Presenters não fazem chamadas diretas a `RestClient`; consomem `IntakeService`.
- Payload `{ "description": ... }` é montado em `IntakeRestService`, não na UI.
- Todos os caminhos citados existem no projeto ou estão marcados como **novo arquivo**.
- Widgets internos com responsabilidade própria foram organizados em pasta própria com `*_view.dart`, `*_presenter.dart` (quando aplicável) e `index.dart`.
- A UI deve usar componentes Flutter Material alinhados ao tema existente (`AppThemeTokens`).
- Arquivos em `snake_case`, classes em `PascalCase`, providers e métodos em `camelCase`.