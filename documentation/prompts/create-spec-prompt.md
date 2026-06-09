---
title: Edição manual da minuta de petição no PetitionDraftDialog
prd: ../prd.md
ticket: N/A
last_updated_at: 2026-06-05
status: draft
---

# 1. Objetivo

Tornar o `PetitionDraftDialog` (atualmente `PetitionDraftModal`, renomeado por padronização com `JudgmentDraftDialog`) editável, permitindo que o advogado edite cada campo da minuta diretamente no app com salvamento automático via debounce. Cada campo de texto é um `ReactiveTextField`, campos de lista (`requests` e `precedent_citations`) são renderizados como TextFields separados com opção de adicionar/remover itens. O dialog ganha presenter próprio com `FormGroup`, debounce e indicador discreto de salvamento no header.

---

# 2. Escopo

## 2.1 In-scope

- Renomear `PetitionDraftModal` → `PetitionDraftDialog` (pasta, arquivos, typedef, imports)
- Criar `PetitionDraftDialogPresenter` com `FormGroup` do `reactive_forms`, debounce e chamada ao endpoint de update
- Adicionar método `updatePetitionDraft(...)` ao `IntakeService`
- Implementar no `IntakeRestService`: `PUT /intake/analyses/{analysis_id}/petition-drafts` (status 200)
- Tornar cada seção da minuta editável com `ReactiveTextField`
- Campos de lista (`requests`, `precedent_citations`): cada item como `ReactiveTextField` separado + botões de adicionar/remover item
- Validação: nenhum campo vazio (strings não-blank, listas não-vazias, itens não-blank)
- Salvamento automático com debounce ao detectar mudança via `valueChanges`
- Indicador discreto no header do dialog ("Salvo" ✓ / "Salvando..." ↻ / "Erro" ✕)
- Criar widgets internos reutilizáveis: `DynamicListField`, `SaveStatusIndicator`
- Atualizar `PetitionDraftCard` na screen para refletir edições ao fechar o dialog

## 2.2 Out-of-scope

- Regeneração da minuta com comentários (já existe, coberta em ANI-127)
- Exportação DOCX (ticket separado)
- Backend / endpoint `PUT /petition-drafts` (já implementado)
- Edição da minuta de sentença de 2ª instância (ticket separado)
- Testes automatizados

---

# 3. Requisitos

## 3.1 Funcionais

- Cada seção da minuta (`structuredFacts`, `legalGrounds`, `centralThesis`, `requests`, `precedentCitations`) deve ser editável individualmente no dialog fullscreen.
- Campos de texto: `ReactiveTextField` multilinha.
- Campos de lista: cada item como `TextField` separado, com botões de adicionar novo item e remover item existente.
- Remoção de item de lista bloqueada quando restar apenas 1 item.
- Nenhum campo pode ficar vazio — validação inline com mensagem de erro.
- Alterações são salvas automaticamente com debounce (~2s), sem ação explícita do advogado.
- Indicador discreto no header reflete o estado de salvamento: idle, salvando, salvo, erro.
- Regeneração com comentários sobrescreve todas as edições manuais com aviso prévio (comportamento existente, sem mudança).
- Ao fechar o dialog, o `PetitionDraftCard` na screen deve refletir as edições.

## 3.2 Não funcionais

Não aplicável.

---

# 4. O que já existe?

## Core

- **`PetitionDraftDto`** (`lib/core/intake/dtos/petition_draft_dto.dart`) — DTO com `analysisId`, `structuredFacts`, `legalGrounds`, `centralThesis`, `requests`, `precedentCitations`.
- **`IntakeService`** (`lib/core/intake/interfaces/intake_service.dart`) — contrato com `getPetitionDraft(...)`. Não possui `updatePetitionDraft(...)` ainda.

## REST

- **`IntakeRestService`** (`lib/rest/services/intake_rest_service.dart`) — implementação HTTP do `IntakeService`.
- **`PetitionDraftMapper`** (`lib/rest/mappers/intake/petition_draft_mapper.dart`) — mapper existente para `PetitionDraftDto` (snake_case ↔ camelCase).

## UI

- **`PetitionDraftModalView`** (`lib/ui/intake/widgets/pages/case_assessment_analysis_screen/petition_draft_modal/petition_draft_modal_view.dart`) — `StatelessWidget` somente leitura. Renderiza `Scaffold` fullscreen com `_buildSection` (texto) e `_buildListSection` (listas). Props: `draft: PetitionDraftDto`, `onRegenerate: Future<bool> Function()?`.
- **`PetitionDraftModal` typedef** (`lib/ui/intake/widgets/pages/case_assessment_analysis_screen/petition_draft_modal/index.dart`) — `typedef PetitionDraftModal = PetitionDraftModalView`.
- **`PetitionDraftCardView`** (`lib/ui/intake/widgets/pages/case_assessment_analysis_screen/petition_draft_card/petition_draft_card_view.dart`) — card visual com preview truncado e botão "Ver minuta" que abre o dialog.
- **`CaseAssessmentAnalysisScreenView`** (`lib/ui/intake/widgets/pages/case_assessment_analysis_screen/case_assessment_analysis_screen_view.dart`) — view da tela; método `_showPetitionDraftModal(...)` abre o dialog via `Navigator.push` com `fullscreenDialog: true`.
- **`CaseAssessmentAnalysisScreenPresenter`** (`lib/ui/intake/widgets/pages/case_assessment_analysis_screen/case_assessment_analysis_screen_presenter.dart`) — presenter da tela; possui `petitionDraft: Signal<PetitionDraftDto?>` e `_tryLoadPetitionDraft()`.
- **`JudgmentDraftDialogView`** (`lib/ui/intake/widgets/pages/second_instance_analysis_screen/judgment_draft_dialog/judgment_draft_dialog_view.dart`) — referência de padrão visual para o dialog editável; usa `DraftSection` widget para cada seção.

---

# 5. O que deve ser criado?

## Camada Core (Interfaces / Contratos)

- **Arquivo:** `lib/core/intake/interfaces/intake_service.dart` (**modificação**)
- **Método novo:**
  - `Future<RestResponse<PetitionDraftDto>> updatePetitionDraft({required String analysisId, required PetitionDraftDto draft})` — envia o draft completo para o backend via PUT e retorna o draft atualizado.

## Camada REST (Services)

- **Arquivo:** `lib/rest/services/intake_rest_service.dart` (**modificação**)
- **Método novo:**
  - `Future<RestResponse<PetitionDraftDto>> updatePetitionDraft({required String analysisId, required PetitionDraftDto draft})` — chama `PUT /intake/analyses/$analysisId/petition-drafts` com body mapeado via `PetitionDraftMapper.toJson(draft)`, retorna `toResponse(response, PetitionDraftMapper.toDto)`.

## Camada UI (Presenters)

### `PetitionDraftDialogPresenter`

- **Localização:** `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/petition_draft_dialog/petition_draft_dialog_presenter.dart` (**novo arquivo**)
- **Dependências injetadas:** `IntakeService`, `analysisId: String`, `initialDraft: PetitionDraftDto`
- **Estado (`signals`):**
  - `requests: Signal<List<String>>` — inicializado com `initialDraft.requests`
  - `precedentCitations: Signal<List<String>>` — inicializado com `initialDraft.precedentCitations`
  - `saveStatus: Signal<SaveStatus>` — enum `idle`, `saving`, `saved`, `error`
- **FormGroup (`reactive_forms`):**

```dart
FormGroup({
  'structuredFacts': FormControl<String>(
    value: initialDraft.structuredFacts,
    validators: [Validators.required],
  ),
  'legalGrounds': FormControl<String>(
    value: initialDraft.legalGrounds,
    validators: [Validators.required],
  ),
  'centralThesis': FormControl<String>(
    value: initialDraft.centralThesis,
    validators: [Validators.required],
  ),
});
```

- **Provider:** `petitionDraftDialogPresenterProvider` (`Provider.autoDispose.family<PetitionDraftDialogPresenter, ({String analysisId, PetitionDraftDto initialDraft})>`)
- **Métodos:**
  - `void init()` — escuta `form.valueChanges` e mudanças nos signals de listas com debounce (~2s); dispara `_save()` automaticamente.
  - `Future<void> _save()` — valida `form.valid` e listas não-vazias com itens não-blank; se válido, seta `saveStatus = saving`, monta `PetitionDraftDto` completo, chama `IntakeService.updatePetitionDraft(...)`, seta `saveStatus = saved`; se falha, seta `saveStatus = error`.
  - `void addRequest()` — adiciona string vazia à lista `requests`.
  - `void removeRequest(int index)` — remove item no índice (bloqueado se `requests.length == 1`).
  - `void updateRequest(int index, String value)` — atualiza item no índice.
  - `void addPrecedentCitation()` — adiciona string vazia à lista `precedentCitations`.
  - `void removePrecedentCitation(int index)` — remove item no índice (bloqueado se `precedentCitations.length == 1`).
  - `void updatePrecedentCitation(int index, String value)` — atualiza item no índice.
  - `PetitionDraftDto get currentDraft` — monta o `PetitionDraftDto` a partir do estado atual do form + listas.
  - `void dispose()` — cancela subscriptions do debounce.

## Camada UI (Views)

### `PetitionDraftDialogView`

- **Localização:** `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/petition_draft_dialog/petition_draft_dialog_view.dart` (**substituição de `petition_draft_modal_view.dart`**)
- **Base class:** `ConsumerStatefulWidget`
- **Props:** `final String analysisId`, `final PetitionDraftDto initialDraft`, `final Future<bool> Function()? onRegenerate`
- **Bibliotecas de UI:** `flutter_riverpod`, `signals_flutter`, `reactive_forms`
- **Estados visuais:**
  - **Content:** formulário editável com todas as seções + `SaveStatusIndicator` no header
  - **Error de save:** `SaveStatusIndicator` exibe "Erro ao salvar"; formulário permanece editável

## Camada UI (Widgets Internos)

### `DynamicListField`

- **Localização:** `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/petition_draft_dialog/dynamic_list_field/` (**novo arquivo**)
- **Arquivos:** `index.dart`, `dynamic_list_field_view.dart`
- **Tipo:** `View only`
- **Props:**
  - `final List<String> items`
  - `final ValueChanged<int> onRemove`
  - `final void Function(int index, String value) onUpdate`
  - `final VoidCallback onAdd`
  - `final String addLabel` — ex: "Adicionar pedido"
  - `final bool canRemove` — `true` se `items.length > 1`
- **Responsabilidade:** renderiza N `TextField` verticais, cada um com botão de remover (ícone X, desabilitado se `canRemove == false`). Botão "Adicionar" no final da lista. Validação inline: borda de erro se o item estiver vazio.

### `SaveStatusIndicator`

- **Localização:** `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/petition_draft_dialog/save_status_indicator/` (**novo arquivo**)
- **Arquivos:** `index.dart`, `save_status_indicator_view.dart`
- **Tipo:** `View only`
- **Props:** `final SaveStatus status`
- **Responsabilidade:** ícone discreto no `AppBar`:
  - `idle` — não exibe nada
  - `saving` — `SizedBox(16x16)` com `CircularProgressIndicator` + texto "Salvando..."
  - `saved` — ícone ✓ com texto "Salvo" (desaparece após ~3s via `Timer`)
  - `error` — ícone ✕ com texto "Erro ao salvar" em `tokens.danger`

## Camada UI (Barrel Files / `index.dart`)

### `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/petition_draft_dialog/index.dart`

- **Localização:** (**substituição de `petition_draft_modal/index.dart`**)
- **`typedef` exportado:** `typedef PetitionDraftDialog = PetitionDraftDialogView`
- **Exports:** `PetitionDraftDialogPresenter`, `petitionDraftDialogPresenterProvider`

## Estrutura de Pastas

```text
lib/ui/intake/widgets/pages/case_assessment_analysis_screen/
  petition_draft_dialog/                            ← renomeado de petition_draft_modal/
    index.dart                                      ← atualizado
    petition_draft_dialog_view.dart                  ← substituição de petition_draft_modal_view.dart
    petition_draft_dialog_presenter.dart             ← NOVO
    dynamic_list_field/                             ← NOVO
      index.dart
      dynamic_list_field_view.dart
    save_status_indicator/                          ← NOVO
      index.dart
      save_status_indicator_view.dart
```

---

# 6. O que deve ser modificado?

## Camada Core

- **Arquivo:** `lib/core/intake/interfaces/intake_service.dart`
- **Mudança:** adicionar contrato `updatePetitionDraft(...)`.
- **Justificativa:** presenter consome interface do `core`, não `RestClient`.

## Camada REST

- **Arquivo:** `lib/rest/services/intake_rest_service.dart`
- **Mudança:** implementar `updatePetitionDraft(...)` — `PUT /intake/analyses/$analysisId/petition-drafts`.
- **Justificativa:** endpoint já disponível no backend.

## Camada UI

- **Arquivo:** `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/case_assessment_analysis_screen_view.dart`
- **Mudança:** renomear referência de `PetitionDraftModal` para `PetitionDraftDialog`; atualizar `_showPetitionDraftModal` para `_showPetitionDraftDialog`; passar `analysisId` como prop adicional; ao retorno do `Navigator.pop`, chamar `presenter._tryLoadPetitionDraft()` para recarregar o draft editado.
- **Justificativa:** o dialog agora edita o draft; ao fechar, o card precisa refletir as mudanças.

- **Arquivo:** `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/case_assessment_analysis_screen_presenter.dart`
- **Mudança:** expor `reloadPetitionDraft()` como método público (wrapper de `_tryLoadPetitionDraft`) para que a view chame ao fechar o dialog.
- **Justificativa:** `_tryLoadPetitionDraft` é privado; a view precisa de acesso público.

- **Arquivo:** `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/petition_draft_card/petition_draft_card_view.dart`
- **Mudança:** atualizar referência de `PetitionDraftModal` para `PetitionDraftDialog` nos imports.
- **Justificativa:** rename de consistência.

---

# 7. O que deve ser removido?

## Camada UI

- **Arquivo:** `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/petition_draft_modal/petition_draft_modal_view.dart`
- **Motivo da remoção:** substituído por `petition_draft_dialog/petition_draft_dialog_view.dart`.
- **Impacto esperado:** atualizar imports em `case_assessment_analysis_screen_view.dart` e `petition_draft_card_view.dart`.

- **Arquivo:** `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/petition_draft_modal/index.dart`
- **Motivo da remoção:** substituído por `petition_draft_dialog/index.dart`.
- **Impacto esperado:** atualizar typedef de `PetitionDraftModal` para `PetitionDraftDialog`.

---

# 8. Decisões Técnicas e Trade-offs

## 8.1 `reactive_forms` para campos de texto, signals para listas

- **Decisão:** usar `FormGroup` do `reactive_forms` para os 3 campos de texto (`structuredFacts`, `legalGrounds`, `centralThesis`) e `Signal<List<String>>` para os 2 campos de lista (`requests`, `precedentCitations`).
- **Alternativas consideradas:** (a) `reactive_forms` para tudo, incluindo listas com `FormArray`; (b) signals para tudo, sem `reactive_forms`.
- **Motivo da escolha:** `FormArray` do `reactive_forms` adiciona complexidade para listas dinâmicas com add/remove; signals são mais diretos para listas mutáveis. Os campos de texto se beneficiam de `validationMessages` declarativos do `reactive_forms`. Abordagem híbrida equilibra simplicidade e validação.
- **Impactos / trade-offs:** o debounce precisa escutar dois streams (form.valueChanges + signal effects), mas a lógica no presenter permanece enxuta.

## 8.2 PUT com draft completo em vez de PATCH parcial

- **Decisão:** o mobile envia o draft inteiro a cada save (debounce), não apenas o campo alterado.
- **Alternativas consideradas:** PATCH parcial por campo.
- **Motivo da escolha:** alinhado com o contrato do backend (`PUT` com `PetitionDraftDto` completo); simplifica o presenter (não precisa rastrear qual campo mudou); `PetitionDraftsRepository.replace(...)` já faz update completo.
- **Impactos / trade-offs:** payload maior por request, mas o draft tem ~5 campos — overhead negligível.

## 8.3 Rename `PetitionDraftModal` → `PetitionDraftDialog`

- **Decisão:** renomear para alinhar com `JudgmentDraftDialog` da 2ª instância.
- **Alternativas consideradas:** manter `Modal`.
- **Motivo da escolha:** padronização de nomenclatura — ambos são fullscreen dialogs via `Navigator.push(fullscreenDialog: true)`.
- **Impactos / trade-offs:** rename de pasta, arquivos, typedef e imports; impacto localizado na tela de Case Assessment.

## 8.4 Presenter próprio no dialog

- **Decisão:** `PetitionDraftDialogPresenter` separado do `CaseAssessmentAnalysisScreenPresenter`.
- **Alternativas consideradas:** lógica de edição no presenter da screen.
- **Motivo da escolha:** o dialog é fullscreen com ciclo de vida próprio (`Navigator.push/pop`); o `FormGroup`, debounce e save status são responsabilidades isoladas que não devem poluir o presenter da screen.
- **Impactos / trade-offs:** ao fechar o dialog, a screen precisa recarregar o draft via `reloadPetitionDraft()`.

---

# 9. Diagramas e Referências

## 9.1 Fluxo de dados

```text
PetitionDraftDialogView
  → PetitionDraftDialogPresenter
      → petitionDraftDialogPresenterProvider
          → form.valueChanges + signals (debounce ~2s)
          → IntakeService.updatePetitionDraft(...)
              → IntakeRestService
                  → RestClient.put('/intake/analyses/$id/petition-drafts')
          → saveStatus signal (idle → saving → saved | error)

CaseAssessmentAnalysisScreenView
  → Navigator.push(PetitionDraftDialog)
  → await Navigator.pop
  → presenter.reloadPetitionDraft()
      → IntakeService.getPetitionDraft(...)
      → petitionDraft.value = response.body
```

## 9.2 Hierarquia de widgets

```text
PetitionDraftDialogView (ConsumerStatefulWidget)
  Scaffold
    AppBar
      título "Minuta de petição"
      SaveStatusIndicator(status: presenter.saveStatus)
      TextButton.icon "Regerar minuta" (quando onRegenerate != null)
    SingleChildScrollView
      ReactiveForm(formGroup: presenter.form)
        SectionLabel("Fatos estruturados")
        ReactiveTextField(formControlName: 'structuredFacts', minLines: 5, maxLines: null)

        SectionLabel("Fundamentos jurídicos")
        ReactiveTextField(formControlName: 'legalGrounds', minLines: 5, maxLines: null)

        SectionLabel("Tese central")
        ReactiveTextField(formControlName: 'centralThesis', minLines: 3, maxLines: null)

        SectionLabel("Pedidos")
        Watch → DynamicListField(items: presenter.requests, ...)

        SectionLabel("Citações de precedentes")
        Watch → DynamicListField(items: presenter.precedentCitations, ...)
```

## 9.3 Referências

- `lib/ui/intake/widgets/pages/second_instance_analysis_screen/judgment_draft_dialog/judgment_draft_dialog_view.dart` — referência visual do dialog fullscreen com seções (`DraftSection`).
- `lib/ui/intake/widgets/components/regenerate_draft_dialog/regenerate_draft_dialog_view.dart` — referência de dialog com `TextField` + presenter com validação + signals.
- `lib/ui/auth/widgets/pages/sign_up_screen/sign_up_form/sign_up_form_view.dart` — referência de `ReactiveForm` + `ReactiveTextField` + `validationMessages`.

---

# 10. Pendências / Dúvidas

Sem pendências.

---

# Restrições

- A `View` não contém lógica de negócio — toda orquestração fica no `Presenter`.
- O `Presenter` consome apenas a interface `IntakeService`, nunca `RestClient` diretamente.
- Nomes de arquivos em `snake_case`; classes em `PascalCase`; presenters, providers, métodos em `camelCase`.
- Strings da UI em PT-BR acentuadas, alinhadas ao padrão do app.
- Todo widget novo segue `View + Presenter`; o `Presenter` é opcional apenas em widgets puramente visuais.
- Cada widget interno tem seu próprio `index.dart` com `typedef`.
- Não inclua testes automatizados.