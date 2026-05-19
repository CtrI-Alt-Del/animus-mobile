---
title: Tela de Analises Arquivadas (ANI-107)
prd: ../prd.md
ticket: https://joaogoliveiragarcia.atlassian.net/browse/ANI-107
status: open
last_updated_at: 2026-05-18
---

# 1. Objetivo

Entregar a tela de analises arquivadas no `animus`: uma rota dedicada acessivel a partir do perfil que lista as analises com `is_archived = true` via `GET /intake/analyses?is_archived=true` com paginacao por cursor, suporta busca textual local, permite desarquivar uma analise (`PATCH /intake/analyses/{id}/unarchive`) e abre a tela correta segundo o `AnalysisTypeDto` ao tocar em um item. Tambem inclui um label `Analise arquivada` no `AnalysisHeader` para sinalizar telas de analises ja arquivadas. A entrega segue o padrao `MVP` com `Riverpod`, `Signals`, `NavigationDriver`, `IntakeService` e `GoRouter`, reutilizando `AnalysisDto`, `IntakeService.listAnalyses(isArchived: true)` e `IntakeService.unarchiveAnalysis(...)` ja existentes.

---

# 2. Escopo

## 2.1 In-scope

- Criar a tela `archived_analyses_screen` em `lib/ui/intake/widgets/pages/archived_analyses_screen/`, com `View + Presenter`.
- Registrar `Routes.archivedAnalyses = '/archived-analyses'` em `lib/constants/routes.dart` e a rota em `lib/router.dart`.
- Consumir `IntakeService.listAnalyses(cursor:, limit:, isArchived: true)` com paginacao por cursor (`page size = 10`, alinhado a `HomeScreenPresenter._pageSize`).
- Implementar estados visuais: `loading inicial` (skeleton), `empty`, `error com retry`, `loading more` na paginacao subsequente, `inline error` quando paginacao falha mas ja existem items carregados.
- Implementar busca textual local que filtra o conjunto ja carregado por `name` (case-insensitive, trim) e por substring; campo de busca persistente no topo, com botao clear.
- Implementar acao `Desarquivar` em cada item: bottom sheet/dialog de confirmacao, chamada para `IntakeService.unarchiveAnalysis(analysisId)`, remocao do item da lista em sucesso e snackbar de feedback. Erro deve ser sinalizado por snackbar/inline message sem perder o estado da lista.
- Tocar em um item da lista navega para a rota correta conforme `AnalysisTypeDto` via `Routes.getAnalysis(analysisId:, analysisType:)`.
- Adicionar entrada `Analises arquivadas` no `ProfileSettingsGroupView` (camada visual do perfil) que dispara navegacao para `Routes.archivedAnalyses`.
- Adicionar label `Analise arquivada` no `AnalysisHeaderView` quando `isArchived = true`, exibido como chip/badge proximo ao titulo.
- Propagar a prop `isArchived` ao `AnalysisHeader` a partir de `AnalysisScreenView` (rota legada de primeira instancia/case assessment) e `SecondInstanceAnalysisScreenView`, lendo `presenter.analysis?.isArchived` quando disponivel.
- Criar barrel publico `index.dart` em `archived_analyses_screen/` exportando `typedef ArchivedAnalysesScreen = ArchivedAnalysesScreenView;`.

## 2.2 Out-of-scope

- Busca textual server-side (a busca neste escopo e somente client-side sobre os items ja carregados).
- Filtragem por tipo de analise, periodo ou status.
- Selecao multipla / bulk unarchive.
- Drag-to-refresh ou polling automatico de processamento (a tela e estatica, somente carrega/pagina/atualiza apos unarchive).
- Re-arquivar (a acao continua disponivel pela tela da analise via `AnalysisHeader`).
- Edicao de nome/qualquer outra acao destrutiva do item na tela de listagem.
- Mudancas no contrato de `IntakeService` ou em qualquer DTO existente.

---

# 3. Requisitos

## 3.1 Funcionais

- Ao tocar em `Analises arquivadas` na tela de Perfil, o app deve navegar para `Routes.archivedAnalyses`.
- Ao entrar na tela, o presenter deve disparar `IntakeService.listAnalyses(limit: 10, isArchived: true)` automaticamente.
- Enquanto a primeira carga estiver em voo, a tela deve exibir `ArchivedAnalysesLoadingState` (skeleton, mesma estetica de `RecentAnalysesLoadingState`).
- Em sucesso e lista vazia, a tela deve exibir `ArchivedAnalysesEmptyState` com mensagem `Voce ainda nao tem analises arquivadas`.
- Em falha na primeira carga, a tela deve exibir `ArchivedAnalysesErrorState` com mensagem amigavel e CTA `Tentar novamente` que aciona o reload.
- Em sucesso, a tela deve renderizar uma lista de `ArchivedAnalysisCard`, ordenada conforme retornada pelo backend (sem reordenacao no cliente).
- Quando `pagination.nextCursor` nao for nulo/vazio, a tela deve carregar a proxima pagina quando o usuario atingir o final do scroll (limiar `120 px`, alinhado a `RecentAnalysesSection`).
- Enquanto a paginacao subsequente estiver em voo, a lista deve exibir `ArchivedAnalysesLoadingMore` no final.
- Se a paginacao subsequente falhar, a tela deve manter os items ja carregados e exibir `ArchivedAnalysesInlineError` acima da lista (ou em area visivel), permitindo nova tentativa por scroll.
- O campo de busca deve permanecer fixo no topo da tela (abaixo do header), filtrando localmente por `analysis.name` (lowercase, trim, substring), sem disparar request remoto.
- O campo de busca deve oferecer botao `clear` que limpa o filtro instantaneamente.
- Quando o filtro de busca nao tiver match, a tela deve exibir um estado vazio especifico (ex.: `Nenhuma analise encontrada para "<query>"`), distinto do empty state geral.
- Cada `ArchivedAnalysisCard` deve exibir `name`, `dateLabel` formatada de `createdAt` (`dd/MM/yyyy`), e uma acao `Desarquivar` acessivel via icone trailing ou popup menu.
- Ao confirmar `Desarquivar`, o presenter deve chamar `IntakeService.unarchiveAnalysis(analysisId)` e, em sucesso, remover o item da lista local e exibir `SnackBar` `Analise desarquivada`.
- Em falha de `unarchiveAnalysis`, a tela deve exibir `SnackBar` com mensagem de erro e manter o item na lista.
- Tocar em um card da lista deve disparar navegacao para a rota correta via `Routes.getAnalysis(analysisId:, analysisType:)`, considerando o `AnalysisTypeDto` do item: `firstInstance/LAWYER` → `Routes.getFirstInstanceAnalysis`, `secondInstance/JUDGE` → `Routes.getSecondInstanceAnalysis`, `caseAssessment/PRECEDENT` → `Routes.getSecondInstanceAnalysis` (alinhado ao mapeamento atual em `Routes.getAnalysis`).
- A tela deve oferecer botao de voltar (`AppBar` padrao ou icone arrow_back) que retorna para a tela anterior (Perfil).
- O `AnalysisHeaderView` deve exibir um chip/badge `Analise arquivada` quando a prop `isArchived = true` for repassada.
- `AnalysisScreenView` e `SecondInstanceAnalysisScreenView` devem ler `presenter.analysis?.isArchived` (Signal) e repassar para `AnalysisHeader.isArchived`.

## 3.2 Nao funcionais

- **Performance:** `initialize()` da tela nao deve disparar requisicoes concorrentes; chamadas concorrentes devem ser ignoradas enquanto `isLoadingInitialData == true`.
- **Performance:** paginacao subsequente nao deve disparar mais de uma vez por evento de scroll; usar lock `isLoadingMore`.
- **Acessibilidade:** o botao `Desarquivar` deve ter `tooltip` e/ou label textual visivel; o estado de loading deve ser anunciado via `Semantics`.
- **Offline/Conectividade:** falha de rede em qualquer carga deve manter a tela em estado recuperavel sem sair da rota; nenhuma carga deve crashar a UI.
- **Seguranca:** o token continua sendo lido apenas via `CacheDriver`; a UI nao toca nele.
- **Compatibilidade:** sem novas dependencias; usa apenas `flutter_riverpod`, `signals_flutter`, `go_router` e o stack atual.

---

# 4. O que ja existe?

## Camada Core

- **`AnalysisDto`** (`lib/core/intake/dtos/analysis_dto.dart`) — DTO usado pela listagem; ja possui `id`, `name`, `type`, `status`, `createdAt`, `isArchived`.
- **`AnalysisTypeDto`** (`lib/core/intake/dtos/analysis_type_dto.dart`) — enum usado para escolher a rota de destino.
- **`IntakeService`** (`lib/core/intake/interfaces/intake_service.dart`) — contrato ja expoe `listAnalyses(cursor:, limit:, isArchived:)` e `unarchiveAnalysis(analysisId:)`; nenhuma extensao necessaria.
- **`CursorPaginationResponse<AnalysisDto>`** (`lib/core/shared/responses/cursor_pagination_response.dart`) — payload paginado retornado pelo `listAnalyses`.
- **`RestResponse<T>`** (`lib/core/shared/responses/rest_response.dart`) — wrapper de sucesso/falha consumido pelos presenters.
- **`NavigationDriver`** (`lib/core/shared/interfaces/navigation_driver.dart`) — contrato usado para navegacao desacoplada.

## Camada REST

- **`IntakeRestService`** (`lib/rest/services/intake_rest_service.dart`) — implementacao ja consome `GET /intake/analyses?is_archived=true&cursor=&limit=` (linhas 46-74) e `PATCH /intake/analyses/{id}/unarchive` (linhas 340-353).
- **`intakeServiceProvider`** (`lib/rest/services/index.dart`) — provider Riverpod do `IntakeService` que sera injetado no presenter.
- **`AnalysisMapper`** (`lib/rest/mappers/intake/analysis_mapper.dart`) — ja le `is_archived` do payload e propaga em `AnalysisDto.isArchived`.

## Camada Drivers

- **`GoRouterNavigationDriver`** (`lib/drivers/navigation/go_router/go_router_navigation_driver.dart`) — implementacao concreta de `NavigationDriver` ja usada pelos presenters.
- **`navigationDriverProvider`** (`lib/drivers/navigation/index.dart`) — provider Riverpod usado para injecao.

## Camada UI

- **`HomeScreenPresenter`** (`lib/ui/intake/widgets/pages/home_screen/home_screen_presenter.dart`) — referencia direta de presenter com paginacao por cursor, `loadNextPage`, `refresh`, `formatCreatedAt`, lock de loading e tratamento de erro padronizado (`_resolveErrorMessage`).
- **`RecentAnalysesSectionView`** (`lib/ui/intake/widgets/pages/home_screen/recent_analyses_section/recent_analyses_section_view.dart`) — referencia visual completa de listagem paginada, com `NotificationListener<ScrollNotification>` para `loadMore`, exibicao de skeleton, empty, error, inline error e loading more.
- **`RecentAnalysesSkeletonCardView`, `RecentAnalysesLoadingStateView`, `RecentAnalysesEmptyStateView`, `RecentAnalysesErrorStateView`, `RecentAnalysesLoadingMoreView`, `RecentAnalysesInlineErrorView`** — referencias visuais para os widgets internos correspondentes da tela de arquivadas.
- **`RecentAnalysisCardView`** (`lib/ui/intake/widgets/pages/home_screen/recent_analyses_section/recent_analysis_card/recent_analysis_card_view.dart`) — referencia visual do card de analise (sem acao de desarquivar).
- **`AnalysisHeaderView`** (`lib/ui/intake/widgets/components/analysis_header/analysis_header_view.dart`) — sera modificado para suportar a prop `isArchived` e renderizar o label `Analise arquivada`.
- **`AnalysisScreenView`** (`lib/ui/intake/widgets/pages/first_instance_analysis_screen/first_instance_analysis_screen_view.dart`) — sera ajustado para repassar `isArchived` ao `AnalysisHeader`.
- **`SecondInstanceAnalysisScreenView`** (`lib/ui/intake/widgets/pages/second_instance_analysis_screen/second_instance_analysis_screen_view.dart`) — sera ajustado para repassar `isArchived` ao `AnalysisHeader`.
- **`ProfileSettingsGroupView`** (`lib/ui/auth/widgets/pages/profile_screen/profile_settings_group/profile_settings_group_view.dart`) — sera modificado para acrescentar o tile `Analises arquivadas` e expor um callback de tap.
- **`ProfileScreenView` / `ProfileScreenPresenter`** (`lib/ui/auth/widgets/pages/profile_screen/`) — sera ajustado para injetar o handler de navegacao `goToArchivedAnalyses` no presenter e repassar pro `ProfileSettingsGroupView`.

## App / Router / Constants

- **`Routes`** (`lib/constants/routes.dart`) — definicoes existentes para `Routes.profile`, `Routes.analysis`, `Routes.secondInstanceAnalysis`; sera estendido com `archivedAnalyses`.
- **`appRouter`** (`lib/router.dart`) — `GoRouter` central a estender com a nova rota de archived analyses.

## Lacunas encontradas

- O endpoint `is_archived=true` ja existe em `IntakeRestService` e e usado apenas indiretamente; nao existe consumidor UI dedicado para listagem arquivada.
- Nao existe widget interno reutilizavel para `search bar` no projeto; precisa ser construido seguindo o pattern MVP.
- Nao existe widget interno reutilizavel para a entrada `Analise arquivada` no header; sera adicionado inline no `AnalysisHeaderView`.

---

# 5. O que deve ser criado?

## Camada UI (Screen)

### `ArchivedAnalysesScreenPresenter` (**novo arquivo**)

- **Localizacao:** `lib/ui/intake/widgets/pages/archived_analyses_screen/archived_analyses_screen_presenter.dart`
- **Dependencias injetadas:**
  - `IntakeService` (via `intakeServiceProvider`)
  - `NavigationDriver` (via `navigationDriverProvider`)
- **Estado (`signals`):**
  - `Signal<bool> isLoadingInitialData` — primeira carga em voo.
  - `Signal<bool> isLoadingMore` — paginacao subsequente em voo.
  - `Signal<bool> isUnarchiving` — desarquivamento em voo (para travar acao concorrente).
  - `Signal<String?> generalError` — mensagem de erro recuperavel da carga ou paginacao.
  - `Signal<List<AnalysisDto>> archivedAnalyses` — lista carregada.
  - `Signal<String?> nextCursor` — cursor da proxima pagina.
  - `Signal<String> searchQuery` — texto digitado no campo de busca.
  - `late final ReadonlySignal<bool> hasMore` — `computed` derivado de `nextCursor`.
  - `late final ReadonlySignal<bool> showEmptyState` — `computed` `!isLoadingInitialData && generalError == null && archivedAnalyses.isEmpty`.
  - `late final ReadonlySignal<List<AnalysisDto>> filteredAnalyses` — `computed` que aplica `searchQuery` sobre `archivedAnalyses` (case-insensitive, trim, substring).
  - `late final ReadonlySignal<bool> showSearchEmptyState` — `computed` `searchQuery.trim().isNotEmpty && filteredAnalyses.isEmpty && archivedAnalyses.isNotEmpty`.
- **Provider Riverpod:**
  - `final Provider<ArchivedAnalysesScreenPresenter> archivedAnalysesScreenPresenterProvider = Provider.autoDispose<ArchivedAnalysesScreenPresenter>(...)`.
  - `final Provider<void> archivedAnalysesScreenInitializationProvider = Provider.autoDispose<void>(...)` que chama `presenter.initialize()` via microtask (mesmo padrao do `HomeScreen`).
- **Metodos:**
  - `Future<void> initialize()` — orquestra a primeira carga: valida lock, define `isLoadingInitialData = true`, chama `listAnalyses(limit: 10, isArchived: true)`, popula `archivedAnalyses` e `nextCursor`, trata erro com `_resolveErrorMessage`.
  - `Future<void> loadNextPage()` — pagina a partir de `nextCursor`; respeita locks `isLoadingInitialData/isLoadingMore` e `nextCursor != null`.
  - `Future<void> refresh()` — limpa estado e chama `initialize()` novamente (usado para retry e para reload pos-unarchive falho).
  - `void updateSearchQuery(String value)` — define `searchQuery.value` (trim mantido na UI; computed faz lowercase).
  - `void clearSearch()` — atalho para `updateSearchQuery('')`.
  - `Future<bool> unarchive(AnalysisDto analysis)` — valida `id`, define `isUnarchiving = true`, chama `unarchiveAnalysis(analysisId)`, em sucesso remove o item da lista local, define `isUnarchiving = false`, retorna `true`. Em falha, define `generalError` (somente para snackbar) e retorna `false`.
  - `Future<void> openAnalysis(AnalysisDto analysis)` — valida `id`, chama `navigationDriver.pushTo(Routes.getAnalysis(analysisId:, analysisType: analysis.type))`.
  - `void goBack()` — chama `navigationDriver.pop()` ou `navigationDriver.goTo(Routes.profile)` (depende de qual API estiver disponivel; checar contrato de `NavigationDriver`).
  - `String formatCreatedAt(String value)` — reutiliza o formato `dd/MM/yyyy` usado em `HomeScreenPresenter`.
  - `void dispose()` — libera todos os signals.
  - `String _resolveErrorMessage(RestResponse<dynamic> response, {required String fallback})` — copia do padrao usado em `HomeScreenPresenter` (extrai `errorBody['message']`, ignora mensagens tecnicas de transporte).

### `ArchivedAnalysesScreenView` (**novo arquivo**)

- **Localizacao:** `lib/ui/intake/widgets/pages/archived_analyses_screen/archived_analyses_screen_view.dart`
- **Base class:** `ConsumerWidget`
- **Props:** nenhuma (rota sem parametros).
- **Bibliotecas de UI:** `flutter_riverpod`, `signals_flutter`.
- **Responsabilidade:** monta `Scaffold` com `SafeArea`, `AppBar`/header com botao back e titulo `Analises arquivadas`, integra `ArchivedAnalysesSearchBar` no topo, e abaixo renderiza `ArchivedAnalysesList` (composto pelos estados). Reage a `presenter.*` signals via `Watch`.
- **Estados visuais:**
  - `loading inicial` → `ArchivedAnalysesLoadingState`
  - `error inicial` → `ArchivedAnalysesErrorState`
  - `empty geral` → `ArchivedAnalysesEmptyState`
  - `empty de busca` → `ArchivedAnalysesEmptyState.search(query)` ou variante interna.
  - `conteudo` → `ArchivedAnalysesList`
  - `error paginacao` → `ArchivedAnalysesInlineError` no topo da lista.

### `index.dart` (**novo arquivo**)

- **Localizacao:** `lib/ui/intake/widgets/pages/archived_analyses_screen/index.dart`
- **`typedef` exportado:** `typedef ArchivedAnalysesScreen = ArchivedAnalysesScreenView;`
- **Widgets internos exportados:** lista os barrels dos subwidgets internos para reduzir imports profundos.

## Camada UI (Widgets Internos)

> Todos os widgets internos seguem o padrao `View only` por terem responsabilidade puramente visual; presenters dedicados nao se justificam pois o estado e os handlers vivem no `ArchivedAnalysesScreenPresenter`. Excecao: `ArchivedAnalysesSearchBar` tem `View + Presenter` para encapsular o `TextEditingController`, debounce opcional e leitura do `searchQuery` do presenter pai (acoplamento minimo).

### `ArchivedAnalysesList` (**novo arquivo**)

- **Localizacao:** `lib/ui/intake/widgets/pages/archived_analyses_screen/archived_analyses_list/`
- **Arquivos:** `archived_analyses_list_view.dart`, `index.dart`
- **Tipo:** `View only`
- **Props:** `List<AnalysisDto> analyses`, `bool isLoadingMore`, `bool hasMore`, `String? errorMessage`, `String Function(String) formatCreatedAt`, `Future<void> Function() onLoadMore`, `Future<void> Function(AnalysisDto) onTapAnalysis`, `Future<void> Function(AnalysisDto) onUnarchive`.
- **Responsabilidade:** Renderiza `ListView.separated` envolto em `NotificationListener<ScrollNotification>` para detectar fim do scroll e disparar `onLoadMore`. Renderiza `ArchivedAnalysisCard` em cada item e `ArchivedAnalysesLoadingMore` no final quando `isLoadingMore = true`. Quando `errorMessage != null`, renderiza `ArchivedAnalysesInlineError` no topo.

### `ArchivedAnalysesLoadingState` (**novo arquivo**)

- **Localizacao:** `lib/ui/intake/widgets/pages/archived_analyses_screen/archived_analyses_loading_state/`
- **Arquivos:** `archived_analyses_loading_state_view.dart`, `index.dart`
- **Tipo:** `View only`
- **Props:** nenhuma.
- **Responsabilidade:** Renderiza `ListView.separated` com 4 `ArchivedAnalysesSkeletonCard`. Inspirado em `RecentAnalysesLoadingStateView`.

### `ArchivedAnalysesEmptyState` (**novo arquivo**)

- **Localizacao:** `lib/ui/intake/widgets/pages/archived_analyses_screen/archived_analyses_empty_state/`
- **Arquivos:** `archived_analyses_empty_state_view.dart`, `index.dart`
- **Tipo:** `View only`
- **Props:** `String message`, `IconData icon` (opcional, default `Icons.inbox_outlined`).
- **Responsabilidade:** Renderiza icone + mensagem centralizada. Sem CTA (o usuario chega aqui por navegacao). Variante de busca usa o mesmo widget com mensagem customizada.

### `ArchivedAnalysesErrorState` (**novo arquivo**)

- **Localizacao:** `lib/ui/intake/widgets/pages/archived_analyses_screen/archived_analyses_error_state/`
- **Arquivos:** `archived_analyses_error_state_view.dart`, `index.dart`
- **Tipo:** `View only`
- **Props:** `String message`, `VoidCallback onRetry`.
- **Responsabilidade:** Renderiza icone, mensagem e CTA `Tentar novamente`. Espelha `RecentAnalysesErrorStateView`.

### `ArchivedAnalysesSkeletonCard` (**novo arquivo**)

- **Localizacao:** `lib/ui/intake/widgets/pages/archived_analyses_screen/archived_analyses_skeleton_card/`
- **Arquivos:** `archived_analyses_skeleton_card_view.dart`, `index.dart`
- **Tipo:** `View only`
- **Props:** nenhuma.
- **Responsabilidade:** Renderiza um placeholder visual com mesmas dimensoes do `ArchivedAnalysisCard`. Espelha `RecentAnalysesSkeletonCardView`.

### `ArchivedAnalysesInlineError` (**novo arquivo**)

- **Localizacao:** `lib/ui/intake/widgets/pages/archived_analyses_screen/archived_analyses_inline_error/`
- **Arquivos:** `archived_analyses_inline_error_view.dart`, `index.dart`
- **Tipo:** `View only`
- **Props:** `String message`.
- **Responsabilidade:** Renderiza um banner inline com icone de info e mensagem. Espelha `RecentAnalysesInlineErrorView`.

### `ArchivedAnalysesLoadingMore` (**novo arquivo**)

- **Localizacao:** `lib/ui/intake/widgets/pages/archived_analyses_screen/archived_analyses_loading_more/`
- **Arquivos:** `archived_analyses_loading_more_view.dart`, `index.dart`
- **Tipo:** `View only`
- **Props:** nenhuma.
- **Responsabilidade:** Renderiza um `CircularProgressIndicator` pequeno centralizado. Espelha `RecentAnalysesLoadingMoreView`.

### `ArchivedAnalysesSearchBar` (**novo arquivo**)

- **Localizacao:** `lib/ui/intake/widgets/pages/archived_analyses_screen/archived_analyses_search_bar/`
- **Arquivos:** `archived_analyses_search_bar_view.dart`, `archived_analyses_search_bar_presenter.dart`, `index.dart`
- **Tipo:** `View + Presenter`
- **Props (View):** `String initialQuery`, `void Function(String) onQueryChanged`, `VoidCallback onClear`.
- **Responsabilidade:** Renderiza `TextField` com prefix icon (`search`), placeholder `Buscar por nome...`, suffix `clear` quando o texto nao for vazio. O `Presenter` mantem `TextEditingController` e dispara `onQueryChanged` em cada alteracao (sem debounce nesta primeira versao — busca local barata). Em `dispose`, libera o controller.

### `ArchivedAnalysisCard` (**novo arquivo**)

- **Localizacao:** `lib/ui/intake/widgets/pages/archived_analyses_screen/archived_analysis_card/`
- **Arquivos:** `archived_analysis_card_view.dart`, `index.dart`
- **Tipo:** `View only`
- **Props:** `String title`, `String dateLabel`, `bool isUnarchiving`, `VoidCallback onTap`, `Future<void> Function() onUnarchive`.
- **Responsabilidade:** Renderiza card com `InkWell` (tap → `onTap`), `title`, `dateLabel`, e um botao trailing `IconButton` (`unarchive_outlined`/`unarchive`) que abre um dialog de confirmacao e em seguida chama `onUnarchive`. Espelha estilo de `RecentAnalysisCardView`, com a acao adicional.

## Camada UI (Modificacoes — `AnalysisHeaderView`)

> Detalhado em Secao 6. Aqui apenas registra-se que o `AnalysisHeaderView` ganha a prop `bool isArchived` (default `false`) e renderiza um chip visual `Analise arquivada` ao lado do titulo quando `true`.

## Rotas (`go_router`)

- **Localizacao:** `lib/constants/routes.dart`
- **Mudanca:** adicionar `static const String archivedAnalyses = '/archived-analyses';`
- **Localizacao:** `lib/router.dart`
- **Mudanca:** registrar a rota `Routes.archivedAnalyses` apontando para `ArchivedAnalysesScreen()`. Como a tela e acessada a partir do perfil (que esta dentro do `StatefulShellRoute`), a rota deve ser registrada como `GoRoute` no nivel raiz do `appRouter`, fora do shell (similar a `Routes.analysis`), para que abra cobrindo a bottom navigation.

## Estrutura de Pastas

```text
lib/ui/intake/widgets/pages/archived_analyses_screen/
  index.dart
  archived_analyses_screen_view.dart
  archived_analyses_screen_presenter.dart
  archived_analyses_list/
    index.dart
    archived_analyses_list_view.dart
  archived_analyses_loading_state/
    index.dart
    archived_analyses_loading_state_view.dart
  archived_analyses_empty_state/
    index.dart
    archived_analyses_empty_state_view.dart
  archived_analyses_error_state/
    index.dart
    archived_analyses_error_state_view.dart
  archived_analyses_skeleton_card/
    index.dart
    archived_analyses_skeleton_card_view.dart
  archived_analyses_inline_error/
    index.dart
    archived_analyses_inline_error_view.dart
  archived_analyses_loading_more/
    index.dart
    archived_analyses_loading_more_view.dart
  archived_analyses_search_bar/
    index.dart
    archived_analyses_search_bar_view.dart
    archived_analyses_search_bar_presenter.dart
  archived_analysis_card/
    index.dart
    archived_analysis_card_view.dart
```

---

# 6. O que deve ser modificado?

## Constants

- **Arquivo:** `lib/constants/routes.dart`
- **Mudanca:** adicionar `static const String archivedAnalyses = '/archived-analyses';`.
- **Justificativa:** a nova rota precisa de constante semantica reutilizavel pelo router e pelos presenters.

## Router

- **Arquivo:** `lib/router.dart`
- **Mudanca:** importar `archived_analyses_screen/index.dart` e registrar `GoRoute(path: Routes.archivedAnalyses, builder: (context, state) => const ArchivedAnalysesScreen())` no nivel raiz (fora do shell, similar a `Routes.analysis`).
- **Justificativa:** a tela e acessada a partir do perfil e deve ocupar a tela inteira, cobrindo a bottom navigation.

## UI - Analysis Header

- **Arquivo:** `lib/ui/intake/widgets/components/analysis_header/analysis_header_view.dart`
- **Mudanca:** adicionar prop `final bool isArchived` (default `false`); renderizar inline (proximo ao titulo, dentro do mesmo `Row`) um chip visual `Analise arquivada` quando `true` — `Container` com `padding`, `borderRadius`, cor de fundo derivada de `tokens.surfaceElevated` ou `tokens.danger.withValues(alpha: 0.12)` e texto em `textTheme.labelSmall`.
- **Justificativa:** sinalizar visualmente para o usuario que a analise aberta esta arquivada (RF do PRD).

## UI - Analysis Screens (consumidores do AnalysisHeader)

- **Arquivo:** `lib/ui/intake/widgets/pages/first_instance_analysis_screen/first_instance_analysis_screen_view.dart`
- **Mudanca:** ao construir `AnalysisHeader(...)`, ler `presenter.analysis?.isArchived` do signal correspondente e repassar como `isArchived:`. Se o presenter atual nao tiver um signal direto para `analysis`, o ajuste deve apenas usar o atributo equivalente ja exposto (a inspecao detalhada do presenter sera feita durante a implementacao; o spec ja registra o requisito).
- **Justificativa:** propagar o estado arquivado para o header da tela de primeira instancia / case assessment.

- **Arquivo:** `lib/ui/intake/widgets/pages/second_instance_analysis_screen/second_instance_analysis_screen_view.dart`
- **Mudanca:** mesma mudanca, ler `presenter.analysis?.isArchived` e repassar para `AnalysisHeader.isArchived`.
- **Justificativa:** propagar o estado arquivado para o header da tela de segunda instancia / judge.

> Observacao: nao existe atualmente um `analysis_screen_view.dart` dedicado para `CASE_ASSESSMENT` separado do first/second instance; o mapeamento de `Routes.getAnalysis` redireciona `caseAssessment` para `secondInstanceAnalysis`. Assim, cobrir os dois views acima e suficiente para todos os tipos.

## UI - Profile

- **Arquivo:** `lib/ui/auth/widgets/pages/profile_screen/profile_settings_group/profile_settings_group_view.dart`
- **Mudanca:** adicionar uma nova `ProfileSettingsTile` com titulo `Analises arquivadas`, icone `Icons.inventory_2_outlined` (ou similar) e callback `onArchivedAnalysesTap`. A prop `onArchivedAnalysesTap` deve ser adicionada ao construtor.
- **Justificativa:** ponto de entrada para a nova tela conforme PRD.

- **Arquivo:** `lib/ui/auth/widgets/pages/profile_screen/profile_screen_presenter.dart`
- **Mudanca:** adicionar metodo `void goToArchivedAnalyses() => _navigationDriver.pushTo(Routes.archivedAnalyses);`.
- **Justificativa:** a navegacao deve ficar no Presenter, nao na View.

- **Arquivo:** `lib/ui/auth/widgets/pages/profile_screen/profile_screen_view.dart`
- **Mudanca:** repassar `presenter.goToArchivedAnalyses` para o novo callback do `ProfileSettingsGroupView`.
- **Justificativa:** completar o fluxo da entrada visual.

---

# 7. O que deve ser removido?

**Nao aplicavel**.

---

# 8. Decisoes Tecnicas e Trade-offs

- **Decisao:** Reutilizar `IntakeService.listAnalyses` com `isArchived: true` (ja existe) em vez de criar um novo endpoint dedicado.
- **Alternativas consideradas:** Criar um metodo separado `listArchivedAnalyses` no `IntakeService`.
- **Motivo da escolha:** O contrato atual ja parametriza `is_archived` e o servico ja propaga corretamente; criar um metodo separado adicionaria duplicacao sem ganho.
- **Impactos / trade-offs:** Nenhum.

- **Decisao:** Busca textual implementada como filtro local sobre os items ja carregados (client-side), sem chamada server-side dedicada.
- **Alternativas consideradas:** Adicionar query param `q` ao endpoint de listagem e implementar busca server-side.
- **Motivo da escolha:** O escopo da task nao menciona busca server-side; nao ha contrato backend para isso; client-side e suficiente quando a lista cabe em poucas paginas e elimina latencia. Quando a lista crescer muito, a busca pode escalar para server-side em iteracoes futuras.
- **Impactos / trade-offs:** Se o usuario tiver muitas analises arquivadas, ele precisara carregar mais paginas para que a busca encontre items das paginas seguintes. Isso e aceitavel para o MVP da feature.

- **Decisao:** Acao `Desarquivar` exibe dialog de confirmacao antes de chamar a API.
- **Alternativas consideradas:** Acao direta sem confirmacao, com `SnackBar` de undo; swipe-to-action.
- **Motivo da escolha:** Confirmacao explicita evita acidentes; consistente com a acao `Arquivar` na tela de analise (`archive_analysis_dialog`). O padrao `SnackBar` com undo nao tem precedente no app.
- **Impactos / trade-offs:** Mais cliques para desarquivar; aceitavel pois nao e fluxo de alta frequencia.

- **Decisao:** Registrar a rota `Routes.archivedAnalyses` fora do `StatefulShellRoute`, no nivel raiz do `appRouter`.
- **Alternativas consideradas:** Registrar dentro do branch de profile do shell.
- **Motivo da escolha:** A tela e uma feature secundaria do perfil que deve ocupar a tela inteira (cobrindo a bottom navigation), seguindo o padrao das telas de analise (`Routes.analysis`, `Routes.secondInstanceAnalysis`).
- **Impactos / trade-offs:** O usuario sai do shell ao entrar na tela; ao voltar (pop), retorna ao perfil corretamente.

- **Decisao:** O label `Analise arquivada` no header e implementado inline no `AnalysisHeaderView` (sem widget interno dedicado).
- **Alternativas consideradas:** Criar um widget `AnalysisArchivedBadge` dedicado.
- **Motivo da escolha:** E uma simples decoracao visual condicional, sem estado proprio nem handlers, e nao ha previsao de reuso fora do header. Extrair seria over-engineering.
- **Impactos / trade-offs:** Caso o badge seja reutilizado em outras areas no futuro, ele pode ser promovido a widget interno sem refactor disruptivo.

- **Decisao:** `ArchivedAnalysesSearchBar` tem `View + Presenter` enquanto os outros widgets internos sao `View only`.
- **Alternativas consideradas:** Manter tudo como `View only` e o `TextEditingController` no Presenter da tela.
- **Motivo da escolha:** O controller e estado proprio do componente de busca (life-cycle do `TextEditingController` + descarte). Extrair para o Presenter da tela acoplaria o presenter a um detalhe de UI; deixar no presenter do widget mantem a responsabilidade onde ela pertence, conforme regra de UI Layer.
- **Impactos / trade-offs:** Um arquivo a mais; ganha-se isolamento de ciclo de vida do controller.

---

# 9. Diagramas e Referencias

## Fluxo de dados (carga + acao)

```text
ProfileSettingsGroupView (tile "Analises arquivadas")
  -> ProfileScreenPresenter.goToArchivedAnalyses
     -> NavigationDriver.pushTo(Routes.archivedAnalyses)
        -> GoRouter
           -> ArchivedAnalysesScreenView (rota raiz)

ArchivedAnalysesScreenView
  -> archivedAnalysesScreenInitializationProvider (microtask)
     -> ArchivedAnalysesScreenPresenter.initialize()
        -> IntakeService.listAnalyses(limit: 10, isArchived: true)
           -> IntakeRestService.get('/intake/analyses?is_archived=true&limit=10')
           -> CursorPaginationResponse<AnalysisDto>
        -> signal: archivedAnalyses + nextCursor

User scroll -> ArchivedAnalysesList.onLoadMore()
  -> ArchivedAnalysesScreenPresenter.loadNextPage()
     -> IntakeService.listAnalyses(cursor:, limit: 10, isArchived: true)

User tap unarchive -> dialog confirm -> ArchivedAnalysisCard.onUnarchive
  -> ArchivedAnalysesScreenPresenter.unarchive(analysis)
     -> IntakeService.unarchiveAnalysis(analysisId)
        -> IntakeRestService.patch('/intake/analyses/{id}/unarchive')
     -> signal: archivedAnalyses (remove item)
     -> SnackBar feedback

User tap card -> ArchivedAnalysesScreenPresenter.openAnalysis(analysis)
  -> NavigationDriver.pushTo(Routes.getAnalysis(analysisId:, analysisType:))
```

## Hierarquia de widgets

```text
ArchivedAnalysesScreenView (Scaffold + SafeArea)
  AppBar/header (titulo + back)
  ArchivedAnalysesSearchBar
  Watch { conteudo }
    if loading inicial: ArchivedAnalysesLoadingState
    elif error inicial: ArchivedAnalysesErrorState
    elif empty geral: ArchivedAnalysesEmptyState
    elif empty de busca: ArchivedAnalysesEmptyState (variant)
    else:
      ArchivedAnalysesList
        if error paginacao: ArchivedAnalysesInlineError (topo)
        ListView.separated
          ArchivedAnalysisCard
            tap -> openAnalysis
            unarchive icon -> confirm dialog -> unarchive
        if isLoadingMore: ArchivedAnalysesLoadingMore (footer)
```

## Referencias

- `lib/ui/intake/widgets/pages/home_screen/home_screen_presenter.dart` (padrao de paginacao por cursor, lock, refresh, `_resolveErrorMessage`)
- `lib/ui/intake/widgets/pages/home_screen/recent_analyses_section/recent_analyses_section_view.dart` (scroll listener para loadMore, montagem visual dos estados)
- `lib/ui/intake/widgets/pages/home_screen/recent_analyses_section/recent_analyses_*` (widgets internos espelhados)
- `lib/ui/intake/widgets/components/analysis_header/archive_analysis_dialog/` (padrao de dialog de confirmacao para acao destrutiva)
- `lib/ui/auth/widgets/pages/profile_screen/profile_settings_group/profile_settings_group_view.dart` (padrao do tile de perfil)
- `lib/ui/auth/widgets/pages/profile_screen/profile_screen_presenter.dart` (padrao de presenter com `NavigationDriver`)
- `lib/router.dart` (registro de rota raiz fora do shell)
- `lib/constants/routes.dart` (constantes de rota)

---

# 10. Pendencias / Duvidas

- **Descricao:** O design especifico para a tela de analises arquivadas ainda nao foi publicado no Pencil/Google Stitch.
- **Impacto:** A tela seguira o padrao visual da Home (cards iguais a `RecentAnalysisCard`) com adicao do botao de desarquivar e do chip de busca. Quando o design for publicado, ajustes visuais podem ser necessarios.
- **Acao sugerida:** Implementar com o padrao atual; se o design vier antes do PR, ajustar ali.

- **Descricao:** O label exato e visual do chip `Analise arquivada` no `AnalysisHeader` nao foi formalmente especificado.
- **Impacto:** Estetica do badge.
- **Acao sugerida:** Usar estilo neutro derivado de `tokens.surfaceElevated`/`tokens.borderSubtle` com texto `Analise arquivada` em `labelSmall`; ajustes finos podem ser feitos sem impacto arquitetural.

---

# Restricoes

- **Nao inclua testes automatizados na spec.**
- A `View` nao deve conter logica de negocio; toda orquestracao (carga, paginacao, busca, desarquivamento, navegacao) fica no `ArchivedAnalysesScreenPresenter`.
- O `Presenter` da Screen permanece enxuto e orquestrador; o presenter do `ArchivedAnalysesSearchBar` cuida apenas do `TextEditingController`.
- Presenters nao fazem chamadas diretas a `RestClient`; consumem `IntakeService` e `NavigationDriver`.
- Todos os caminhos citados na spec existem no projeto ou estao marcados como **novo arquivo**.
- A spec segue o padrao atual da codebase: arquivos em `snake_case`, classes em `PascalCase`, `Provider` Riverpod para composicao, barrel files por widget.
- Todo widget novo segue `View + Presenter` quando houver estado proprio; os widgets puramente visuais usam apenas `*_view.dart`.
- Nenhuma alteracao em `lib/core`, `lib/rest` ou `lib/drivers` e necessaria (todos os contratos ja existem).
