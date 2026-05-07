---
title: Plano de Implementação — Tela de Pasta da Biblioteca
spec: [documentation/ani-73-spec.md](documentation/ani-73-spec.md)
created_at: 2026-05-04
status: closed
---

---

## Análise de Dependências

### Artefatos do `core` que desbloqueiam outras camadas
- `LibraryService` com `getFolder`, `listFolderAnalyses`, `updateFolderName`, `archiveFolder`, `moveAnalysesToFolder` e `archiveAnalyses` desbloqueia `rest` e `ui`.
- `FolderDto` com `id`, `name`, `analysisCount`, `accountId` e `isArchived` desbloqueia header, modais e mappers.
- `AnalysisDto` com `id`, `name`, `createdAt`, `folderId` e `isArchived` desbloqueia lista, picker e operações batch.
- `IntakeService.listAnalyses` desbloqueia o fluxo de pasta vazia.
- `RestResponse`, `CursorPaginationResponse` e `NavigationDriver` já são contratos-base para services e presenters.

### Partes de `rest` e `drivers` independentes entre si
- `LibraryRestService` pode evoluir independente da UI depois do contrato `LibraryService`.
- `IntakeRestService.listAnalyses` é independente de `LibraryRestService`, pois só precisa respeitar `IntakeService`.
- `FolderMapper` e `CursorPaginationMapper` podem ser ajustados em paralelo com services, desde que os DTOs estejam estáveis.
- Não há novo `driver`; `NavigationDriver` e sua implementação existente só precisam ser consumidos.

### Presenters/widgets/screens paralelizáveis
- `LibraryFolderScreenPresenter`, `MoveAnalysesModalPresenter` e `FolderSettingsModalPresenter` podem ser trabalhados em paralelo após os contratos do `core`.
- Widgets view-only da pasta podem ser criados em paralelo por arquivo/pasta: header, background, loading, error, empty, list, card, action bar e dialog.
- `FolderAvailableAnalysisPicker` pode ser criado em `ui/library` em paralelo aos ajustes do presenter.
- `LibraryScreenPresenter/View` pode ser ajustado em paralelo ao fluxo interno da tela de pasta.

### Tarefas iniciáveis com stub
- `LibraryFolderScreenPresenter` pode iniciar com stubs de `LibraryService` e `IntakeService`.
- `LibraryFolderScreenView` pode iniciar com stub de `LibraryFolderScreenPresenter`.
- `FolderAvailableAnalysisPicker` pode iniciar com listas estáticas de `AnalysisDto`.
- `MoveAnalysesModalView` pode iniciar com stub de `MoveAnalysesModalPresenter`.

### Impacto em navegação, estado compartilhado e integrações
- Há impacto em `Routes` e `router.dart` para `/library/folders/:folderId`.
- Estado local fica em `signals`; composição fica em providers Riverpod.
- Não há novo cache local nem integração de plataforma nova.

---

## ⚠️ Gargalos identificados

- **F1 — Contratos e rotas base**: bloqueia 9 tarefas; deve ser iniciada primeiro.
- **F3-T1 — Orquestração do `LibraryFolderScreenPresenter`**: bloqueia integração da tela, picker e modais; deve ser priorizada logo após F1.
- **F4-T1 — `FolderAvailableAnalysisPicker` no módulo correto**: bloqueia o requisito principal de pasta vazia.

---

## Mapa de Paralelização

| Fase | Objetivo | Depende de | Pode rodar em paralelo com |
|------|----------|------------|----------------------------|
| F1 | Estabilizar contratos, DTOs e rotas base | - | - |
| F2 | Alinhar REST e providers | F1 | F3, F4, F5 |
| F3 | Implementar presenters da pasta e modais | F1 | F2, F4, F5 |
| F4 | Criar/ajustar widgets internos da pasta | F1, F3-T1 parcial | F2, F3, F5 |
| F5 | Ligar biblioteca principal à tela de pasta | F1 | F2, F3, F4 |
| F6 | Integrar tela, barrels e router final | F2, F3, F4, F5 | - |

---

## Fases e Tarefas

### F1 — Contratos e rotas base

- [x] **F1-T1** — Garantir contrato `LibraryService`
  - Camada: `core`
  - Artefato: `lib/core/library/interfaces/library_service.dart`
  - Depende de: —
  - Desbloqueia: F2-T1, F3-T1, F3-T2, F3-T3
  - Artefatos: `lib/core/library/interfaces/library_service.dart`
  - Concluído em: 2026-05-04

- [x] **F1-T2** — Garantir DTOs consumidos pela pasta
  - Camada: `core`
  - Artefato: `lib/core/library/dtos/folder_dto.dart`, `lib/core/intake/dtos/analysis_dto.dart`
  - Depende de: —
  - Desbloqueia: F2-T2, F4-T1, F4-T4, F4-T5
  - Artefatos: `lib/core/library/dtos/folder_dto.dart`, `lib/core/intake/dtos/analysis_dto.dart`
  - Concluído em: 2026-05-04

- [x] **F1-T3** — Garantir `IntakeService.listAnalyses`
  - Camada: `core`
  - Artefato: `lib/core/intake/interfaces/intake_service.dart`
  - Depende de: —
  - Desbloqueia: F2-T3, F3-T1
  - Artefatos: `lib/core/intake/interfaces/intake_service.dart`
  - Concluído em: 2026-05-04

- [x] **F1-T4** — Garantir rota `Routes.libraryFolder` e helper
  - Camada: `constants`
  - Artefato: `lib/constants/routes.dart`
  - Depende de: —
  - Desbloqueia: F5-T1, F6-T2
  - Artefatos: `lib/constants/routes.dart`
  - Concluído em: 2026-05-04

### F2 — REST e providers

- [x] **F2-T1** — Alinhar endpoints de pasta e batch actions
  - Camada: `rest`
  - Artefato: `lib/rest/services/library_rest_service.dart`
  - Depende de: F1-T1, F1-T2
  - Desbloqueia: F6-T1
  - Artefatos: `lib/rest/services/library_rest_service.dart`, `test/rest/services/library_rest_service_test.dart`
  - Concluído em: 2026-05-04

- [x] **F2-T2** — Garantir mapper de pasta
  - Camada: `rest`
  - Artefato: `lib/rest/mappers/library/folder_mapper.dart`
  - Depende de: F1-T2
  - Desbloqueia: F2-T1
  - Artefatos: `lib/rest/mappers/library/folder_mapper.dart`
  - Concluído em: 2026-05-04

- [x] **F2-T3** — Reutilizar listagem de análises ativas
  - Camada: `rest`
  - Artefato: `lib/rest/services/intake_rest_service.dart`
  - Depende de: F1-T3
  - Desbloqueia: F3-T1
  - Artefatos: `lib/rest/services/intake_rest_service.dart`
  - Concluído em: 2026-05-04

- [x] **F2-T4** — Garantir provider de `LibraryService`
  - Camada: `rest`
  - Artefato: `lib/rest/services/index.dart`
  - Depende de: F2-T1
  - Desbloqueia: F3-T1, F3-T2
  - Artefatos: `lib/rest/services/index.dart`
  - Concluído em: 2026-05-04

### F3 — Presenters

- [x] **F3-T1** — Ajustar `LibraryFolderScreenPresenter`
  - Camada: `ui`
  - Artefato: `lib/ui/library/widgets/pages/library_folder_screen/library_folder_screen_presenter.dart`
  - Depende de: F1-T1, F1-T2, F1-T3
  - Desbloqueia: F4-T1, F6-T1
  - Artefatos: `lib/ui/library/widgets/pages/library_folder_screen/library_folder_screen_presenter.dart`, `test/ui/storage/widgets/pages/library_folder_screen/library_folder_screen_presenter_test.dart`
  - Concluído em: 2026-05-04

- [x] **F3-T2** — Ajustar presenter do modal de movimentação
  - Camada: `ui`
  - Artefato: `lib/ui/library/widgets/pages/library_folder_screen/move_analyses_modal/move_analyses_modal_presenter.dart`
  - Depende de: F1-T1
  - Desbloqueia: F4-T6, F6-T1
  - Artefatos: `lib/ui/library/widgets/pages/library_folder_screen/move_analyses_modal/move_analyses_modal_presenter.dart`
  - Concluído em: 2026-05-04

- [x] **F3-T3** — Ajustar presenter do modal de configurações
  - Camada: `ui`
  - Artefato: `lib/ui/library/widgets/pages/library_folder_screen/folder_settings_modal/folder_settings_modal_presenter.dart`
  - Depende de: F1-T1, F1-T2
  - Desbloqueia: F4-T7, F6-T1
  - Artefatos: `lib/ui/library/widgets/pages/library_folder_screen/folder_settings_modal/folder_settings_modal_presenter.dart`
  - Concluído em: 2026-05-04

### F4 — Widgets internos da tela de pasta

- [x] **F4-T1** — Criar picker de análises disponíveis no módulo `ui/library`
  - Camada: `ui`
  - Artefato: `lib/ui/library/widgets/pages/library_folder_screen/folder_available_analysis_picker/folder_available_analysis_picker_view.dart`
  - Depende de: F1-T2, F3-T1
  - Desbloqueia: F6-T1
  - Artefatos: `lib/ui/library/widgets/pages/library_folder_screen/folder_available_analysis_picker/folder_available_analysis_picker_view.dart`, `lib/ui/library/widgets/pages/library_folder_screen/folder_available_analysis_picker/index.dart`
  - Concluído em: 2026-05-04

- [x] **F4-T2** — Ajustar estados visuais básicos
  - Camada: `ui`
  - Artefato: `lib/ui/library/widgets/pages/library_folder_screen/folder_loading_state`, `folder_error_state`, `folder_empty_state`
  - Depende de: F1-T2
  - Desbloqueia: F6-T1
  - Artefatos: `lib/ui/library/widgets/pages/library_folder_screen/folder_loading_state`, `lib/ui/library/widgets/pages/library_folder_screen/folder_error_state`, `lib/ui/library/widgets/pages/library_folder_screen/folder_empty_state`
  - Concluído em: 2026-05-04

- [x] **F4-T3** — Ajustar header e background
  - Camada: `ui`
  - Artefato: `lib/ui/library/widgets/pages/library_folder_screen/library_folder_header`, `library_folder_background`
  - Depende de: F1-T2
  - Desbloqueia: F6-T1
  - Artefatos: `lib/ui/library/widgets/pages/library_folder_screen/library_folder_header`, `lib/ui/library/widgets/pages/library_folder_screen/library_folder_background`
  - Concluído em: 2026-05-04

- [x] **F4-T4** — Ajustar lista e card de análise
  - Camada: `ui`
  - Artefato: `lib/ui/library/widgets/pages/library_folder_screen/folder_analysis_list`, `folder_analysis_card`
  - Depende de: F1-T2
  - Desbloqueia: F6-T1
  - Artefatos: `lib/ui/library/widgets/pages/library_folder_screen/folder_analysis_list`, `lib/ui/library/widgets/pages/library_folder_screen/folder_analysis_card`
  - Concluído em: 2026-05-04

- [x] **F4-T5** — Ajustar action bar e dialog de arquivamento
  - Camada: `ui`
  - Artefato: `lib/ui/library/widgets/pages/library_folder_screen/folder_selection_action_bar`, `archive_selected_analyses_dialog`
  - Depende de: F3-T1
  - Desbloqueia: F6-T1
  - Artefatos: `lib/ui/library/widgets/pages/library_folder_screen/folder_selection_action_bar`, `lib/ui/library/widgets/pages/library_folder_screen/archive_selected_analyses_dialog`
  - Concluído em: 2026-05-04

- [x] **F4-T6** — Ajustar modal de movimentação
  - Camada: `ui`
  - Artefato: `lib/ui/library/widgets/pages/library_folder_screen/move_analyses_modal/move_analyses_modal_view.dart`
  - Depende de: F3-T2
  - Desbloqueia: F6-T1
  - Artefatos: `lib/ui/library/widgets/pages/library_folder_screen/move_analyses_modal/move_analyses_modal_view.dart`
  - Concluído em: 2026-05-04

- [x] **F4-T7** — Ajustar modal de configurações
  - Camada: `ui`
  - Artefato: `lib/ui/library/widgets/pages/library_folder_screen/folder_settings_modal/folder_settings_modal_view.dart`
  - Depende de: F3-T3
  - Desbloqueia: F6-T1
  - Artefatos: `lib/ui/library/widgets/pages/library_folder_screen/folder_settings_modal/folder_settings_modal_view.dart`
  - Concluído em: 2026-05-04

### F5 — Entrada pela biblioteca principal

- [x] **F5-T1** — Garantir navegação por `openFolder`
  - Camada: `ui`
  - Artefato: `lib/ui/library/widgets/pages/library_screen/library_screen_presenter.dart`
  - Depende de: F1-T4
  - Desbloqueia: F5-T2
  - Artefatos: `lib/ui/library/widgets/pages/library_screen/library_screen_presenter.dart`
  - Concluído em: 2026-05-04

- [x] **F5-T2** — Conectar cards de pasta ao presenter
  - Camada: `ui`
  - Artefato: `lib/ui/library/widgets/pages/library_screen/library_screen_view.dart`
  - Depende de: F5-T1
  - Desbloqueia: F6-T2
  - Artefatos: `lib/ui/library/widgets/pages/library_screen/library_screen_view.dart`
  - Concluído em: 2026-05-04

### F6 — Integração final

- [x] **F6-T1** — Integrar estados e widgets na tela de pasta
  - Camada: `ui`
  - Artefato: `lib/ui/library/widgets/pages/library_folder_screen/library_folder_screen_view.dart`
  - Depende de: F2-T4, F3-T1, F3-T2, F3-T3, F4-T1, F4-T2, F4-T3, F4-T4, F4-T5, F4-T6, F4-T7
  - Desbloqueia: F6-T3
  - Artefatos: `lib/ui/library/widgets/pages/library_folder_screen/library_folder_screen_view.dart`
  - Concluído em: 2026-05-04

- [x] **F6-T2** — Garantir registro da rota autenticada
  - Camada: `ui`
  - Artefato: `lib/router.dart`
  - Depende de: F1-T4, F5-T2
  - Desbloqueia: F6-T3
  - Artefatos: `lib/router.dart`
  - Concluído em: 2026-05-04

- [x] **F6-T3** — Atualizar barrels públicos da pasta
  - Camada: `ui`
  - Artefato: `lib/ui/library/widgets/pages/library_folder_screen/index.dart`
  - Depende de: F4-T1, F6-T1
  - Desbloqueia: —
  - Artefatos: `lib/ui/library/widgets/pages/library_folder_screen/index.dart`
  - Concluído em: 2026-05-04

---

## Pendências

- A limpeza dos artefatos legados em `lib/ui/storage/widgets/pages/library_folder_screen/` deve ficar fora deste recorte para evitar misturar migração técnica com a entrega funcional.
- A rota dedicada `/library/unfoldered` permanece fora do escopo; este plano cobre a seção `Sem pasta` na biblioteca e o destino `Sem pasta` em movimentações.
- Validar manualmente depois da implementação os fluxos com backend real: 403/404 amigáveis, paginação, pasta vazia, batch move/archive e retorno para biblioteca.

---

## Divergências em relação à Spec

- Nenhuma.
