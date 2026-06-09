---
title: Plano de Implementação — Edição manual da minuta de sentença
spec: [documentation/features/intake/second-instance-analysis/second-instance-judgment-draft-edition-spec.md](documentation/features/intake/second-instance-analysis/second-instance-judgment-draft-edition-spec.md)
created_at: 2026-06-06
status: closed
---

---

## Análise de Dependências

### Artefatos do `core` que desbloqueiam outras camadas
- O único novo pré-requisito real de `core` é o método `IntakeService.updateSecondInstanceJudgmentDraft(...)` em `lib/core/intake/interfaces/intake_service.dart`.
- `SecondInstanceJudgmentDraftDto` já existe em `lib/core/intake/dtos/second_instance_judgment_draft_dto.dart` e já desbloqueia tanto `rest` quanto `ui`; não há necessidade de criar novo DTO.
- `RestResponse<T>` já existe em `lib/core/shared/responses/rest_response.dart` e já atende o contrato do novo `PUT`.
- Não há necessidade de novos enums de domínio, erros de domínio ou wrappers adicionais no `core` para esta feature.

### Partes de `rest` e `drivers` independentes entre si
- `IntakeRestService.updateSecondInstanceJudgmentDraft(...)` é independente de `drivers`; ele só depende do contrato novo em `IntakeService` e do DTO já existente.
- O payload do `PUT` pode ser montado localmente em `lib/rest/services/intake_rest_service.dart`, seguindo as regras da camada REST; não há dependência de mapper novo para request.
- O mapper `SecondInstanceJudgmentDraftMapper.toDto` já existe e pode ser reutilizado isoladamente na resposta do `PUT`.
- Não há nova entrega em `drivers` para esta feature. Exportação continua usando drivers já existentes no presenter atual, sem exigir novo contrato ou adaptação de plataforma.
- Impactos transversais: não há mudança em `go_router`, `lib/router.dart`, `lib/app.dart`, `lib/main.dart` nem em cache local; o único ponto de navegação afetado é o fechamento do dialog fullscreen com `flush` antes do `pop`.

### Presenters/widgets/screens paralelizáveis
- `JudgmentDraftDialogPresenter` pode ser evoluído em paralelo ao `IntakeRestService`, desde que o contrato de `core` já exista; o save remoto pode começar com fake/stub.
- `DraftSection` pode ser adaptado para `editableContent` em paralelo ao trabalho do presenter, porque é uma alteração visual isolada.
- A extração/globalização de `SaveStatusIndicator` pode ocorrer em paralelo ao `rest` e ao presenter da segunda instância.
- A extração/globalização de `DynamicListField` também pode ocorrer em paralelo ao `rest` e ao presenter, desde que a API pública do componente seja definida.
- `SecondInstanceAnalysisScreenPresenter.updateJudgmentDraftLocally(...)` pode ser implementado em paralelo ao dialog editável.
- O encadeamento do callback entre `SecondInstanceAnalysisScreenView` e `JudgmentDraftCardView` pode começar antes da implementação real do autosave, desde que a assinatura de `onDraftUpdated` esteja definida.
- Observação importante da codebase atual: o `JudgmentDraftDialogPresenter` já existe, mas hoje é focado em exportação; o plano deve tratá-lo como expansão/refatoração, não como criação do zero.
- Observação importante da codebase atual: `SaveStatusIndicator` e `DynamicListField` já existem no fluxo `petition_draft_dialog`; para evitar duplicação, a entrega deve priorizar extração/globalização desses componentes.

### Tarefas iniciáveis com stub
- `JudgmentDraftDialogPresenter` pode ser iniciado com stub/fake de `IntakeService.updateSecondInstanceJudgmentDraft(...)` após `F1-T1`.
- `JudgmentDraftDialogView` pode ser iniciado com o presenter fake e com `SecondInstanceJudgmentDraftDto` já existente, sem aguardar a implementação real do `PUT`.
- O fluxo de sincronização local (`updateJudgmentDraftLocally` + callback `onDraftUpdated`) pode ser iniciado com callback fake, sem aguardar `rest`.
- A adaptação de `DraftSection` é totalmente independente de backend.
- A globalização de `SaveStatusIndicator` e `DynamicListField` pode ser iniciada sem aguardar `core`, `rest` ou `drivers`.

---

## ⚠️ Gargalos identificados

- **F1-T1 — estender `IntakeService`**: bloqueia 2 tarefas críticas (`F2-T1` e `F4-T1`); deve ser iniciada primeiro.
- **F4-T1 — expandir `JudgmentDraftDialogPresenter`**: bloqueia 3 tarefas da UI (`F5-T2`, `F7-T2` e a integração real do autosave); deve começar assim que `F1-T1` terminar.
- **F3-T1/F3-T2 — globalizar componentes compartilhados de UI**: bloqueiam a composição final do dialog editável sem duplicação de código; devem ocorrer cedo em paralelo com `rest`.

---

## Mapa de Paralelização

| Fase | Objetivo | Depende de | Pode rodar em paralelo com |
|------|----------|------------|----------------------------|
| F1 | Estabilizar o contrato do `core` para edição da minuta | - | F3, F6 |
| F2 | Implementar o `PUT` no adaptador REST | F1 | F3, F4, F6 |
| F3 | Globalizar componentes compartilhados de UI já existentes no fluxo de petição | - | F1, F2, F4, F6 |
| F4 | Reestruturar o `JudgmentDraftDialogPresenter` para formulário e auto-save | F1 | F2, F3, F6 |
| F5 | Tornar o dialog de segunda instância editável | F3, F4 | F6 |
| F6 | Expor atualização local do `judgmentDraft` na tela principal | - | F1, F2, F3, F4, F5 |
| F7 | Encadear o callback de atualização até o ponto real de abertura do dialog | F5, F6 | - |

---

## Fases e Tarefas

### F1 — Estabilizar o contrato do `core` para edição da minuta

- [x] **F1-T1** — Estender `IntakeService` com `updateSecondInstanceJudgmentDraft({ required String analysisId, required SecondInstanceJudgmentDraftDto dto })`
  - Camada: `core`
  - Artefatos: `lib/core/intake/interfaces/intake_service.dart` *(alterado)*
  - Depende de: —
  - Desbloqueia: F2-T1, F4-T1
  - Concluído em: 2026-06-06

### F2 — Implementar o `PUT` no adaptador REST

- [x] **F2-T1** — Implementar `updateSecondInstanceJudgmentDraft(...)` em `IntakeRestService`, montando payload `snake_case` no próprio service e reutilizando `SecondInstanceJudgmentDraftMapper.toDto` para a resposta
  - Camada: `rest`
  - Artefato: `lib/rest/services/intake_rest_service.dart`
  - Depende de: F1-T1
  - Desbloqueia: integração real do autosave em F4-T1 e validação funcional do fluxo em F5-T2
  - Artefatos: `lib/rest/services/intake_rest_service.dart` *(alterado)*, `documentation/features/intake/second-instance-analysis/second-instance-judgment-draft-edition-plan.md` *(alterado)*
  - Concluído em: 2026-06-06

### F3 — Globalizar componentes compartilhados de UI já existentes no fluxo de petição

- [x] **F3-T1** — Extrair `SaveStatus` para um contrato compartilhado de UI e criar `SaveStatusIndicator` global desacoplado de `petition_draft_dialog`
  - Camada: `ui`
  - Artefato: `lib/ui/intake/widgets/components/save_status_indicator/save_status_indicator_view.dart`
  - Depende de: —
  - Desbloqueia: F3-T2, F5-T2
  - Artefatos: `lib/ui/intake/widgets/components/save_status_indicator/save_status.dart` *(novo)*, `lib/ui/intake/widgets/components/save_status_indicator/save_status_indicator_view.dart` *(novo)*, `lib/ui/intake/widgets/components/save_status_indicator/index.dart` *(novo)*, `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/petition_draft_dialog/petition_draft_dialog_presenter.dart` *(alterado)*, `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/petition_draft_dialog/dialog_header/petition_draft_dialog_header_presenter.dart` *(alterado)*
  - Concluído em: 2026-06-06

- [x] **F3-T2** — Migrar o fluxo `petition_draft_dialog` para consumir o `SaveStatusIndicator` global, preservando o comportamento visual e o auto-hide atual
  - Camada: `ui`
  - Artefato: `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/petition_draft_dialog/dialog_header/petition_draft_dialog_header_view.dart`
  - Depende de: F3-T1
  - Desbloqueia: F5-T2
  - Artefatos: `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/petition_draft_dialog/dialog_header/petition_draft_dialog_header_view.dart` *(alterado)*
  - Concluído em: 2026-06-06

- [x] **F3-T3** — Criar `DynamicListField` global reutilizável para listas editáveis e alinhar sua API ao uso esperado no dialog de segunda instância
  - Camada: `ui`
  - Artefato: `lib/ui/intake/widgets/components/dynamic_list_field/dynamic_list_field_view.dart`
  - Depende de: —
  - Desbloqueia: F5-T2
  - Artefatos: `lib/ui/intake/widgets/components/dynamic_list_field/dynamic_list_field_view.dart` *(novo)*, `lib/ui/intake/widgets/components/dynamic_list_field/index.dart` *(novo)*, `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/petition_draft_dialog/dialog_form/petition_draft_dialog_form_view.dart` *(alterado)*, `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/petition_draft_dialog/index.dart` *(alterado)*
  - Concluído em: 2026-06-06

### F4 — Reestruturar o `JudgmentDraftDialogPresenter` para formulário e auto-save

- [x] **F4-T1** — Expandir o `JudgmentDraftDialogPresenter` existente para incluir `FormGroup`, debounce, `flush`, validação inline, `SaveStatus`, retry manual, sincronização com `onDraftUpdated` e preservação do fluxo atual de exportação
  - Camada: `ui`
  - Artefato: `lib/ui/intake/widgets/pages/second_instance_analysis_screen/judgment_draft_dialog/judgment_draft_dialog_presenter.dart`
  - Depende de: F1-T1
  - Desbloqueia: F5-T2, F7-T2
  - Artefatos: `lib/ui/intake/widgets/pages/second_instance_analysis_screen/judgment_draft_dialog/judgment_draft_dialog_presenter.dart` *(alterado)*, `lib/ui/intake/widgets/pages/second_instance_analysis_screen/judgment_draft_dialog/judgment_draft_dialog_view.dart` *(alterado)*
  - Concluído em: 2026-06-06

### F5 — Tornar o dialog de segunda instância editável

- [x] **F5-T1** — Adaptar `DraftSection` para aceitar `editableContent` opcional, mantendo fallback read-only para não quebrar consumidores existentes
  - Camada: `ui`
  - Artefato: `lib/ui/intake/widgets/pages/second_instance_analysis_screen/judgment_draft_dialog/draft_section/draft_section_view.dart`
  - Depende de: —
  - Desbloqueia: F5-T2
  - Artefatos: `lib/ui/intake/widgets/pages/second_instance_analysis_screen/judgment_draft_dialog/draft_section/draft_section_view.dart` *(alterado)*, `documentation/features/intake/second-instance-analysis/second-instance-judgment-draft-edition-plan.md` *(alterado)*
  - Concluído em: 2026-06-06

- [x] **F5-T2** — Refatorar `JudgmentDraftDialogView` para usar o presenter de formulário, renderizar `ReactiveTextField` por seção, usar `DynamicListField` em `ruling`, exibir `SaveStatusIndicator` no header e executar `flush` no close/back
  - Camada: `ui`
  - Artefato: `lib/ui/intake/widgets/pages/second_instance_analysis_screen/judgment_draft_dialog/judgment_draft_dialog_view.dart`
  - Depende de: F3-T1, F3-T3, F4-T1, F5-T1
  - Desbloqueia: F7-T2
  - Artefatos: `lib/ui/intake/widgets/pages/second_instance_analysis_screen/judgment_draft_dialog/judgment_draft_dialog_view.dart` *(alterado)*, `documentation/features/intake/second-instance-analysis/second-instance-judgment-draft-edition-plan.md` *(alterado)*
  - Concluído em: 2026-06-06

### F6 — Expor atualização local do `judgmentDraft` na tela principal

- [x] **F6-T1** — Expor `updateJudgmentDraftLocally(SecondInstanceJudgmentDraftDto dto)` no presenter da tela para sincronizar o preview sem chamada remota
  - Camada: `ui`
  - Artefatos: `lib/ui/intake/widgets/pages/second_instance_analysis_screen/second_instance_analysis_screen_presenter.dart` *(alterado)*
  - Depende de: —
  - Desbloqueia: F7-T1
  - Concluído em: 2026-06-06

### F7 — Encadear o callback de atualização até o ponto real de abertura do dialog

- [x] **F7-T1** — Encaminhar `onDraftUpdated` da `SecondInstanceAnalysisScreenView` para o `JudgmentDraftCard`, chamando `presenter.updateJudgmentDraftLocally(...)`
  - Camada: `ui`
  - Artefato: `lib/ui/intake/widgets/pages/second_instance_analysis_screen/second_instance_analysis_screen_view.dart`
  - Depende de: F6-T1
  - Desbloqueia: F7-T2
  - Artefatos: `lib/ui/intake/widgets/pages/second_instance_analysis_screen/second_instance_analysis_screen_view.dart` *(alterado)*, `documentation/features/intake/second-instance-analysis/second-instance-judgment-draft-edition-plan.md` *(alterado)*
  - Concluído em: 2026-06-06

- [x] **F7-T2** — Repassar `onDraftUpdated` do `JudgmentDraftCard` para o `JudgmentDraftDialog`, preservando o card como preview read-only e sem mover a navegação para outra camada
  - Camada: `ui`
  - Artefato: `lib/ui/intake/widgets/pages/second_instance_analysis_screen/judgment_draft_card/judgment_draft_card_view.dart`
  - Depende de: F5-T2, F7-T1
  - Desbloqueia: fluxo end-to-end de edição com preview sincronizado
  - Artefatos: `lib/ui/intake/widgets/pages/second_instance_analysis_screen/judgment_draft_card/judgment_draft_card_view.dart` *(alterado)*, `documentation/features/intake/second-instance-analysis/second-instance-judgment-draft-edition-plan.md` *(alterado)*
  - Concluído em: 2026-06-06

---

## Pendências

- A validação global com `flutter analyze` e `flutter test` segue bloqueada por pendências fora do escopo desta fase: `flutter analyze` ainda falha em `test/ui/intake/widgets/pages/second_instance_analysis_screen/second_instance_analysis_screen_presenter_test.dart` por exigir o parâmetro `decision` em `SecondInstanceAnalysisReportDto`, e `flutter test` continua com falhas pré-existentes adicionais na suíte de UI.
- O endpoint `PUT /intake/analyses/{analysis_id}/second-instance-judgment-drafts` depende de ticket server separado; impacto: a implementação mobile pode avançar, mas a validação ponta a ponta depende do backend.
- A spec trata `SaveStatusIndicator` e `DynamicListField` como novos componentes globais, mas a codebase atual já possui versões locais em `petition_draft_dialog`; impacto: sem alinhamento, há risco de duplicação. Ação sugerida: extrair/globalizar antes de usar na segunda instância.
- A spec indica alteração apenas em `SecondInstanceAnalysisScreenView` para abrir o dialog com callback, mas na codebase atual o ponto real de abertura está em `JudgmentDraftCardView`; impacto: será necessário ajustar esse arquivo para propagar `onDraftUpdated`, mantendo o card read-only.
- Não há impacto previsto em `go_router`, `lib/router.dart`, `lib/app.dart`, `lib/main.dart`, cache local ou novos drivers; se isso mudar durante a implementação, a spec precisará ser revisitada.

## Divergências em relação à Spec

- O `SaveStatusIndicator` global disponível nesta fase exibe os estados de auto-save no header, mas não expõe callback visual de retry. O retry manual continua implementado no `JudgmentDraftDialogPresenter` e pode ser conectado em fase posterior sem alterar a view atual.
