---
title: Plano de Implementação — Exportação da Minuta de Sentença de 2ª Instância em DOCX
spec: [documentation/features/intake/second-instance-analysis/second-instance-judgment-draft-exportation-spec.md](documentation/features/intake/second-instance-analysis/second-instance-judgment-draft-exportation-spec.md)
created_at: 2026-06-05
status: closed
---

---

## Análise de Dependências

### Artefatos do `core` que desbloqueiam outras camadas
- O único pré-requisito novo de `core` é o contrato `IntakeService.exportJudgmentDraft({required String analysisId})` em `lib/core/intake/interfaces/intake_service.dart`.
- `AnalysisDocumentDto` já existe em `lib/core/intake/dtos/analysis_document_dto.dart` e será reutilizado por `rest` e `ui`, incluindo o campo `name` como fonte do nome do arquivo compartilhado.
- `RestResponse<AnalysisDocumentDto>` já existe e continua sendo o envelope tipado que evita vazamento de HTTP para a UI.
- Não há necessidade de novo contrato de `drivers`: `FileStorageDriver.getFile(...)` já existe em `lib/core/storage/interfaces/drivers/file_storage_driver.dart` e deve retornar o `File` consumido por `FileShareDriver.shareFile(...)`.

### Partes de `rest` e `drivers` independentes entre si
- A implementação REST é isolada em um único método novo de `IntakeRestService` em `lib/rest/services/intake_rest_service.dart`, reutilizando `AnalysisDocumentMapper`.
- Não há nova implementação de `drivers` na spec validada: o download via `FileStorageDriver` e o share sheet via `FileShareDriver` já existem.
- Como não há driver novo, `rest` não depende de `drivers` para avançar; ambos só convergem na camada `ui`.

### Presenters/widgets/screens paralelizáveis
- `JudgmentDraftDialogPresenter` pode ser construído em paralelo com `IntakeRestService` assim que o contrato de `core` existir.
- `JudgmentDraftDialogView` pode avançar em paralelo com o `rest` usando a API pública do presenter.
- `JudgmentDraftCardView` pode ser ajustado em paralelo à implementação REST, pois só precisa repassar `analysisId` e abrir o dialog.
- `SecondInstanceAnalysisScreenView` pode ser ajustada em paralelo ao `rest`, desde que a assinatura nova de `JudgmentDraftCard` já esteja definida.

### Tarefas iniciáveis com stub
- `JudgmentDraftDialogPresenter` pode iniciar com stub de `IntakeService.exportJudgmentDraft`, stub de `FileStorageDriver.getFile` retornando `File`, e stub de `FileShareDriver.shareFile`.
- `JudgmentDraftDialogView` pode iniciar com stub de `isExportingDraft`, `generalError` e `exportJudgmentDraft()`.
- `JudgmentDraftCardView` e `SecondInstanceAnalysisScreenView` podem iniciar com callback fake de exportação, sem aguardar a implementação real do `rest`.
- Não há bloqueio de `go_router`, `router.dart`, `app.dart`, `main.dart` ou `constants`.
- Não há impacto em cache local ou estado compartilhado global; o estado novo é local ao dialog e deve ficar em `signals`.
- Há integração de plataforma já existente para download e compartilhamento, mas ela não bloqueia outras fases porque os drivers já estão prontos.

---

## ⚠️ Gargalos identificados

- **F1-T1**: bloqueia 2 tarefas diretas; deve ser iniciada primeiro.
- **F3-T1**: bloqueia 2 tarefas de UI e define a API pública do fluxo de exportação no dialog; deve começar assim que F1-T1 terminar.

---

## Mapa de Paralelização

| Fase | Objetivo | Depende de | Pode rodar em paralelo com |
|------|----------|------------|----------------------------|
| F1   | Estabilizar contrato de exportação no `core` | - | - |
| F2   | Implementar endpoint de exportação no adapter `rest` | F1 | F3 |
| F3   | Criar orquestração de exportação no presenter do dialog | F1 | F2 |
| F4   | Integrar UX do dialog e pontos de entrada da tela | F3 | F2 |

---

## Fases e Tarefas

### F1 — Estabilizar contrato de exportação no `core`

- [x] **F1-T1** — Adicionar o contrato `exportJudgmentDraft({required String analysisId})` ao `IntakeService`
  - Camada: `core`
  - Artefatos: `lib/core/intake/interfaces/intake_service.dart` *(alterado)*
  - Depende de: —
  - Desbloqueia: F2-T1, F3-T1
  - Concluído em: 2026-06-05

### F2 — Implementar endpoint de exportação no adapter `rest`

- [x] **F2-T1** — Implementar `exportJudgmentDraft(...)` em `IntakeRestService` chamando `POST /intake/analyses/{analysis_id}/second-instance-judgment-drafts/export` e retornando `AnalysisDocumentMapper.toDto`
  - Camada: `rest`
  - Artefatos: `lib/rest/services/intake_rest_service.dart` *(alterado)*
  - Depende de: F1-T1
  - Desbloqueia: validação funcional do fluxo completo em F4-T1
  - Concluído em: 2026-06-05

### F3 — Criar orquestração de exportação no presenter do dialog

- [x] **F3-T1** — Criar `JudgmentDraftDialogPresenter` com `isExportingDraft`, `generalError`, `exportJudgmentDraft()`, injeção de `IntakeService`, `FileStorageDriver`, `FileShareDriver` e `analysisId`; o método deve usar `response.body.name` como filename de compartilhamento e encadear download + share
  - Camada: `ui`
  - Artefatos: `lib/ui/intake/widgets/pages/second_instance_analysis_screen/judgment_draft_dialog/judgment_draft_dialog_presenter.dart` *(novo)*
  - Depende de: F1-T1
  - Desbloqueia: F4-T1, F4-T2
  - Concluído em: 2026-06-05

### F4 — Integrar UX do dialog e pontos de entrada da tela

- [x] **F4-T1** — Adaptar `JudgmentDraftDialogView` para consumir o presenter, adicionar o botão "Exportar minuta" no header, desabilitar exportação concorrente, exibir loading discreto e propagar `generalError` sem fechar o dialog
  - Camada: `ui`
  - Artefatos: `lib/ui/intake/widgets/pages/second_instance_analysis_screen/judgment_draft_dialog/judgment_draft_dialog_view.dart` *(alterado)*
  - Depende de: F3-T1
  - Desbloqueia: conclusão visual do fluxo de exportação
  - Concluído em: 2026-06-05

- [x] **F4-T2** — Ajustar `JudgmentDraftCardView` para repassar apenas `analysisId` e abrir o dialog com a nova API baseada em presenter, sem depender de `analysisName` para exportação
  - Camada: `ui`
  - Artefatos: `lib/ui/intake/widgets/pages/second_instance_analysis_screen/judgment_draft_card/judgment_draft_card_view.dart` *(alterado)*
  - Depende de: F3-T1
  - Desbloqueia: F4-T3
  - Concluído em: 2026-06-05

- [x] **F4-T3** — Ajustar `SecondInstanceAnalysisScreenView` para fornecer `analysisId` atual ao `JudgmentDraftCard`, preservando o fluxo já existente de regeneração e a independência da exportação de PDF
  - Camada: `ui`
  - Artefatos: `lib/ui/intake/widgets/pages/second_instance_analysis_screen/second_instance_analysis_screen_view.dart` *(alterado)*
  - Depende de: F4-T2
  - Desbloqueia: entrega completa da feature na tela
  - Concluído em: 2026-06-05

---

## Pendências

- Nenhuma.
