---
title: Tela Home (Recorte ANI-60)
prd: https://joaogoliveiragarcia.atlassian.net/wiki/spaces/anm/pages/18153473/PRD+RF+05+Home+Interativa
ticket: https://joaogoliveiragarcia.atlassian.net/browse/ANI-60
status: closed
last_updated_at: 2026-03-31
---

# 1. Objetivo

Esta spec define a implementação da `Home` do `animus` no recorte aprovado para `ANI-60`: carregar a saudação dinâmica do usuário a partir de `GET /auth/me`, listar análises recentes não arquivadas com paginação por cursor via `GET /intake/analyses`, permitir a criação de uma nova análise por `POST /intake/analyses` e navegar para uma tela placeholder em `/analyses/:id`. A entrega deve respeitar a arquitetura em camadas já adotada no projeto, reutilizando `AuthService`, introduzindo `IntakeService`, mantendo `MVP`, `Riverpod`, `signals`, `Dio` e `GoRouter`, e usando a tela `Home` do `design/animus.pen` (`96TaK`) apenas como referência visual parcial, sem a seção `Em andamento` que ficou fora deste sprint.

---

# 2. Escopo

## 2.1 In-scope

- Criar a tela `home_screen` em `lib/ui/intake/widgets/pages/home_screen/` com header, lista de recentes, `FAB` e bottom navigation.
- Buscar os dados do usuário autenticado via `GET /auth/me` para exibir saudação por período + primeiro nome.
- Buscar análises não arquivadas via `GET /intake/analyses` com `limit`, `cursor` e `is_archived=false`.
- Implementar scroll infinito para carregar novas páginas sem descartar os itens já exibidos.
- Renderizar card de análise com data formatada, nome da análise e affordance de navegação.
- Navegar para `Routes.analysis` ao tocar em um item válido da lista.
- Criar uma análise via `POST /intake/analyses` sem body obrigatório e navegar para `/analyses/:id` com o `id` retornado.
- Registrar a rota placeholder da tela de análise em `lib/router.dart`.
- Renderizar bottom navigation com `HOME` ativo e `PERFIL` / `BIBLIOTECA` como destinos visuais desta sprint.

## 2.2 Out-of-scope

- Implementar a seção `Em andamento` prevista no `PRD RF 05` e presente no design `96TaK`.
- Exibir tags de categoria, pasta associada, status visual de processamento ou link `Ver todas`.
- Implementar o fluxo funcional de upload de petição (`RF 02`) a partir da Home.
- Implementar conteúdo funcional da tela `/analyses/:id`; nesta sprint ela será apenas placeholder.
- Criar telas de `PERFIL` e `BIBLIOTECA` ou tornar a bottom navigation funcional para esses destinos.
- Introduzir auth guard global no `GoRouter`, refresh token automático ou bootstrap completo de sessão.

---

# 3. Requisitos

## 3.1 Funcionais

- A Home deve exibir saudação contextual com base no horário do dispositivo: `Bom dia`, `Boa tarde` ou `Boa noite`.
- A saudação deve incluir o primeiro nome retornado por `GET /auth/me`.
- O subtítulo fixo do header deve ser `Seu resumo jurídico de hoje`.
- O header deve usar avatar default, sem integração com foto de perfil.
- A seção `Recentes` deve carregar análises via `GET /intake/analyses` com `is_archived=false`, ordenação vinda do backend e paginação por cursor.
- Cada item da lista deve exibir `data formatada + nome da análise + chevron`.
- Enquanto a primeira página estiver carregando, a tela deve exibir estado visual de loading da seção `Recentes`.
- Quando não houver análises, a seção deve exibir estado vazio com mensagem convidando o usuário a iniciar a primeira análise.
- Ao tocar em um item da lista com `id` válido, o app deve navegar para `Routes.getAnalysis(id: analysisId)`.
- O `FAB` deve chamar `POST /intake/analyses`, receber `AnalysisDto` e navegar imediatamente para a tela placeholder da análise criada.
- A rota `/analyses/:id` deve existir e aceitar o `id` retornado pelo backend.

## 3.2 Não funcionais

- **Performance:** a tela deve evitar requisições duplicadas por ação; `initialize`, `loadNextPage` e `createAnalysis` não podem disparar em paralelo para o mesmo fluxo.
- **Acessibilidade:** `FAB`, bottom navigation, estado vazio e estado de erro devem ter texto visível e `tooltip` ou `label` descritivo quando aplicável.
- **Offline/Conectividade:** falha ao carregar a primeira página deve manter a tela em estado de erro recuperável com `retry`; falha ao paginar não deve apagar os itens já exibidos.
- **Segurança:** `GET /auth/me`, `GET /intake/analyses` e `POST /intake/analyses` devem usar `Bearer token` obtido de `CacheDriver` com `CacheKeys.accessToken`; nenhum token deve ser exposto na camada `ui`.
- **Compatibilidade:** a implementação deve permanecer compatível com `flutter_riverpod`, `signals`, `go_router`, `dio` e `shared_preferences` já presentes em `pubspec.yaml`, sem introduzir nova dependência apenas para formatação de data.

---

# 4. O que já existe?

## Camada Core

- **`AuthService`** (`lib/core/auth/interfaces/auth_service.dart`) - contrato atual já concentra operações autenticadas de conta e sessão, mas ainda não expõe `fetchAccount()`.
- **`AccountDto`** (`lib/core/auth/dtos/account_dto.dart`) - DTO já compatível com `id`, `name` e `email`; os demais campos têm fallback e não bloqueiam `GET /auth/me`.
- **`AnalysisDto`** (`lib/core/intake/dtos/analysis_dto.dart`) - DTO de análise já existe, mas ainda não contém `createdAt`, necessário para a Home.
- **`IntakeService`** (`lib/core/intake/interfaces/intake_service.dart`) - contrato existe, porém está vazio e precisa passar a representar o gateway de análises.
- **`CursorPaginationResponse`** (`lib/core/shared/responses/cursor_pagination_response.dart`) - arquivo já existe, mas está vazio e ainda não cobre paginação por cursor.
- **`CacheDriver`** (`lib/core/shared/interfaces/cache_driver.dart`) - contrato pronto para leitura do `access token` persistido localmente.
- **`NavigationDriver`** (`lib/core/shared/interfaces/navigation_driver.dart`) - contrato usado pela UI para navegação sem acoplamento direto ao `GoRouter`.
- **`RestResponse`** (`lib/core/shared/responses/rest_response.dart`) - wrapper comum para sucesso e falha, já usado pelos fluxos de autenticação.

## Camada REST

- **`AuthRestService`** (`lib/rest/services/auth_rest_service.dart`) - implementação atual do `AuthService`; já conhece `AccountDto` e é o ponto mais natural para adicionar `fetchAccount()`.
- **`AccountMapper`** (`lib/rest/mappers/auth/account_mapper.dart`) - mapper já pronto para transformar payload de conta em `AccountDto`.
- **`DioRestClient`** (`lib/rest/dio/dio_rest_client.dart`) - cliente HTTP concreto que encapsula `Dio` e suporta `get`, `post` e `setHeader`.
- **`authServiceProvider`** (`lib/rest/services/index.dart`) - provider Riverpod existente para compor presenters com `AuthService`.

## Camada Drivers

- **`SharedPreferencesCacheDriver`** (`lib/drivers/caches/shared_preferences/shared_preferences_cache_driver.dart`) - implementação concreta de `CacheDriver`, já usada para persistir sessão.
- **`cacheDriverProvider`** (`lib/drivers/cache/index.dart`) - provider Riverpod disponível para leitura de token no app.
- **`GoRouterNavigationDriver`** (`lib/drivers/navigation/go_router/go_router_navigation_driver.dart`) - implementação concreta de `NavigationDriver`, já usada pelos presenters de auth.

## Camada UI

- **`SignInScreenPresenter`** (`lib/ui/auth/widgets/pages/sign_in_screen/sign_in_screen_presenter.dart`) - referência direta de presenter com `signals`, `Provider.autoDispose`, `CacheDriver` e `NavigationDriver`.
- **`EmailConfirmationScreenPresenter`** (`lib/ui/auth/widgets/pages/email_confirmation_screen/email_confirmation_screen_presenter.dart`) - referência de presenter que persiste tokens, traduz `RestResponse` e controla side effects assíncronos.
- **`SignInFormView`** (`lib/ui/auth/widgets/pages/sign_in_screen/sign_in_form/sign_in_form_view.dart`) - referência de `ConsumerWidget` com `Watch(...)` para observar `signals` e renderizar estados visuais.
- **`lib/ui/intake/widgets/pages/.gitkeep`** - o módulo `intake` já existe na camada UI, mas ainda não possui telas reais implementadas.

## App / Router

- **`Routes`** (`lib/constants/routes.dart`) - já centraliza `Routes.home` e uma constante `Routes.analysis` ainda não alinhada ao contrato `/analyses/:id`.
- **`appRouter`** (`lib/router.dart`) - atualmente inicia em `Routes.signIn` e redireciona `Routes.home` para login; isso precisa ser substituído pela Home real.
- **`CacheKeys`** (`lib/constants/cache_keys.dart`) - já define `CacheKeys.accessToken` e `CacheKeys.refreshToken`.

## Design / Referência visual

- **`Home`** (`design/animus.pen`, node `96TaK`) - referência visual da tela com header, cards recentes, `FAB` e tab bar; a spec reutiliza header, lista, `FAB` e bottom navigation, mas exclui `Em andamento` por decisão de sprint.
- **`Chat - Upload`** (`design/animus.pen`, node `jhO0x`) e **`Chat - Resumo`** (`design/animus.pen`, node `pw1KC`) - existem no design como contexto futuro do domínio `intake`, mas não entram nesta implementação além da criação da rota placeholder.

---

# 5. O que deve ser criado?

## Camada REST (Services)

- **Localização:** `lib/rest/services/intake_rest_service.dart` (**novo arquivo**)
- **Interface implementada:** `IntakeService`
- **Dependências:** `RestClient`, `CacheDriver`
- **Métodos:**
- `Future<RestResponse<CursorPaginationResponse<AnalysisDto>>> listAnalyses({String? cursor, required int limit, bool isArchived = false})` - autentica a chamada, envia `GET /intake/analyses` com `cursor`, `limit` e `is_archived`, e converte o payload paginado para `CursorPaginationResponse<AnalysisDto>`.
- `Future<RestResponse<AnalysisDto>> createAnalysis({String? folderId})` - autentica a chamada, envia `POST /intake/analyses` com `folder_id` apenas quando houver valor e devolve a análise criada.

## Camada REST (Mappers)

- **Localização:** `lib/rest/mappers/intake/analysis_mapper.dart` (**novo arquivo**)
- **Métodos:**
- `AnalysisDto toDto(Map<String, dynamic> json)` - mapeia `id`, `name`, `account_id`, `status`, `summary`, `folder_id`, `is_archived` e `created_at` para `AnalysisDto`.

## Camada UI (Presenters)

- **Localização:** `lib/ui/intake/widgets/pages/home_screen/home_screen_presenter.dart` (**novo arquivo**)
- **Dependências injetadas:** `AuthService`, `IntakeService`, `CacheDriver`, `NavigationDriver`
- **Estado (`signals`):**
- **Signals simples:** `signal<bool> isLoadingInitialData`, `signal<bool> isLoadingMore`, `signal<bool> isCreatingAnalysis`, `signal<String?> generalError`, `signal<String?> firstName`, `signal<List<AnalysisDto>> recentAnalyses`, `signal<String?> nextCursor`
- **Computeds:** `computed<String> greeting`, `computed<bool> hasMore`, `computed<bool> showEmptyState`
- **Provider Riverpod:** `homeScreenPresenterProvider`
- **Métodos:**
- `Future<void> initialize()` - valida a existência de sessão local, busca conta e primeira página de análises e prepara o estado inicial da tela.
- `Future<void> loadNextPage()` - carrega a próxima página quando houver `nextCursor` e nenhuma paginação estiver em voo.
- `Future<void> createAnalysis()` - cria uma nova análise via `IntakeService.createAnalysis` e navega para `Routes.getAnalysis(id: ...)`.
- `void openAnalysis(AnalysisDto analysis)` - navega para a tela placeholder da análise tocada quando o `id` estiver disponível.
- `void onDestinationSelected(int index)` - mantém `HOME` ativo e trata `PERFIL` / `BIBLIOTECA` como destinos visuais sem navegação nesta sprint.
- `String formatCreatedAt(String value)` - converte a string de data da API para `dd/MM/yyyy` para exibição nos cards.

## Camada UI (Views)

- **Localização:** `lib/ui/intake/widgets/pages/home_screen/home_screen_view.dart` (**novo arquivo**)
- **Base class:** `ConsumerWidget`
- **Props:** nenhuma
- **Bibliotecas de UI:** `flutter/material.dart`, `flutter_riverpod`, `signals_flutter`
- **Estados visuais:**
- `Loading` - estrutura da tela visível com loading da seção `Recentes` e `FAB` desabilitado.
- `Error` - mensagem textual com CTA de retry quando a carga inicial falhar antes de haver itens exibidos.
- `Empty` - header carregado e estado vazio na seção `Recentes`, com CTA para iniciar a primeira análise.
- `Content` - header, lista paginada, `FAB` e bottom navigation.

- **Localização:** `lib/ui/intake/widgets/pages/analysis_screen/analysis_screen_view.dart` (**novo arquivo**)
- **Base class:** `StatelessWidget`
- **Props:** `required String analysisId`
- **Bibliotecas de UI:** `flutter/material.dart`
- **Estados visuais:**
- `Content` - tela placeholder com `AppBar`, identificação da análise e mensagem de que o conteúdo funcional será implementado depois.

## Camada UI (Widgets Internos)

- **Localização:** `lib/ui/intake/widgets/pages/home_screen/home_header/` (**novo arquivo** em pasta nova)
- **Tipo:** View only
- **Arquivos:** `index.dart`, `home_header_view.dart`
- **Props:** `required String greeting`, `required String subtitle`
- **Responsabilidade:** renderizar o bloco superior da Home com saudação, subtítulo fixo e avatar default.

- **Localização:** `lib/ui/intake/widgets/pages/home_screen/recent_analyses_section/` (**novo arquivo** em pasta nova)
- **Tipo:** View only
- **Arquivos:** `index.dart`, `recent_analyses_section_view.dart`
- **Props:** `required List<AnalysisDto> analyses`, `required bool isLoading`, `required bool isLoadingMore`, `required bool showEmptyState`, `required String? errorMessage`, `required String Function(String value) formatCreatedAt`, `required ValueChanged<AnalysisDto> onTapAnalysis`, `required VoidCallback onRetry`, `required VoidCallback onLoadMore`, `required VoidCallback onCreateFirstAnalysis`
- **Responsabilidade:** renderizar a seção `Recentes`, alternando entre loading, erro, vazio e conteúdo, e disparar a paginação ao chegar ao final da lista.

- **Localização:** `lib/ui/intake/widgets/pages/home_screen/recent_analyses_section/recent_analysis_card/` (**novo arquivo** em pasta nova)
- **Tipo:** View only
- **Arquivos:** `index.dart`, `recent_analysis_card_view.dart`
- **Props:** `required String title`, `required String dateLabel`, `required VoidCallback onTap`
- **Responsabilidade:** renderizar cada card de análise recente com data, título e chevron.

- **Localização:** `lib/ui/intake/widgets/pages/home_screen/create_analysis_fab/` (**novo arquivo** em pasta nova)
- **Tipo:** View only
- **Arquivos:** `index.dart`, `create_analysis_fab_view.dart`
- **Props:** `required bool isLoading`, `required VoidCallback? onPressed`
- **Responsabilidade:** renderizar o `FAB` de criação com loading e estado desabilitado quando a criação estiver em voo.

- **Localização:** `lib/ui/intake/widgets/pages/home_screen/home_bottom_navigation/` (**novo arquivo** em pasta nova)
- **Tipo:** View only
- **Arquivos:** `index.dart`, `home_bottom_navigation_view.dart`
- **Props:** `required int currentIndex`, `required ValueChanged<int> onDestinationSelected`
- **Responsabilidade:** renderizar a bottom navigation da Home com `HOME` selecionado e destinos visuais para `PERFIL` e `BIBLIOTECA`.

## Camada UI (Barrel Files / `index.dart`)

- **Localização:** `lib/ui/intake/widgets/pages/home_screen/index.dart` (**novo arquivo**)
- **`typedef` exportado:** `typedef HomeScreen = HomeScreenView`
- **Widgets internos exportados:** não aplicável

- **Localização:** `lib/ui/intake/widgets/pages/analysis_screen/index.dart` (**novo arquivo**)
- **`typedef` exportado:** `typedef AnalysisScreen = AnalysisScreenView`
- **Widgets internos exportados:** não aplicável

## Camada UI (Providers Riverpod - se isolados)

- **Localização:** `lib/ui/intake/widgets/pages/home_screen/home_screen_presenter.dart` (**novo arquivo**)
- **Nome do provider:** `homeScreenPresenterProvider`
- **Tipo:** `Provider.autoDispose<HomeScreenPresenter>`
- **Dependências:** `ref.watch(authServiceProvider)`, `ref.watch(intakeServiceProvider)`, `ref.watch(cacheDriverProvider)`, `ref.watch(navigationDriverProvider)`

## Rotas (`go_router`) - se aplicável

- **Localização:** `lib/router.dart` e `lib/constants/routes.dart`
- **Caminho da rota:** `Routes.home = '/'`
- **Widget principal:** `HomeScreen`
- **Guards / redirecionamentos:** sem auth guard global; o presenter valida sessão local ao inicializar.

- **Localização:** `lib/router.dart` e `lib/constants/routes.dart`
- **Caminho da rota:** `Routes.analysis = '/analyses/:id'`
- **Widget principal:** `AnalysisScreen`
- **Guards / redirecionamentos:** se `id` vier ausente ou vazio, redirecionar para `Routes.home`.

## Estrutura de Pastas

```text
lib/ui/intake/widgets/pages/
  home_screen/
    index.dart
    home_screen_view.dart
    home_screen_presenter.dart
    home_header/
      index.dart
      home_header_view.dart
    recent_analyses_section/
      index.dart
      recent_analyses_section_view.dart
      recent_analysis_card/
        index.dart
        recent_analysis_card_view.dart
    create_analysis_fab/
      index.dart
      create_analysis_fab_view.dart
    home_bottom_navigation/
      index.dart
      home_bottom_navigation_view.dart
  analysis_screen/
    index.dart
    analysis_screen_view.dart
```

---

# 6. O que deve ser modificado?

## Camada Core

- **Arquivo:** `lib/core/auth/interfaces/auth_service.dart`
- **Mudança:** adicionar `Future<RestResponse<AccountDto>> fetchAccount()`.
- **Justificativa:** a Home precisa buscar o nome do usuário autenticado sem acessar `RestClient` diretamente.

- **Arquivo:** `lib/core/intake/interfaces/intake_service.dart`
- **Mudança:** substituir o contrato vazio por `listAnalyses(...)` e `createAnalysis(...)` com `RestResponse` tipado.
- **Justificativa:** a UI da Home precisa de uma porta estável para consumir o domínio `intake`.

- **Arquivo:** `lib/core/intake/dtos/analysis_dto.dart`
- **Mudança:** adicionar `final String createdAt` ao DTO existente.
- **Justificativa:** a lista da Home precisa exibir data formatada por item e hoje o DTO não carrega esse dado.

- **Arquivo:** `lib/core/shared/responses/cursor_pagination_response.dart`
- **Mudança:** implementar a classe genérica `CursorPaginationResponse<T>` com `items` e `nextCursor`.
- **Justificativa:** `GET /intake/analyses` retorna paginação por cursor e o arquivo atual está vazio.

## Camada REST

- **Arquivo:** `lib/rest/services/auth_rest_service.dart`
- **Mudança:** adicionar `fetchAccount()`, injetar `CacheDriver` e configurar o header `Authorization` antes de chamadas autenticadas.
- **Justificativa:** `GET /auth/me` depende de sessão válida e deve permanecer encapsulado na camada REST.

- **Arquivo:** `lib/rest/services/index.dart`
- **Mudança:** injetar `cacheDriverProvider` no `authServiceProvider` e registrar `intakeServiceProvider` para `IntakeRestService`.
- **Justificativa:** os presenters precisam compor `AuthService` e `IntakeService` já autenticados via Riverpod.

## App / Router

- **Arquivo:** `lib/constants/routes.dart`
- **Mudança:** alinhar `Routes.analysis` para `'/analyses/:id'` e adicionar `String getAnalysis({required String id})`.
- **Justificativa:** a navegação da Home e do `FAB` precisa construir a rota final da análise sem concatenar strings manualmente.

- **Arquivo:** `lib/router.dart`
- **Mudança:** substituir o redirect de `Routes.home` por um builder real para `HomeScreen` e registrar a rota `Routes.analysis` com extração de `id`.
- **Justificativa:** a Home deixa de ser placeholder e passa a ser a primeira tela útil após autenticação.

---

# 7. O que deve ser removido?

**Não aplicável**.

---

# 8. Decisões Técnicas e Trade-offs

- **Decisão:** priorizar o recorte de `ANI-60` sobre o escopo completo do `PRD RF 05`.
- **Alternativas consideradas:** seguir o PRD integral com `Em andamento`, CTA para upload (`RF 02`) e link `Ver todas`.
- **Motivo da escolha:** o escopo foi validado explicitamente pelo usuário durante a elaboração desta spec.
- **Impactos / trade-offs:** a spec fica consistente com o sprint atual, mas documenta uma entrega menor que o PRD e o design `96TaK`.

- **Decisão:** estender `AuthService` com `fetchAccount()` em vez de criar um `AccountService` novo.
- **Alternativas consideradas:** criar um contrato dedicado para conta em `lib/core/auth/interfaces/`.
- **Motivo da escolha:** já existe `AccountDto`, `AccountMapper` e `AuthRestService`; a extensão é menor e evita duplicidade de provider e service.
- **Impactos / trade-offs:** `AuthService` cresce um pouco, mas continua coeso dentro do domínio `auth`.

- **Decisão:** adicionar autenticação por `Bearer token` diretamente nos services REST via `CacheDriver`.
- **Alternativas consideradas:** criar um interceptor global de `Dio` ou um `RestClient` autenticado separado.
- **Motivo da escolha:** o projeto ainda não possui bootstrap global de sessão nem interceptor configurado; a solução por service é a menor mudança correta para esta sprint.
- **Impactos / trade-offs:** a configuração do header fica distribuída entre `AuthRestService` e `IntakeRestService`, mas evita introduzir infraestrutura nova antes da necessidade real.

- **Decisão:** manter `Routes.home` sem auth guard global e validar a sessão no `HomeScreenPresenter.initialize()`.
- **Alternativas consideradas:** redirecionamento global no `GoRouter` baseado em cache local.
- **Motivo da escolha:** o `router.dart` atual não é composto por Riverpod nem por um mecanismo de sessão reativo; a validação no presenter é a adaptação mínima ao estado atual da app.
- **Impactos / trade-offs:** a proteção de rota fica menos centralizada e deverá ser refatorada quando houver bootstrap de sessão mais robusto.

- **Decisão:** manter a bottom navigation local à pasta da Home e com comportamento visual para `PERFIL` e `BIBLIOTECA`.
- **Alternativas consideradas:** criar componente global em `lib/ui/shared/` ou já implementar rotas inexistentes.
- **Motivo da escolha:** ainda não há evidência de reuso no código nem telas prontas para os outros destinos.
- **Impactos / trade-offs:** quando `PERFIL` e `BIBLIOTECA` entrarem no roadmap, esse widget provavelmente precisará ser extraído para um ponto compartilhado.

- **Decisão:** formatar a data no presenter sem adicionar `intl`.
- **Alternativas consideradas:** adicionar `intl` apenas para `dd/MM/yyyy`.
- **Motivo da escolha:** o projeto não usa `intl` hoje e a necessidade desta sprint é restrita a um formato simples e fixo.
- **Impactos / trade-offs:** a solução fica menos flexível para internacionalização futura, mas evita custo de dependência nova neste momento.

---

# 9. Diagramas e Referências

- **Fluxo de dados:**

```text
HomeScreenView
  -> homeScreenPresenterProvider
    -> HomeScreenPresenter.initialize()
      -> CacheDriver.get(CacheKeys.accessToken)
      -> AuthService.fetchAccount()
        -> AuthRestService
          -> CacheDriver.get(token)
          -> RestClient.setHeader('Authorization', 'Bearer ...')
          -> RestClient.get('/auth/me')
      -> IntakeService.listAnalyses(limit: pageSize, isArchived: false)
        -> IntakeRestService
          -> CacheDriver.get(token)
          -> RestClient.setHeader('Authorization', 'Bearer ...')
          -> RestClient.get('/intake/analyses')
      -> signals (greeting, recentAnalyses, nextCursor, generalError)

FAB tap
  -> HomeScreenPresenter.createAnalysis()
    -> IntakeService.createAnalysis()
      -> IntakeRestService
        -> RestClient.post('/intake/analyses')
    -> NavigationDriver.goTo(Routes.getAnalysis(id: ...))
```

- **Hierarquia de widgets:**

```text
HomeScreenView
  Scaffold
    SafeArea
      Column
        HomeHeader
        Expanded
          RecentAnalysesSection
            ErrorState | EmptyState | LoadingState | ListView.builder
              RecentAnalysisCard * N
        CreateAnalysisFab
        HomeBottomNavigation

AnalysisScreenView
  Scaffold
    AppBar
    Center
      Placeholder content
```

- **Referências:**
- `lib/ui/auth/widgets/pages/sign_in_screen/sign_in_screen_presenter.dart`
- `lib/ui/auth/widgets/pages/sign_in_screen/sign_in_form/sign_in_form_view.dart`
- `lib/ui/auth/widgets/pages/email_confirmation_screen/email_confirmation_screen_presenter.dart`
- `lib/rest/services/auth_rest_service.dart`
- `lib/rest/services/index.dart`
- `lib/router.dart`
- `design/animus.pen` - node `96TaK` (`Home`)

---

# 10. Pendências / Dúvidas

- **Descrição da pendência:** o contrato textual de `ANI-29` não lista explicitamente os campos do `AnalysisDto` retornado pelo backend, mas a Home depende de `created_at` para exibir a data formatada.
- **Impacto na implementação:** se o backend não devolver `created_at`, o card de recentes ficará sem um dos dados obrigatórios do ticket.
- **Ação sugerida:** validar com backend na `ANI-29` que o payload de `AnalysisDto` inclui `created_at` antes de iniciar a implementação mobile.

- **Descrição da pendência:** `PERFIL` e `BIBLIOTECA` aparecem no design e no ticket, mas ainda não possuem telas nem rotas reais na codebase.
- **Impacto na implementação:** a bottom navigation desta sprint precisa permanecer visual ou com `no-op`, evitando navegação para destinos inexistentes.
- **Ação sugerida:** validar com produto e design que o comportamento visual sem navegação atende a DoD de `ANI-60`.

---

# Restrições

- **Não inclua testes automatizados na spec.**
- A `View` não deve conter lógica de negócio; toda orquestração fica no `Presenter`.
- Presenters não fazem chamadas diretas a `RestClient`; consomem sempre `AuthService` ou `IntakeService` definidos no `core`.
- Todos os caminhos citados nesta spec existem no projeto ou estão marcados como **novo arquivo**.
- Esta spec não inventa telas funcionais para `PERFIL`, `BIBLIOTECA` nem para o fluxo completo de upload; esses pontos permanecem fora do escopo.
- Toda referência a código existente usa caminho relativo real em `lib/...` ou `design/...`.
- Se uma seção não se aplicar, ela foi preenchida explicitamente com **Não aplicável**.
- Toda widget com responsabilidade própria ou subestrutura relevante foi organizada em pasta própria com `index.dart` e `*_view.dart`; apenas `home_screen` recebe `*_presenter.dart` porque concentra o estado da tela.
- A UI deve continuar baseada em componentes Flutter Material alinhados ao tema existente (`AppThemeTokens`).
- A spec mantém a nomenclatura da codebase: arquivos em `snake_case`, classes em `PascalCase`, métodos e providers em `camelCase`, e barrel files por widget.
