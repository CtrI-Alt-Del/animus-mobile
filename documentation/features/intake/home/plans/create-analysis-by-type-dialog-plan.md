---
title: Plano de Implementação — Dialog de criação de análise por tipo
spec: ../specs/create-analysis-by-type-dialog-spec.md
created_at: 2026-05-18
status: closed
---

---

## Análise de Dependências

### Artefatos do `core` que desbloqueiam outras camadas

- Nenhum artefato novo de `core` precisa ser criado. O enum `AnalysisTypeDto` (`lib/core/intake/dtos/analysis_type_dto.dart`) e o contrato `IntakeService.createAnalysis({required AnalysisTypeDto type, String? folderId})` (`lib/core/intake/interfaces/intake_service.dart`) já existem e já são consumidos por `HomeScreenPresenter`.

### Partes de `rest` e `drivers` independentes entre si

- Não aplicável. Esta entrega não toca `lib/rest` nem `lib/drivers` (somente `lib/ui`). Os contratos remotos e os adaptadores de plataforma permanecem inalterados.

### Presenters/widgets/screens paralelizáveis

- **`CreateAnalysisTypeOptionView`** (`View only` puramente visual) é independente — pode ser criado isoladamente assim que os tokens de tema forem confirmados (já existem).
- **`CreateAnalysisTypeDialogPresenter`** não depende de nenhum outro novo artefato; pode ser criado em paralelo com o `OptionView`.
- **Ajuste em `HomeScreenPresenter.createAnalysis`** (adicionar parâmetro `type` com default `firstInstance` e usar `Routes.getAnalysis(analysisType: type)` para navegar) é independente do dialog em si, pois mantém a chamada sem argumentos compatível; pode rodar em paralelo com a criação do dialog.
- **`CreateAnalysisTypeDialogView`** depende de `CreateAnalysisTypeDialogPresenter` (consome `Signal`/getters) e de `CreateAnalysisTypeOptionView` (renderiza tiles).
- **Ajuste em `HomeScreenView`** depende de `CreateAnalysisTypeDialog` (precisa do `typedef` exportado pelo `index.dart`) e do `HomeScreenPresenter` já aceitando o parâmetro `type`.

### Tarefas iniciáveis com stub

- **F4 — Ajustar `HomeScreenPresenter`** pode iniciar imediatamente, sem stub, pois não consome novos artefatos.
- **F2 — `CreateAnalysisTypeDialogPresenter`** pode iniciar imediatamente (não depende de outras tarefas).
- **F1 — `CreateAnalysisTypeOptionView`** pode iniciar imediatamente (não depende de outras tarefas).
- **F3 — `CreateAnalysisTypeDialogView`** pode iniciar com stub do `CreateAnalysisTypeOptionView` e do `CreateAnalysisTypeDialogPresenter` se necessário, mas o ganho é baixo — recomendado aguardar F1 e F2.

---

## ⚠️ Gargalos identificados

- **Nenhum gargalo crítico.** F1, F2 e F4 podem rodar simultaneamente. F3 e F5 são consolidadores no final. O caminho crítico passa por F1 + F2 (paralelas) → F3 → F5 (a parte mais visível ao usuário), com F4 podendo rodar em paralelo a esse caminho.

---

## Mapa de Paralelização

| Fase | Objetivo | Depende de | Pode rodar em paralelo com |
|------|----------|------------|----------------------------|
| F1   | Criar widget interno `CreateAnalysisTypeOption` (View only) | — | F2, F4 |
| F2   | Criar `CreateAnalysisTypeDialogPresenter` (Signals, getters de copy/ícone) | — | F1, F4 |
| F3   | Criar `CreateAnalysisTypeDialogView` e barrel `index.dart` do dialog | F1, F2 | F4 |
| F4   | Ajustar `HomeScreenPresenter.createAnalysis(type: ...)` e navegação via `Routes.getAnalysis` | — | F1, F2, F3 |
| F5   | Ajustar `HomeScreenView` para abrir o dialog via `showDialog<AnalysisTypeDto>` | F3, F4 | — |

---

## Fases e Tarefas

### F1 — Widget interno `CreateAnalysisTypeOption`

- [x] **F1-T1** — Criar `CreateAnalysisTypeOptionView` (View only)
  - Camada: `ui`
  - Artefato: `lib/ui/intake/widgets/pages/home_screen/create_analysis_type_dialog/create_analysis_type_option/create_analysis_type_option_view.dart` *(novo)*
  - Concluído em: 2026-05-18

- [x] **F1-T2** — Criar `index.dart` do widget interno
  - Camada: `ui`
  - Artefato: `lib/ui/intake/widgets/pages/home_screen/create_analysis_type_dialog/create_analysis_type_option/index.dart` *(novo)*
  - Concluído em: 2026-05-18

### F2 — Presenter do dialog

- [x] **F2-T1** — Criar `CreateAnalysisTypeDialogPresenter`
  - Camada: `ui`
  - Artefato: `lib/ui/intake/widgets/pages/home_screen/create_analysis_type_dialog/create_analysis_type_dialog_presenter.dart` *(novo)*
  - Concluído em: 2026-05-18

### F3 — View do dialog e barrel público

- [x] **F3-T1** — Criar `CreateAnalysisTypeDialogView`
  - Camada: `ui`
  - Artefato: `lib/ui/intake/widgets/pages/home_screen/create_analysis_type_dialog/create_analysis_type_dialog_view.dart` *(novo)*
  - Concluído em: 2026-05-18

- [x] **F3-T2** — Criar `index.dart` do dialog
  - Camada: `ui`
  - Artefato: `lib/ui/intake/widgets/pages/home_screen/create_analysis_type_dialog/index.dart` *(novo)*
  - Concluído em: 2026-05-18

### F4 — Ajuste no `HomeScreenPresenter`

- [x] **F4-T1** — Adicionar parâmetro `type` em `createAnalysis` e ajustar navegação
  - Camada: `ui`
  - Artefato: `lib/ui/intake/widgets/pages/home_screen/home_screen_presenter.dart` *(modificação)*
  - Concluído em: 2026-05-18

### F5 — Integração na `HomeScreenView`

- [x] **F5-T1** — Integrar `showDialog<AnalysisTypeDto>` no `FAB` e no `EmptyState`
  - Camada: `ui`
  - Artefato: `lib/ui/intake/widgets/pages/home_screen/home_screen_view.dart` *(modificação)*
  - Concluído em: 2026-05-18
  - Notas: além do `home_screen_view.dart`, foi necessário atualizar o teste de widget `test/ui/intake/widgets/pages/home_screen/home_screen_view_test.dart` para refletir o novo fluxo (registrar `AnalysisTypeDto` como fallback, ajustar stub de `createAnalysis(type:)`, abrir/cancelar/confirmar o dialog).

---

## Pendências

- Nenhuma.
