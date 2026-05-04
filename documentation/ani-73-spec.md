---
title: Tela de pasta da biblioteca
status: closed
prd: https://joaogoliveiragarcia.atlassian.net/wiki/spaces/ANM/pages/17989633/PRD+RF+04+Armazenamento+e+organiza+o+de+an+lises
ticket: https://joaogoliveiragarcia.atlassian.net/browse/ANI-73
last_updated_at: 2026-05-04
---

# 1. Objetivo

Detalhar a implementação do fluxo de biblioteca e pasta no recorte `ANI-73`: a tela `F - Biblioteca` (`smS6d`) já existe como entrada do usuário e deve exibir as seções `Sem pasta` e `Pastas`; ao tocar em uma pasta da seção `Pastas`, o app abre a tela `G - Pasta` (`HoZeb`) em `/library/folders/:folderId`. A tela de pasta deve carregar metadados, listar análises associadas, abrir análises salvas, selecionar itens, mover análises em lote para outra pasta ou para `Sem pasta`, arquivar análises em lote, renomear a pasta e arquivar a pasta. Quando a pasta estiver vazia, a tela deve mostrar todas as análises disponíveis para adição; o usuário seleciona quais análises quer adicionar e, ao confirmar, essas análises passam a aparecer dentro da pasta. A entrega deve respeitar `MVP`, `Riverpod`, `signals`, `GoRouter`, `Dio`, `RestResponse`, os contratos dos bounded contexts `library` e `intake`, e a hierarquia visual dos nodes `smS6d` (`F - Biblioteca`), `HoZeb` (`G - Pasta`) e `VqUTX` (`Modal - Config Pasta`) em `design/animus.pen`.

---

# 2. Escopo

## 2.1 In-scope

- Registrar e consumir a rota autenticada `Routes.libraryFolder = '/library/folders/:folderId'`.
- Manter a tela principal da biblioteca baseada no node `smS6d` (`F - Biblioteca`) com duas seções: `Sem pasta` e `Pastas`.
- Navegar da seção `Pastas` da biblioteca para a tela de pasta ao tocar em uma pasta válida.
- Carregar os metadados da pasta por `LibraryService.getFolder({required String folderId})`.
- Listar análises ativas da pasta por `LibraryService.listFolderAnalyses({required String folderId, String? cursor, required int limit})`.
- Ao entrar em uma pasta vazia, carregar e exibir análises disponíveis para adição à pasta.
- Permitir que o usuário selecione uma ou mais análises disponíveis e confirme a adição.
- Após adicionar análises à pasta vazia, exibir imediatamente essas análises na lista da pasta.
- Renderizar estados visuais de `Loading`, `Error`, `AvailablePicker`, `Empty` e `Content`.
- Permitir `pull-to-refresh` e paginação por cursor ao chegar ao fim da lista.
- Abrir uma análise salva por `Routes.getAnalysis({required String analysisId})`.
- Controlar seleção múltipla local de análises exibidas na pasta.
- Exibir action bar inferior apenas quando houver seleção.
- Mover análises selecionadas para outra pasta existente ou para `Sem pasta`.
- Arquivar análises selecionadas em lote, sem exclusão permanente.
- Abrir modal de configurações da pasta.
- Renomear a pasta com validação local de nome obrigatório e máximo de 50 caracteres.
- Arquivar a pasta e retornar para a tela principal da biblioteca.
- Atualizar a lista e o contador local apenas após sucesso das operações batch.
- Adaptar o visual dos nodes `HoZeb` e `VqUTX` aos tokens atuais de `AppThemeTokens` e componentes Flutter Material.
- Manter largura máxima visual de `402px` na tela de pasta.

## 2.2 Out-of-scope

- Tela dedicada completa de `/library/unfoldered`; a seção `Sem pasta` dentro da tela `F - Biblioteca` permanece contemplada neste fluxo.
- Busca textual dentro de análises salvas.
- Filtros, ordenação manual ou agrupamentos adicionais dentro da pasta.
- Exclusão permanente de análises ou pastas.
- Compartilhamento de análises entre usuários.
- Uma análise pertencer a múltiplas pastas simultaneamente.
- Exportação da listagem da pasta.
- Alterações no fluxo de geração, síntese, precedentes ou exportação individual de relatório.
- Cache offline da pasta ou da lista de análises.
- Mudanças de backend além do consumo dos contratos REST já previstos para `library` e `intake`.

---

# 3. Requisitos

## 3.1 Funcionais

- A rota `/library/folders/:folderId` deve rejeitar `folderId` ausente ou vazio e redirecionar para `Routes.library`.
- A tela principal da biblioteca deve existir como `F - Biblioteca` e exibir duas seções principais: `Sem pasta` e `Pastas`.
- A seção `Sem pasta` da tela `F - Biblioteca` deve exibir análises sem pasta para acesso rápido, sem ser confundida com a rota dedicada `/library/unfoldered`.
- A seção `Pastas` da tela `F - Biblioteca` deve exibir cards de pasta e navegar para `Routes.getLibraryFolder(folderId: folderId)` ao tocar em uma pasta.
- A tela de pasta deve carregar metadados da pasta e primeira página de análises em paralelo.
- O cabeçalho deve exibir nome da pasta, contador de análises, botão de voltar e botão de configurações.
- A lista deve exibir cada análise com nome, data de criação formatada em `dd/MM/yyyy`, ícone de documento e checkbox de seleção.
- Ao entrar em uma pasta sem análises, a tela não deve ficar apenas em estado vazio informativo; ela deve carregar todas as análises disponíveis para adição.
- Análises disponíveis são análises ativas retornadas por `IntakeService.listAnalyses(isArchived: false)` que não pertencem à pasta atual.
- O usuário deve poder selecionar uma ou mais análises disponíveis na pasta vazia.
- Ao confirmar a seleção de análises disponíveis, o presenter deve chamar `LibraryService.moveAnalysesToFolder(analysisIds: ids, folderId: folderId)` para vincular as análises à pasta atual.
- Em sucesso ao adicionar análises, os itens selecionados devem sair da lista de disponíveis e aparecer imediatamente na lista principal da pasta.
- Em falha ao adicionar análises, a seleção de disponíveis deve ser preservada e nenhuma análise deve ser adicionada localmente.
- Quando `analysis.id` estiver vazio, o item não deve navegar nem entrar na seleção.
- Em modo normal, tocar no card deve abrir a análise.
- Em modo seleção, tocar no card deve alternar a seleção do item.
- A action bar inferior deve exibir contador de selecionadas e ações `Mover` e `Arquivar`.
- A ação `Mover` deve abrir seletor de destino com a opção `Sem pasta` e todas as pastas carregadas, exceto a pasta atual.
- A ação `Mover` deve chamar `LibraryService.moveAnalysesToFolder(...)` em uma única requisição batch.
- A ação `Arquivar` deve pedir confirmação explícita antes de chamar `LibraryService.archiveAnalyses(...)`.
- Falha em movimentação ou arquivamento deve manter a seleção e exibir erro recuperável.
- Sucesso em movimentação ou arquivamento deve remover os itens da lista atual, limpar seleção e atualizar o contador da pasta.
- O modal de configurações deve permitir renomear a pasta.
- O modal de configurações deve permitir arquivar a pasta, deixando claro que análises não são excluídas permanentemente.
- Sucesso ao arquivar a pasta deve navegar de volta para `Routes.library`.
- Falhas de carregamento inicial devem exibir estado de erro com CTA de retry.
- Falhas de paginação ou operação em lote não devem apagar dados já renderizados.

## 3.2 Não funcionais

- **Performance:** a carga inicial deve evitar chamadas duplicadas por meio de `initialize()` idempotente.
- **Performance:** `loadNextPage()` não pode executar se já houver carga inicial, paginação ou ausência de `nextCursor`.
- **Performance:** operações batch devem bloquear concorrência por `isOperating`.
- **Acessibilidade:** cards, botões, checkbox, dialogs e modal devem manter labels/textos visíveis e áreas de toque compatíveis com Material.
- **Offline/Conectividade:** falhas de rede devem manter contexto visual recuperável e permitir retry.
- **Segurança:** a UI não deve lidar com token, header HTTP ou payload cru; autenticação permanece encapsulada na classe base `Service`.
- **Compatibilidade:** a implementação deve continuar usando Flutter Material, `flutter_riverpod`, `signals_flutter`, `go_router` e `dio` já presentes na aplicação.
- **Arquitetura:** `View` não deve conter regra de negócio; seleção, paginação, movimentação, arquivamento e navegação ficam no `Presenter`.
- **Arquitetura:** presenters não acessam `RestClient`; eles consomem `LibraryService` e `NavigationDriver`.
- **Robustez:** respostas `404` e `403` da pasta devem virar mensagens amigáveis, sem vazar mensagens técnicas do transporte para a UI.

---

# 4. O que já existe?

## Camada Core

- **`AnalysisDto`** (`lib/core/intake/dtos/analysis_dto.dart`) - DTO usado na lista da pasta, com `id`, `name`, `createdAt`, `folderId`, `isArchived`, `status`, `summary` e `accountId`.
- **`IntakeService`** (`lib/core/intake/interfaces/intake_service.dart`) - contrato já expõe `listAnalyses({String? cursor, required int limit, bool isArchived = false})`, usado para carregar análises disponíveis quando a pasta está vazia.
- **`FolderDto`** (`lib/core/library/dtos/folder_dto.dart`) - DTO de pasta com `id`, `name`, `analysisCount`, `accountId` e `isArchived`.
- **`LibraryService`** (`lib/core/library/interfaces/library_service.dart`) - contrato do bounded context `library`, consumido pela UI e implementado na camada REST.
- **`CursorPaginationResponse<T>`** (`lib/core/shared/responses/cursor_pagination_response.dart`) - wrapper de paginação por cursor com `items` e `nextCursor`.
- **`RestResponse<T>`** (`lib/core/shared/responses/rest_response.dart`) - envelope padrão de sucesso/falha usado pelos services.
- **`NavigationDriver`** (`lib/core/shared/interfaces/navigation_driver.dart`) - contrato usado por presenters para navegar sem acoplar a UI a `GoRouter`.

## Camada REST

- **`LibraryRestService`** (`lib/rest/services/library_rest_service.dart`) - implementação concreta de `LibraryService`; concentra endpoints de pastas e operações batch de análises.
- **`IntakeRestService`** (`lib/rest/services/intake_rest_service.dart`) - implementação concreta de `IntakeService`; fornece `GET /intake/analyses` para carregar análises disponíveis.
- **`FolderMapper`** (`lib/rest/mappers/library/folder_mapper.dart`) - mapper de `FolderDto` para payloads `snake_case`.
- **`AnalysisMapper`** (`lib/rest/mappers/intake/analysis_mapper.dart`) - mapper de análises retornadas por `/intake/analyses`.
- **`CursorPaginationMapper`** (`lib/rest/mappers/shared/cursor_pagination_mapper.dart`) - mapper genérico de respostas com `items` ou `data` e `next_cursor` ou `nextCursor`.
- **`libraryServiceProvider`** (`lib/rest/services/index.dart`) - provider Riverpod que injeta `RestClient`, `CacheDriver` e `NavigationDriver` em `LibraryRestService`.
- **`Service`** (`lib/rest/services/service.dart`) - classe base que valida autenticação e normaliza respostas de services REST.

## Camada UI

- **`LibraryScreenView`** (`lib/ui/library/widgets/pages/library_screen/library_screen_view.dart`) - tela principal da biblioteca, equivalente ao node `smS6d`, que exibe as seções `Sem pasta` e `Pastas` e dispara navegação para a tela de pasta.
- **`LibraryScreenPresenter`** (`lib/ui/library/widgets/pages/library_screen/library_screen_presenter.dart`) - presenter da biblioteca; referência direta de carregamento, criação de pasta e `openFolder(String folderId)`.
- **`LibraryFolderScreenView`** (`lib/ui/library/widgets/pages/library_folder_screen/library_folder_screen_view.dart`) - tela de pasta do recorte `ANI-73`.
- **`LibraryFolderScreenPresenter`** (`lib/ui/library/widgets/pages/library_folder_screen/library_folder_screen_presenter.dart`) - presenter da tela de pasta, responsável por carga, paginação, seleção, batch actions e navegação.
- **`MoveAnalysesModalPresenter`** (`lib/ui/library/widgets/pages/library_folder_screen/move_analyses_modal/move_analyses_modal_presenter.dart`) - presenter do seletor de destino de movimentação.
- **`FolderSettingsModalPresenter`** (`lib/ui/library/widgets/pages/library_folder_screen/folder_settings_modal/folder_settings_modal_presenter.dart`) - presenter do modal de configuração da pasta.
- **`LibraryFolderBackgroundView`** (`lib/ui/library/widgets/pages/library_folder_screen/library_folder_background/library_folder_background_view.dart`) - fundo decorativo da tela, reutilizando `RadialGlow`.
- **`LibraryFolderHeaderView`** (`lib/ui/library/widgets/pages/library_folder_screen/library_folder_header/library_folder_header_view.dart`) - cabeçalho com título, contador, voltar e configurações.
- **`FolderAnalysisListView`** (`lib/ui/library/widgets/pages/library_folder_screen/folder_analysis_list/folder_analysis_list_view.dart`) - lista paginada com `RefreshIndicator` e `NotificationListener<ScrollNotification>`.
- **`FolderAnalysisCardView`** (`lib/ui/library/widgets/pages/library_folder_screen/folder_analysis_card/folder_analysis_card_view.dart`) - card individual de análise.
- **`FolderSelectionActionBarView`** (`lib/ui/library/widgets/pages/library_folder_screen/folder_selection_action_bar/folder_selection_action_bar_view.dart`) - action bar de seleção.
- **`MoveAnalysesModalView`** (`lib/ui/library/widgets/pages/library_folder_screen/move_analyses_modal/move_analyses_modal_view.dart`) - modal de escolha de destino.
- **`FolderSettingsModalView`** (`lib/ui/library/widgets/pages/library_folder_screen/folder_settings_modal/folder_settings_modal_view.dart`) - modal de renomeação e arquivamento da pasta.
- **`ArchiveSelectedAnalysesDialogView`** (`lib/ui/library/widgets/pages/library_folder_screen/archive_selected_analyses_dialog/archive_selected_analyses_dialog_view.dart`) - diálogo de confirmação para arquivamento em lote.
- **`FolderAvailableAnalysisPickerView`** (`lib/ui/storage/widgets/pages/library_folder_screen/folder_available_analysis_picker/folder_available_analysis_picker_view.dart`) - implementação legada no módulo `storage` que serve como referência de comportamento para o picker de análises disponíveis no módulo correto `ui/library`.

## App / Router

- **`Routes.library`** (`lib/constants/routes.dart`) - rota principal da biblioteca.
- **`Routes.libraryFolder`** (`lib/constants/routes.dart`) - rota parametrizada `/library/folders/:folderId`.
- **`Routes.getLibraryFolder({required String folderId})`** (`lib/constants/routes.dart`) - helper que aplica `Uri.encodeComponent` no `folderId`.
- **`Routes.analysis`** (`lib/constants/routes.dart`) - rota de detalhes de análise.
- **`Routes.getAnalysis({required String analysisId})`** (`lib/constants/routes.dart`) - helper usado para abrir análise salva.
- **`appRouter`** (`lib/router.dart`) - registra a tela de pasta no shell autenticado e protege `folderId` vazio via redirect.

## Design

- **`F - Biblioteca`** (`design/animus.pen`, node `smS6d`) - referência visual da tela de biblioteca com seção `Sem pasta`, seção `Pastas`, botão `Nova` e navegação inferior.
- **`G - Pasta`** (`design/animus.pen`, node `HoZeb`) - referência visual da tela de pasta, com status bar, header, cards, seleção e action bar inferior.
- **`Modal - Config Pasta`** (`design/animus.pen`, node `VqUTX`) - referência visual do modal de configurações.
- **Tokens do Pencil** (`design/animus.pen`) - paleta `bg-page`, `bg-card`, `bg-elevated`, `text-primary`, `text-muted`, `red-error` e `indigo` usada como referência para `AppThemeTokens`.

## Pontos de atenção

- **Duplicidade histórica de módulo:** existem artefatos similares em `lib/ui/storage/widgets/pages/library_folder_screen/`, incluindo `folder_available_analysis_picker`, mas a rota de produção importa `lib/ui/library/widgets/pages/library_folder_screen/index.dart`.
- **Sem pasta:** `ANI-73` contempla a seção `Sem pasta` dentro da tela `F - Biblioteca` e o destino `Sem pasta` em movimentações; a rota dedicada `/library/unfoldered` permanece fora deste recorte.

---

# 5. O que deve ser criado?

## Camada UI (Presenters)

- **Localização:** `lib/ui/library/widgets/pages/library_folder_screen/library_folder_screen_presenter.dart` (**novo arquivo no recorte ANI-73**)
- **Dependências injetadas:** `LibraryService`, `IntakeService`, `NavigationDriver`
- **Estado (`signals`):**
- `Signal<bool> isLoading` - controla a primeira carga.
- `Signal<bool> isLoadingMore` - controla paginação.
- `Signal<bool> isLoadingAvailableAnalyses` - controla a carga de análises disponíveis quando a pasta está vazia.
- `Signal<bool> isAddingAvailableAnalyses` - controla o submit de adição de análises à pasta.
- `Signal<bool> isOperating` - bloqueia operações batch concorrentes.
- `Signal<String?> generalError` - guarda erro recuperável.
- `Signal<FolderDto?> folder` - metadados da pasta atual.
- `Signal<List<AnalysisDto>> analyses` - análises renderizadas.
- `Signal<List<AnalysisDto>> availableAnalyses` - análises disponíveis para adição quando a pasta está vazia.
- `Signal<Set<String>> selectedAnalysisIds` - seleção múltipla local.
- `Signal<Set<String>> selectedAvailableAnalysisIds` - seleção local das análises disponíveis.
- `Signal<String?> nextCursor` - cursor da próxima página.
- **Computeds:**
- `ReadonlySignal<bool> hasSelection` - verdadeiro quando há pelo menos uma análise selecionada.
- `ReadonlySignal<int> selectedCount` - quantidade de análises selecionadas.
- `ReadonlySignal<bool> hasMore` - verdadeiro quando `nextCursor` não está vazio.
- `ReadonlySignal<bool> showAvailableAnalysisPicker` - verdadeiro quando a pasta está vazia e há carga ou itens disponíveis para adição.
- `ReadonlySignal<bool> showEmptyState` - verdadeiro quando não há loading, erro, análises da pasta ou análises disponíveis.
- **Provider Riverpod:** `libraryFolderScreenPresenterProvider`
- **Métodos:**
- `Future<void> initialize()` - executa `load()` apenas uma vez por instância do presenter.
- `Future<void> load()` - carrega `getFolder` e primeira página de `listFolderAnalyses` em paralelo.
- `Future<void> refresh()` - limpa seleção, lista e cursor, depois recarrega a pasta.
- `Future<void> loadNextPage()` - carrega próxima página quando `hasMore` estiver verdadeiro.
- `Future<void> loadAvailableAnalysesForEmptyFolder()` - carrega análises ativas por `IntakeService.listAnalyses(isArchived: false)` e remove itens já vinculados à pasta atual.
- `void toggleAvailableAnalysisSelection(String analysisId)` - alterna seleção de análise disponível.
- `void clearAvailableAnalysisSelection()` - limpa seleção de disponíveis.
- `Future<void> addSelectedAvailableAnalyses()` - adiciona análises disponíveis selecionadas à pasta atual via `LibraryService.moveAnalysesToFolder`.
- `Future<void> openAnalysis(AnalysisDto analysis)` - navega para `Routes.getAnalysis` se `analysis.id` for válido.
- `void toggleSelection(String analysisId)` - alterna seleção de uma análise válida.
- `void clearSelection()` - limpa seleção.
- `Future<bool> moveSelectedAnalyses(String? destinationFolderId)` - move seleção para outra pasta ou `Sem pasta`.
- `Future<bool> archiveSelectedAnalyses()` - arquiva seleção em lote.
- `Future<bool> renameFolder(String name)` - valida e atualiza nome da pasta.
- `Future<bool> archiveFolder()` - arquiva a pasta e navega para `Routes.library` em sucesso.
- `void goBack()` - volta na pilha se possível; caso contrário navega para `Routes.library`.
- `String formatCreatedAt(String value)` - formata ISO date em `dd/MM/yyyy` ou retorna fallback.
- `void dispose()` - libera todos os `signals` e `computed`.

- **Localização:** `lib/ui/library/widgets/pages/library_folder_screen/move_analyses_modal/move_analyses_modal_presenter.dart` (**novo arquivo no recorte ANI-73**)
- **Dependências injetadas:** `LibraryService`
- **Estado (`signals`):**
- `Signal<bool> isLoading` - carrega destinos.
- `Signal<String?> generalError` - erro ao carregar destinos.
- `Signal<List<FolderDto>> folders` - pastas disponíveis, excluindo a pasta atual.
- `Signal<String?> selectedFolderId` - destino escolhido; `null` representa `Sem pasta`.
- `Signal<bool> hasSelectedDestination` - diferencia destino `null` escolhido de ausência de escolha.
- **Provider Riverpod:** `moveAnalysesModalPresenterProvider`
- **Métodos:**
- `Future<void> load()` - pagina `LibraryService.listFolders(limit: 50)`, acumulando destinos até `nextCursor` acabar.
- `void selectFolder(String? folderId)` - seleciona destino, incluindo `null` para `Sem pasta`.
- `void dispose()` - libera estado reativo.

- **Localização:** `lib/ui/library/widgets/pages/library_folder_screen/folder_settings_modal/folder_settings_modal_presenter.dart` (**novo arquivo no recorte ANI-73**)
- **Dependências injetadas:** callbacks do `LibraryFolderScreenPresenter` via provider family.
- **Estado (`signals`):**
- `Signal<String> name` - nome editado.
- `Signal<bool> isSavingName` - loading da renomeação.
- `Signal<bool> isArchivingFolder` - loading do arquivamento da pasta.
- `Signal<String?> nameError` - erro de validação do campo.
- `Signal<String?> generalError` - erro operacional do modal.
- **Computed:** `ReadonlySignal<bool> canSaveName` - verdadeiro quando o nome tem 1 a 50 caracteres.
- **Provider Riverpod:** `folderSettingsModalPresenterProvider`
- **Métodos:**
- `void setName(String value)` - atualiza campo e limpa erros.
- `Future<bool> submitRename()` - valida e delega renomeação ao presenter da tela.
- `Future<bool> submitArchiveFolder()` - delega arquivamento ao presenter da tela.
- `void dispose()` - libera estado reativo.

## Camada UI (Views)

- **Localização:** `lib/ui/library/widgets/pages/library_folder_screen/library_folder_screen_view.dart` (**novo arquivo no recorte ANI-73**)
- **Base class:** `ConsumerWidget`
- **Props:** `required String folderId`
- **Bibliotecas de UI:** `flutter/material.dart`, `flutter_riverpod`, `signals_flutter`
- **Estados visuais:** `Loading`, `Error`, `AvailablePicker`, `Empty`, `Content`
- **Responsabilidade:** compor a tela, observar `signals`, abrir modais/dialogs, exibir o picker de análises disponíveis quando a pasta estiver vazia e despachar ações para `LibraryFolderScreenPresenter`.

- **Localização:** `lib/ui/library/widgets/pages/library_folder_screen/move_analyses_modal/move_analyses_modal_view.dart` (**novo arquivo no recorte ANI-73**)
- **Base class:** `ConsumerStatefulWidget`
- **Props:** `required String currentFolderId`, `required int selectedCount`, `required Future<bool> Function(String? folderId) onMove`
- **Bibliotecas de UI:** `flutter/material.dart`, `flutter_riverpod`, `signals_flutter`
- **Estados visuais:** carregando destinos, erro de destinos, lista de destinos, erro de submit.
- **Responsabilidade:** permitir escolha de destino e executar `onMove` apenas quando houver destino selecionado.

- **Localização:** `lib/ui/library/widgets/pages/library_folder_screen/folder_settings_modal/folder_settings_modal_view.dart` (**novo arquivo no recorte ANI-73**)
- **Base class:** `ConsumerStatefulWidget`
- **Props:** `required String folderId`, `required FolderDto folder`
- **Bibliotecas de UI:** `flutter/material.dart`, `flutter_riverpod`, `signals_flutter`
- **Estados visuais:** edição de nome, erro de validação, loading de renomeação, loading de arquivamento.
- **Responsabilidade:** renderizar o modal de configurações e delegar submit ao presenter.

## Camada UI (Widgets Internos)

- **Localização:** `lib/ui/library/widgets/pages/library_folder_screen/folder_available_analysis_picker/` (**novo arquivo**)
- **Tipo:** `View only`
- **Props:** `required List<AnalysisDto> availableAnalyses`, `required Set<String> selectedAnalysisIds`, `required bool isLoading`, `required bool isAdding`, `required void Function(String analysisId) onToggleSelection`, `required Future<void> Function() onConfirm`, `required Future<void> Function() onRetry`
- **Responsabilidade:** renderizar a lista de análises disponíveis quando a pasta estiver vazia, permitir seleção múltipla e confirmar a adição à pasta.

- **Localização:** `lib/ui/library/widgets/pages/library_folder_screen/library_folder_background/` (**novo arquivo no recorte ANI-73**)
- **Tipo:** `View only`
- **Props:** `required AppThemeTokens tokens`
- **Responsabilidade:** renderizar glows decorativos de fundo com `RadialGlow`.

- **Localização:** `lib/ui/library/widgets/pages/library_folder_screen/library_folder_header/` (**novo arquivo no recorte ANI-73**)
- **Tipo:** `View only`
- **Props:** `required String title`, `required int analysisCount`, `required VoidCallback onBack`, `required VoidCallback onSettings`
- **Responsabilidade:** renderizar título, contador, navegação de volta e botão de configurações.

- **Localização:** `lib/ui/library/widgets/pages/library_folder_screen/folder_loading_state/` (**novo arquivo no recorte ANI-73**)
- **Tipo:** `View only`
- **Props:** nenhuma.
- **Responsabilidade:** renderizar skeleton visual da lista durante a carga inicial.

- **Localização:** `lib/ui/library/widgets/pages/library_folder_screen/folder_error_state/` (**novo arquivo no recorte ANI-73**)
- **Tipo:** `View only`
- **Props:** `required String message`, `required Future<void> Function() onRetry`
- **Responsabilidade:** renderizar erro bloqueante inicial com retry.

- **Localização:** `lib/ui/library/widgets/pages/library_folder_screen/folder_empty_state/` (**novo arquivo no recorte ANI-73**)
- **Tipo:** `View only`
- **Props:** `required String folderName`, `required Future<void> Function() onRefresh`
- **Responsabilidade:** renderizar estado vazio somente quando a pasta não tiver análises e também não houver análises disponíveis para adicionar.

- **Localização:** `lib/ui/library/widgets/pages/library_folder_screen/folder_analysis_list/` (**novo arquivo no recorte ANI-73**)
- **Tipo:** `View only`
- **Props:** `required List<AnalysisDto> analyses`, `required Set<String> selectedIds`, `required bool isLoadingMore`, `required bool hasMore`, `required String Function(String value) formatCreatedAt`, `required Future<void> Function() onRefresh`, `required Future<void> Function() onLoadMore`, `required Future<void> Function(AnalysisDto analysis) onTapAnalysis`, `required void Function(String analysisId) onToggleSelection`
- **Responsabilidade:** renderizar lista paginada, refresh e disparo de próxima página.

- **Localização:** `lib/ui/library/widgets/pages/library_folder_screen/folder_analysis_card/` (**novo arquivo no recorte ANI-73**)
- **Tipo:** `View only`
- **Props:** `required AnalysisDto analysis`, `required String dateLabel`, `required bool isSelected`, `required VoidCallback onTap`, `required VoidCallback onToggleSelection`
- **Responsabilidade:** renderizar card de análise, fallback de nome e checkbox.

- **Localização:** `lib/ui/library/widgets/pages/library_folder_screen/folder_selection_action_bar/` (**novo arquivo no recorte ANI-73**)
- **Tipo:** `View only`
- **Props:** `required int selectedCount`, `required bool isOperating`, `required VoidCallback onMove`, `required VoidCallback onArchive`
- **Responsabilidade:** renderizar action bar inferior com contador e ações batch.

- **Localização:** `lib/ui/library/widgets/pages/library_folder_screen/archive_selected_analyses_dialog/` (**novo arquivo no recorte ANI-73**)
- **Tipo:** `View only`
- **Props:** `required int selectedCount`
- **Responsabilidade:** confirmar arquivamento em lote e deixar claro que não há exclusão permanente.

## Camada UI (Barrel Files / `index.dart`)

- **Localização:** `lib/ui/library/widgets/pages/library_folder_screen/index.dart` (**novo arquivo no recorte ANI-73**)
- **`typedef` exportado:** `typedef LibraryFolderScreen = LibraryFolderScreenView`
- **Widgets internos exportados:** `archive_selected_analyses_dialog`, `folder_available_analysis_picker`, `folder_analysis_card`, `folder_analysis_list`, `folder_empty_state`, `folder_error_state`, `folder_loading_state`, `folder_selection_action_bar`, `folder_settings_modal`, `library_folder_background`, `library_folder_header`, `move_analyses_modal`

- **Localização:** subpastas de `lib/ui/library/widgets/pages/library_folder_screen/**/index.dart` (**novo arquivo no recorte ANI-73**)
- **`typedef` exportado:** um typedef público por widget, como `typedef FolderAnalysisCard = FolderAnalysisCardView`
- **Widgets internos exportados:** apenas o presenter quando a subpasta possui presenter próprio.

## Camada UI (Providers Riverpod)

- **Localização:** `lib/ui/library/widgets/pages/library_folder_screen/library_folder_screen_presenter.dart`
- **Nome do provider:** `libraryFolderScreenPresenterProvider`
- **Tipo:** `Provider.autoDispose.family<LibraryFolderScreenPresenter, String>`
- **Dependências:** `ref.watch(libraryServiceProvider)`, `ref.watch(navigationDriverProvider)`
- **Dependências adicionais para pasta vazia:** `ref.watch(intakeServiceProvider)` para carregar análises disponíveis.

- **Localização:** `lib/ui/library/widgets/pages/library_folder_screen/library_folder_screen_presenter.dart`
- **Nome do provider:** `libraryFolderScreenInitializationProvider`
- **Tipo:** `Provider.autoDispose.family<void, String>`
- **Dependências:** `libraryFolderScreenPresenterProvider(folderId)`

- **Localização:** `lib/ui/library/widgets/pages/library_folder_screen/move_analyses_modal/move_analyses_modal_presenter.dart`
- **Nome do provider:** `moveAnalysesModalPresenterProvider`
- **Tipo:** `Provider.autoDispose.family<MoveAnalysesModalPresenter, String>`
- **Dependências:** `ref.watch(libraryServiceProvider)`

- **Localização:** `lib/ui/library/widgets/pages/library_folder_screen/folder_settings_modal/folder_settings_modal_presenter.dart`
- **Nome do provider:** `folderSettingsModalPresenterProvider`
- **Tipo:** `Provider.autoDispose.family<FolderSettingsModalPresenter, ({String folderId, String initialName})>`
- **Dependências:** `libraryFolderScreenPresenterProvider(args.folderId)`

## Estrutura de Pastas

```text
lib/ui/library/widgets/pages/library_folder_screen/
  index.dart
  library_folder_screen_view.dart
  library_folder_screen_presenter.dart
  archive_selected_analyses_dialog/
    index.dart
    archive_selected_analyses_dialog_view.dart
  folder_available_analysis_picker/
    index.dart
    folder_available_analysis_picker_view.dart
  folder_analysis_card/
    index.dart
    folder_analysis_card_view.dart
  folder_analysis_list/
    index.dart
    folder_analysis_list_view.dart
  folder_empty_state/
    index.dart
    folder_empty_state_view.dart
  folder_error_state/
    index.dart
    folder_error_state_view.dart
  folder_loading_state/
    index.dart
    folder_loading_state_view.dart
  folder_selection_action_bar/
    index.dart
    folder_selection_action_bar_view.dart
  folder_settings_modal/
    index.dart
    folder_settings_modal_view.dart
    folder_settings_modal_presenter.dart
  library_folder_background/
    index.dart
    library_folder_background_view.dart
  library_folder_header/
    index.dart
    library_folder_header_view.dart
  move_analyses_modal/
    index.dart
    move_analyses_modal_view.dart
    move_analyses_modal_presenter.dart
```

---

# 6. O que deve ser modificado?

## Camada Core

- **Arquivo:** `lib/core/library/interfaces/library_service.dart`
- **Mudança:** garantir os contratos `listFolderAnalyses`, `getFolder`, `updateFolderName`, `archiveFolder`, `moveAnalysesToFolder` e `archiveAnalyses`.
- **Justificativa:** a UI da pasta precisa de uma porta estável para consulta de pasta, listagem paginada e operações batch.

- **Arquivo:** `lib/core/library/dtos/folder_dto.dart`
- **Mudança:** garantir `id`, `name`, `analysisCount`, `accountId` e `isArchived`.
- **Justificativa:** a tela depende de nome e contador; operações de pasta dependem do identificador e do status arquivado.

- **Arquivo:** `lib/core/intake/dtos/analysis_dto.dart`
- **Mudança:** garantir `id`, `name`, `createdAt`, `folderId` e `isArchived`.
- **Justificativa:** a lista de pasta precisa abrir análise, exibir data, validar pertencimento à pasta e ignorar itens arquivados.

- **Arquivo:** `lib/core/intake/interfaces/intake_service.dart`
- **Mudança:** reutilizar `Future<RestResponse<CursorPaginationResponse<AnalysisDto>>> listAnalyses({String? cursor, required int limit, bool isArchived = false})` no fluxo de pasta vazia.
- **Justificativa:** ao entrar em uma pasta vazia, o app precisa listar análises disponíveis para o usuário adicionar à pasta sem acessar `RestClient` diretamente.

## Camada REST

- **Arquivo:** `lib/rest/services/library_rest_service.dart`
- **Mudança:** implementar `Future<RestResponse<FolderDto>> getFolder({required String folderId})` com `GET /library/folders/{folderId}`.
- **Justificativa:** a tela precisa dos metadados da pasta antes de renderizar header e ações.

- **Arquivo:** `lib/rest/services/library_rest_service.dart`
- **Mudança:** implementar `Future<RestResponse<CursorPaginationResponse<AnalysisDto>>> listFolderAnalyses({required String folderId, String? cursor, required int limit})` com `GET /intake/analyses`, query params `folder_id`, `is_archived=false`, `limit` e `cursor`.
- **Justificativa:** análises salvas continuam no domínio `intake`, mas são consultadas pela experiência de biblioteca.

- **Arquivo:** `lib/rest/services/library_rest_service.dart`
- **Mudança:** implementar `Future<RestResponse<FolderDto>> updateFolderName({required String folderId, required String name})` com `PATCH /library/folders/{folderId}` e body `{name}`.
- **Justificativa:** o modal de configurações deve renomear pasta sem a UI conhecer endpoint ou payload.

- **Arquivo:** `lib/rest/services/library_rest_service.dart`
- **Mudança:** implementar `Future<RestResponse<FolderDto>> archiveFolder({required String folderId})` com `PATCH /library/folders/{folderId}/archive`.
- **Justificativa:** a ação de "excluir" do PRD é tratada no mobile como arquivamento da pasta, preservando análises e movendo-as para `Sem pasta` conforme regra de negócio.

- **Arquivo:** `lib/rest/services/library_rest_service.dart`
- **Mudança:** implementar `Future<RestResponse<void>> moveAnalysesToFolder({required List<String> analysisIds, required String? folderId})` com `PATCH /intake/analyses/folder` e body `analysis_ids` + `folder_id`.
- **Justificativa:** movimentação em lote deve ser uma única operação remota atômica para a experiência do usuário.

- **Arquivo:** `lib/rest/services/library_rest_service.dart`
- **Mudança:** implementar `Future<RestResponse<void>> archiveAnalyses({required List<String> analysisIds})` com `PATCH /intake/analyses/archive`.
- **Justificativa:** a ação visual de arquivar remove as análises da visualização ativa sem exclusão permanente.

- **Arquivo:** `lib/rest/services/intake_rest_service.dart`
- **Mudança:** reutilizar `listAnalyses({String? cursor, required int limit, bool isArchived = false})`, consumindo `GET /intake/analyses` com `is_archived=false`.
- **Justificativa:** a pasta vazia precisa carregar análises ativas disponíveis antes de chamar o batch de movimentação para a pasta atual.

- **Arquivo:** `lib/rest/mappers/library/folder_mapper.dart`
- **Mudança:** mapear `id`, `name`, `analysis_count`, `account_id` e `is_archived` para `FolderDto`.
- **Justificativa:** o payload remoto usa `snake_case` e deve ser convertido antes de chegar à UI.

- **Arquivo:** `lib/rest/services/index.dart`
- **Mudança:** expor `libraryServiceProvider` para `LibraryRestService`.
- **Justificativa:** presenters devem consumir `LibraryService` via Riverpod, sem instanciar adapters concretos.

## App / Router

- **Arquivo:** `lib/constants/routes.dart`
- **Mudança:** adicionar `Routes.libraryFolder = '/library/folders/:folderId'` e `Routes.getLibraryFolder({required String folderId})`.
- **Justificativa:** navegação deve ser centralizada e fazer encoding do parâmetro.

- **Arquivo:** `lib/router.dart`
- **Mudança:** registrar `GoRoute` para `Routes.libraryFolder`, extrair `state.pathParameters['folderId']`, redirecionar ids vazios para `Routes.library` e construir `LibraryFolderScreen(folderId: folderId)`.
- **Justificativa:** a rota da pasta substitui o placeholder e precisa permanecer dentro do fluxo autenticado.

## Camada UI

- **Arquivo:** `lib/ui/library/widgets/pages/library_screen/library_screen_presenter.dart`
- **Mudança:** adicionar ou manter `Future<void> openFolder(String folderId)` navegando via `NavigationDriver.pushTo(Routes.getLibraryFolder(folderId: folderId))` e recarregando a biblioteca no retorno.
- **Justificativa:** a navegação parte da tela principal da biblioteca e deve preservar desacoplamento de `GoRouter`.

- **Arquivo:** `lib/ui/library/widgets/pages/library_screen/library_screen_view.dart`
- **Mudança:** conectar `FolderGridCard.onTap` a `presenter.openFolder(folder.id!)` quando `folder.id` existir.
- **Justificativa:** torna as pastas listadas navegáveis.

- **Arquivo:** `lib/ui/library/widgets/pages/library_folder_screen/library_folder_screen_presenter.dart`
- **Mudança:** injetar `IntakeService`; adicionar estado de análises disponíveis, seleção de disponíveis, loading de disponíveis e loading de adição; carregar disponíveis quando `listFolderAnalyses` retornar vazio; adicionar `addSelectedAvailableAnalyses()`.
- **Justificativa:** a regra de pasta vazia exige que o usuário consiga escolher análises existentes para preencher a pasta, sem concentrar lógica na View.

- **Arquivo:** `lib/ui/library/widgets/pages/library_folder_screen/library_folder_screen_view.dart`
- **Mudança:** renderizar `FolderAvailableAnalysisPicker` quando `presenter.showAvailableAnalysisPicker` estiver ativo.
- **Justificativa:** a tela de pasta vazia deve mostrar análises disponíveis, não apenas um estado vazio informativo.

- **Arquivo:** `lib/ui/library/widgets/pages/library_folder_screen/index.dart`
- **Mudança:** exportar `folder_available_analysis_picker/index.dart`.
- **Justificativa:** manter a fronteira pública da pasta de widgets consistente com os demais componentes internos.

---

# 7. O que deve ser removido?

**Não aplicável**.

Os artefatos similares em `lib/ui/storage/widgets/pages/library_folder_screen/` devem ser tratados como limpeza técnica separada, porque a rota de produção de `ANI-73` usa `lib/ui/library/widgets/pages/library_folder_screen/`.

---

# 8. Decisões Técnicas e Trade-offs

- **Decisão:** usar o bounded context `library` (`LibraryService`) para a tela de pasta, em vez de adicionar os contratos ao `IntakeService`.
- **Alternativas consideradas:** seguir literalmente o rascunho do ticket e concentrar `getFolder`, `listFolderAnalyses` e batch actions em `IntakeService`.
- **Motivo da escolha:** a codebase já possui `core/library`, `rest/services/library_rest_service.dart` e `libraryServiceProvider`; operações de pasta pertencem ao contexto de biblioteca, mesmo quando listam `AnalysisDto` do domínio `intake`.
- **Impactos / trade-offs:** o fluxo cruza `library` e `intake` no REST, mas a UI consome uma única porta coesa.

- **Decisão:** manter `AnalysisDto` em `core/intake` e `FolderDto` em `core/library`.
- **Alternativas consideradas:** criar um DTO específico de item de pasta ou mover análises para `core/library`.
- **Motivo da escolha:** análise continua sendo entidade do fluxo `intake`; a pasta apenas organiza análises existentes.
- **Impactos / trade-offs:** a lista da pasta depende de `AnalysisDto`, mas evita duplicar modelo de análise.

- **Decisão:** quando uma pasta estiver vazia, trocar o vazio puramente informativo por um picker de análises disponíveis.
- **Alternativas consideradas:** exibir apenas mensagem vazia com CTA de refresh; exigir que o usuário volte para a biblioteca e mova análises por outro fluxo; criar análises novas diretamente dentro da pasta.
- **Motivo da escolha:** o fluxo desejado é: entrar em pasta vazia, ver análises disponíveis, selecionar quais adicionar e finalizar com essas análises aparecendo na pasta.
- **Impactos / trade-offs:** a tela de pasta passa a depender também de `IntakeService.listAnalyses`, mas mantém a movimentação final em `LibraryService.moveAnalysesToFolder` e evita lógica de payload na UI.

- **Decisão:** considerar movimentação e arquivamento em lote como operações atômicas na experiência local.
- **Alternativas consideradas:** remover cada item otimisticamente antes da resposta do backend; atualizar parcialmente itens bem-sucedidos.
- **Motivo da escolha:** o ticket exige que falha em qualquer item não remova análises localmente.
- **Impactos / trade-offs:** o feedback visual depende da resposta remota, mas evita divergência entre UI e servidor.

- **Decisão:** remover itens da lista local somente em sucesso.
- **Alternativas consideradas:** recarregar a pasta inteira após cada operação; manter itens até refresh manual.
- **Motivo da escolha:** remoção local é mais responsiva e suficiente porque as análises deixam de pertencer à visualização atual.
- **Impactos / trade-offs:** o contador local precisa ser atualizado defensivamente para não ficar negativo.

- **Decisão:** mapear a ação visual de "deletar" do design para `archiveAnalyses` e `archiveFolder`.
- **Alternativas consideradas:** expor texto de exclusão permanente; criar endpoint de delete definitivo.
- **Motivo da escolha:** o PRD determina que análises não sejam excluídas ao remover pasta, e o ticket define `PATCH /intake/analyses/archive` para o lote.
- **Impactos / trade-offs:** a UI deve usar linguagem de arquivamento para reduzir ambiguidade, mesmo que o node `HoZeb` use "Deletar".

- **Decisão:** `MoveAnalysesModalPresenter` usa `hasSelectedDestination` separado de `selectedFolderId`.
- **Alternativas consideradas:** usar apenas `selectedFolderId == null` para controlar o botão.
- **Motivo da escolha:** `null` é um destino válido que representa `Sem pasta`; sem um boolean separado não há como diferenciar "não escolheu" de "escolheu Sem pasta".
- **Impactos / trade-offs:** há um signal extra, mas a regra fica explícita no presenter.

- **Decisão:** carregar todas as pastas de destino por paginação antes de confirmar movimentação.
- **Alternativas consideradas:** carregar apenas primeira página; criar busca de destino; paginar visualmente dentro do modal.
- **Motivo da escolha:** o seletor precisa oferecer destinos disponíveis de forma simples, e a quantidade esperada de pastas por usuário é pequena no recorte atual.
- **Impactos / trade-offs:** contas com muitas pastas podem ter modal mais custoso; se isso crescer, a escolha deve evoluir para busca ou paginação visual.

- **Decisão:** manter widgets internos majoritariamente `View only`, com presenters apenas nos modais que possuem estado próprio.
- **Alternativas consideradas:** criar presenter para cada card, header, empty state e action bar.
- **Motivo da escolha:** esses widgets apenas renderizam props e encaminham callbacks; presenters artificiais aumentariam ruído sem reduzir acoplamento.
- **Impactos / trade-offs:** a tela centraliza a seleção no presenter principal, mas lógica específica de modal fica isolada em presenters filhos.

- **Decisão:** limitar a largura da tela a `402px` com `ConstrainedBox`.
- **Alternativas consideradas:** ocupar toda largura do dispositivo sem limite; usar breakpoints diferentes.
- **Motivo da escolha:** o design `HoZeb` foi validado com largura `402px` e o app já prioriza experiência mobile.
- **Impactos / trade-offs:** em telas largas, a experiência fica centralizada em coluna mobile.

- **Decisão:** usar `NavigationDriver` em presenters e `Navigator` apenas para fechar modal/dialog local na View.
- **Alternativas consideradas:** injetar `BuildContext` no presenter; chamar `GoRouter` diretamente na View para abrir análise.
- **Motivo da escolha:** navegação entre rotas é side effect da camada de apresentação orquestrado pelo presenter; fechamento de modal é detalhe visual local.
- **Impactos / trade-offs:** a View ainda controla `showModalBottomSheet`, `showDialog` e `Navigator.pop`, mas não decide regra de negócio.

- **Decisão:** tratar mensagens técnicas de transporte no presenter e trocar por fallback amigável.
- **Alternativas consideradas:** exibir `response.errorMessage` diretamente.
- **Motivo da escolha:** mensagens de `Dio`/HTTP podem vazar detalhes técnicos e não ajudam o usuário.
- **Impactos / trade-offs:** algumas mensagens específicas do backend podem ser ocultadas quando parecerem técnicas, priorizando UX segura.

---

# 9. Diagramas e Referências

- **Fluxo de dados:**

```text
LibraryScreenView
  -> renderiza F - Biblioteca (node smS6d)
     -> seção Sem pasta
        -> lista análises sem folder para acesso rápido
     -> seção Pastas
        -> cards de FolderDto
  -> LibraryScreenPresenter.openFolder(folderId)
  -> NavigationDriver.pushTo(Routes.getLibraryFolder(folderId))
  -> GoRouter /library/folders/:folderId
  -> LibraryFolderScreenView(folderId)
  -> libraryFolderScreenPresenterProvider(folderId)
  -> LibraryFolderScreenPresenter.initialize()
     -> LibraryService.getFolder(folderId)
        -> LibraryRestService.get('/library/folders/{folderId}')
        -> FolderMapper.toDto(json)
     -> LibraryService.listFolderAnalyses(folderId, limit: 50)
        -> LibraryRestService.get('/intake/analyses', queryParams)
        -> CursorPaginationMapper.toDto(json, AnalysisMapper.toDto)
     -> signals (folder, analyses, nextCursor, generalError)
  -> LibraryFolderScreenView renderiza estado
```

- **Fluxo de pasta vazia e adição de análises:**

```text
LibraryFolderScreenPresenter.load()
  -> LibraryService.getFolder(folderId)
  -> LibraryService.listFolderAnalyses(folderId, limit: 50)
  -> analyses vazio
  -> LibraryFolderScreenPresenter.loadAvailableAnalysesForEmptyFolder()
     -> IntakeService.listAnalyses(limit: 50, isArchived: false)
        -> IntakeRestService.get('/intake/analyses', queryParams)
        -> CursorPaginationMapper.toDto(json, AnalysisMapper.toDto)
     -> filtra análises sem id, já vinculadas à pasta atual ou já carregadas
  -> FolderAvailableAnalysisPicker
     -> usuário seleciona análises disponíveis
     -> LibraryFolderScreenPresenter.addSelectedAvailableAnalyses()
        -> LibraryService.moveAnalysesToFolder(analysisIds, folderId atual)
        -> LibraryRestService.patch('/intake/analyses/folder')
     -> sucesso: análises selecionadas aparecem em FolderAnalysisList
     -> falha: mantém seleção e lista de disponíveis
```

- **Fluxo de movimentação em lote:**

```text
FolderSelectionActionBar.onMove
  -> LibraryFolderScreenView.showModalBottomSheet()
  -> MoveAnalysesModalView
  -> MoveAnalysesModalPresenter.load()
     -> LibraryService.listFolders(limit: 50)
     -> folders sem currentFolderId
  -> usuário escolhe destino
  -> LibraryFolderScreenPresenter.moveSelectedAnalyses(destinationFolderId)
     -> LibraryService.moveAnalysesToFolder(analysisIds, folderId)
        -> LibraryRestService.patch('/intake/analyses/folder')
     -> sucesso: remove análises da lista atual e limpa seleção
     -> falha: mantém seleção e exibe generalError
```

- **Fluxo de arquivamento em lote:**

```text
FolderSelectionActionBar.onArchive
  -> ArchiveSelectedAnalysesDialog
  -> confirmação
  -> LibraryFolderScreenPresenter.archiveSelectedAnalyses()
     -> LibraryService.archiveAnalyses(analysisIds)
        -> LibraryRestService.patch('/intake/analyses/archive')
     -> sucesso: remove análises da lista atual e limpa seleção
     -> falha: mantém seleção e exibe generalError
```

- **Fluxo de configuração da pasta:**

```text
LibraryFolderHeader.onSettings
  -> FolderSettingsModalView(folder)
  -> folderSettingsModalPresenterProvider(folderId, initialName)
     -> usa LibraryFolderScreenPresenter.renameFolder
     -> usa LibraryFolderScreenPresenter.archiveFolder

Renomear
  -> FolderSettingsModalPresenter.submitRename()
  -> LibraryFolderScreenPresenter.renameFolder(name)
  -> LibraryService.updateFolderName(folderId, name)
  -> LibraryRestService.patch('/library/folders/{folderId}')

Arquivar pasta
  -> FolderSettingsModalPresenter.submitArchiveFolder()
  -> LibraryFolderScreenPresenter.archiveFolder()
  -> LibraryService.archiveFolder(folderId)
  -> LibraryRestService.patch('/library/folders/{folderId}/archive')
  -> NavigationDriver.goTo(Routes.library)
```

- **Hierarquia de widgets:**

```text
LibraryScreenView
  Scaffold
    AppBar("Biblioteca")
    ListView
      LibraryTabs
      Sem pasta
        UnfolderedAnalysisTile * N
      Pastas
        FolderGridCard * N

LibraryFolderScreenView
  Scaffold
    SafeArea
      Center
        ConstrainedBox(maxWidth: 402)
          Stack
            LibraryFolderBackground
            Column
              LibraryFolderHeader
              Expanded
                FolderLoadingState
                FolderErrorState
                FolderAvailableAnalysisPicker
                FolderEmptyState
                FolderAnalysisList
                  FolderAnalysisCard * N
                  _LoadingMoreCard
            FolderSelectionActionBar

Modais e dialogs
  MoveAnalysesModal
    _DestinationTile(Sem pasta)
    _DestinationTile(folder) * N
  ArchiveSelectedAnalysesDialog
  FolderSettingsModal
```

- **Referências de implementação:**
- `lib/core/library/interfaces/library_service.dart`
- `lib/core/intake/interfaces/intake_service.dart`
- `lib/core/library/dtos/folder_dto.dart`
- `lib/core/intake/dtos/analysis_dto.dart`
- `lib/rest/services/library_rest_service.dart`
- `lib/rest/services/intake_rest_service.dart`
- `lib/rest/mappers/library/folder_mapper.dart`
- `lib/rest/mappers/intake/analysis_mapper.dart`
- `lib/rest/mappers/shared/cursor_pagination_mapper.dart`
- `lib/rest/services/index.dart`
- `lib/constants/routes.dart`
- `lib/router.dart`
- `lib/ui/library/widgets/pages/library_screen/library_screen_presenter.dart`
- `lib/ui/library/widgets/pages/library_screen/library_screen_view.dart`
- `lib/ui/library/widgets/pages/library_folder_screen/library_folder_screen_presenter.dart`
- `lib/ui/library/widgets/pages/library_folder_screen/library_folder_screen_view.dart`
- `lib/ui/library/widgets/pages/library_folder_screen/move_analyses_modal/move_analyses_modal_presenter.dart`
- `lib/ui/library/widgets/pages/library_folder_screen/folder_settings_modal/folder_settings_modal_presenter.dart`
- `lib/ui/storage/widgets/pages/library_folder_screen/folder_available_analysis_picker/folder_available_analysis_picker_view.dart`
- `design/animus.pen` (nodes `smS6d`, `HoZeb`, `VqUTX`)

---

# 10. Pendências / Dúvidas

- **Descrição da pendência:** existem artefatos legados com nomes equivalentes em `lib/ui/storage/widgets/pages/library_folder_screen/`, enquanto a rota real usa `lib/ui/library/widgets/pages/library_folder_screen/`.
- **Impacto na implementação:** pode haver confusão ao evoluir a feature ou ao procurar referências, principalmente porque os nomes de classes são similares.
- **Ação sugerida:** abrir tarefa de limpeza técnica para consolidar ou remover o legado de `ui/storage`, sem misturar essa remoção ao escopo funcional de `ANI-73`.

- **Descrição da pendência:** a tela `F - Biblioteca` contempla a seção `Sem pasta`, mas a rota/tela dedicada `/library/unfoldered` permanece fora do recorte funcional de `ANI-73`.
- **Impacto na implementação:** o usuário vê análises sem pasta na biblioteca e consegue mover análises para `Sem pasta`, mas uma experiência completa dedicada para todas as análises sem pasta deve ser validada em recorte próprio.
- **Ação sugerida:** tratar a rota/tela dedicada `Sem pasta` em tarefa separada vinculada ao RF 04, sem remover a seção `Sem pasta` da biblioteca.

---

# Restrições

- **Não inclua testes automatizados na spec.**
- A `View` não deve conter lógica de negócio; toda orquestração de carga, seleção, paginação e operações batch fica em presenters.
- Presenters não fazem chamadas diretas a `RestClient`; consomem sempre `LibraryService`.
- A UI não deve montar payload HTTP nem acessar `Dio`.
- Ao entrar em pasta vazia, a UI deve apenas renderizar o picker; carregamento de disponíveis, seleção e confirmação pertencem ao presenter.
- A adição de análises à pasta vazia deve usar `IntakeService.listAnalyses` para consulta e `LibraryService.moveAnalysesToFolder` para efetivar o vínculo.
- `folder_id`, `analysis_ids`, `is_archived` e demais campos `snake_case` ficam confinados à camada REST.
- Todos os caminhos citados nesta spec existem no projeto ou estão marcados como **novo arquivo no recorte ANI-73**.
- A ação visual de exclusão deve ser implementada como arquivamento, não como remoção permanente.
- `null` em `moveAnalysesToFolder.folderId` representa destino `Sem pasta`.
- O presenter da tela deve preservar a seleção em falhas de operação batch.
- Widgets internos com estado próprio devem manter presenter próprio; widgets puramente visuais podem ser `View only`.
- Use componentes Flutter Material alinhados ao tema atual do projeto.
- A nomenclatura deve seguir a codebase: arquivos em `snake_case`, classes em `PascalCase`, métodos/providers em `camelCase` e barrel files por widget.
