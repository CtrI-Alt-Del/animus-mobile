---
title: Plano de Implementacao - Tela de Pasta da Biblioteca
spec: documentation/ani-73-spec.md
created_at: 2026-05-04
status: closed
---

---

## Analise de Dependencias

### Artefatos do `core` que desbloqueiam outras camadas
- Atualizacao de `LibraryService` com `listFolderAnalyses`, `moveAnalysesToFolder` e `archiveAnalyses`.
- Reuso de `AnalysisDto`, `FolderDto`, `CursorPaginationResponse<T>` e `RestResponse<T>` como contratos tipados para REST e UI.
- `NavigationDriver` ja existe e desbloqueia navegacao da tela sem criar novo driver.

### Partes de `rest` e `drivers` independentes entre si
- `LibraryRestService.listFolderAnalyses` e independente das operacoes batch, mas escreve no mesmo arquivo.
- `LibraryRestService.moveAnalysesToFolder` e `archiveAnalyses` compartilham padrao de payload batch, mas nao dependem da listagem.
- Nenhum novo `driver` e necessario; `NavigationDriver` existente pode ser consumido pela UI em paralelo ao REST.

### Presenters/widgets/screens paralelizaveis
- `LibraryFolderScreenPresenter`, `FolderDestinationPickerPresenter` e `LibraryFolderSettingsModalPresenter` podem ser criados em paralelo apos os contratos relevantes.
- Widgets view-only (`Header`, `AnalysisItem`, `ActionBar`, `EmptyState`, `ErrorState`) podem ser criados em paralelo.
- `FolderAvailableAnalysisPicker`, `LibraryFolderAnalysisList`, `FolderDestinationPicker` e `SettingsModal` podem avancar com props estaveis antes da tela final.

### Tarefas iniciaveis com stub
- `LibraryFolderScreenPresenter` pode iniciar com fake/stub de `LibraryService`, `IntakeService` e `NavigationDriver`.
- `LibraryFolderScreenView` pode iniciar com o presenter ja definido, sem aguardar o REST real.
- Widgets view-only podem iniciar com `AnalysisDto`/`FolderDto` mockados.
- `FolderDestinationPicker` pode iniciar com stub de `listFolders`.

---

## Gargalos identificados

- **F1-T1 - Atualizar `LibraryService`**: bloqueia 5 tarefas; deve ser iniciada primeiro.
- **F3-T1 - Criar `LibraryFolderScreenPresenter`**: bloqueia a composicao final da tela; deve comecar assim que F1-T1 estiver estavel.
- **F5-T2 - Criar barrel publico da tela**: bloqueia o wiring da rota em `router.dart`.

---

## Mapa de Paralelizacao

| Fase | Objetivo | Depende de | Pode rodar em paralelo com |
|------|----------|------------|----------------------------|
| F1 | Definir contratos do `core` | - | F4 parcial com widgets view-only |
| F2 | Implementar adaptacao REST | F1 | F3, F4, F5 parcial com stubs |
| F3 | Criar presenters da UI | F1 | F2, F4 |
| F4 | Criar widgets internos da tela | F1 parcial | F2, F3 |
| F5 | Compor `LibraryFolderScreen` | F3, F4 | F2, se iniciado com stub de `LibraryService` |
| F6 | Registrar rota final | F5, F2 | - |

---

## Fases e Tarefas

### F1 - Contratos do Core

- [x] **F1-T1** - Adicionar operacoes de pasta e lote em `LibraryService`
  - Camada: `core`
  - Artefato: `lib/core/library/interfaces/library_service.dart`
  - Artefatos: `lib/core/library/interfaces/library_service.dart` *(alterado)*
  - Concluido em: 2026-05-04
  - Depende de: -
  - Desbloqueia: F2-T1, F2-T2, F3-T1, F3-T3, F5-T1

### F2 - Implementacao REST

- [x] **F2-T1** - Implementar listagem paginada de analises da pasta
  - Camada: `rest`
  - Artefato: `lib/rest/services/library_rest_service.dart`
  - Artefatos: `lib/rest/services/library_rest_service.dart` *(alterado)*
  - Concluido em: 2026-05-04
  - Depende de: F1-T1
  - Desbloqueia: carga real da F3-T1 e F5-T1

- [x] **F2-T2** - Implementar mover/adicionar e arquivar analises em lote
  - Camada: `rest`
  - Artefato: `lib/rest/services/library_rest_service.dart`
  - Artefatos: `lib/rest/services/library_rest_service.dart` *(alterado)*
  - Concluido em: 2026-05-04
  - Depende de: F1-T1
  - Desbloqueia: fluxos reais de adicionar, mover e arquivar em F3-T1

### F3 - Presenters da UI

- [x] **F3-T1** - Criar `LibraryFolderScreenPresenter` e provider family
  - Camada: `ui`
  - Artefato: `lib/ui/storage/widgets/pages/library_folder_screen/library_folder_screen_presenter.dart`
  - Artefatos: `lib/ui/storage/widgets/pages/library_folder_screen/library_folder_screen_presenter.dart` *(novo)*
  - Concluido em: 2026-05-04
  - Depende de: F1-T1
  - Desbloqueia: F5-T1

- [x] **F3-T2** - Criar presenter do modal de configuracoes
  - Camada: `ui`
  - Artefato: `lib/ui/storage/widgets/pages/library_folder_screen/library_folder_settings_modal/library_folder_settings_modal_presenter.dart`
  - Artefatos: `lib/ui/storage/widgets/pages/library_folder_screen/library_folder_settings_modal/library_folder_settings_modal_presenter.dart` *(novo)*
  - Concluido em: 2026-05-04
  - Depende de: `FolderDto` existente
  - Desbloqueia: F4-T7

- [x] **F3-T3** - Criar presenter do seletor de destino
  - Camada: `ui`
  - Artefato: `lib/ui/storage/widgets/pages/library_folder_screen/folder_destination_picker/folder_destination_picker_presenter.dart`
  - Artefatos: `lib/ui/storage/widgets/pages/library_folder_screen/folder_destination_picker/folder_destination_picker_presenter.dart` *(novo)*
  - Concluido em: 2026-05-04
  - Depende de: `LibraryService.listFolders`
  - Desbloqueia: F4-T8

### F4 - Widgets Internos

- [x] **F4-T1** - Criar header da pasta
  - Camada: `ui`
  - Artefato: `lib/ui/storage/widgets/pages/library_folder_screen/library_folder_header/`
  - Artefatos: `lib/ui/storage/widgets/pages/library_folder_screen/library_folder_header/library_folder_header_view.dart` *(novo)*, `lib/ui/storage/widgets/pages/library_folder_screen/library_folder_header/index.dart` *(novo)*
  - Concluido em: 2026-05-04
  - Depende de: -
  - Desbloqueia: F5-T1

- [x] **F4-T2** - Criar item visual de analise
  - Camada: `ui`
  - Artefato: `lib/ui/storage/widgets/pages/library_folder_screen/library_folder_analysis_item/`
  - Artefatos: `lib/ui/storage/widgets/pages/library_folder_screen/library_folder_analysis_item/library_folder_analysis_item_view.dart` *(novo)*, `lib/ui/storage/widgets/pages/library_folder_screen/library_folder_analysis_item/index.dart` *(novo)*
  - Concluido em: 2026-05-04
  - Depende de: `AnalysisDto` existente
  - Desbloqueia: F4-T3, F5-T1

- [x] **F4-T3** - Criar lista paginada de analises
  - Camada: `ui`
  - Artefato: `lib/ui/storage/widgets/pages/library_folder_screen/library_folder_analysis_list/`
  - Artefatos: `lib/ui/storage/widgets/pages/library_folder_screen/library_folder_analysis_list/library_folder_analysis_list_view.dart` *(novo)*, `lib/ui/storage/widgets/pages/library_folder_screen/library_folder_analysis_list/index.dart` *(novo)*
  - Concluido em: 2026-05-04
  - Depende de: F4-T2
  - Desbloqueia: F5-T1

- [x] **F4-T4** - Criar picker de analises disponiveis para pasta vazia
  - Camada: `ui`
  - Artefato: `lib/ui/storage/widgets/pages/library_folder_screen/folder_available_analysis_picker/`
  - Artefatos: `lib/ui/storage/widgets/pages/library_folder_screen/folder_available_analysis_picker/folder_available_analysis_picker_view.dart` *(novo)*, `lib/ui/storage/widgets/pages/library_folder_screen/folder_available_analysis_picker/index.dart` *(novo)*
  - Concluido em: 2026-05-04
  - Depende de: `AnalysisDto` existente
  - Desbloqueia: F5-T1

- [x] **F4-T5** - Criar action bar inferior de selecao
  - Camada: `ui`
  - Artefato: `lib/ui/storage/widgets/pages/library_folder_screen/library_folder_action_bar/`
  - Artefatos: `lib/ui/storage/widgets/pages/library_folder_screen/library_folder_action_bar/library_folder_action_bar_view.dart` *(novo)*, `lib/ui/storage/widgets/pages/library_folder_screen/library_folder_action_bar/index.dart` *(novo)*
  - Concluido em: 2026-05-04
  - Depende de: -
  - Desbloqueia: F5-T1

- [x] **F4-T6** - Criar estados de vazio e erro recuperavel
  - Camada: `ui`
  - Artefato: `lib/ui/storage/widgets/pages/library_folder_screen/library_folder_empty_state/` e `library_folder_error_state/`
  - Artefatos: `lib/ui/storage/widgets/pages/library_folder_screen/library_folder_empty_state/library_folder_empty_state_view.dart` *(novo)*, `lib/ui/storage/widgets/pages/library_folder_screen/library_folder_empty_state/index.dart` *(novo)*, `lib/ui/storage/widgets/pages/library_folder_screen/library_folder_error_state/library_folder_error_state_view.dart` *(novo)*, `lib/ui/storage/widgets/pages/library_folder_screen/library_folder_error_state/index.dart` *(novo)*
  - Concluido em: 2026-05-04
  - Depende de: -
  - Desbloqueia: F5-T1

- [x] **F4-T7** - Criar view do modal de configuracoes da pasta
  - Camada: `ui`
  - Artefato: `lib/ui/storage/widgets/pages/library_folder_screen/library_folder_settings_modal/library_folder_settings_modal_view.dart`
  - Artefatos: `lib/ui/storage/widgets/pages/library_folder_screen/library_folder_settings_modal/library_folder_settings_modal_view.dart` *(novo)*, `lib/ui/storage/widgets/pages/library_folder_screen/library_folder_settings_modal/index.dart` *(novo)*
  - Concluido em: 2026-05-04
  - Depende de: F3-T2
  - Desbloqueia: F5-T1

- [x] **F4-T8** - Criar view do seletor de destino
  - Camada: `ui`
  - Artefato: `lib/ui/storage/widgets/pages/library_folder_screen/folder_destination_picker/folder_destination_picker_view.dart`
  - Artefatos: `lib/ui/storage/widgets/pages/library_folder_screen/folder_destination_picker/folder_destination_picker_view.dart` *(novo)*, `lib/ui/storage/widgets/pages/library_folder_screen/folder_destination_picker/index.dart` *(novo)*
  - Concluido em: 2026-05-04
  - Depende de: F3-T3
  - Desbloqueia: F5-T1

### F5 - Composicao da Tela

- [x] **F5-T1** - Criar `LibraryFolderScreenView` integrando presenter, estados e widgets
  - Camada: `ui`
  - Artefato: `lib/ui/storage/widgets/pages/library_folder_screen/library_folder_screen_view.dart`
  - Artefatos: `lib/ui/storage/widgets/pages/library_folder_screen/library_folder_screen_view.dart` *(novo)*
  - Concluido em: 2026-05-04
  - Depende de: F3-T1, F4-T1, F4-T3, F4-T4, F4-T5, F4-T6, F4-T7, F4-T8
  - Desbloqueia: F5-T2, F6-T1

- [x] **F5-T2** - Criar barrel publico da tela
  - Camada: `ui`
  - Artefato: `lib/ui/storage/widgets/pages/library_folder_screen/index.dart`
  - Artefatos: `lib/ui/storage/widgets/pages/library_folder_screen/index.dart` *(novo)*
  - Concluido em: 2026-05-04
  - Depende de: F5-T1
  - Desbloqueia: F6-T1

### F6 - Router e Entrada da Rota

- [x] **F6-T1** - Substituir placeholder da rota por `LibraryFolderScreen`
  - Camada: `ui`
  - Artefato: `lib/router.dart`
  - Artefatos: `lib/router.dart` *(alterado)*
  - Concluido em: 2026-05-04
  - Depende de: F2-T1, F2-T2, F5-T2
  - Desbloqueia: entrega navegavel da ANI-73

---

## Pendencias

- Resolvido em 2026-05-04: `listFolderAnalyses` usa `GET /intake/analyses` com `folder_id`, `is_archived=false`, `limit` e `cursor`, e aplica filtro local defensivo por `AnalysisDto.folderId`.
- Confirmar se os endpoints batch retornam objeto/sem body para manter `RestResponse<void>`.
- Validar copy final de "Deletar" versus "Arquivar"; a logica deve tratar como arquivamento, nao exclusao permanente.
- A implementacao REST toca o mesmo arquivo para tres metodos; se houver paralelizacao nessa fase, coordenar ownership para evitar conflito de merge.

---

## Divergencias em relacao a Spec

- **F2-T1:** o endpoint `GET /library/folders/{folderId}/analyses` retornou 404 no backend local; a implementacao foi ajustada para `GET /intake/analyses` com filtro `folder_id`.
- **F2-T1:** como o sintoma observado indica possivel retorno sem filtro efetivo de pasta, a implementacao tambem filtra localmente os itens retornados por `folder_id` antes de renderizar a tela.
- **F6-T1:** a rota `/library/folders/:folderId` foi movida para fora da `StatefulShellBranch` em vez de usar `parentNavigatorKey: rootNavigatorKey` dentro da branch, porque o `go_router` valida que subrotas de uma branch usem `parentNavigatorKey` nulo ou igual ao navigator da propria branch.

---

## Validacao

- `dart format .` - concluido fora do sandbox em 2026-05-04.
- `flutter analyze` - sem issues, concluido fora do sandbox em 2026-05-04.
- `flutter test` - 154 testes passaram, concluido fora do sandbox em 2026-05-04.
