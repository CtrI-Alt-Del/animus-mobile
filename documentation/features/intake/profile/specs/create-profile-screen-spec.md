---
title: Tela de Perfil (Recorte ANI-43)
prd: https://joaogoliveiragarcia.atlassian.net/wiki/spaces/anm/pages/16908291/PRD+RF+01+Gerenciamento+de+sess+o+do+usu+rio
ticket: https://joaogoliveiragarcia.atlassian.net/browse/ANI-43
status: closed
last_updated_at: 2026-04-02
screen_ids: [CHZUu]  # Pencil/raw .pen fallback: I - Configuracoes
---

# 1. Objetivo

Esta spec define a implementacao da tela de perfil no `animus` no recorte confirmado para `ANI-43`: disponibilizar uma rota funcional de perfil, acessivel pela bottom navigation da Home e pelo avatar do header da Home, seguindo o shell visual principal do node `CHZUu` (`I - Configuracoes`) e carregando os dados da conta autenticada via `GET /auth/account`. A entrega deve respeitar a arquitetura atual do projeto, reutilizando `AuthService.fetchAccount`, mantendo `MVP`, `Riverpod`, `signals`, `NavigationDriver`, `CacheDriver` e `GoRouter`, sem introduzir contratos novos de backend para editar nome, trocar senha, desativar conta ou sair da sessao.

---

# 2. Escopo

## 2.1 In-scope

- Criar a tela `profile_screen` em `lib/ui/auth/widgets/pages/profile_screen/`.
- Registrar a rota `Routes.profile` em `lib/router.dart`.
- Tornar a bottom navigation funcional entre `HOME` e `PERFIL`, com a ordem `HOME | BIBLIOTECA | PERFIL`.
- Carregar a conta autenticada ao entrar na tela de perfil usando `AuthService.fetchAccount()`.
- Exibir estado de `Loading`, `Error` recuperavel e `Content` read-only para `name` e `email`.
- Reproduzir a hierarquia visual principal validada no node `CHZUu`, ajustando o titulo exibido na tela para `Perfil`, com card de perfil, grupo de configuracoes, botao destrutivo inferior e tab bar.
- Renderizar o grupo de configuracoes e o botao `Sair da Conta` como elementos visuais normais nesta sprint, sem fluxo funcional associado.
- Extrair a bottom navigation atual da Home para um widget compartilhado em `lib/ui/shared/widgets/components/app_bottom_navigation/`.
- Tornar o avatar do topo da Home clicavel para navegar para `Routes.profile`.

## 2.2 Out-of-scope

- Edicao de nome da conta.
- Troca de senha com `senha atual + nova senha`.
- Desativacao ou exclusao de conta.
- Logout funcional com limpeza de tokens.
- Criacao de novos endpoints, DTOs, interfaces ou mapeadores REST para perfil.
- Implementacao funcional do destino `BIBLIOTECA`.
- Implementacao funcional das linhas `Editar Nome`, `Alterar Senha`, `Tema`, `Sobre o App`, `Deletar Conta` e `Sair da Conta`.
- Exibicao do item `Numero de Precedentes`, pois nao existe fonte de dados correspondente na codebase mobile nem contrato backend publicado.
- Auth guard global, refresh token automatico ou tratamento centralizado de expiracao de sessao.

---

# 3. Requisitos

## 3.1 Funcionais

- Ao tocar em `PERFIL` na bottom navigation da Home, o app deve navegar para `Routes.profile`.
- Ao tocar no avatar do topo da Home, o app deve navegar para `Routes.profile`.
- A rota `Routes.profile` deve renderizar uma tela dedicada de perfil sem parametros obrigatorios.
- Ao entrar na tela, o presenter deve validar a existencia local de `CacheKeys.accessToken`; se o token estiver ausente, deve redirecionar para `Routes.signIn`.
- Com sessao local presente, a tela deve chamar `AuthService.fetchAccount()` e exibir os dados da conta autenticada.
- Em sucesso, a tela deve exibir o titulo `Perfil`, um card de perfil com avatar por inicial, `name` e `email` vindos de `AccountDto`.
- O avatar do card deve derivar a inicial a partir do primeiro caractere util de `name`; se `name` vier vazio, a tela deve usar um fallback textual seguro.
- A tela deve renderizar um grupo de configuracoes visual com as linhas `Editar Nome`, `Alterar Senha`, `Tema`, `Sobre o App` e `Deletar Conta`, respeitando a ordem do design validado.
- A linha `Tema` deve refletir apenas o estado visual atual do app (`AppTheme.defaultThemeMode`), sem permitir alteracao nesta sprint.
- A linha `Sobre o App` pode exibir a versao visual `v1.0.0`, alinhada ao `pubspec.yaml` atual, sem criar mecanismo novo de leitura de metadata.
- O item `Numero de Precedentes` nao deve ser implementado neste recorte.
- A tela deve renderizar o botao inferior `Sair da Conta` apenas como elemento visual, sem apagar sessao local.
- Em falha na carga remota, a tela deve exibir mensagem visivel e CTA de `Tentar novamente`, sem sair da rota automaticamente.
- A tela de perfil deve usar a mesma bottom navigation compartilhada da Home, com `PERFIL` marcado como ativo e ordem `HOME | BIBLIOTECA | PERFIL`.
- Ao tocar em `HOME` na tela de perfil, o app deve navegar para `Routes.home`.
- Ao tocar em `BIBLIOTECA`, o app deve manter o comportamento visual atual da sprint, sem navegacao funcional.

## 3.2 Nao funcionais

- **Performance:** `initialize()` da tela de perfil nao deve disparar requisicoes concorrentes para `fetchAccount`; enquanto uma carga estiver em voo, novas tentativas devem ser ignoradas.
- **Acessibilidade:** os destinos da bottom navigation devem ter label textual visivel; o estado ativo nao pode depender apenas de cor; o estado de erro deve ter texto e CTA explicitos.
- **Offline/Conectividade:** falha de rede deve manter a tela em estado recuperavel, com possibilidade de nova tentativa sem reiniciar a aplicacao.
- **Seguranca:** o token continua sendo lido apenas via `CacheDriver`; nenhum token ou header HTTP pode vazar para a camada `ui`.
- **Compatibilidade:** a implementacao deve permanecer compativel com `flutter_riverpod`, `signals_flutter`, `go_router`, `dio` e `shared_preferences`, sem adicionar dependencia nova para esta task.

---

# 4. O que ja existe?

## Camada Core

- **`AuthService`** (`lib/core/auth/interfaces/auth_service.dart`) - contrato atual ja expõe `Future<RestResponse<AccountDto>> fetchAccount()` e pode ser reutilizado sem extensoes.
- **`AccountDto`** (`lib/core/auth/dtos/account_dto.dart`) - DTO atual concentra `id`, `name`, `email`, `isVerified` e `socialAccounts`; para este recorte, apenas `name` e `email` sao requisitos obrigatorios de exibicao.
- **`CacheDriver`** (`lib/core/shared/interfaces/cache_driver.dart`) - contrato atual permite validar a existencia local do `access token` antes da carga remota.
- **`NavigationDriver`** (`lib/core/shared/interfaces/navigation_driver.dart`) - contrato ja usado pelos presenters para navegar sem acoplamento direto ao `GoRouter`.

## Camada REST

- **`AuthRestService`** (`lib/rest/services/auth_rest_service.dart`) - implementacao concreta do `AuthService`; ja possui `fetchAccount()` chamando `GET /auth/account`.
- **`AccountMapper`** (`lib/rest/mappers/auth/account_mapper.dart`) - mapper ja existente para converter a resposta de conta em `AccountDto`.
- **`authServiceProvider`** (`lib/rest/services/index.dart`) - provider Riverpod atual para injecao de `AuthService` nos presenters.

## Camada Drivers

- **`SharedPreferencesCacheDriver`** (`lib/drivers/caches/shared_preferences/shared_preferences_cache_driver.dart`) - implementacao concreta usada para leitura do token persistido.
- **`cacheDriverProvider`** (`lib/drivers/cache/index.dart`) - provider atual de `CacheDriver`.
- **`GoRouterNavigationDriver`** (`lib/drivers/navigation/go_router/go_router_navigation_driver.dart`) - implementacao concreta de `NavigationDriver` ja usada pela Home e pelos fluxos de auth.

## Camada UI

- **`HomeScreenPresenter`** (`lib/ui/intake/widgets/pages/home_screen/home_screen_presenter.dart`) - referencia direta para presenter com `signals`, leitura de token local, `AuthService.fetchAccount()` e orquestracao de navegacao.
- **`HomeScreenView`** (`lib/ui/intake/widgets/pages/home_screen/home_screen_view.dart`) - referencia de tela pos-login com `Scaffold`, `SafeArea`, `ConstrainedBox`, bottom navigation e avatar de header.
- **`HomeBottomNavigationView`** (`lib/ui/intake/widgets/pages/home_screen/home_bottom_navigation/home_bottom_navigation_view.dart`) - implementacao atual da tab bar com `HOME`, `PERFIL` e `BIBLIOTECA`; hoje esta acoplada ao modulo da Home e sera substituida por um componente compartilhado com ordem `HOME`, `BIBLIOTECA`, `PERFIL`.
- **`AuthHeaderView`** (`lib/ui/auth/widgets/components/auth_header/auth_header_view.dart`) - componente visual existente que pode servir como referencia de titulo/subtitulo tipografico para a tela de perfil.
- **`MessageBoxView`** (`lib/ui/auth/widgets/pages/email_confirmation_screen/message_box/message_box_view.dart`) - componente textual ja existente para feedback de erro visivel e consistente com o modulo `auth`.

## Design / Referencia visual

- **`I - Configuracoes`** (`design/animus.pen`, node `CHZUu`) - o layout validado contem `Status Bar`, `header`, card de perfil, `Settings Group`, botao `Sair da Conta`, `Tab Bar` e decoracoes de fundo.
- **`pubspec.yaml`** (`pubspec.yaml`) - a versao atual do app e `1.0.0+1`, o que permite alinhar a copy visual `v1.0.0` da linha `Sobre o App` sem criar contrato novo.
- **`AppTheme.defaultThemeMode`** (`lib/theme.dart`) - o estado global atual e `ThemeMode.dark`, servindo como referencia apenas visual para a linha `Tema`.

## App / Router

- **`Routes`** (`lib/constants/routes.dart`) - a constante `Routes.profile = '/auth/profile'` ja existe, mas ainda nao ha rota registrada no `appRouter`.
- **`appRouter`** (`lib/router.dart`) - roteador atual ja registra `signIn`, `signUp`, `emailConfirmation`, `forgotPassword`, `checkEmail`, `newPassword`, `home` e `analysis`, mas nao registra `profile`.
- **`CacheKeys`** (`lib/constants/cache_keys.dart`) - ja define `CacheKeys.accessToken` e `CacheKeys.refreshToken`.

## Lacunas encontradas

- Nao existe modulo de perfil em `lib/ui/`; a constante de rota existe, mas a tela nao.
- Nao existe endpoint backend para editar nome da conta.
- Nao existe endpoint backend para trocar senha exigindo `senha atual`.
- Nao existe endpoint backend para desativar conta, embora a entidade do servidor ja tenha suporte interno a `deactivate()`.
- Nao existe fluxo de logout implementado na UI atual, embora `CacheDriver.delete(...)` permita construi-lo no futuro.
- Nao existe fonte de dados publicada para a metrica `Numero de Precedentes` mostrada no design.
- `ANI-43` no Jira nao descreve contrato backend; o recorte confirmado pelo usuario foi explicitamente reduzido para `so tela e navegacao`.

---

# 5. O que deve ser criado?

## Camada UI (Presenters)

- **Localizacao:** `lib/ui/auth/widgets/pages/profile_screen/profile_screen_presenter.dart` (**novo arquivo**)
- **Dependencias injetadas:** `AuthService`, `CacheDriver`, `NavigationDriver`
- **Estado (`signals`):**
- `signal<bool> isLoadingInitialData` - controla a carga inicial da conta.
- `signal<String?> generalError` - armazena erro recuperavel de carregamento.
- `signal<AccountDto?> account` - guarda a conta autenticada carregada.
- `computed<bool> hasAccount` - verdadeiro quando `account != null`.
- `computed<String> displayInitial` - deriva a inicial do avatar a partir de `account.name`, com fallback quando vazio.
- `computed<String> displayName` - deriva o nome exibivel a partir de `account.name`, com fallback textual quando vazio.
- `computed<String> displayEmail` - deriva o e-mail exibivel a partir de `account.email`, com fallback textual quando vazio.
- **Provider Riverpod:** `profileScreenPresenterProvider`, `profileScreenInitializationProvider`
- **Metodos:**
- `Future<void> initialize()` - valida a sessao local, chama `AuthService.fetchAccount()`, atualiza `account` em sucesso e `generalError` em falha.
- `void onDestinationSelected(int index)` - navega para `Routes.home` quando `index == 0`, ignora `index == 1` nesta sprint e mantem a tela atual quando `index == 2`.
- `void dispose()` - libera `signals` e qualquer estado derivado.

## Camada UI (Views)

- **Localizacao:** `lib/ui/auth/widgets/pages/profile_screen/profile_screen_view.dart` (**novo arquivo**)
- **Base class:** `ConsumerWidget`
- **Props:** nenhuma
- **Bibliotecas de UI:** `flutter/material.dart`, `flutter_riverpod`, `signals_flutter`
- **Estados visuais:**
- `Loading` - estrutura da pagina ja visivel, com area de conteudo em carregamento e bottom navigation ativa.
- `Error` - mensagem textual com CTA de retry quando `fetchAccount()` falhar antes de haver conteudo valido.
- `Content` - cabecalho `Perfil`, card read-only com avatar inicial + `name` + `email`, grupo de configuracoes visual e botao destrutivo inferior sem acao.

## Camada UI (Widgets Internos / Compartilhados)

- **Localizacao:** `lib/ui/auth/widgets/pages/profile_screen/profile_account_card/` (**novo arquivo** em pasta nova)
- **Tipo:** View only
- **Arquivos:** `index.dart`, `profile_account_card_view.dart`
- **Props:** `required String initial`, `required String name`, `required String email`
- **Responsabilidade:** renderizar o card superior de perfil validado no design, com avatar circular, inicial, nome e e-mail.

- **Localizacao:** `lib/ui/auth/widgets/pages/profile_screen/profile_settings_group/` (**novo arquivo** em pasta nova)
- **Tipo:** View only
- **Arquivos:** `index.dart`, `profile_settings_group_view.dart`
- **Props:** `required bool isDarkThemeEnabled`, `required String appVersionLabel`
- **Responsabilidade:** renderizar o bloco `Settings Group` do design com linhas visuais nao funcionais para `Editar Nome`, `Alterar Senha`, `Tema`, `Sobre o App` e `Deletar Conta`.

- **Localizacao:** `lib/ui/auth/widgets/pages/profile_screen/profile_logout_button/` (**novo arquivo** em pasta nova)
- **Tipo:** View only
- **Arquivos:** `index.dart`, `profile_logout_button_view.dart`
- **Props:** `required VoidCallback onPressed`
- **Responsabilidade:** renderizar o botao inferior `Sair da Conta` com estilo destrutivo; neste recorte, `onPressed` existe apenas para manter o estado visual normal, sem fluxo funcional.

- **Localizacao:** `lib/ui/shared/widgets/components/app_bottom_navigation/` (**novo arquivo** em pasta nova)
- **Tipo:** View only
- **Arquivos:** `index.dart`, `app_bottom_navigation_view.dart`
- **Props:** `required int currentIndex`, `required ValueChanged<int> onDestinationSelected`
- **Responsabilidade:** renderizar a tab bar compartilhada do app com `HOME`, `BIBLIOTECA` e `PERFIL`, permitindo reuso por Home e Perfil sem acoplamento entre modulos.

## Camada UI (Barrel Files / `index.dart`)

- **Localizacao:** `lib/ui/auth/widgets/pages/profile_screen/index.dart` (**novo arquivo**)
- **`typedef` exportado:** `typedef ProfileScreen = ProfileScreenView`
- **Widgets internos exportados:** nao aplicavel

- **Localizacao:** `lib/ui/auth/widgets/pages/profile_screen/profile_account_card/index.dart` (**novo arquivo**)
- **`typedef` exportado:** `typedef ProfileAccountCard = ProfileAccountCardView`
- **Widgets internos exportados:** nao aplicavel

- **Localizacao:** `lib/ui/auth/widgets/pages/profile_screen/profile_settings_group/index.dart` (**novo arquivo**)
- **`typedef` exportado:** `typedef ProfileSettingsGroup = ProfileSettingsGroupView`
- **Widgets internos exportados:** nao aplicavel

- **Localizacao:** `lib/ui/auth/widgets/pages/profile_screen/profile_logout_button/index.dart` (**novo arquivo**)
- **`typedef` exportado:** `typedef ProfileLogoutButton = ProfileLogoutButtonView`
- **Widgets internos exportados:** nao aplicavel

- **Localizacao:** `lib/ui/shared/widgets/components/app_bottom_navigation/index.dart` (**novo arquivo**)
- **`typedef` exportado:** `typedef AppBottomNavigation = AppBottomNavigationView`
- **Widgets internos exportados:** nao aplicavel

## Camada UI (Providers Riverpod - se isolados)

- **Localizacao:** `lib/ui/auth/widgets/pages/profile_screen/profile_screen_presenter.dart` (**novo arquivo**)
- **Nome do provider:** `profileScreenPresenterProvider`
- **Tipo:** `Provider.autoDispose<ProfileScreenPresenter>`
- **Dependencias:** `ref.watch(authServiceProvider)`, `ref.watch(cacheDriverProvider)`, `ref.watch(navigationDriverProvider)`

- **Localizacao:** `lib/ui/auth/widgets/pages/profile_screen/profile_screen_presenter.dart` (**novo arquivo**)
- **Nome do provider:** `profileScreenInitializationProvider`
- **Tipo:** `Provider.autoDispose<void>`
- **Dependencias:** `ref.watch(profileScreenPresenterProvider)`

## Rotas (`go_router`) - se aplicavel

- **Localizacao:** `lib/router.dart`
- **Caminho da rota:** `Routes.profile`
- **Widget principal:** `ProfileScreen`
- **Guards / redirecionamentos:** sem query params obrigatorios; a validacao de sessao continua no presenter via `CacheDriver`.

## Estrutura de Pastas

```text
lib/ui/auth/widgets/pages/profile_screen/
  index.dart
  profile_screen_view.dart
  profile_screen_presenter.dart
  profile_account_card/
    index.dart
    profile_account_card_view.dart
  profile_settings_group/
    index.dart
    profile_settings_group_view.dart
  profile_logout_button/
    index.dart
    profile_logout_button_view.dart

lib/ui/shared/widgets/components/app_bottom_navigation/
  index.dart
  app_bottom_navigation_view.dart
```

---

# 6. O que deve ser modificado?

## Camada UI

- **Arquivo:** `lib/ui/intake/widgets/pages/home_screen/home_screen_presenter.dart`
- **Mudanca:** atualizar `onDestinationSelected(int index)` para respeitar a nova ordem da bottom navigation, navegando para `Routes.profile` quando `index == 2` e mantendo `index == 1` sem implementacao funcional.
- **Justificativa:** a Home ja expoe `PERFIL` na tab bar, mas hoje o toque nao faz nada; a navegacao precisa ser ativada para abrir a nova tela.

- **Arquivo:** `lib/ui/intake/widgets/pages/home_screen/home_screen_view.dart`
- **Mudanca:** substituir o consumo do widget local `HomeBottomNavigation` pelo widget compartilhado `AppBottomNavigation`, mantendo `currentIndex: 0`.
- **Justificativa:** a bottom navigation passa a ser compartilhada entre Home e Perfil, deixando de pertencer apenas ao modulo `intake`.

- **Arquivo:** `lib/ui/intake/widgets/pages/home_screen/home_header/home_header_view.dart`
- **Mudanca:** tornar o avatar do header clicavel e despachar a navegacao para `Routes.profile` via presenter da Home.
- **Justificativa:** a Home passa a oferecer um atalho visual adicional para a tela de Perfil.

## App / Router

- **Arquivo:** `lib/router.dart`
- **Mudanca:** adicionar import de `ProfileScreen` e registrar `GoRoute(path: Routes.profile, builder: ...)`.
- **Justificativa:** a constante `Routes.profile` ja existe, mas a rota ainda nao esta acessivel no app.

> Nao ha alteracoes necessarias em `core`, `rest` ou `drivers` para este recorte.

---

# 7. O que deve ser removido?

## Camada UI

- **Arquivo:** `lib/ui/intake/widgets/pages/home_screen/home_bottom_navigation/index.dart`
- **Motivo da remocao:** o barrel local deixa de ser necessario apos a extracao da bottom navigation para `lib/ui/shared/widgets/components/app_bottom_navigation/`.
- **Impacto esperado:** imports da Home devem apontar para o novo widget compartilhado.

- **Arquivo:** `lib/ui/intake/widgets/pages/home_screen/home_bottom_navigation/home_bottom_navigation_view.dart`
- **Motivo da remocao:** a implementacao deixa de ser exclusiva da Home e passa a morar em `ui/shared`.
- **Impacto esperado:** Home e Perfil passam a consumir a mesma fonte de verdade para a tab bar.

---

# 8. Decisoes Tecnicas e Trade-offs

## 8.1 Limitar `ANI-43` a tela read-only e navegacao

- **Decisao:** implementar apenas a tela de perfil read-only e a navegacao entre Home e Perfil.
- **Alternativas consideradas:** cobrir todo o escopo do PRD (`editar nome`, `trocar senha`, `desativar conta`) na mesma spec.
- **Motivo da escolha:** o usuario confirmou explicitamente que o recorte da task e `so tela e navegacao`, e nao ha contratos backend publicados para os demais fluxos.
- **Impactos / trade-offs:** a tela de perfil nasce funcional apenas para leitura; sera necessaria uma spec complementar quando o backend de perfil existir.

## 8.2 Reutilizar `AuthService.fetchAccount()` sem criar estado global de conta

- **Decisao:** a tela de perfil faz sua propria chamada a `fetchAccount()` ao entrar na rota.
- **Alternativas consideradas:** compartilhar o estado da conta carregado na Home via provider global ou via `state.extra`/cache local.
- **Motivo da escolha:** a codebase atual nao possui store global de conta; refetch local mantem o recorte pequeno e reutiliza contrato ja implementado.
- **Impactos / trade-offs:** entrar no Perfil gera uma nova chamada de rede, mas evita introduzir sincronizacao adicional entre telas nesta sprint.

## 8.3 Extrair a bottom navigation para `ui/shared`

- **Decisao:** mover a tab bar de `home_bottom_navigation` para `lib/ui/shared/widgets/components/app_bottom_navigation/`.
- **Alternativas consideradas:** duplicar o widget na tela de perfil ou importar o widget de `intake` dentro de `auth`.
- **Motivo da escolha:** a navegacao `HOME | PERFIL | BIBLIOTECA` e um elemento de shell do app, nao de um unico modulo; extrair evita acoplamento `auth -> intake` e duplicacao.
- **Impactos / trade-offs:** a task ganha uma pequena refatoracao de UI compartilhada, mas reduz a chance de divergencia visual entre abas.

## 8.4 Reproduzir o shell visual sem acoplar fluxos inexistentes

- **Decisao:** reproduzir o shell visual principal validado em `CHZUu`, mas manter as acoes de configuracao e o botao `Sair da Conta` como elementos visuais normais, sem fluxo.
- **Alternativas consideradas:** omitir completamente o grupo de configuracoes ou, no extremo oposto, implementar todos os taps sem contrato backend.
- **Motivo da escolha:** o design da tela ja esta definido e ajuda a estabilizar a hierarquia visual do Perfil; ao mesmo tempo, os fluxos ainda nao existem na codebase nem no backend.
- **Impactos / trade-offs:** a tela fica mais fiel ao layout aprovado, mas parte dos elementos permanecera apenas visual ate que haja novas tasks de comportamento.

---

# 9. Diagramas e Referencias

- **Fluxo de dados:**

```text
HomeScreenView
  -> HomeScreenPresenter.onDestinationSelected(2)
  -> NavigationDriver.goTo(Routes.profile)

ProfileScreenView
  -> profileScreenInitializationProvider
  -> ProfileScreenPresenter.initialize()
  -> CacheDriver.get(CacheKeys.accessToken)
  -> AuthService.fetchAccount()
  -> AuthRestService.fetchAccount()
  -> RestClient.get('/auth/account')
  -> API
```

- **Hierarquia de widgets (se aplicavel):**

```text
ProfileScreenView
  Scaffold
    bottomNavigationBar: AppBottomNavigation(currentIndex: 2)
    body: SafeArea
      Center
        ConstrainedBox
          Padding
            Column
              page header (`Perfil`)
              Loading | Error | ProfileAccountCard
              ProfileSettingsGroup
              ProfileLogoutButton
```

- **Referencias:**

`lib/core/auth/interfaces/auth_service.dart`

`lib/core/auth/dtos/account_dto.dart`

`lib/rest/services/auth_rest_service.dart`

`lib/rest/mappers/auth/account_mapper.dart`

`lib/ui/intake/widgets/pages/home_screen/home_screen_presenter.dart`

`lib/ui/intake/widgets/pages/home_screen/home_screen_view.dart`

`lib/ui/intake/widgets/pages/home_screen/home_bottom_navigation/home_bottom_navigation_view.dart`

`lib/ui/auth/widgets/components/auth_header/auth_header_view.dart`

`lib/ui/auth/widgets/pages/email_confirmation_screen/message_box/message_box_view.dart`

`design/animus.pen` - node `CHZUu` (`I - Configuracoes`)

`pubspec.yaml`

---

# 10. Pendencias / Duvidas

- **Descricao da pendencia:** o backend ainda nao expoe endpoints para editar nome, trocar senha com `senha atual` ou desativar conta.
- **Impacto na implementacao:** a tela de perfil desta spec precisa permanecer read-only; qualquer CTA de gestao de conta depende de novos contratos em `core`, `rest` e server.
- **Acao sugerida:** abrir tasks dedicadas de backend + mobile para os fluxos de perfil e produzir uma spec complementar quando os contratos estiverem publicados.

- **Descricao da pendencia:** o design `CHZUu` contem a linha `Numero de Precedentes`, mas nao existe fonte de dados nem contrato mobile/backend para alimenta-la.
- **Impacto na implementacao:** o item precisa ficar fora deste recorte para evitar valor fake ou regra arbitraria na UI.
- **Acao sugerida:** validar com produto/backend qual metrica deve ser exibida e em qual endpoint ela sera exposta.

- **Descricao da pendencia:** o node de design referencia `Configuracoes` como copy principal, mas a decisao aprovada para o recorte mobile foi padronizar a tela com o titulo `Perfil`.
- **Impacto na implementacao:** a hierarquia visual principal do layout permanece, mas a copy do header diverge do design source atual.
- **Acao sugerida:** refletir essa decisao no arquivo de design quando houver nova rodada de ajuste visual no Pencil.

- **Descricao da pendencia:** o MCP do Pencil nao conseguiu conectar ao app local; a validacao do design foi feita por fallback na leitura direta de `design/animus.pen`.
- **Impacto na implementacao:** a hierarquia estrutural foi confirmada, mas nao houve captura de screenshot para conferencia final de espacamento/renderizacao.
- **Acao sugerida:** se o app do Pencil estiver disponivel depois, rodar uma validacao visual final do node `CHZUu` antes da implementacao.

---

# Restricoes

- **Nao inclua testes automatizados na spec.**
- A `View` nao deve conter logica de negocio; toda orquestracao fica no `Presenter`.
- Presenters nao fazem chamadas diretas a `RestClient`; o Perfil continua consumindo apenas `AuthService`.
- Todos os caminhos citados existem no projeto **ou** estao explicitamente marcados como **novo arquivo**.
- Esta spec nao inventa endpoints, payloads ou contratos de backend para perfil alem do que ja existe em `GET /auth/account`.
- O layout usa o node `CHZUu` como referencia visual parcial; qualquer elemento sem contrato de dados ou fluxo disponivel deve permanecer apenas como shell visual ou ficar fora do recorte.
- Toda referencia a codigo existente inclui caminho relativo real (`lib/...`).
- Toda a navegacao nova continua baseada em `Routes`, `NavigationDriver` e `GoRouter`.
- A bottom navigation compartilhada deve continuar usando componentes Flutter Material alinhados ao tema do projeto.
