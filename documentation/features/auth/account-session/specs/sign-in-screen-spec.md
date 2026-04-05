---

## title: Sign In com E-mail e Senha
prd: [https://joaogoliveiragarcia.atlassian.net/wiki/spaces/anm/pages/16908291/PRD+RF+01+Gerenciamento+de+sess+o+do+usu+rio](https://joaogoliveiragarcia.atlassian.net/wiki/spaces/anm/pages/16908291/PRD+RF+01+Gerenciamento+de+sess+o+do+usu+rio)
ticket: [https://joaogoliveiragarcia.atlassian.net/browse/ANI-39](https://joaogoliveiragarcia.atlassian.net/browse/ANI-39)
status: closed
last_updated_at: 2026-03-26

# 1. Objetivo

Esta spec define a implementacao da tela de `sign in` do `animus` para autenticacao via e-mail e senha, seguindo o layout do Pencil (`design/animus.pen`, node `GcF5c`) e os padroes ja adotados no fluxo de `sign up`: `MVP`, `Riverpod`, `signals`, `reactive_forms`, `AuthService` no `core`, implementacao HTTP na camada `rest` e persistencia de tokens via `CacheDriver`. A entrega cobre o formulario de login, tratamento de erro por `statusCode`, persistencia da sessao local e navegacao entre telas de autenticacao; o fluxo OAuth do Google fica explicitamente fora do escopo desta spec.

---

# 2. Escopo

## 2.1 In-scope

- Criar a tela `sign_in_screen` em `lib/ui/auth/widgets/pages/sign_in_screen/` com layout baseado no Pencil `GcF5c`.
- Exibir formulario com `email` e `password`, toggle de visibilidade da senha, CTA principal de login, divisor `ou`, botao visual de Google e link para cadastro.
- Implementar `AuthService.signIn(...)` e sua implementacao em `AuthRestService` com `POST /auth/sign-in`.
- Persistir `accessToken.value` e `refreshToken.value` em cache usando `CacheDriver` + `CacheKeys` apos login bem-sucedido.
- Exibir mensagem generica para `401` e tratar `403` como conta nao verificada, com reenvio automatico do OTP e redirecionamento para confirmacao de e-mail.
- Adicionar rota explicita para `Routes.signIn` e ligar a navegacao `Sign Up -> Sign In`.

## 2.2 Out-of-scope

- Implementacao do fluxo OAuth do Google (`ANI-41`); nesta spec o botao Google sera apenas visual.
- Implementacao funcional de `forgot password` (`ANI-42`); o link pode ser renderizado como CTA visual sem navegacao.
- Implementacao da tela Home (`RF 05`) ou de um auth guard global completo.
- Logout, refresh token automatico, expiracao de sessao e edicao de perfil.
- Alteracoes no backend alem do contrato ja esperado para `POST /auth/sign-in`.

---

# 3. Requisitos

## 3.1 Funcionais

- O usuario deve conseguir informar `email` e `password` na tela de login.
- O campo de senha deve permitir alternar entre texto oculto e visivel.
- Ao submeter com formulario valido, o app deve chamar `POST /auth/sign-in` com payload `{ "email", "password" }`.
- Em `200`, o app deve mapear a resposta para `SessionDto`, persistir `accessToken.value` e `refreshToken.value` separadamente via `CacheDriver.set(...)` e entao navegar para `Routes.home`.
- Em `401`, o app deve exibir a mensagem generica `E-mail ou senha incorretos.` em feedback geral, sem indicar qual campo falhou.
- Em `403`, o app deve assumir o caso de conta nao verificada, acionar automaticamente `AuthService.resendVerificationEmail(...)` com o e-mail informado e redirecionar para `Routes.getEmailConfirmation(email: email)`.
- O CTA principal deve ficar desabilitado e com feedback visual de carregamento enquanto a requisicao estiver em voo.
- A tela deve exibir o botao `Continuar com Google` e o link `Nao tem conta? Criar conta`, mas apenas o link para cadastro tera comportamento funcional nesta spec.

## 3.2 Nao funcionais

- **Performance:** permitir apenas uma requisicao de login em voo por vez.
- **Acessibilidade:** labels, placeholders e mensagens de erro devem ser textuais; o estado do botao desabilitado nao pode depender apenas de cor.
- **Offline/Conectividade:** falhas de rede no `signIn` ou no reenvio automatico do OTP nao podem limpar o formulario; quando o reenvio automatico falhar, o app ainda deve navegar para a tela de confirmacao com o e-mail informado para permitir novo disparo manual.
- **Seguranca:** `password` nao deve ser persistida em cache nem circular fora do presenter/service; somente os valores dos tokens devem ser gravados em `CacheDriver`.
- **Compatibilidade:** a integracao deve continuar usando `Env.animusServerAppUrl`, `shared_preferences`, `Riverpod` e `signals` ja presentes no projeto; a UI deve navegar via contrato `NavigationDriver` implementado por `GoRouter`.

---

# 4. O que ja existe?

## Camada Core

- `**AuthService`** (`lib/core/auth/interfaces/auth_service.dart`) — contrato de autenticacao ja cobre `signUp`, `verifyEmail` e `resendVerificationEmail`, mas ainda nao possui `signIn`.
- `**SessionDto**` (`lib/core/auth/dtos/session_dto.dart`) — DTO de sessao pronto para representar o retorno do login.
- `**TokenDto**` (`lib/core/auth/dtos/token_dto.dart`) — DTO reutilizado por `SessionDto` para `accessToken` e `refreshToken`.
- `**CacheDriver**` (`lib/core/shared/interfaces/cache_driver.dart`) — contrato string-based ja usado no fluxo de confirmacao de e-mail.
- `**RestResponse**` (`lib/core/shared/responses/rest_response.dart`) — wrapper ja preparado para propagar `statusCode`, `errorMessage` e `errorBody` ate a UI.

## Camada REST

- `**AuthRestService**` (`lib/rest/services/auth_rest_service.dart`) — implementacao atual do `AuthService`; sera estendida com `signIn(...)`.
- `**SessionMapper**` (`lib/rest/mappers/auth/session_mapper.dart`) — mapper ja pronto para converter `access_token` e `refresh_token` em `SessionDto`.
- `**DioRestClient**` (`lib/rest/dio/dio_rest_client.dart`) — cliente HTTP concreto que ja encapsula `Dio` e devolve `RestResponse<Json>`.
- `**authServiceProvider**` (`lib/rest/services/index.dart`) — provider Riverpod ja usado para compor presenters de auth.

## Camada Drivers

- `**SharedPreferencesCacheDriver**` (`lib/drivers/caches/shared_preferences/shared_preferences_cache_driver.dart`) — implementacao concreta de `CacheDriver` ja usada por `email_confirmation_screen`.
- `**GoRouterNavigationDriver**` (`lib/drivers/navigation/go_router/go_router_navigation_driver.dart`) — implementacao concreta de `NavigationDriver` usada para padronizar navegacao da UI.
- `**CacheKeys**` (`lib/constants/cache_keys.dart`) — chaves reais de persistencia para `accessToken` e `refreshToken`.

## Camada UI

- `**SignUpScreenPresenter**` (`lib/ui/auth/widgets/pages/sign_up_screen/sign_up_screen_presenter.dart`) — referencia direta de form reativo com `signals`, `reactive_forms`, chamada a `AuthService` e navegacao via `NavigationDriver`.
- `**SignUpFormPresenter**` (`lib/ui/auth/widgets/pages/sign_up_screen/sign_up_form/sign_up_form_presenter.dart`) — referencia de presenter interno que delega estado e acoes ao presenter de tela.
- `**BrandHeaderView**` (`lib/ui/auth/widgets/pages/sign_up_screen/brand_header/brand_header_view.dart`) — componente visual ja aderente ao branding do Pencil; pode ser reutilizado no `sign_in_screen`.
- `**SignInHintView**` (`lib/ui/auth/widgets/pages/sign_up_screen/sign_up_form/sign_in_hint/sign_in_hint_view.dart`) — CTA textual entre telas de autenticacao, ja navegando para `Routes.signIn`.
- `**EmailConfirmationScreenPresenter**` (`lib/ui/auth/widgets/pages/email_confirmation_screen/email_confirmation_screen_presenter.dart`) — referencia concreta de persistencia de sessao via `CacheDriver` injetado por provider.

## App / Router

- `**Routes**` (`lib/constants/routes.dart`) — possui `Routes.signIn`, `Routes.signUp` e `Routes.home` como pontos de entrada do fluxo de autenticacao.
- `**appRouter**` (`lib/router.dart`) — inicia em `Routes.signIn` e ja registra `signIn`, `signUp` e `emailConfirmation`.

## Design / Referencia visual

- `**A - Login**` (`design/animus.pen`, node `GcF5c`) — hierarquia visual da tela, incluindo `Toast Error`, formulario, CTA principal, divisor, botao Google e footer com link de cadastro.

---

# 5. O que deve ser criado?

## Camada UI (Presenters)

- **Localizacao:** `lib/ui/auth/widgets/pages/sign_in_screen/sign_in_screen_presenter.dart` (**novo arquivo**)
- **Dependencias injetadas:** `AuthService`, `CacheDriver`, `NavigationDriver`
- **Estado (`signals`):**
  - Signals simples: `signal<String?> generalError`, `signal<bool> isSubmitting`, `signal<bool> isPasswordVisible`
  - Signals derivados: `computed<bool> canSubmit` — verdadeiro quando o formulario esta valido e `isSubmitting == false`
  - Formulario: `FormGroup form` com controles `email` e `password`
- **Provider Riverpod:** `signInScreenPresenterProvider`
- **Metodos:**
  - `FormControl<String> get emailControl` — expoe o controle tipado de e-mail.
  - `FormControl<String> get passwordControl` — expoe o controle tipado de senha.
  - `void togglePasswordVisibility()` — alterna a visibilidade do campo `password`.
  - `void applyStatusCodeError(RestResponse<dynamic> response)` — traduz `401` e falhas genericas para `generalError`.
  - `Future<void> handleUnverifiedAccount()` — dispara `AuthService.resendVerificationEmail(email: ...)` sem bloquear o fluxo caso o reenvio automatico falhe.
  - `Future<void> submit()` — valida o formulario, chama `AuthService.signIn`, persiste os tokens via `CacheDriver`, navega para `Routes.home` em sucesso, redireciona para confirmacao em `403` e atualiza `generalError` nas demais falhas.
  - `void goToSignUp()` — navega para `Routes.signUp` a partir do footer da tela.
- **Localizacao:** `lib/ui/auth/widgets/pages/sign_in_screen/sign_in_form/sign_in_form_presenter.dart` (**novo arquivo**)
- **Dependencias injetadas:** `SignInScreenPresenter`
- **Estado (`signals`):** proxys dos sinais do presenter de tela (`generalError`, `isSubmitting`, `isPasswordVisible`, `canSubmit`)
- **Provider Riverpod:** `signInFormPresenterProvider`
- **Metodos:**
  - `Future<void> submit()` — delega para `SignInScreenPresenter.submit`.
  - `void togglePasswordVisibility()` — delega para `SignInScreenPresenter.togglePasswordVisibility`.
  - `void goToSignUp()` — delega para `SignInScreenPresenter.goToSignUp`.
  - Getters de `validationMessages` para `email` e `password` — concentram as mensagens consumidas pela View.

## Camada UI (Views)

- **Localizacao:** `lib/ui/auth/widgets/pages/sign_in_screen/sign_in_screen_view.dart` (**novo arquivo**)
- **Base class:** `StatelessWidget`
- **Props:** nenhuma
- **Bibliotecas de UI:** `flutter/material.dart`
- **Estados visuais:**
  - `Content` — tela principal com `BrandHeader`, titulo, formulario e footer.
  - `Error` — feedback geral renderizado dentro do formulario quando `generalError` estiver preenchido.
- **Localizacao:** `lib/ui/auth/widgets/pages/sign_in_screen/sign_in_form/sign_in_form_view.dart` (**novo arquivo**)
- **Base class:** `ConsumerWidget`
- **Props:** nenhuma
- **Bibliotecas de UI:** `flutter_riverpod`, `signals_flutter`, `reactive_forms`
- **Estados visuais:**
  - `Loading` — botao `Entrar` desabilitado e com label de progresso.
  - `Content` — campos, link visual de esqueci a senha, divisoria, botao Google visual e hint de cadastro.
  - `Error` — alerta textual geral acima do CTA principal.

## Camada UI (Widgets Internos)

- **Localizacao:** `lib/ui/auth/widgets/components/auth_header/` (**novo arquivo** em pasta nova)
- **Tipo:** View only (componente compartilhado da modulo `auth`)
- **Arquivos:** `index.dart`, `auth_header_view.dart`
- **Props:** `required String title`, `required String subtitle`
- **Responsabilidade:** renderizar o cabecalho textual de autenticacao e permitir reuso entre `sign_in_screen` e `sign_up_screen`, conforme o Pencil.
- **Localizacao:** `lib/ui/auth/widgets/pages/sign_in_screen/sign_in_form/general_error_alert/` (**novo arquivo** em pasta nova)
- **Tipo:** View only
- **Arquivos:** `index.dart`, `general_error_alert_view.dart`
- **Props:** `String? message`
- **Responsabilidade:** exibir o feedback textual de erro geral para `401` e falhas genericas de rede/servidor.
- **Localizacao:** `lib/ui/auth/widgets/pages/sign_in_screen/sign_in_form/sign_in_submit_button/` (**novo arquivo** em pasta nova)
- **Tipo:** View only
- **Arquivos:** `index.dart`, `sign_in_submit_button_view.dart`
- **Props:** `required bool isSubmitting`, `required bool enabled`, `required VoidCallback? onPressed`
- **Responsabilidade:** renderizar o CTA principal `Entrar` com estados de loading e disabled.
- **Localizacao:** `lib/ui/auth/widgets/pages/sign_in_screen/sign_in_form/or_divider/` (**novo arquivo** em pasta nova)
- **Tipo:** View only
- **Arquivos:** `index.dart`, `or_divider_view.dart`
- **Responsabilidade:** renderizar a divisoria horizontal com o texto `ou`.
- **Localizacao:** `lib/ui/auth/widgets/pages/sign_in_screen/sign_in_form/google_sign_in_button/` (**novo arquivo** em pasta nova)
- **Tipo:** View only
- **Arquivos:** `index.dart`, `google_sign_in_button_view.dart`
- **Props:** `required bool enabled`
- **Responsabilidade:** renderizar o botao `Continuar com Google` no visual do Pencil; nesta spec o botao permanece desabilitado ou sem handler funcional, deixando a dependencia explicita de `ANI-41`.
- **Localizacao:** `lib/ui/auth/widgets/pages/sign_in_screen/sign_in_form/sign_up_hint/` (**novo arquivo** em pasta nova)
- **Tipo:** View only
- **Arquivos:** `index.dart`, `sign_up_hint_view.dart`
- **Props:** `required VoidCallback onTap`
- **Responsabilidade:** renderizar o footer `Nao tem conta? Criar conta` e encaminhar o clique para `Routes.signUp`.
- **Localizacao:** `lib/ui/auth/widgets/pages/sign_in_screen/sign_in_form/forgot_password_hint/` (**novo arquivo** em pasta nova)
- **Tipo:** View only
- **Arquivos:** `index.dart`, `forgot_password_hint_view.dart`
- **Responsabilidade:** renderizar o CTA visual `Esqueceu a senha?` conforme o Pencil, sem navegacao funcional nesta spec.

## Camada UI (Barrel Files / `index.dart`)

- **Localizacao:** `lib/ui/auth/widgets/pages/sign_in_screen/index.dart` (**novo arquivo**)
- `**typedef` exportado:** `typedef SignInScreen = SignInScreenView`
- **Widgets internos exportados:** Não aplicável
- **Localizacao:** `lib/ui/auth/widgets/pages/sign_in_screen/sign_in_form/index.dart` (**novo arquivo**)
- `**typedef` exportado:** `typedef SignInForm = SignInFormView`
- **Widgets internos exportados:** `GeneralErrorAlert`, `SignInSubmitButton`, `OrDivider`, `GoogleSignInButton`, `SignUpHint`, `ForgotPasswordHint`

## Camada UI (Providers Riverpod — se isolados)

- **Localizacao:** `lib/ui/auth/widgets/pages/sign_in_screen/sign_in_screen_presenter.dart` (**novo arquivo**)
- **Nome do provider:** `signInScreenPresenterProvider`
- **Tipo:** `Provider.autoDispose<SignInScreenPresenter>`
- **Dependencias:** `ref.watch(authServiceProvider)`, `ref.watch(cacheDriverProvider)`, `ref.watch(navigationDriverProvider)`
- **Localizacao:** `lib/ui/auth/widgets/pages/sign_in_screen/sign_in_form/sign_in_form_presenter.dart` (**novo arquivo**)
- **Nome do provider:** `signInFormPresenterProvider`
- **Tipo:** `Provider.autoDispose<SignInFormPresenter>`
- **Dependencias:** `ref.watch(signInScreenPresenterProvider)`

## Rotas (`go_router`)

- **Localizacao:** `lib/router.dart`
- **Caminho da rota:** `Routes.signIn`
- **Widget principal:** `SignInScreen`
- **Guards / redirecionamentos:** Não aplicável nesta rota; a decisao de auth guard para `Routes.home` fica fora do escopo desta spec.

## Estrutura de Pastas

```text
lib/ui/auth/widgets/components/auth_header/
  index.dart
  auth_header_view.dart

lib/ui/auth/widgets/pages/sign_in_screen/
  index.dart
  sign_in_screen_view.dart
  sign_in_screen_presenter.dart
  sign_in_form/
    index.dart
    sign_in_form_view.dart
    sign_in_form_presenter.dart
    forgot_password_hint/
      index.dart
      forgot_password_hint_view.dart
    general_error_alert/
      index.dart
      general_error_alert_view.dart
    google_sign_in_button/
      index.dart
      google_sign_in_button_view.dart
    or_divider/
      index.dart
      or_divider_view.dart
    sign_in_submit_button/
      index.dart
      sign_in_submit_button_view.dart
    sign_up_hint/
      index.dart
      sign_up_hint_view.dart
```

---

# 6. O que deve ser modificado?

## Camada Core

- **Arquivo:** `lib/core/auth/interfaces/auth_service.dart`
- **Mudanca:** adicionar `Future<RestResponse<SessionDto>> signIn({required String email, required String password})`.
- **Justificativa:** a UI de login precisa consumir o contrato de autenticacao sem acessar `RestClient` diretamente.

## Camada REST

- **Arquivo:** `lib/rest/services/auth_rest_service.dart`
- **Mudanca:** implementar `signIn(...)` com `POST /auth/sign-in`, payload inline `{ "email", "password" }` e retorno `response.mapBody<SessionDto>(SessionMapper.toDto)`.
- **Justificativa:** concentrar o endpoint de login na mesma implementacao REST de auth ja existente.
- **Arquivo:** `lib/rest/services/index.dart`
- **Mudanca:** manter `authServiceProvider` como fronteira publica, sem alterar a forma de injecao; apenas garantir que a instancia entregue suporte o novo metodo `signIn(...)`.
- **Justificativa:** preservar o padrao de composicao usado pelos presenters de auth.

## Camada UI

- **Arquivo:** `lib/router.dart`
- **Mudanca:** registrar `GoRoute(path: Routes.signIn, builder: ...)` e atualizar `initialLocation` para `Routes.signIn`.
- **Justificativa:** o app passa a ter tela dedicada de login e deve entrar por ela no bootstrap atual de autenticacao.
- **Arquivo:** `lib/ui/auth/widgets/pages/sign_up_screen/sign_up_form/sign_in_hint/sign_in_hint_view.dart`
- **Mudanca:** transformar `Entrar` em CTA clicavel que navega para `Routes.signIn`.
- **Justificativa:** garantir fluxo bidirecional entre cadastro e login, alinhado ao ticket `ANI-39`.
- **Arquivo:** `lib/ui/auth/widgets/pages/sign_up_screen/sign_up_form/sign_up_form_view.dart`
- **Mudanca:** manter o hint de `Entrar`, agora funcional, sem alterar a estrutura do formulario de cadastro.
- **Justificativa:** o `sign up` ja contem o ponto de entrada visual para login; so falta ligar a acao.

## Camada Drivers

- **Arquivo:** `lib/drivers/caches/shared_preferences/shared_preferences_cache_driver.dart`
- **Mudanca:** remover `CacheDriverFactory` e `cacheDriverFactoryProvider`, expondo `sharedPreferencesProvider` e `cacheDriverProvider` para injecao direta de `CacheDriver`.
- **Justificativa:** eliminar factory assicrona no presenter e centralizar inicializacao concreta no bootstrap da app.
- **Arquivo:** `lib/drivers/cache/index.dart`
- **Mudanca:** exportar os providers e o driver concreto de cache por um ponto unico de entrada para imports da UI.
- **Justificativa:** padronizar o acesso aos drivers por `index.dart`, reduzindo acoplamento ao path concreto de implementacao.

## App / Rotas

- **Arquivo:** `lib/constants/routes.dart`
- **Mudanca:** manter `Routes.signIn` como fonte unica de verdade; nao criar novas constantes para o mesmo caminho.
- **Justificativa:** a constante ja existe e evita duplicacao desnecessaria.
- **Arquivo:** `lib/main.dart`
- **Mudanca:** inicializar `SharedPreferences` no bootstrap e sobrescrever `sharedPreferencesProvider` dentro do `ProviderScope`.
- **Justificativa:** garantir que o driver de cache receba dependencia concreta na inicializacao da aplicacao, sem acesso direto a plugin dentro dos presenters.

---

# 7. O que deve ser removido?

**Não aplicável**.

---

# 8. Decisoes Tecnicas e Trade-offs

## 8.1 Reutilizar a mesma stack de formulario do `sign up`

- **Decisao:** implementar o login com `reactive_forms`, `signals` e `Riverpod`, espelhando o padrao de `sign_up_screen`.
- **Alternativas consideradas:** usar `TextEditingController`; implementar presenter sem `FormGroup`.
- **Motivo da escolha:** a codebase ja consolidou esse padrao no modulo `auth`, reduzindo ambiguidade e custo cognitivo.
- **Impactos / trade-offs:** aumenta a consistencia entre telas de auth, mas mantem a dependencia de duas bibliotecas de estado/formulario no mesmo fluxo.

## 8.2 Limitar o escopo funcional ao login por e-mail e senha

- **Decisao:** renderizar o botao Google apenas como CTA visual e deixar a integracao funcional para `ANI-41`.
- **Alternativas consideradas:** inventar agora um contrato `GoogleAuthService`; acoplar a UI a um plugin externo inexistente na codebase.
- **Motivo da escolha:** nao ha evidencia atual de contrato, driver ou provider de Google auth no repositorio, e o proprio Jira separa esse fluxo em outra task.
- **Impactos / trade-offs:** a tela fica visualmente completa, mas o botao Google nao entrega comportamento real nesta etapa.

## 8.3 Tratar erros de login por `statusCode` e mensagem geral

- **Decisao:** usar `generalError` apenas para `401` e falhas genericas; em `403`, redirecionar o usuario para `email_confirmation_screen` apos tentar reenviar automaticamente o OTP.
- **Alternativas consideradas:** manter `403` como erro geral na tela de login; marcar campos com erro inline; exigir acao manual antes de navegar.
- **Motivo da escolha:** o fluxo de conta nao verificada ja existe na codebase com `email_confirmation_screen`, entao a melhor UX e levar o usuario diretamente para o passo correto em vez de apenas bloquea-lo na tela de login.
- **Impactos / trade-offs:** melhora a recuperacao do fluxo, mas acopla o significado de `403` ao caso de e-mail nao verificado nesta etapa.

## 8.4 Persistir apenas `TokenDto.value` no cache

- **Decisao:** salvar somente os valores de `accessToken.value` e `refreshToken.value` em `CacheDriver` usando `CacheKeys`.
- **Alternativas consideradas:** serializar `TokenDto` completo; criar DTO de sessao persistida.
- **Motivo da escolha:** o fluxo atual de `email_confirmation_screen` ja grava apenas as strings e o contrato `CacheDriver` e string-based.
- **Impactos / trade-offs:** mantem compatibilidade com o cache atual, mas nao persiste `expiresAt` para futuros guards de expiracao.

## 8.5 Aceitar a dependencia de `Routes.home` como integracao posterior

- **Decisao:** manter `Routes.home` como destino pos-login, mesmo sem tela Home implementada no bootstrap atual.
- **Alternativas consideradas:** inventar uma tela placeholder; redirecionar para outra rota sem evidencia no PRD.
- **Motivo da escolha:** `Routes.home` ja e o destino semantico correto para sessao autenticada e a home pertence a outro requisito (`RF 05`).
- **Impactos / trade-offs:** o presenter fica correto do ponto de vista contratual, mas a navegacao final depende de ajuste complementar no roteamento global.

---

# 9. Diagramas e Referencias

## Fluxo de dados

```text
SignInScreenView
      -> SignInFormView
          -> SignInFormPresenter.submit()
              -> SignInScreenPresenter.submit()
              -> AuthService.signIn(email, password)
                  -> AuthRestService.signIn(...)
                      -> RestClient.post('/auth/sign-in')
                      -> SessionMapper.toDto(...)
              -> [200] CacheDriver.set(CacheKeys.accessToken, session.accessToken.value)
              -> [200] CacheDriver.set(CacheKeys.refreshToken, session.refreshToken.value)
              -> [200] NavigationDriver.goTo(Routes.home)
              -> [403] AuthService.resendVerificationEmail(email)
              -> [403] NavigationDriver.goTo(Routes.getEmailConfirmation(email: email))
              -> [401/rede] generalError
```

## Hierarquia de widgets

```text
SignInScreenView
  Scaffold
    SafeArea
      Center
        SingleChildScrollView
          ConstrainedBox
            Container principal
              BrandHeaderView (reutilizado)
              AuthHeaderView
              SignInFormView
                EmailField
                PasswordField + eye toggle
                ForgotPasswordHintView
                GeneralErrorAlertView?
                SignInSubmitButtonView
                OrDividerView
                GoogleSignInButtonView
                SignUpHintView
```

## Referencias

- `lib/ui/auth/widgets/pages/sign_up_screen/sign_up_screen_presenter.dart` — referencia principal do padrao de presenter com `FormGroup`, `signals` e `AuthService`.
- `lib/ui/auth/widgets/pages/sign_up_screen/sign_up_form/sign_up_form_presenter.dart` — referencia de presenter interno delegado.
- `lib/ui/auth/widgets/pages/email_confirmation_screen/email_confirmation_screen_presenter.dart` — referencia de persistencia de sessao via `CacheDriver`.
- `lib/rest/services/auth_rest_service.dart` — implementacao REST que deve receber o novo metodo `signIn(...)`.
- `lib/rest/mappers/auth/session_mapper.dart` — referencia direta para mapear o sucesso de `POST /auth/sign-in`.
- `lib/drivers/caches/shared_preferences/shared_preferences_cache_driver.dart` — implementacao concreta de cache ja adotada pelo modulo.
- `lib/drivers/cache/index.dart` — entrypoint de export para consumo de `cacheDriverProvider` e `sharedPreferencesProvider`.
- `lib/drivers/navigation/go_router/go_router_navigation_driver.dart` — implementacao concreta de `NavigationDriver` para a camada UI.
- `lib/drivers/navigation/index.dart` — entrypoint de export para consumo do `navigationDriverProvider`.
- `lib/constants/routes.dart` e `lib/router.dart` — pontos de entrada para a nova rota de login.
- `lib/ui/auth/widgets/pages/sign_up_screen/brand_header/brand_header_view.dart` — componente visual reutilizavel para manter o branding entre telas de auth.
- `lib/ui/auth/widgets/components/auth_header/auth_header_view.dart` — componente visual compartilhado para titulo/subtitulo entre `sign_in_screen` e `sign_up_screen`.
- `design/animus.pen` (node `GcF5c`) — referencia visual da tela de login usada para validar hierarquia e estados principais.

---

# 10. Pendencias / Duvidas

- **Descricao da pendencia:** `Routes.home` pertence a outro ticket (`RF 05`), mas `lib/router.dart` ainda redireciona `/` para `Routes.signIn` no estado atual da codebase.
- **Impacto na implementacao:** a tela de login pode concluir autenticacao e persistencia de sessao corretamente, porem a validacao end-to-end do redirecionamento final depende da entrega da Home em sua task propria.
- **Acao sugerida:** manter `Routes.home` como destino contratual desta spec e tratar a integracao final do roteamento na task responsavel pela Home, evitando expandir o escopo de `ANI-39`.

- **Descricao da pendencia:** o redirecionamento automatico em `403` pressupoe que esse status represente especificamente conta nao verificada no `POST /auth/sign-in`.
- **Impacto na implementacao:** se o backend reutilizar `403` para outros bloqueios, o app pode mandar o usuario para a verificacao de e-mail em cenarios incorretos.
- **Acao sugerida:** validar com backend se `403` vira acompanhado de um identificador semantico no `errorBody` (ex: `code: unverified_account`) ou se o contrato garante exclusividade desse status para conta nao verificada.

---

# Restricoes

- **Nao inclua testes automatizados na spec.**
- A `View` nao deve conter logica de negocio; toda validacao, persistencia de tokens e navegacao fica no `Presenter`.
- Presenters nao fazem chamadas diretas a `RestClient`; consomem sempre `AuthService`.
- Todos os caminhos citados acima existem no projeto ou estao explicitamente marcados como **novo arquivo**.
- Esta spec nao inventa integracao funcional de Google auth nem de `forgot password`; ambas permanecem dependencias explicitas de `ANI-41` e `ANI-42`.
- Toda referencia a codigo existente usa caminho relativo real em `lib/...`.
- Toda widget com responsabilidade propria foi colocada em pasta propria com `index.dart`.
- A UI deve permanecer em Flutter Material e alinhada ao tema atual do projeto.
- A nomenclatura deve seguir a codebase: arquivos em `snake_case`, classes em `PascalCase`, providers e metodos em `camelCase`.
