prd: https://joaogoliveiragarcia.atlassian.net/wiki/x/AYDsAg
ticket: N/A
Status: closed
Última atualização: 2026-06-06

# Edição manual da minuta de petição no PetitionDraftDialog (mobile)

## Objetivo

Tornar o `PetitionDraftDialog` editável, permitindo que o advogado edite cada campo da minuta diretamente no app com salvamento automático via debounce. Cada campo de texto é um `ReactiveTextField`, campos de lista (`requests` e `precedent_citations`) são renderizados como TextFields separados com opção de adicionar/remover itens. O dialog ganha presenter próprio com `FormGroup`, debounce e indicador discreto de salvamento no header.

---

## Escopo

### In-scope

- Criar `PetitionDraftDialogPresenter` com `FormGroup` do `reactive_forms`, debounce e chamada ao endpoint de update
- Adicionar método `updatePetitionDraft(...)` ao `IntakeService`
- Implementar no `IntakeRestService`: `PUT /intake/analyses/{analysis_id}/petition-drafts` (status 200)
- Tornar cada seção da minuta editável com `ReactiveTextField`
- Campos de lista (`requests`, `precedent_citations`): cada item como `ReactiveTextField` separado + botões de adicionar/remover item
- Validação: nenhum campo vazio (strings não-blank, listas não-vazias, itens não-blank)
- Salvamento automático com debounce ao detectar mudança via `valueChanges`
- Indicador discreto no header do dialog (ex.: ícone "Salvo" / "Salvando...")
- Atualizar `PetitionDraftCard` na screen para refletir edições ao fechar o dialog

### Out-of-scope

- Regeneração da minuta com comentários (já existe)
- Exportação DOCX (ticket separado)
- Backend (endpoint já implementado)
- Edição da minuta de sentença de 2ª instância (ticket separado)

---

## Contrato REST (server já implementado)

```python
# PUT /intake/analyses/{analysis_id}/petition-drafts
# Status: 200
# Body (snake_case):
structured_facts: str        # min_length=1, não-blank
legal_grounds: str            # min_length=1, não-blank
central_thesis: str           # min_length=1, não-blank
requests: list[str]           # não-vazia, itens não-blank
precedent_citations: list[str] # não-vazia, itens não-blank

# Response: PetitionDraftDto
```

---

## PetitionDraftDialogPresenter (novo)

- **Localização:** `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/petition_draft_dialog/petition_draft_dialog_presenter.dart`
- **Dependências:** `IntakeService`, `analysisId: String`, `initialDraft: PetitionDraftDto`
- **FormGroup:**

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

- **Estado para listas (signals):**
  - `requests: Signal<List<String>>` — inicializado com `initialDraft.requests`
  - `precedentCitations: Signal<List<String>>` — inicializado com `initialDraft.precedentCitations`
  - Métodos: `addRequest()`, `removeRequest(int index)`, `updateRequest(int index, String value)` (idem para `precedentCitations`)

- **Salvamento:**
  - `saveStatus: Signal<SaveStatus>` — enum `idle`, `saving`, `saved`, `error`
  - Escuta `form.valueChanges` + mudanças nas listas via signals com debounce (~2s)
  - Ao disparar save: valida que `form.valid`, todas as listas não-vazias e itens não-blank
  - Se válido: seta `saveStatus = saving`, chama `IntakeService.updatePetitionDraft(...)` com o draft completo, seta `saveStatus = saved`
  - Se inválido: não salva, exibe validação inline nos campos
  - Se falha no request: seta `saveStatus = error`

- **Provider:** `petitionDraftDialogPresenterProvider` (`Provider.autoDispose.family`)

---

## PetitionDraftDialogView (atualizado)

- **Antes:** `View only` — renderizava `draft.content` em `SingleChildScrollView`
- **Agora:** `ConsumerStatefulWidget` com presenter, `ReactiveForm`, campos editáveis e indicador de save

### Hierarquia de widgets

```
PetitionDraftDialogView
  Scaffold
    AppBar
      título "Minuta de petição"
      SaveStatusIndicator (ícone discreto: "Salvo" ✓ / "Salvando..." ↻ / "Erro" ✕)
    SingleChildScrollView
      ReactiveForm(formGroup: presenter.form)
        SectionLabel("Fatos estruturados")
        ReactiveTextField(formControlName: 'structuredFacts', multilinha)

        SectionLabel("Fundamentos jurídicos")
        ReactiveTextField(formControlName: 'legalGrounds', multilinha)

        SectionLabel("Tese central")
        ReactiveTextField(formControlName: 'centralThesis', multilinha)

        SectionLabel("Pedidos")
        DynamicListField(
          items: presenter.requests
          onAdd: presenter.addRequest
          onRemove: presenter.removeRequest
          onUpdate: presenter.updateRequest
        )

        SectionLabel("Citações de precedentes")
        DynamicListField(
          items: presenter.precedentCitations
          onAdd: presenter.addPrecedentCitation
          onRemove: presenter.removePrecedentCitation
          onUpdate: presenter.updatePrecedentCitation
        )
```

### DynamicListField (widget novo)

Renderiza N `TextField` verticais, cada um com botão de remover (ícone X). Botão "Adicionar" no final da lista. Validação inline: erro se o item estiver vazio. Remoção bloqueada se restar apenas 1 item.

### SaveStatusIndicator (widget novo)

Ícone discreto no `AppBar` que reflete `saveStatus`:
- `idle` — não exibe nada
- `saving` — ícone de loading pequeno ou texto "Salvando..."
- `saved` — ícone ✓ com texto "Salvo" (desaparece após alguns segundos)
- `error` — ícone ✕ com texto "Erro ao salvar"

---

## Atualização do PetitionDraftCard na Screen

Ao fechar o dialog, o presenter da screen precisa recarregar o `PetitionDraftDto` atualizado via `IntakeService.getPetitionDraft(...)` para refletir as edições no card de preview.

---

## Estrutura de pastas atualizada

```
petition_draft_dialog/
  index.dart
  petition_draft_dialog_view.dart
  petition_draft_dialog_presenter.dart       ← NOVO
  dynamic_list_field/                       ← NOVO
    index.dart
    dynamic_list_field_view.dart
  save_status_indicator/                    ← NOVO
    index.dart
    save_status_indicator_view.dart
```

---

## Critérios de aceite

- [ ] Dialog abre com todos os campos preenchidos a partir do draft atual
- [ ] Campos de texto (`structuredFacts`, `legalGrounds`, `centralThesis`) são editáveis com `ReactiveTextField`
- [ ] Campos de lista (`requests`, `precedentCitations`) exibem cada item em TextField separado
- [ ] Botão "Adicionar" insere novo item vazio na lista
- [ ] Botão "Remover" remove o item da lista (bloqueado se restar apenas 1 item)
- [ ] Validação inline: campo vazio exibe erro, item de lista vazio exibe erro
- [ ] Alteração em qualquer campo dispara save automático com debounce
- [ ] Header exibe indicador discreto: "Salvando..." durante o PUT, "Salvo" após sucesso
- [ ] Erro no PUT exibe "Erro ao salvar" no header sem perder os dados editados
- [ ] Save não é disparado se o form estiver inválido (campo ou item vazio)
- [ ] Ao fechar o dialog, o `PetitionDraftCard` na screen reflete as edições
- [ ] Regeneração com comentários continua funcionando e sobrescreve edições manuais com aviso prévio
