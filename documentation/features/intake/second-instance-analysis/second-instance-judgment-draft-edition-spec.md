---
title: Edição manual da minuta de sentença no JudgmentDraftDialog — Segunda Instância (mobile)
prd: https://joaogoliveiragarcia.atlassian.net/wiki/spaces/ANM/pages/49348609
ticket: N/A
status: open
last_updated_at: 2026-06-05
---

# 1. Objetivo

Transformar o `JudgmentDraftDialog` (hoje read-only) em um dialog fullscreen editável campo a campo, com auto-save por debounce a cada alteração, indicador de status de salvamento (`SaveStatusIndicator`), `DynamicListField` para o campo `ruling` (lista dinâmica) e validação que impede campos obrigatórios vazios. A entrega estende `IntakeService` com `updateSecondInstanceJudgmentDraft(...)`, cria o presenter dedicado do dialog com `reactive_forms`, altera cada `DraftSection` para modo editável e adiciona o `SaveStatusIndicator` no header do dialog.

---

# 2. Escopo

## 2.1 In-scope

- Estender `IntakeService` com `updateSecondInstanceJudgmentDraft(analysisId, dto)`.
- Implementar `PUT /intake/analyses/{analysis_id}/second-instance-judgment-drafts` em `IntakeRestService`.
- Criar `JudgmentDraftDialogPresenter` com `FormGroup` (`reactive_forms`), auto-save por debounce e estado de salvamento.
- Criar widget interno `SaveStatusIndicator` reutilizável para feedback visual de salvamento.
- Criar widget interno `DynamicListField` reutilizável para campos do tipo lista (`ruling`).
- Transformar as `DraftSection` existentes do dialog em campos editáveis (`TextField` multiline) sem perder a identidade visual das seções.
- Validar que nenhum campo obrigatório (`report`, `meritAnalysis`, `precedentAdherenceAnalysis`, `ruling`) esteja vazio.
- Campos opcionais (`preliminaryIssues`, `noApplicablePrecedentNotice`) podem ficar vazios; quando vazios, o PUT envia `null`.
- Atualizar o `judgmentDraft` no presenter da tela após cada save bem-sucedido para manter o card de preview sincronizado.
- Manter o CTA "Regerar minuta" funcional no dialog editável.

## 2.2 Out-of-scope

- Criar ou alterar endpoints no server (o `PUT` é responsabilidade de ticket server separado).
- Alterar a geração ou regeneração da minuta.
- Alterar a busca ou classificação de precedentes.
- Alterar a exportação de PDF ou DOCX.
- Alterar o `JudgmentDraftCard` (preview na tela principal) — ele continua read-only.
- Alterar o fluxo de `CASE_ASSESSMENT` ou `FIRST_INSTANCE`.
- Alterações no `design/animus.pen`.
- Testes automatizados.

---

# 3. Requisitos

## 3.1 Funcionais

- Ao abrir o `JudgmentDraftDialog`, todos os campos devem estar preenchidos com os valores atuais do `SecondInstanceJudgmentDraftDto`.
- Cada seção da minuta deve ser editável inline via `TextField` multiline, substituindo o `Text` estático atual.
- O campo `ruling` deve usar um `DynamicListField` que permita adicionar e remover itens da lista, com mínimo de 1 item.
- Ao alterar qualquer campo, o dialog deve iniciar um debounce de **1 segundo**. Ao expirar sem nova alteração, o presenter deve chamar `IntakeService.updateSecondInstanceJudgmentDraft(...)` com o DTO completo atualizado.
- Durante o save, o `SaveStatusIndicator` no header deve exibir "Salvando...".
- Em sucesso, o indicador deve exibir "Salvo" por 3 segundos e depois desaparecer.
- Em falha, o indicador deve exibir "Erro ao salvar" com possibilidade de retry manual.
- Nenhum campo obrigatório pode ser enviado vazio. Se o juiz limpar `report`, `meritAnalysis`, `precedentAdherenceAnalysis` ou todos os itens de `ruling`, o auto-save deve ser bloqueado e o campo deve exibir erro de validação inline.
- Campos opcionais (`preliminaryIssues`, `noApplicablePrecedentNotice`) quando esvaziados devem ser enviados como `null` no DTO.
- Após cada save bem-sucedido, o presenter do dialog deve notificar o presenter da tela para atualizar `judgmentDraft`, mantendo o `JudgmentDraftCard` na tela principal sincronizado.
- O CTA "Regerar minuta" deve continuar funcional e, ao confirmar regeneração, deve fechar o dialog (comportamento atual).
- Ao fechar o dialog (back ou close), se houver alterações não salvas com debounce pendente, o presenter deve disparar o save imediatamente antes de fechar (flush).
- Ao reabrir o dialog, o form deve refletir o estado mais recente do `judgmentDraft` do presenter da tela.

## 3.2 Não funcionais

- **Performance:** debounce de **1 segundo** entre digitação e save remoto; múltiplas alterações rápidas não geram múltiplos requests.
- **Performance:** timeout local de **10 segundos** por chamada de save.
- **Acessibilidade:** cada campo deve ter label visível alinhado ao título da seção (`Relatório`, `Análise do Mérito`, etc.) e hint adequado.
- **Segurança:** o conteúdo da minuta não deve ser persistido em cache local; transita apenas no request.
- **Arquitetura:** a `View` não monta payload nem acessa `RestClient`; o presenter consome `IntakeService`.
- **Arquitetura:** payload do `PUT` é montado em `IntakeRestService`, não na UI.

---

# 4. O que já existe?

## Core

- **`SecondInstanceJudgmentDraftDto`** (`lib/core/intake/dtos/second_instance_judgment_draft_dto.dart`) — DTO estruturado com `analysisId`, `report`, `meritAnalysis`, `precedentAdherenceAnalysis`, `ruling` (list), `preliminaryIssues` (opcional), `noApplicablePrecedentNotice` (opcional).
- **`IntakeService`** (`lib/core/intake/interfaces/intake_service.dart`) — contrato central; já possui `getSecondInstanceJudgmentDraft(...)` e `triggerSecondInstanceJudgmentDraftGeneration(...)`.
- **`RestResponse<T>`** (`lib/core/shared/responses/rest_response.dart`) — wrapper de resposta.

## REST

- **`IntakeRestService`** (`lib/rest/services/intake_rest_service.dart`) — implementação REST; já possui `getSecondInstanceJudgmentDraft` e endpoints de geração/regeneração.
- **`SecondInstanceJudgmentDraftMapper`** (`lib/rest/mappers/intake/second_instance_judgment_draft_mapper.dart`) — mapper já existente para `toDto`; será reutilizado na resposta do PUT.

## UI

- **`JudgmentDraftDialog`** (`lib/ui/intake/widgets/pages/second_instance_analysis_screen/judgment_draft_dialog/judgment_draft_dialog_view.dart`) — dialog fullscreen atual, **read-only**. Exibe seções via `DraftSection`. Recebe `draft` e `onRegenerate` como props. Não possui presenter.
- **`DraftSection`** (`lib/ui/intake/widgets/pages/second_instance_analysis_screen/judgment_draft_dialog/draft_section/draft_section_view.dart`) — widget que renderiza uma seção com ícone, título e conteúdo textual estático.
- **`JudgmentDraftCard`** (`lib/ui/intake/widgets/pages/second_instance_analysis_screen/judgment_draft_card/judgment_draft_card_view.dart`) — card preview na tela, read-only; fora do escopo de edição.
- **`SecondInstanceAnalysisScreenPresenter`** (`lib/ui/intake/widgets/pages/second_instance_analysis_screen/second_instance_analysis_screen_presenter.dart`) — presenter da tela; possui signal `judgmentDraft` que deve ser atualizado após saves.
- **`RegenerateDraftDialog`** (`lib/ui/intake/widgets/components/regenerate_draft_dialog/`) — dialog de regeração com comentários; já integrado ao `JudgmentDraftDialog` via `onRegenerate`.

## Server (contratos existentes)

- **`PUT /intake/analyses/{analysis_id}/second-instance-judgment-drafts`** — endpoint server para edição manual da minuta (ticket server separado). Body: `SecondInstanceJudgmentDraftDto` completo. Retorno: `200` com `SecondInstanceJudgmentDraftDto` atualizado.

---

# 5. O que deve ser criado?

## Camada Core (Interfaces)

### Extensão de `IntakeService` *(arquivo existente)*

- **Localização:** `lib/core/intake/interfaces/intake_service.dart`
- **Novo método:**
  - `Future<RestResponse<SecondInstanceJudgmentDraftDto>> updateSecondInstanceJudgmentDraft({required String analysisId, required SecondInstanceJudgmentDraftDto dto})` — edição manual da minuta via PUT.

## Camada REST (Services)

### Extensão de `IntakeRestService` *(arquivo existente)*

- **Localização:** `lib/rest/services/intake_rest_service.dart`
- **Novo método:**
  - `updateSecondInstanceJudgmentDraft(...)` — `PUT /intake/analyses/{analysis_id}/second-instance-judgment-drafts` com body serializado de `SecondInstanceJudgmentDraftDto`, mapeia resposta `200` via `SecondInstanceJudgmentDraftMapper.toDto`.

## Camada UI (Presenter)

### `JudgmentDraftDialogPresenter` *(novo arquivo)*

- **Localização:** `lib/ui/intake/widgets/pages/second_instance_analysis_screen/judgment_draft_dialog/judgment_draft_dialog_presenter.dart`
- **Dependências injetadas:** `IntakeService`
- **Provider Riverpod:** `judgmentDraftDialogPresenterProvider` (`AutoDisposeFamilyProvider<JudgmentDraftDialogPresenter, String>`, parametrizado por `analysisId`).

**FormGroup (`reactive_forms`):**

```
FormGroup {
  'report':              FormControl<String>(validators: [Validators.required]),
  'preliminary_issues':  FormControl<String>(),  // opcional
  'merit_analysis':      FormControl<String>(validators: [Validators.required]),
  'precedent_adherence': FormControl<String>(validators: [Validators.required]),
  'ruling':              FormArray<String>([FormControl<String>(validators: [Validators.required])]),
  'no_applicable_notice': FormControl<String>(),  // opcional
}
```

**Signals:**

- `Signal<SaveStatus> saveStatus` — enum com valores `idle`, `saving`, `saved`, `error`.
- `Signal<String?> saveError` — mensagem de erro do último save falho.

**Computeds:**

- `canSave` — `form.valid && saveStatus.value != saving`.

**Métodos:**

- `void initialize(SecondInstanceJudgmentDraftDto draft)` — popula o `FormGroup` com os valores do DTO. Registra listener de `valueChanges` com debounce de 1 segundo que dispara `_autoSave()`.
- `Future<void> _autoSave()` — se `!form.valid`, marca campos como touched e retorna sem salvar. Se válido, monta `SecondInstanceJudgmentDraftDto` a partir do form, chama `IntakeService.updateSecondInstanceJudgmentDraft(...)`. Em sucesso: seta `saveStatus = saved`, notifica callback `onDraftUpdated(dto)`. Em falha: seta `saveStatus = error` e `saveError`.
- `Future<void> retrySave()` — re-executa `_autoSave()` manualmente.
- `Future<void> flush()` — cancela debounce pendente e executa save imediato se houver alterações pendentes. Chamado pelo dialog ao fechar.
- `void addRulingItem()` — adiciona novo `FormControl<String>` ao `FormArray` de `ruling`.
- `void removeRulingItem(int index)` — remove item do `FormArray` se houver mais de 1 item.
- `void dispose()` — cancela debounce timer, descarta form listeners.

## Camada UI (Widgets Internos)

### `SaveStatusIndicator` *(novo arquivo em pasta nova)*

- **Localização:** `lib/ui/intake/widgets/components/save_status_indicator/`
- **Arquivos:** `save_status_indicator_view.dart`, `index.dart`
- **Base class:** `StatelessWidget`
- **Props:**
  - `required SaveStatus status` — enum `idle | saving | saved | error`
  - `VoidCallback? onRetry` — chamado ao tocar em "Erro ao salvar"
- **Estados visuais:**
  - `idle`: invisível (`SizedBox.shrink`)
  - `saving`: `Row` com `SizedBox(12x12, CircularProgressIndicator(strokeWidth: 1.5))` + `Text("Salvando...", bodySmall/textMuted)`
  - `saved`: `Row` com `Icon(Icons.check_circle_outline, size: 14, accent)` + `Text("Salvo", bodySmall/textMuted)`; auto-transiciona para `idle` após 3 segundos (controlado pelo consumidor)
  - `error`: `Row` com `Icon(Icons.error_outline, size: 14, error)` + `TextButton("Erro ao salvar. Tentar novamente", onRetry)`

### `DynamicListField` *(novo arquivo em pasta nova)*

- **Localização:** `lib/ui/intake/widgets/components/dynamic_list_field/`
- **Arquivos:** `dynamic_list_field_view.dart`, `index.dart`
- **Base class:** `StatelessWidget`
- **Props:**
  - `required FormArray<String> formArray` — o `FormArray` do `reactive_forms`
  - `required String itemLabel` — label base dos itens (ex: "Item do dispositivo")
  - `required String addLabel` — label do botão de adicionar (ex: "Adicionar item")
  - `int minItems` — mínimo de itens permitido (default: 1)
- **Visual:**
  - Lista de `ReactiveTextField` vinculados a cada `FormControl` do `FormArray`, com `IconButton(Icons.remove_circle_outline)` para remover (desabilitado quando `formArray.length <= minItems`).
  - Botão `TextButton.icon(Icons.add, addLabel)` no final para adicionar item.

---

# 6. O que deve ser modificado?

## UI

- **Arquivo:** `lib/ui/intake/widgets/pages/second_instance_analysis_screen/judgment_draft_dialog/judgment_draft_dialog_view.dart`
- **Mudança:** transformar de `StatelessWidget` sem presenter para `ConsumerStatefulWidget` com `JudgmentDraftDialogPresenter`. Substituir cada `DraftSection` com `Text` estático por `ReactiveTextField` multiline vinculado ao `FormControl` correspondente, preservando ícone e título de seção. Substituir a seção `ruling` (hoje loop de `Text`) por `DynamicListField` vinculado ao `FormArray`. Adicionar `SaveStatusIndicator` no header do dialog ao lado do título. Chamar `presenter.flush()` em `dispose()` e no handler de close/back. Manter `onRegenerate` funcional.

- **Arquivo:** `lib/ui/intake/widgets/pages/second_instance_analysis_screen/judgment_draft_dialog/draft_section/draft_section_view.dart`
- **Mudança:** adicionar prop opcional `Widget? editableContent` que, quando fornecido, substitui o `Text(content)` estático. Quando `editableContent == null`, mantém o comportamento read-only atual (fallback). Isso permite que o dialog passe `ReactiveTextField` sem quebrar outros possíveis consumidores do `DraftSection`.

- **Arquivo:** `lib/ui/intake/widgets/pages/second_instance_analysis_screen/second_instance_analysis_screen_view.dart`
- **Mudança:** ao abrir o dialog, passar callback `onDraftUpdated` que atualiza `presenter.judgmentDraft.value` com o DTO retornado a cada save.

- **Arquivo:** `lib/ui/intake/widgets/pages/second_instance_analysis_screen/second_instance_analysis_screen_presenter.dart`
- **Mudança:** expor método `void updateJudgmentDraftLocally(SecondInstanceJudgmentDraftDto dto)` que atualiza `judgmentDraft.value` sem chamada remota. Chamado pelo callback do dialog.

---

# 7. O que deve ser removido?

**Não aplicável.**

---

# 8. Decisões Técnicas e Trade-offs

- **Decisão:** auto-save com debounce de 1 segundo, sem botão "Salvar" explícito.
- **Alternativas consideradas:** botão "Salvar" manual; auto-save sem debounce (a cada keystroke).
- **Motivo da escolha:** auto-save elimina risco de perda de dados e alinha com o padrão definido no RF 09 para edição de minuta de petição (`PetitionDraftDialog`). Debounce de 1s equilibra responsividade e economia de requests.
- **Impactos / trade-offs:** gera mais requests ao server do que save manual, mas cada request é barato (PUT síncrono) e o debounce limita a frequência.

- **Decisão:** `reactive_forms` com `FormGroup` e `FormArray` no presenter do dialog.
- **Alternativas consideradas:** `TextEditingController` puro; `signals` com validação manual.
- **Motivo da escolha:** o projeto já usa `reactive_forms` para formulários com validação; o `FormArray` cobre nativamente o campo `ruling` sem lógica customizada de lista.
- **Impactos / trade-offs:** boilerplate de `reactive_forms`, compensado por validação declarativa e binding reativo.

- **Decisão:** `DraftSection` recebe prop opcional `editableContent` para modo editável.
- **Alternativas consideradas:** criar `EditableDraftSection` separado; duplicar o widget.
- **Motivo da escolha:** mantém um único componente sem duplicação, e o fallback garante compatibilidade caso `DraftSection` seja reutilizado em contexto read-only.
- **Impactos / trade-offs:** o widget fica levemente mais complexo (prop opcional), mas evita dois widgets quase idênticos.

- **Decisão:** `SaveStatusIndicator` e `DynamicListField` como componentes globais em `lib/ui/intake/widgets/components/`.
- **Alternativas consideradas:** widgets internos do `JudgmentDraftDialog` apenas.
- **Motivo da escolha:** o `PetitionDraftDialog` do fluxo de advogado precisa dos mesmos componentes (conforme `Ticket-Edicao-Minuta-Peticao-Mobile.md`). Globalizar agora evita duplicação futura.
- **Impactos / trade-offs:** adiciona dois componentes globais antes de haver dois consumidores reais, mas o segundo consumidor está previsto no roadmap imediato.

- **Decisão:** flush do auto-save ao fechar o dialog.
- **Alternativas consideradas:** descartar silenciosamente alterações pendentes; confirmar com dialog de "alterações não salvas".
- **Motivo da escolha:** o auto-save cria a expectativa de que tudo foi salvo; o flush garante essa promessa sem friccão. Dialog de confirmação seria inconsistente com a experiência de auto-save.
- **Impactos / trade-offs:** o close pode demorar até 10s se o save falhar (timeout), mas esse caso é raro e o indicador de status informa o usuário.

- **Decisão:** campos opcionais esvaziados enviam `null` no DTO.
- **Alternativas consideradas:** enviar string vazia; não enviar o campo.
- **Motivo da escolha:** alinhado ao contrato server onde `preliminary_issues` e `no_applicable_precedent_notice` são `str | None`.
- **Impactos / trade-offs:** o presenter precisa normalizar string vazia → `null` antes de montar o DTO.

---

# 9. Diagramas e Referências

### Fluxo de dados do auto-save

```text
JudgmentDraftDialogView
  -> ReactiveTextField.onChanged
      -> FormGroup.valueChanges (debounce 1s)
          -> JudgmentDraftDialogPresenter._autoSave()
              -> saveStatus = saving
              -> SecondInstanceJudgmentDraftDto.fromForm(...)
              -> IntakeService.updateSecondInstanceJudgmentDraft(analysisId, dto)
                  -> IntakeRestService
                      -> RestClient PUT /intake/analyses/{id}/second-instance-judgment-drafts
              <- RestResponse<SecondInstanceJudgmentDraftDto>
              -> saveStatus = saved
              -> onDraftUpdated(dto)
                  -> SecondInstanceAnalysisScreenPresenter.updateJudgmentDraftLocally(dto)
                      -> judgmentDraft.value = dto
```

### Fluxo de flush ao fechar

```text
JudgmentDraftDialogView.dispose()
  -> JudgmentDraftDialogPresenter.flush()
      -> cancela debounce timer
      -> se form.dirty && form.valid
          -> _autoSave() imediato
      -> retorna
```

### Mapeamento FormGroup → DTO

```text
FormGroup                              SecondInstanceJudgmentDraftDto
─────────────────────────────────      ──────────────────────────────
'report'              (String)    →    report
'preliminary_issues'  (String?)   →    preliminaryIssues     (null se vazio)
'merit_analysis'      (String)    →    meritAnalysis
'precedent_adherence' (String)    →    precedentAdherenceAnalysis
'ruling'              (String[])  →    ruling
'no_applicable_notice'(String?)   →    noApplicablePrecedentNotice (null se vazio)
analysisId (do contexto)          →    analysisId
```

### Seções do dialog e seus campos

| Seção visual | Ícone | FormControl | Obrigatório | Tipo |
|---|---|---|---|---|
| Relatório | `article_outlined` | `report` | Sim | `TextField` multiline |
| Questões Preliminares | `rule_folder_outlined` | `preliminary_issues` | Não | `TextField` multiline |
| Análise do Mérito | `balance_outlined` | `merit_analysis` | Sim | `TextField` multiline |
| Aderência aos Precedentes | `account_tree_outlined` | `precedent_adherence` | Sim | `TextField` multiline |
| Aviso | `info_outline` | `no_applicable_notice` | Não | `TextField` multiline |
| Dispositivo | `gavel_outlined` | `ruling` | Sim (min 1) | `DynamicListField` |

### Referências

- `lib/ui/intake/widgets/pages/second_instance_analysis_screen/judgment_draft_dialog/` — dialog alvo.
- `lib/ui/intake/widgets/pages/second_instance_analysis_screen/judgment_draft_dialog/draft_section/` — seção a adaptar.
- `lib/ui/intake/widgets/pages/second_instance_analysis_screen/judgment_draft_card/` — card de preview (não alterado).
- `lib/ui/intake/widgets/components/regenerate_draft_dialog/` — referência de dialog com presenter e `reactive_forms`.
- `lib/rest/mappers/intake/second_instance_judgment_draft_mapper.dart` — mapper reutilizado.
- `lib/core/intake/dtos/second_instance_judgment_draft_dto.dart` — DTO do contrato.
- `documentation/rules/ui-layer-rules.md` — regras de camada UI.
- `https://joaogoliveiragarcia.atlassian.net/wiki/spaces/ANM/pages/49348609` — PRD RF 08.

---

# 10. Pendências / Dúvidas

- **Descrição da pendência:** o endpoint `PUT /intake/analyses/{analysis_id}/second-instance-judgment-drafts` é responsabilidade de ticket server separado (`Ticket-Edicao-Minuta-Sentenca-2a-Instancia.md`).
- **Impacto na implementação:** a implementação mobile pode ser escrita contra o contrato esperado, mas a validação ponta a ponta depende do backend.
- **Ação sugerida:** validar com backend antes de mover para QA; se o contrato do PUT divergir, ajustar apenas `IntakeRestService`.

- **Descrição da pendência:** o `SaveStatusIndicator` será reutilizado no `PetitionDraftDialog` do fluxo de advogado. O design visual exato (posição no header, cores, transições) deve ser consistente entre os dois dialogs.
- **Impacto na implementação:** se o ticket de petição for implementado primeiro e criar o componente com visual diferente, será necessário alinhar.
- **Ação sugerida:** implementar o `SaveStatusIndicator` como componente global neste ticket; o ticket de petição reutiliza.

- **Descrição da pendência:** o `DynamicListField` será reutilizado no `PetitionDraftDialog` para o campo `requests` (que também é lista). Mesma lógica de globalização.
- **Impacto na implementação:** nenhum impacto se este ticket for implementado primeiro.
- **Ação sugerida:** criar como componente global neste ticket.

---

# 11. Restrições

- A `View` não deve conter lógica de negócio; toda orquestração de auto-save, debounce e validação fica no `Presenter`.
- Presenters não fazem chamadas diretas a `RestClient`; consomem `IntakeService`.
- Payload do PUT é montado em `IntakeRestService`, não na UI.
- Todos os caminhos citados existem no projeto ou estão marcados como **novo arquivo**.
- Widgets internos com responsabilidade própria foram organizados em pasta própria com `*_view.dart` e `index.dart`.
- A UI deve usar componentes Flutter Material alinhados ao tema existente (`AppThemeTokens`).
- Arquivos em `snake_case`, classes em `PascalCase`, providers e métodos em `camelCase`.
- O `JudgmentDraftCard` na tela principal **não** é alterado neste ticket — permanece read-only.
- O `DraftSection` deve manter compatibilidade com modo read-only via prop opcional.