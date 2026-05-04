---
title: "ANI-73 - Tela de pasta da biblioteca"
prd: "https://joaogoliveiragarcia.atlassian.net/wiki/spaces/ANM/pages/17989633/PRD+RF+04+Armazenamento+e+organiza+o+de+an+lises"
ticket: "https://joaogoliveiragarcia.atlassian.net/browse/ANI-73?atlOrigin=eyJpIjoiOWZlMjI0M2JkMTgxNDhiMWIwMDljYzM0YTc3ZjIyMWYiLCJwIjoiaiJ9"
last_updated_at: "2026-05-04"
---

# 1. Objetivo

Implementar a tela dedicada de uma pasta da biblioteca para substituir o placeholder de `/library/folders/:folderId`, permitindo carregar metadados da pasta, listar análises vinculadas, abrir uma análise, selecionar múltiplos itens, mover análises em lote para outra pasta ou para `Sem pasta`, arquivar análises em lote e gerenciar a pasta por modal de configuração. Ao abrir uma pasta vazia, a tela deve exibir o fluxo de adicionar análises disponíveis; ao confirmar a seleção, as análises adicionadas devem aparecer na pasta. A implementação deve respeitar a arquitetura MVP, `Riverpod`, `Signals`, `GoRouter` e os contratos tipados do `core`.

---

# 2. Escopo

## 2.1 In-scope

- Criar a tela `LibraryFolderScreen` para a rota `/library/folders/:folderId`.
- Carregar `FolderDto` e análises da pasta com paginação por cursor.
- Exibir estados de loading, erro recuperável, conteúdo e pasta vazia com fluxo de adicionar análises.
- Ao abrir uma pasta vazia, listar análises disponíveis para seleção e permitir adicioná-las à pasta atual.
- Abrir uma análise salva pela rota `/analyses/:analysisId`.
- Controlar seleção múltipla local e exibir action bar inferior quando houver seleção.
- Mover análises selecionadas em lote para outra pasta existente ou para `Sem pasta`.
- Arquivar análises selecionadas em lote, sem exclusão permanente.
- Abrir modal de configuração da pasta para renomear e arquivar a pasta.
- Atualizar contratos `core`, implementação `rest`, providers e rotas necessários.
- Seguir os nodes `HoZeb` e `VqUTX` de `design/animus.pen`, adaptando tokens ao `AppTheme`.

## 2.2 Out-of-scope

- Área `Sem pasta` funcional em `/library/unfoldered`.
- Busca textual dentro de análises salvas.
- Exclusão permanente de análises.
- Compartilhamento de análises entre usuários.
- Exportação da listagem de análises.
- Botão `+` para adicionar análises quando a pasta já possui conteúdo.
- CRUD completo de pastas fora das operações necessárias nesta tela.
- Mudanças no `animus-server`; esta spec assume os endpoints de ANI-66 como disponíveis.

---

# 3. Requisitos

## 3.1 Funcionais

- A tela deve receber `folderId` pela rota e bloquear a entrada quando o parâmetro estiver vazio.
- A tela deve buscar os metadados da pasta e a primeira página de análises vinculadas.
- Ao clicar em uma pasta na biblioteca, a rota deve abrir a tela daquela pasta e exibir as análises vinculadas a ela, não uma nova listagem de pastas.
- As análises devem ser exibidas com nome e data de criação; quando o nome vier vazio, usar fallback visual `Análise sem nome`.
- O contador no header deve refletir a quantidade carregada da pasta ou `FolderDto.analysisCount`, priorizando o valor remoto quando disponível.
- Se a pasta não tiver análises, a tela não deve parar em uma mensagem vazia: deve mostrar a lista de análises disponíveis para adicionar à pasta.
- Na lista de adição da pasta vazia, o usuário deve poder selecionar uma ou mais análises disponíveis e confirmar a adição.
- Ao confirmar a adição com sucesso, chamar o contrato de mover/adicionar análises para a pasta atual, atualizar a lista local e exibir imediatamente as análises adicionadas dentro da pasta.
- Em falha ao adicionar análises na pasta vazia, manter a seleção e não alterar a lista local da pasta.
- Ao tocar em uma análise fora do modo seleção, navegar para `Routes.getAnalysis`.
- Ao tocar no checkbox do item, alternar a seleção da análise.
- Ao selecionar ao menos uma análise, exibir action bar com contador, ação `Mover` e ação de arquivamento.
- Ao mover com sucesso para outra pasta ou para `Sem pasta`, remover os itens movidos da lista atual e limpar a seleção.
- Ao arquivar com sucesso, remover os itens arquivados da lista atual e limpar a seleção.
- Em falha de lote, manter seleção e lista local inalteradas.
- O modal de configuração deve permitir renomear a pasta e arquivar a pasta.
- Ao renomear com sucesso, atualizar o nome da pasta no header sem recarregar toda a tela.
- Ao arquivar a pasta com sucesso, voltar para a biblioteca.

## 3.2 Não funcionais

- **Arquitetura:** `View` não chama `RestClient`; toda orquestração fica em `Presenter` consumindo `LibraryService`.
- **Estado:** usar `Signal<T>` e `computed<T>` para estado local da tela e seleção.
- **Navegação:** a rota de pasta deve permanecer autenticada e preservar o estado da branch Biblioteca.
- **Acessibilidade:** botões de voltar, configurações, seleção e ações devem ter área mínima de toque de 44x44 e labels/tooltip semânticos.
- **Performance:** carregar a primeira página com `limit` definido no presenter e buscar próximas páginas apenas quando o scroll aproximar do fim.
- **Consistência visual:** cores, tipografia, bordas e gradientes devem usar `AppThemeTokens` sempre que houver token correspondente.

---

# 4. O que já existe?

## Core

- **`AnalysisDto`** (`lib/core/intake/dtos/analysis_dto.dart`) - DTO de análise com `id`, `name`, `createdAt`, `folderId` e `isArchived`.
- **`FolderDto`** (`lib/core/library/dtos/folder_dto.dart`) - DTO de pasta com `id`, `name`, `analysisCount`, `accountId` e `isArchived`.
- **`LibraryService`** (`lib/core/library/interfaces/library_service.dart`) - contrato atual para listar/criar/buscar/renomear/arquivar pastas e listar análises sem pasta.
- **`IntakeService`** (`lib/core/intake/interfaces/intake_service.dart`) - contrato atual para listar análises por `listAnalyses`, criar, buscar, renomear e arquivar uma análise individual.
- **`CursorPaginationResponse<T>`** (`lib/core/shared/responses/cursor_pagination_response.dart`) - envelope de paginação por cursor.
- **`RestResponse<T>`** (`lib/core/shared/responses/rest_response.dart`) - wrapper de sucesso/falha usado pelos services.
- **`NavigationDriver`** (`lib/core/shared/interfaces/navigation_driver.dart`) - contrato para `goTo`, `pushTo`, `goBack` e `canGoBack`.

## REST

- **`LibraryRestService`** (`lib/rest/services/library_rest_service.dart`) - implementação REST atual de `LibraryService`.
- **`IntakeRestService`** (`lib/rest/services/intake_rest_service.dart`) - implementação REST atual de `IntakeService`.
- **`FolderMapper`** (`lib/rest/mappers/library/folder_mapper.dart`) - mapper de payload `snake_case` para `FolderDto`.
- **`AnalysisMapper`** (`lib/rest/mappers/intake/analysis_mapper.dart`) - mapper de payload `snake_case` para `AnalysisDto`.
- **`CursorPaginationMapper`** (`lib/rest/mappers/shared/cursor_pagination_mapper.dart`) - mapper para respostas com `items`/`data` e `next_cursor`.
- **`libraryServiceProvider`** (`lib/rest/services/index.dart`) - provider Riverpod que compõe `LibraryRestService`.

## UI

- **`LibraryScreenView`** (`lib/ui/storage/widgets/pages/library_screen/library_screen_view.dart`) - tela atual da biblioteca com listagem de pastas e navegação para pasta.
- **`LibraryScreenPresenter`** (`lib/ui/storage/widgets/pages/library_screen/library_screen_presenter.dart`) - presenter que carrega pastas e chama `Routes.getLibraryFolder`.
- **`FolderListItem`** (`lib/ui/storage/widgets/pages/library_screen/folder_list_item/folder_list_item_view.dart`) - item visual de pasta.
- **`CreateFolderModal`** (`lib/ui/storage/widgets/pages/library_screen/create_folder_modal/create_folder_modal_view.dart`) - referência de modal/form de pasta existente.
- **`RecentAnalysesSection`** (`lib/ui/intake/widgets/pages/home_screen/recent_analyses_section/recent_analyses_section_view.dart`) - referência de lista paginada, estados e pull-to-refresh.
- **`RecentAnalysisCard`** (`lib/ui/intake/widgets/pages/home_screen/recent_analyses_section/recent_analysis_card/recent_analysis_card_view.dart`) - referência de card de análise.
- **`RenameAnalysisDialog`** (`lib/ui/intake/widgets/pages/analysis_screen/analysis_header/rename_analysis_dialog/rename_analysis_dialog_view.dart`) - referência de diálogo de renomeação.
- **`ArchiveAnalysisDialog`** (`lib/ui/intake/widgets/pages/analysis_screen/analysis_header/archive_analysis_dialog/archive_analysis_dialog_view.dart`) - referência de confirmação de arquivamento.

## Rotas e Design

- **`Routes.libraryFolder`** (`lib/constants/routes.dart`) - rota `/library/folders/:folderId` já declarada.
- **`Routes.getLibraryFolder`** (`lib/constants/routes.dart`) - builder de URL com `Uri.encodeComponent`.
- **`router.dart`** (`lib/router.dart`) - registra a rota de pasta como placeholder.
- **`AppShell`** (`lib/ui/shared/widgets/pages/app_shell/app_shell_view.dart`) - shell autenticado com bottom navigation.
- **Node `HoZeb`** (`design/animus.pen`) - tela "G - Pasta" com header, lista de análises, alerta e action bar.
- **Node `VqUTX`** (`design/animus.pen`) - modal "Config Pasta" com input de nome, atualizar nome, perigo e deletar pasta.

---

# 5. O que deve ser criado?

## Camada UI (Presenters)

- **Localização:** `lib/ui/storage/widgets/pages/library_folder_screen/library_folder_screen_presenter.dart` (**novo arquivo**)
- **Dependências injetadas:** `LibraryService`, `IntakeService` e `NavigationDriver`.
- **Estado (`signals`):**
  - `Signal<bool> isLoadingInitialData` - indica carga inicial de pasta e análises.
  - `Signal<bool> isLoadingMore` - indica paginação incremental.
  - `Signal<bool> isLoadingAvailableAnalyses` - indica carga da lista de análises disponíveis para adicionar em pasta vazia.
  - `Signal<bool> isAddingAvailableAnalyses` - bloqueia confirmações concorrentes ao adicionar análises à pasta vazia.
  - `Signal<bool> isMovingAnalyses` - bloqueia operações concorrentes de mover.
  - `Signal<bool> isArchivingAnalyses` - bloqueia operações concorrentes de arquivamento.
  - `Signal<bool> isManagingFolder` - bloqueia renomeação/arquivamento concorrente da pasta.
  - `Signal<String?> generalError` - mensagem recuperável para falhas remotas.
  - `Signal<FolderDto?> folder` - metadados da pasta carregada.
  - `Signal<List<AnalysisDto>> analyses` - análises visíveis da pasta.
  - `Signal<List<AnalysisDto>> availableAnalyses` - análises não arquivadas disponíveis para adicionar quando a pasta atual estiver vazia.
  - `Signal<Set<String>> selectedAnalysisIds` - seleção múltipla por id.
  - `Signal<Set<String>> selectedAvailableAnalysisIds` - seleção da lista de análises disponíveis para adicionar à pasta vazia.
  - `Signal<String?> nextCursor` - cursor da próxima página.
  - `ReadonlySignal<bool> hasMore` - `true` quando `nextCursor` não está vazio.
  - `ReadonlySignal<bool> hasSelection` - `true` quando há ids selecionados.
  - `ReadonlySignal<int> selectedCount` - quantidade de ids selecionados.
  - `ReadonlySignal<bool> showAvailableAnalysisPicker` - `true` quando não está carregando, não há erro, a pasta está vazia e `isLoadingAvailableAnalyses` está ativo ou `availableAnalyses` tem itens.
  - `ReadonlySignal<bool> showEmptyState` - `true` apenas quando a pasta está vazia, `availableAnalyses` também está vazia e não há carregamento de análises disponíveis em andamento.
- **Provider Riverpod:** `libraryFolderScreenPresenterProvider`, `Provider.autoDispose.family<LibraryFolderScreenPresenter, String>`.
- **Métodos:**
  - `Future<void> initialize()` - garante carga inicial única para o `folderId`.
  - `Future<void> load()` - busca `getFolder` e `listFolderAnalyses` em paralelo, popula estado e, se a pasta vier vazia, chama `loadAvailableAnalysesForEmptyFolder`.
  - `Future<void> refresh()` - limpa cursor/lista e recarrega a primeira página.
  - `Future<void> loadNextPage()` - busca próxima página por `nextCursor`.
  - `Future<void> loadAvailableAnalysesForEmptyFolder()` - chama `IntakeService.listAnalyses(isArchived: false, limit: 50)`, remove itens sem `id` e remove itens já vinculados à pasta caso existam no estado local.
  - `void toggleAvailableAnalysisSelection(String analysisId)` - adiciona/remove id da seleção da lista de análises disponíveis.
  - `void clearAvailableAnalysisSelection()` - limpa a seleção da lista de análises disponíveis.
  - `Future<void> addSelectedAvailableAnalyses()` - chama `LibraryService.moveAnalysesToFolder` com `folderId` da rota, atualiza `analyses` com os itens adicionados e limpa `selectedAvailableAnalysisIds` somente em sucesso.
  - `Future<void> openAnalysis(AnalysisDto analysis)` - navega para `/analyses/:analysisId` quando houver `id`.
  - `void toggleSelection(String analysisId)` - adiciona/remove id da seleção.
  - `void clearSelection()` - limpa a seleção atual.
  - `Future<void> moveSelectedAnalyses(String? folderId)` - chama `LibraryService.moveAnalysesToFolder`, atualiza a lista local e limpa seleção em sucesso.
  - `Future<void> archiveSelectedAnalyses()` - chama `LibraryService.archiveAnalyses`, remove itens arquivados da lista e limpa seleção em sucesso.
  - `Future<bool> renameFolder(String name)` - valida nome, chama `LibraryService.updateFolderName` e atualiza `folder`.
  - `Future<bool> archiveFolder()` - chama `LibraryService.archiveFolder` e volta para a biblioteca em sucesso.
  - `void goBack()` - usa `NavigationDriver.goBack` quando possível; fallback para `Routes.library`.
  - `String formatCreatedAt(String value)` - formata ISO em `dd/MM/yyyy`; fallback `Data indisponível`.
  - `void dispose()` - descarta todos os signals/computeds.

## Camada UI (Views)

- **Localização:** `lib/ui/storage/widgets/pages/library_folder_screen/library_folder_screen_view.dart` (**novo arquivo**)
- **Base class:** `ConsumerWidget`.
- **Props:** `final String folderId`.
- **Bibliotecas de UI:** `flutter/material.dart`, `flutter_riverpod`, `signals_flutter`.
- **Estados visuais:**
  - Loading: skeleton ou `CircularProgressIndicator` central durante carga inicial.
  - Error: mensagem com CTA `Tentar novamente`.
  - Empty/add: quando a pasta não tem análises, renderizar a lista de análises disponíveis para adicionar; usar mensagem vazia apenas se também não houver análises disponíveis.
  - Content: header, lista paginada, alerta e action bar condicional.
- **Responsabilidade:** compor a tela, observar signals do presenter e delegar eventos.

## Camada UI (Widgets Internos)

- **Localização:** `lib/ui/storage/widgets/pages/library_folder_screen/library_folder_header/` (**novo arquivo**)
- **Tipo:** `View only`.
- **Props:** `String title`, `int count`, `VoidCallback onBackPressed`, `VoidCallback onSettingsPressed`.
- **Responsabilidade:** renderizar botão de voltar, nome da pasta, contador e botão de configurações conforme node `HoZeb`.

- **Localização:** `lib/ui/storage/widgets/pages/library_folder_screen/library_folder_analysis_list/` (**novo arquivo**)
- **Tipo:** `View only`.
- **Props:** `List<AnalysisDto> analyses`, `Set<String> selectedAnalysisIds`, `bool isLoadingMore`, `bool hasMore`, `String Function(String) formatCreatedAt`, `Future<void> Function(AnalysisDto) onTapAnalysis`, `void Function(String) onToggleSelection`, `Future<void> Function() onLoadMore`, `Future<void> Function() onRefresh`.
- **Responsabilidade:** renderizar lista com `RefreshIndicator`/scroll listener, disparar paginação e repassar seleção.

- **Localização:** `lib/ui/storage/widgets/pages/library_folder_screen/library_folder_analysis_item/` (**novo arquivo**)
- **Tipo:** `View only`.
- **Props:** `AnalysisDto analysis`, `bool isSelected`, `String dateLabel`, `VoidCallback onTap`, `VoidCallback onToggleSelection`.
- **Responsabilidade:** renderizar card da análise com ícone, nome, data, checkbox e estado selecionado.

- **Localização:** `lib/ui/storage/widgets/pages/library_folder_screen/folder_available_analysis_picker/` (**novo arquivo**)
- **Tipo:** `View only`.
- **Props:** `List<AnalysisDto> availableAnalyses`, `Set<String> selectedAnalysisIds`, `bool isLoading`, `bool isAdding`, `void Function(String) onToggleSelection`, `Future<void> Function() onConfirm`, `Future<void> Function() onRetry`.
- **Responsabilidade:** renderizar, quando a pasta estiver vazia, a lista de análises disponíveis para adicionar à pasta atual. O usuário seleciona uma ou mais análises e confirma; em sucesso, a tela volta a exibir a lista normal da pasta já com as análises adicionadas.

- **Localização:** `lib/ui/storage/widgets/pages/library_folder_screen/library_folder_action_bar/` (**novo arquivo**)
- **Tipo:** `View only`.
- **Props:** `int selectedCount`, `bool isMoving`, `bool isArchiving`, `VoidCallback onMovePressed`, `VoidCallback onArchivePressed`.
- **Responsabilidade:** renderizar a action bar inferior do node `HoZeb`; desabilitar ações durante operação remota.

- **Localização:** `lib/ui/storage/widgets/pages/library_folder_screen/library_folder_settings_modal/` (**novo arquivo**)
- **Tipo:** `View + Presenter`.
- **Props:** `FolderDto folder`, `Future<bool> Function(String name) onRename`, `Future<bool> Function() onArchive`.
- **Responsabilidade:** renderizar modal `VqUTX`, controlar campo de nome, validação local, loading e erro de renomear/arquivar.

- **Localização:** `lib/ui/storage/widgets/pages/library_folder_screen/library_folder_settings_modal/library_folder_settings_modal_presenter.dart` (**novo arquivo**)
- **Dependências injetadas:** callbacks recebidos por props; não injeta services.
- **Estado (`signals`):**
  - `Signal<String?> errorMessage` - erro de validação ou operação.
  - `Signal<bool> isUpdatingName` - loading de renomeação.
  - `Signal<bool> isArchivingFolder` - loading de arquivamento da pasta.
- **Métodos:**
  - `Future<bool> submitName(String name)` - valida nome não vazio e até 50 caracteres, chama `onRename`.
  - `Future<bool> confirmArchive()` - chama `onArchive`.
  - `void dispose()` - descarta signals.

- **Localização:** `lib/ui/storage/widgets/pages/library_folder_screen/folder_destination_picker/` (**novo arquivo**)
- **Tipo:** `View + Presenter`.
- **Props:** `String currentFolderId`, `Future<void> Function(String? folderId) onSelected`.
- **Responsabilidade:** abrir seletor de destino para mover análises, incluindo opção `Sem pasta` e pastas existentes.

- **Localização:** `lib/ui/storage/widgets/pages/library_folder_screen/folder_destination_picker/folder_destination_picker_presenter.dart` (**novo arquivo**)
- **Dependências injetadas:** `LibraryService`.
- **Estado (`signals`):**
  - `Signal<bool> isLoading` - carga de pastas.
  - `Signal<String?> errorMessage` - erro recuperável.
  - `Signal<List<FolderDto>> folders` - pastas disponíveis, excluindo a pasta atual.
- **Provider Riverpod:** `folderDestinationPickerPresenterProvider`, `Provider.autoDispose.family<FolderDestinationPickerPresenter, String>`.
- **Métodos:**
  - `Future<void> load()` - chama `LibraryService.listFolders(limit: 50)` e remove `currentFolderId`.
  - `Future<void> retry()` - recarrega lista.
  - `void dispose()` - descarta signals.

- **Localização:** `lib/ui/storage/widgets/pages/library_folder_screen/library_folder_empty_state/` (**novo arquivo**)
- **Tipo:** `View only`.
- **Props:** nenhuma obrigatória.
- **Responsabilidade:** renderizar fallback de vazio apenas quando a pasta não tem análises e também não existem análises disponíveis para adicionar.

- **Localização:** `lib/ui/storage/widgets/pages/library_folder_screen/library_folder_error_state/` (**novo arquivo**)
- **Tipo:** `View only`.
- **Props:** `String message`, `VoidCallback onRetry`.
- **Responsabilidade:** renderizar erro recuperável.

## Camada UI (Barrel Files / `index.dart`)

- **Localização:** `lib/ui/storage/widgets/pages/library_folder_screen/index.dart` (**novo arquivo**)
- **`typedef` exportado:** `typedef LibraryFolderScreen = LibraryFolderScreenView`.
- **Widgets internos exportados:** exportar apenas os barrels dos widgets usados fora da pasta, se houver. Os subwidgets internos permanecem importados pela própria tela.

- **Localização:** `lib/ui/storage/widgets/pages/library_folder_screen/<widget_interno>/index.dart` (**novo arquivo**)
- **`typedef` exportado:** um typedef por widget, como `typedef LibraryFolderHeader = LibraryFolderHeaderView`.

## Camada Core (Interfaces / Contratos)

- **Localização:** `lib/core/library/interfaces/library_service.dart`
- **Métodos novos:**
  - `Future<RestResponse<CursorPaginationResponse<AnalysisDto>>> listFolderAnalyses({required String folderId, String? cursor, required int limit})` - lista análises não arquivadas vinculadas à pasta.
  - `Future<RestResponse<void>> moveAnalysesToFolder({required List<String> analysisIds, required String? folderId})` - move análises em lote para uma pasta ou para `Sem pasta`.
  - `Future<RestResponse<void>> archiveAnalyses({required List<String> analysisIds})` - arquiva análises em lote de forma atômica.
- **Decisão:** manter essas operações em `LibraryService`, porque a codebase já usa esse contrato para fluxos de biblioteca e já consulta `/intake/analyses/unfoldered` por `LibraryRestService`.

## Camada REST (Services)

- **Localização:** `lib/rest/services/library_rest_service.dart`
- **Interface implementada:** `LibraryService`.
- **Dependências:** `RestClient`, `CacheDriver`, `NavigationDriver`.
- **Métodos novos:**
  - `Future<RestResponse<CursorPaginationResponse<AnalysisDto>>> listFolderAnalyses({required String folderId, String? cursor, required int limit})` - chama endpoint de listagem da pasta, aplica `CursorPaginationMapper.toDto<AnalysisDto>`.
  - `Future<RestResponse<void>> moveAnalysesToFolder({required List<String> analysisIds, required String? folderId})` - chama `PATCH /intake/analyses/folder` com `analysis_ids` e `folder_id`; usa `toVoidResponse`.
  - `Future<RestResponse<void>> archiveAnalyses({required List<String> analysisIds})` - chama `PATCH /intake/analyses/archive` com `analysis_ids`; usa `toVoidResponse`.

## Rotas (`go_router`)

- **Localização:** `lib/router.dart`
- **Caminho da rota:** `/library/folders/:folderId`.
- **Widget principal:** `LibraryFolderScreen(folderId: folderId)`.
- **Guards / redirecionamentos:** se `folderId` vazio, redirecionar para `Routes.library`.
- **Estratégia visual:** registrar a rota autenticada na branch Biblioteca usando `parentNavigatorKey: rootNavigatorKey` para exibir a tela full-screen acima do `AppShell`, evitando conflito entre bottom navigation e action bar inferior, enquanto preserva a pilha da branch.

## Estrutura de Pastas

```text
lib/ui/storage/widgets/pages/library_folder_screen/
  index.dart
  library_folder_screen_view.dart
  library_folder_screen_presenter.dart
  folder_available_analysis_picker/
    index.dart
    folder_available_analysis_picker_view.dart
  folder_destination_picker/
    index.dart
    folder_destination_picker_view.dart
    folder_destination_picker_presenter.dart
  library_folder_action_bar/
    index.dart
    library_folder_action_bar_view.dart
  library_folder_analysis_item/
    index.dart
    library_folder_analysis_item_view.dart
  library_folder_analysis_list/
    index.dart
    library_folder_analysis_list_view.dart
  library_folder_empty_state/
    index.dart
    library_folder_empty_state_view.dart
  library_folder_error_state/
    index.dart
    library_folder_error_state_view.dart
  library_folder_header/
    index.dart
    library_folder_header_view.dart
  library_folder_settings_modal/
    index.dart
    library_folder_settings_modal_view.dart
    library_folder_settings_modal_presenter.dart
```

---

# 6. O que deve ser modificado?

## Core

- **Arquivo:** `lib/core/library/interfaces/library_service.dart`
- **Mudança:** adicionar contratos `listFolderAnalyses`, `moveAnalysesToFolder` e `archiveAnalyses`.
- **Justificativa:** a tela precisa listar análises da pasta e executar operações batch sem conhecer endpoints.

- **Arquivo:** `lib/core/intake/interfaces/intake_service.dart`
- **Mudança:** não adicionar contrato obrigatório; reutilizar `listAnalyses(isArchived: false)` para carregar análises disponíveis no fluxo de adicionar em pasta vazia.
- **Justificativa:** o contrato atual já expõe a listagem paginada de análises salvas não arquivadas.

## REST

- **Arquivo:** `lib/rest/services/library_rest_service.dart`
- **Mudança:** implementar os novos métodos de `LibraryService`, incluindo payloads `analysis_ids` e `folder_id`.
- **Justificativa:** manter transporte HTTP encapsulado na camada REST e reaproveitar `AnalysisMapper`.

## UI

- **Arquivo:** `lib/router.dart`
- **Mudança:** substituir o placeholder da rota `Routes.libraryFolder` por `LibraryFolderScreen(folderId: folderId)` e redirecionar `folderId` vazio para `Routes.library`.
- **Justificativa:** ANI-73 entrega a tela real de pasta.

- **Arquivo:** `lib/router.dart`
- **Mudança:** importar `package:animus/ui/storage/widgets/pages/library_folder_screen/index.dart`.
- **Justificativa:** disponibilizar o widget da nova rota.

- **Arquivo:** `lib/ui/storage/widgets/pages/library_screen/library_screen_presenter.dart`
- **Mudança:** manter `openFolder` usando `Routes.getLibraryFolder`, sem alteração funcional esperada.
- **Justificativa:** a navegação da biblioteca já aponta para a rota correta.

- **Arquivo:** `lib/ui/storage/widgets/pages/library_screen/library_screen_view.dart`
- **Mudança:** não aplicar mudança obrigatória; revisar apenas se a nova navegação exigir feedback de pasta sem `id`.
- **Justificativa:** a tela já valida `f.id != null` antes de abrir a pasta.

---

# 7. O que deve ser removido?

## UI

- **Arquivo:** `lib/router.dart`
- **Motivo da remoção:** remover o `Scaffold` com texto `Pasta $folderId (Placeholder)`.
- **Impacto esperado:** a rota passa a abrir `LibraryFolderScreen` e deixa de expor placeholder ao usuário.

---

# 8. Decisões Técnicas e Trade-offs

- **Decisão:** concentrar contratos de pasta e organização em lote em `LibraryService`.
- **Alternativas consideradas:** adicionar métodos em `IntakeService`, conforme texto do ticket ANI-73.
- **Motivo da escolha:** a codebase já possui `core/library`, `LibraryService`, `LibraryRestService` e usa esse service para fluxos de biblioteca, incluindo análises sem pasta.
- **Impactos / trade-offs:** `LibraryRestService` continuará chamando endpoints `/intake/analyses/*` quando o caso de uso for organização da biblioteca.

- **Decisão:** usar `parentNavigatorKey: rootNavigatorKey` na rota de pasta.
- **Alternativas consideradas:** manter a tela dentro do `AppShell` com bottom navigation visível.
- **Motivo da escolha:** o node `HoZeb` tem action bar inferior própria e não prevê bottom navigation; a documentação atual de `go_router` aponta `parentNavigatorKey` como mecanismo para escolher o `Navigator` onde a página é colocada.
- **Impactos / trade-offs:** a tela fica full-screen acima do shell, mas ainda é autenticada e retorna para a biblioteca com `NavigationDriver.goBack`.

- **Decisão:** pasta vazia abre o fluxo de adicionar análises disponíveis, sem depender de botão `+`.
- **Alternativas consideradas:** exibir apenas um estado vazio informativo ou exigir um botão `+` no header.
- **Motivo da escolha:** ao clicar em uma pasta vazia, o usuário precisa conseguir preencher a pasta no mesmo fluxo; a spec deve deixar explícito que, ao confirmar a seleção, as análises passam a aparecer na pasta.
- **Impactos / trade-offs:** a tela de pasta vazia fica mais funcional, mas exige carregar também a lista de análises disponíveis.

- **Decisão:** tratar `Deletar` do design como arquivamento, não exclusão permanente.
- **Alternativas consideradas:** implementar exclusão definitiva.
- **Motivo da escolha:** o PRD deixa exclusão permanente fora do escopo, e ANI-66 define `PATCH /intake/analyses/archive` para arquivamento em lote.
- **Impactos / trade-offs:** textos de confirmação devem dizer `Arquivar` ou explicar que não é remoção definitiva, mesmo se o rótulo visual do node usar `Deletar`.

- **Decisão:** operações batch são otimistas apenas após sucesso remoto.
- **Alternativas consideradas:** remover itens da UI antes da resposta e reverter em falha.
- **Motivo da escolha:** ANI-66 exige atomicidade; falha parcial não deve gerar estado local divergente.
- **Impactos / trade-offs:** feedback pode parecer menos instantâneo, mas evita inconsistência.

- **Decisão:** `LibraryFolderScreenPresenter` orquestra dados da rota; modais com estado próprio têm presenters dedicados.
- **Alternativas consideradas:** concentrar form, seletor e operações no presenter da tela.
- **Motivo da escolha:** as regras de UI exigem presenters filhos para widgets com estado, handlers ou validação própria.
- **Impactos / trade-offs:** mais arquivos, porém responsabilidades menores e manutenção mais simples.

---

# 9. Diagramas e Referências

- **Fluxo de dados:**

```text
LibraryFolderScreenView
  -> LibraryFolderScreenPresenter
  -> libraryFolderScreenPresenterProvider(folderId)
  -> LibraryService
  -> LibraryRestService
  -> RestClient
  -> API

LibraryFolderScreenView
  -> signals/computeds
  -> loading/error/empty/content/action bar
```

- **Fluxo de adicionar análises em pasta vazia:**

```text
LibraryScreen -> click na pasta -> LibraryFolderScreenView
  -> LibraryFolderScreenPresenter.load
  -> LibraryService.listFolderAnalyses
  -> analyses vazio
  -> IntakeService.listAnalyses(isArchived: false)
  -> FolderAvailableAnalysisPicker
  -> usuario seleciona analises disponiveis
  -> LibraryService.moveAnalysesToFolder(folderId atual)
  -> atualiza analyses e exibe os itens dentro da pasta
```

- **Fluxo de mover análises:**

```text
Action Bar -> FolderDestinationPicker -> LibraryFolderScreenPresenter
  -> LibraryService.moveAnalysesToFolder
  -> LibraryRestService
  -> PATCH /intake/analyses/folder
  -> remove itens da lista local somente em sucesso
```

- **Fluxo de arquivar análises:**

```text
Action Bar -> confirmacao -> LibraryFolderScreenPresenter
  -> LibraryService.archiveAnalyses
  -> LibraryRestService
  -> PATCH /intake/analyses/archive
  -> remove itens da lista local somente em sucesso
```

- **Hierarquia de widgets:**

```text
LibraryFolderScreenView
  LibraryFolderHeader
  LibraryFolderErrorState | FolderAvailableAnalysisPicker | LibraryFolderEmptyState | LibraryFolderAnalysisList
    LibraryFolderAnalysisItem
  LibraryFolderActionBar
  LibraryFolderSettingsModal
  FolderDestinationPicker
```

- **Referências de implementação:**
  - `lib/ui/storage/widgets/pages/library_screen/library_screen_view.dart`
  - `lib/ui/storage/widgets/pages/library_screen/library_screen_presenter.dart`
  - `lib/ui/storage/widgets/pages/library_screen/create_folder_modal/create_folder_modal_view.dart`
  - `lib/ui/intake/widgets/pages/home_screen/home_screen_presenter.dart`
  - `lib/ui/intake/widgets/pages/home_screen/recent_analyses_section/recent_analyses_section_view.dart`
  - `lib/ui/intake/widgets/pages/home_screen/recent_analyses_section/recent_analysis_card/recent_analysis_card_view.dart`
  - `lib/ui/intake/widgets/pages/analysis_screen/analysis_header/rename_analysis_dialog/rename_analysis_dialog_view.dart`
  - `lib/ui/intake/widgets/pages/analysis_screen/analysis_header/archive_analysis_dialog/archive_analysis_dialog_view.dart`
  - `lib/core/library/interfaces/library_service.dart`
  - `lib/rest/services/library_rest_service.dart`
  - `lib/constants/routes.dart`
  - `lib/router.dart`
  - `design/animus.pen` nodes `HoZeb` e `VqUTX`

---

# 10. Pendências / Dúvidas

- **Descrição da pendência:** o PRD RF 04 registra ANI-73 como concluída, mas a codebase local ainda possui placeholder em `lib/router.dart`.
- **Impacto na implementação:** esta spec assume a codebase local como fonte do estado a implementar e o PRD como fonte do comportamento esperado.
- **Ação sugerida:** validar se o branch atual está atrasado em relação à implementação concluída ou se a spec deve guiar uma reimplementação.

- **Descrição da pendência:** o endpoint exato para listar análises de uma pasta não aparece implementado no mobile atual.
- **Impacto na implementação:** `listFolderAnalyses` precisa confirmar com o backend se deve chamar `GET /library/folders/{folderId}/analyses` ou `GET /intake/analyses` com filtro `folder_id`.
- **Ação sugerida:** validar contrato com backend antes de implementar `LibraryRestService.listFolderAnalyses`.

- **Descrição da pendência:** ANI-66 permite que endpoints batch retornem lista de análises, mas o `RestClient` mobile tipa respostas como `Json` (`Map<String, dynamic>`).
- **Impacto na implementação:** se o backend responder array JSON direto, a camada REST mobile pode exigir ajuste no contrato do `RestClient`; se responder objeto ou sem body, `RestResponse<void>` atende esta tela.
- **Ação sugerida:** confirmar se `PATCH /intake/analyses/folder` e `PATCH /intake/analyses/archive` retornam objeto/sem body para manter `toVoidResponse`.

- **Descrição da pendência:** ANI-73 usa "excluir/deletar" no layout, enquanto PRD e ANI-66 definem arquivamento para análises.
- **Impacto na implementação:** textos finais de UI devem evitar interpretação de exclusão permanente.
- **Ação sugerida:** validar copy com produto/design; se não houver resposta, usar "Arquivar" nos diálogos e manter ícone de lixeira apenas como referência visual do design.

---

# Restrições

- Não incluir testes automatizados na spec.
- A `View` não deve conter lógica de negócio; toda orquestração fica no `Presenter`.
- Presenters não fazem chamadas diretas a `RestClient`; consomem sempre uma interface de serviço do `core`.
- Todos os caminhos citados existem no projeto ou estão marcados como **novo arquivo**.
- Não introduzir dependência de `Dio`, `GoRouter` concreto ou payload cru em `core`.
- Não fazer parse de `Map<String, dynamic>` na UI.
- Todo widget novo deve seguir o padrão `View + Presenter`; o `Presenter` é opcional apenas para widgets puramente visuais sem estado, handlers ou lógica.
- O `Presenter` da screen deve ser enxuto e orquestrador.
- Widgets internos com estado, handlers ou validação devem ter pasta própria com `index.dart`, `*_view.dart` e `*_presenter.dart`.
- Usar componentes Flutter Material alinhados ao tema do projeto.
- Arquivar análises ou pasta não pode ser tratado como exclusão permanente na lógica local.
