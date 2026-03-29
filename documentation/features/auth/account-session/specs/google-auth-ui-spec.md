---
title: Google Auth em Sign In e Sign Up
prd: https://joaogoliveiragarcia.atlassian.net/wiki/spaces/anm/pages/16908291/PRD+RF+01+Gerenciamento+de+sess+o+do+usu+rio
ticket: https://joaogoliveiragarcia.atlassian.net/browse/ANI-41
status: closed
last_updated_at: 2026-03-29
---

# 1. Objetivo

Esta spec define a implementacao do login com Google no `animus`, conectando os CTAs de `Sign In` e `Sign Up` ao fluxo OAuth via `google_sign_in`, encapsulado em driver proprio, com envio do `idToken` para `POST /auth/sign-up/google`, persistencia de `accessToken` e `refreshToken` via `CacheDriver` e redirecionamento para `Routes.home`. A entrega tambem corrige a inconsistncia atual da UI de cadastro, que ainda nao renderiza o CTA de Google apesar de o ticket exigir o fluxo nas duas telas.

---

# 2. Escopo

## 2.1 In-scope

- Adicionar suporte funcional ao CTA `Continuar com Google` na tela `sign_in_screen`.
- Adicionar o CTA `Continuar com Google` na tela `sign_up_screen`, reutilizando o mesmo componente visual e o mesmo fluxo tecnico.
- Criar um contrato no `core` para isolamento do SDK Google e implementa-lo na camada `drivers`.
- Estender `AuthService` com um metodo especifico para login social via `idToken`.
- Implementar `POST /auth/sign-up/google` em `AuthRestService`, reaproveitando `SessionMapper`.
- Persistir a sessao com `CacheDriver` usando `CacheKeys.accessToken` e `CacheKeys.refreshToken`.
- Tratar cancelamento do fluxo Google sem erro visual e tratar falhas tecnicas/API com `generalError`.
- Ajustar configuracao minima do app para suportar `google_sign_in` no Flutter e registrar a configuracao nativa obrigatoria.

## 2.2 Out-of-scope

- Login com Apple, Facebook ou qualquer outro provider social.
- Edicao de perfil, vinculacao/desvinculacao manual de contas sociais ou exibicao de provedores conectados ao usuario.
- Refresh token automatico, logout global e auth guard de sessao.
- Qualquer alteracao no contrato do backend alem de `POST /auth/sign-up/google` ja citado no ticket.
- Implementacao de web ou macOS; o foco desta spec e mobile `Android` + `iOS`.
- Testes automatizados, analytics e telemetria do funil OAuth.

---

# 3. Requisitos

## 3.1 Funcionais

- O usuario deve conseguir tocar em `Continuar com Google` tanto em `Sign In` quanto em `Sign Up`.
- O app deve iniciar o fluxo OAuth do Google via SDK nativo encapsulado por driver.
- Quando o usuario concluir o fluxo Google com sucesso, o app deve obter um `idToken` valido e chamar `AuthService.signInWithGoogle(idToken: ...)`.
- O service REST deve enviar `{ "id_token": idToken }` para `POST /auth/sign-up/google`.
- Em sucesso remoto, o app deve mapear a resposta para `SessionDto`, persistir `accessToken.value` e `refreshToken.value` via `CacheDriver` e navegar para `Routes.home`.
- Se o usuario cancelar o seletor/consentimento do Google, o app deve encerrar o fluxo silenciosamente, sem `generalError` e sem navegar.
- Se o SDK Google falhar antes da chamada ao backend, o presenter deve exibir mensagem generica em `generalError` e manter a tela atual.
- Se a API retornar falha, o presenter deve exibir feedback geral reutilizando o mesmo padrao de erro textual ja usado nos fluxos atuais de auth.
- O CTA principal do formulario e o CTA Google nao devem disparar requisicoes concorrentes no mesmo presenter.

## 3.2 Nao funcionais

- **Performance:** cada tela deve permitir no maximo um fluxo de autenticacao remoto por vez (`credentials` ou `google`).
- **Acessibilidade:** o CTA Google deve manter label textual visivel e estado de loading/desabilitado nao pode depender apenas da cor.
- **Offline/Conectividade:** falhas do SDK ou do backend nao podem limpar os campos do formulario ja digitados; o usuario deve poder tentar novamente sem perder estado local.
- **Seguranca:** o `idToken` do Google nao deve ser persistido em cache nem armazenado em `Signal` duravel; apenas `accessToken` e `refreshToken` devem ser gravados via `CacheDriver`.
- **Compatibilidade:** a implementacao deve respeitar a arquitetura em camadas do projeto, usando `AuthService` + `GoogleAuthDriver` em vez de importar `google_sign_in` diretamente na UI.
- **Compatibilidade:** a feature depende de configuracao OAuth valida para `Android` e `iOS`; sem `clientId`/`serverClientId` e URL scheme corretos, o fluxo nao deve ser considerado pronto para validacao manual.

---

# 4. O que ja existe?

## Camada Core

- **`AuthService`** (`lib/core/auth/interfaces/auth_service.dart`) - contrato atual de auth ja concentra `signIn`, `signUp`, `verifyEmail` e `resendVerificationEmail`; sera estendido com o fluxo Google.
- **`SessionDto`** (`lib/core/auth/dtos/session_dto.dart`) - DTO de sessao ja usado em `signIn` e `verifyEmail`, adequado para o retorno do endpoint Google.
- **`TokenDto`** (`lib/core/auth/dtos/token_dto.dart`) - DTO reutilizado por `SessionDto` para `accessToken` e `refreshToken`.
- **`CacheDriver`** (`lib/core/shared/interfaces/cache_driver.dart`) - contrato string-based ja usado para persistencia de sessao no modulo de auth.
- **`NavigationDriver`** (`lib/core/shared/interfaces/navigation_driver.dart`) - contrato de navegacao usado pelos presenters de auth.
- **`RestResponse`** (`lib/core/shared/responses/rest_response.dart`) - wrapper tipado que ja preserva `statusCode`, `errorMessage` e `errorBody`.

## Camada REST

- **`AuthRestService`** (`lib/rest/services/auth_rest_service.dart`) - implementacao concreta de `AuthService`; hoje nao contem metodo para login social.
- **`SessionMapper`** (`lib/rest/mappers/auth/session_mapper.dart`) - mapper ja pronto para converter `access_token` e `refresh_token` em `SessionDto`.
- **`authServiceProvider`** (`lib/rest/services/index.dart`) - fronteira publica de injecao de `AuthService` consumida pela UI.
- **`DioRestClient`** (`lib/rest/dio/dio_rest_client.dart`) - cliente HTTP concreto que ja centraliza `baseUrl`, parse de erro e `RestResponse<Json>`.

## Camada Drivers

- **`SharedPreferencesCacheDriver`** (`lib/drivers/caches/shared_preferences/shared_preferences_cache_driver.dart`) - implementacao concreta de `CacheDriver` usada para salvar tokens.
- **`GoRouterNavigationDriver`** (`lib/drivers/navigation/go_router/go_router_navigation_driver.dart`) - implementacao concreta de `NavigationDriver` ja usada pelos presenters atuais.
- **Estado atual:** o driver de Google auth ja existe em `lib/drivers/google-auth-driver/` e a dependencia `google_sign_in` ja esta declarada no `pubspec.yaml`.

## Camada UI

- **`SignInScreenPresenter`** (`lib/ui/auth/widgets/pages/sign_in_screen/sign_in_screen_presenter.dart`) - ja executa auth por e-mail/senha, persiste tokens e navega para `Routes.home`; sera referencia direta do fluxo Google.
- **`SignInFormPresenter`** (`lib/ui/auth/widgets/pages/sign_in_screen/sign_in_form/sign_in_form_presenter.dart`) - proxy do presenter de tela para o formulario de login.
- **`SignInFormView`** (`lib/ui/auth/widgets/pages/sign_in_screen/sign_in_form/sign_in_form_view.dart`) - ja renderiza um CTA visual de Google, atualmente desabilitado (`enabled: false`).
- **`GoogleSignInButtonView`** (`lib/ui/auth/widgets/pages/sign_in_screen/sign_in_form/google_sign_in_button/google_sign_in_button_view.dart`) - implementacao visual atual do botao Google, mas acoplada ao fluxo de `sign_in` e sem handler funcional.
- **`SignUpScreenPresenter`** (`lib/ui/auth/widgets/pages/sign_up_screen/sign_up_screen_presenter.dart`) - ja orquestra cadastro por e-mail/senha e navegacao para confirmacao de e-mail.
- **`SignUpFormView`** (`lib/ui/auth/widgets/pages/sign_up_screen/sign_up_form/sign_up_form_view.dart`) - formulario atual de cadastro; ainda nao contem divisor `ou` nem CTA Google.
- **`AuthHeaderView`** (`lib/ui/auth/widgets/components/auth_header/auth_header_view.dart`) e **`BrandHeaderView`** (`lib/ui/auth/widgets/pages/sign_up_screen/brand_header/brand_header_view.dart`) - referencias visuais que devem ser preservadas.

## App / Configuracao

- **`Routes`** (`lib/constants/routes.dart`) - ja expoe `Routes.home`, `Routes.signIn`, `Routes.signUp` e `Routes.getEmailConfirmation(...)`; nao requer nova rota para esta feature.
- **`appRouter`** (`lib/router.dart`) - fluxo atual de auth ja entra por `Routes.signIn`.
- **`Env`** (`lib/constants/env.dart`) e **`.env.example`** (`.env.example`) - ja expoem `ANIMUS_SERVER_APP_URL`, `ANIMUS_GOOGLE_IOS_CLIENT_ID` e `ANIMUS_GOOGLE_SERVER_CLIENT_ID`, todos carregados via `flutter_dotenv`.
- **`pubspec.yaml`** (`pubspec.yaml`) - ja declara `google_sign_in`.
- **`ios/Runner/Info.plist`** (`ios/Runner/Info.plist`) - ja contem `CFBundleURLTypes`; o URL scheme do callback deve permanecer alinhado ao `reversed client id` configurado via build setting.
- **`android/app/build.gradle.kts`** (`android/app/build.gradle.kts`) - esta implementacao usa `applicationId = "br.com.animus.app"`, alinhando a identidade do app ao registro OAuth.

---

# 5. O que deve ser criado?

## Camada Core (Interfaces / Contratos)

- **Localizacao:** `lib/core/auth/interfaces/google_auth_driver.dart` (**novo arquivo**)
- **Metodo:** `Future<String?> requestIdToken()` - inicializa o SDK quando necessario, abre o fluxo Google e retorna o `idToken`; retorna `null` quando o usuario cancelar.

## Camada Drivers (Adaptadores)

- **Localizacao:** `lib/drivers/google-auth-driver/google_sign_in/google_sign_in_google_auth_driver.dart` (**novo arquivo**)
- **Interface implementada:** `GoogleAuthDriver`
- **Biblioteca/pacote utilizado:** `google_sign_in`
- **Dependencias:** configuracao de `clientId`/`serverClientId` e instancia do SDK `GoogleSignIn.instance`
- **Metodo:** `Future<String?> requestIdToken()` - executa `initialize(...)`, dispara `authenticate()`/fluxo equivalente do pacote, resolve o `idToken` da autenticacao e normaliza cancelamento para `null`.

- **Localizacao:** `lib/drivers/google-auth-driver/index.dart` (**novo arquivo**)
- **Responsabilidade:** expor `googleAuthDriverProvider` como fronteira publica da camada.

## Camada UI (Widgets Internos)

- **Localizacao:** `lib/ui/auth/widgets/components/google_auth_button/` (**novo arquivo** em pasta nova)
- **Tipo:** View only
- **Arquivos:** `index.dart`, `google_auth_button_view.dart`
- **Props:** `required bool enabled`, `required bool isLoading`, `required VoidCallback? onPressed`
- **Responsabilidade:** renderizar o CTA compartilhado `Continuar com Google` com icone, loading e estado disabled para `sign_in` e `sign_up`.

- **Localizacao:** `lib/ui/auth/widgets/components/or_divider/` (**novo arquivo** em pasta nova)
- **Tipo:** View only
- **Arquivos:** `index.dart`, `or_divider_view.dart`
- **Responsabilidade:** renderizar o divisor horizontal com o texto `ou` como componente compartilhado entre os dois fluxos.

## Camada UI (Barrel Files / `index.dart`)

- **Localizacao:** `lib/ui/auth/widgets/components/google_auth_button/index.dart` (**novo arquivo**)
- **`typedef` exportado:** `typedef GoogleAuthButton = GoogleAuthButtonView`

- **Localizacao:** `lib/ui/auth/widgets/components/or_divider/index.dart` (**novo arquivo**)
- **`typedef` exportado:** `typedef OrDivider = OrDividerView`

## Estrutura de Pastas

```text
lib/core/auth/interfaces/
  auth_service.dart
  google_auth_driver.dart

lib/drivers/google-auth-driver/
  index.dart
  google_sign_in/
    google_sign_in_google_auth_driver.dart

lib/ui/auth/widgets/components/
  auth_header/
  google_auth_button/
    index.dart
    google_auth_button_view.dart
  or_divider/
    index.dart
    or_divider_view.dart
```

---

# 6. O que deve ser modificado?

## Camada Core

- **Arquivo:** `lib/core/auth/interfaces/auth_service.dart`
- **Mudanca:** adicionar `Future<RestResponse<SessionDto>> signInWithGoogle({required String idToken})`.
- **Justificativa:** a UI precisa consumir o login social por contrato, sem conhecer endpoint nem `RestClient`.

## Camada REST

- **Arquivo:** `lib/rest/services/auth_rest_service.dart`
- **Mudanca:** implementar `signInWithGoogle({required String idToken})` com `POST /auth/sign-up/google`, payload inline `{ 'id_token': idToken }` e retorno `response.mapBody<SessionDto>(SessionMapper.toDto)`.
- **Justificativa:** o endpoint Google pertence ao mesmo contexto de autenticacao ja concentrado em `AuthRestService`.

- **Arquivo:** `lib/rest/services/index.dart`
- **Mudanca:** manter `authServiceProvider` como fronteira publica, apenas entregando uma instancia de `AuthRestService` que suporte o novo metodo.
- **Justificativa:** preservar o padrao atual de composicao via Riverpod.

## Camada Drivers

- **Arquivo:** `pubspec.yaml`
- **Mudanca:** adicionar `google_sign_in` em `dependencies`.
- **Justificativa:** o fluxo OAuth nativo passa a depender do SDK oficial suportado pelo ecossistema Flutter.

## Camada UI

- **Arquivo:** `lib/ui/auth/widgets/pages/sign_in_screen/sign_in_screen_presenter.dart`
- **Mudanca:** injetar `GoogleAuthDriver`, adicionar `signal<bool> isGoogleSubmitting`, atualizar `canSubmit` para bloquear submissao concorrente e incluir `Future<void> continueWithGoogle()`.
- **Justificativa:** o fluxo Google precisa seguir o mesmo ponto de orquestracao, persistencia de sessao e tratamento de erro do login atual.
- **Detalhamento funcional esperado no arquivo:**
  - `Future<void> continueWithGoogle()` - obtém `idToken` via `GoogleAuthDriver.requestIdToken`, ignora cancelamento (`null`), chama `AuthService.signInWithGoogle`, persiste tokens via `CacheDriver` e navega para `Routes.home`; em falha atualiza `generalError`.
  - `ReadonlySignal<bool> canSubmit` - continua exigindo formulario valido, mas tambem considera `isGoogleSubmitting == false`.
  - `ReadonlySignal<bool> canTriggerGoogleAuth` - verdadeiro quando `isSubmitting == false` e `isGoogleSubmitting == false`.

- **Arquivo:** `lib/ui/auth/widgets/pages/sign_in_screen/sign_in_form/sign_in_form_presenter.dart`
- **Mudanca:** expor `isGoogleSubmitting`, `canTriggerGoogleAuth` e `Future<void> continueWithGoogle()`.
- **Justificativa:** a View precisa consumir estado e acao do CTA Google sem replicar logica.

- **Arquivo:** `lib/ui/auth/widgets/pages/sign_in_screen/sign_in_form/sign_in_form_view.dart`
- **Mudanca:** substituir o botao Google local pelo componente compartilhado e ligar `onPressed` a `presenter.continueWithGoogle`.
- **Justificativa:** o CTA deixa de ser apenas visual e passa a refletir estados reais de loading/disabled.

- **Arquivo:** `lib/ui/auth/widgets/pages/sign_in_screen/sign_in_form/index.dart`
- **Mudanca:** parar de exportar os widgets locais `google_sign_in_button` e `or_divider`, passando a importar os componentes compartilhados.
- **Justificativa:** reduzir acoplamento de componentes compartilhados a uma unica tela.

- **Arquivo:** `lib/ui/auth/widgets/pages/sign_up_screen/sign_up_screen_presenter.dart`
- **Mudanca:** injetar `GoogleAuthDriver`, adicionar `signal<bool> isGoogleSubmitting`, expor `canTriggerGoogleAuth` e incluir `Future<void> continueWithGoogle()` com o mesmo contrato do `sign_in`.
- **Justificativa:** o ticket exige o fluxo OAuth tambem na tela de cadastro, sem criar tela separada.
- **Detalhamento funcional esperado no arquivo:**
  - `Future<void> continueWithGoogle()` - obtém `idToken`, ignora cancelamento, chama `AuthService.signInWithGoogle`, persiste tokens e navega para `Routes.home`; falhas tecnicas/API populam `generalError`.
  - `ReadonlySignal<bool> canSubmit` - continua dependente da validade do formulario e tambem bloqueia quando `isGoogleSubmitting` estiver ativo.
  - `ReadonlySignal<bool> canTriggerGoogleAuth` - verdadeiro quando nenhum fluxo remoto da tela esta em andamento.

- **Arquivo:** `lib/ui/auth/widgets/pages/sign_up_screen/sign_up_form/sign_up_form_presenter.dart`
- **Mudanca:** expor `isGoogleSubmitting`, `canTriggerGoogleAuth` e `Future<void> continueWithGoogle()`.
- **Justificativa:** manter a View do formulario puramente declarativa.

- **Arquivo:** `lib/ui/auth/widgets/pages/sign_up_screen/sign_up_form/sign_up_form_view.dart`
- **Mudanca:** inserir `OrDivider` + `GoogleAuthButton` antes do hint de `Entrar`, preservando `TermsLabel`, `GeneralErrorAlert` e CTA principal existentes.
- **Justificativa:** alinhar o cadastro ao requisito do ticket, hoje nao atendido pela tela atual.

## App / Configuracao

- **Arquivo:** `lib/constants/env.dart`
- **Mudanca:** expor getters para a configuracao do Google consumida pelo driver, com foco minimo em `serverClientId` e `iOS clientId` caso o app opte por inicializacao via Dart.
- **Justificativa:** evitar valores hardcoded dentro do driver e manter a configuracao em ponto central do app.

- **Arquivo:** `.env.example`
- **Mudanca:** documentar as chaves de configuracao Google esperadas pela inicializacao do driver.
- **Justificativa:** o projeto hoje nao comunica quais valores precisam ser provisionados para auth social.

- **Arquivo:** `ios/Runner/Info.plist`
- **Mudanca:** adicionar a secao obrigatoria de `CFBundleURLTypes` para callback do Google Sign-In e, se a equipe optar por configuracao nativa, incluir `GIDClientID` e `GIDServerClientID`.
- **Justificativa:** o SDK iOS exige URL scheme reverso valido para concluir o retorno do provedor.

- **Arquivo:** `android/app/build.gradle.kts`
- **Mudanca:** validar e substituir o `applicationId` placeholder por um identificador real antes do registro OAuth do Android.
- **Justificativa:** o provedor Google exige package name consistente com a aplicacao registrada; o valor atual de template inviabiliza configuracao de producao.

---

# 7. O que deve ser removido?

## Camada UI

- **Arquivo:** `lib/ui/auth/widgets/pages/sign_in_screen/sign_in_form/google_sign_in_button/`
- **Motivo da remocao:** o componente atual e especifico de `sign_in`, mas o CTA passa a ser compartilhado com `sign_up`.
- **Impacto esperado:** os imports da tela de login devem migrar para `lib/ui/auth/widgets/components/google_auth_button/`.

- **Arquivo:** `lib/ui/auth/widgets/pages/sign_in_screen/sign_in_form/or_divider/`
- **Motivo da remocao:** o divisor `ou` deixa de ser interno de `sign_in` e vira componente compartilhado.
- **Impacto esperado:** `sign_in_form_view.dart` e `sign_up_form_view.dart` passam a importar `lib/ui/auth/widgets/components/or_divider/`.

---

# 8. Decisoes Tecnicas e Trade-offs

## 8.1 Isolar o SDK Google em driver proprio

- **Decisao**
- Criar `GoogleAuthDriver` no `core` e implementa-lo na camada `drivers` com `google_sign_in`.
- **Alternativas consideradas**
- Chamar `google_sign_in` diretamente nos presenters; colocar o SDK dentro de `AuthRestService`.
- **Motivo da escolha**
- As regras da arquitetura proíbem a UI de importar SDK concreto e a camada REST nao deve assumir responsabilidade de autenticacao nativa do dispositivo.
- **Impactos / trade-offs**
- Adiciona uma camada a mais no fluxo, mas preserva as fronteiras arquiteturais e deixa a integracao social testavel e substituivel.

## 8.2 Reutilizar os presenters de tela ja existentes

- **Decisao**
- Estender `SignInScreenPresenter` e `SignUpScreenPresenter` com o fluxo Google, em vez de criar presenter separado para auth social.
- **Alternativas consideradas**
- Criar um `GoogleAuthPresenter` compartilhado; mover o fluxo para a View.
- **Motivo da escolha**
- Os presenters atuais ja concentram `generalError`, persistencia de sessao e navegacao; o novo fluxo precisa atualizar exatamente esses mesmos estados.
- **Impactos / trade-offs**
- Ha algum aumento de responsabilidade nos presenters, mas evita coordenacao extra entre presenters e reduz duplicacao de estado visual.

## 8.3 Extrair CTA Google e divisor para componentes compartilhados

- **Decisao**
- Promover `GoogleSignInButton` e `OrDivider` para `lib/ui/auth/widgets/components/`.
- **Alternativas consideradas**
- Duplicar os widgets em `sign_up`; manter os widgets em `sign_in` e importar a pasta de outra tela.
- **Motivo da escolha**
- O ticket exige o mesmo CTA em duas telas, e importar widgets internos de uma tela por outra viola a fronteira publica esperada da camada UI.
- **Impactos / trade-offs**
- Exige pequena reorganizacao de imports, mas elimina acoplamento entre telas irmas.

## 8.4 Enviar apenas `idToken` ao backend

- **Decisao**
- O app envia somente `idToken` para `AuthService.signInWithGoogle`, deixando criacao/vinculacao de conta no backend.
- **Alternativas consideradas**
- Extrair nome/e-mail do usuario no app e mandar payload mais rico; persistir dados do usuario Google localmente.
- **Motivo da escolha**
- O PRD e o ticket deixam claro que o backend decide criar ou vincular conta a partir dos dados do Google; o mobile precisa apenas entregar o token de identidade.
- **Impactos / trade-offs**
- Simplifica o app e reaproveita `SessionDto`, mas limita o mobile a um contrato backend estavel para esse endpoint.

## 8.5 Tratar cancelamento como no-op silencioso

- **Decisao**
- `GoogleAuthDriver.requestIdToken()` retorna `null` quando houver cancelamento do usuario, e o presenter encerra sem erro visual.
- **Alternativas consideradas**
- Exibir `generalError` em qualquer excecao/cancelamento; manter estado visual de erro leve.
- **Motivo da escolha**
- O ticket explicita que cancelamento deve ser silencioso; isso tambem evita UX punitiva em uma acao voluntaria do usuario.
- **Impactos / trade-offs**
- O presenter precisa distinguir cancelamento de falha tecnica do SDK, mas a experiencia final fica consistente com o requisito.

## 8.6 Aceitar configuracao Google como dependencia externa explicita

- **Decisao**
- A spec inclui os pontos tecnicos de configuracao (`Env`, `Info.plist`, `applicationId`), mas registra como pendencia os valores concretos de OAuth ainda ausentes no repositorio.
- **Alternativas consideradas**
- Omitir completamente a configuracao nativa; hardcode de IDs no codigo Dart.
- **Motivo da escolha**
- Sem esses valores o fluxo nao sobe em device real; hardcode violaria o objetivo de configuracao centralizada.
- **Impactos / trade-offs**
- A implementacao continua direta, mas a validacao manual depende da equipe disponibilizar os client IDs e identifiers finais do app.

---

# 9. Diagramas e Referencias

- **Fluxo de dados:**

```text
SignInFormView / SignUpFormView
        -> Presenter.continueWithGoogle()
            -> GoogleAuthDriver.requestIdToken()
                -> google_sign_in SDK
                -> [cancelado] null
                -> [sucesso] idToken
            -> AuthService.signInWithGoogle(idToken)
                -> AuthRestService.signInWithGoogle(...)
                    -> RestClient.post('/auth/sign-up/google')
                    -> SessionMapper.toDto(...)
            -> [sucesso] CacheDriver.set(CacheKeys.accessToken, session.accessToken.value)
            -> [sucesso] CacheDriver.set(CacheKeys.refreshToken, session.refreshToken.value)
            -> [sucesso] NavigationDriver.goTo(Routes.home)
            -> [falha SDK/API] generalError
```

- **Hierarquia de widgets (se aplicavel):**

```text
SignInScreenView
  BrandHeaderView
  AuthHeaderView
  SignInFormView
    EmailField
    PasswordField
    ForgotPasswordHintView
    GeneralErrorAlertView?
    SignInSubmitButtonView
    OrDividerView (shared)
    GoogleAuthButtonView (shared)
    SignUpHintView

SignUpScreenView
  TopProgressBarView
  BrandHeaderView
  AuthHeaderView
  SignUpFormView
    NameField
    EmailField
    PasswordField
    PasswordStrengthIndicatorView
    ConfirmPasswordField
    TermsLabelView
    GeneralErrorAlertView?
    SignUpSubmitButtonView
    OrDividerView (shared)
    GoogleAuthButtonView (shared)
    SignInHintView
```

- **Referencias:**
  - `lib/ui/auth/widgets/pages/sign_in_screen/sign_in_screen_presenter.dart` - referencia principal de persistencia de sessao e navegacao apos auth.
  - `lib/ui/auth/widgets/pages/sign_up_screen/sign_up_screen_presenter.dart` - referencia principal para integrar o CTA Google na tela de cadastro.
  - `lib/ui/auth/widgets/pages/sign_in_screen/sign_in_form/google_sign_in_button/google_sign_in_button_view.dart` - referencia visual do CTA Google que sera promovido a componente compartilhado.
  - `lib/ui/auth/widgets/pages/sign_in_screen/sign_in_form/or_divider/or_divider_view.dart` - referencia visual do divisor `ou` que sera compartilhado.
  - `lib/rest/services/auth_rest_service.dart` - service REST a ser estendido com `signInWithGoogle`.
  - `lib/rest/mappers/auth/session_mapper.dart` - mapper reutilizado para o retorno do endpoint Google.
  - `lib/drivers/caches/shared_preferences/shared_preferences_cache_driver.dart` - referencia de persistencia string-based dos tokens.
  - `lib/drivers/navigation/go_router/go_router_navigation_driver.dart` - referencia do driver de navegacao consumido pelos presenters.
  - `pubspec.yaml` - declaracao das dependencias Flutter da feature.
  - `ios/Runner/Info.plist` e `android/app/build.gradle.kts` - pontos de configuracao nativa relevantes para o fluxo OAuth.

---

# 10. Pendencias / Duvidas

- **Descricao da pendencia**
- Os valores concretos de `serverClientId`, `iOS clientId` e `reversed URL scheme` do Google nao existem no repositorio e nao foram informados no ticket.
- **Impacto na implementacao**
- Sem esses valores o driver pode ser implementado, mas o fluxo nao sera validavel em `iOS` e, dependendo da estrategia Android adotada, tambem nao autenticara em device real.
- **Acao sugerida:** validar com produto/infra/mobile qual projeto OAuth sera usado e provisionar os IDs antes da homologacao.

- **Descricao**
- Os identifiers nativos relevantes para o fluxo Google ja foram atualizados para valores finais no app (`bundleId`/`applicationId` em `br.com.animus.app`); o ponto de atencao remanescente e manter o cadastro do OAuth client sincronizado com esses mesmos identifiers em futuros renomes.
- **Impacto na implementacao**
- Nao ha bloqueio conhecido por placeholder nos artefatos mobile; a validacao depende apenas de o console do Google reutilizar exatamente os identifiers configurados no projeto.
- **Acao sugerida:** garantir que o registro do OAuth client use os identifiers atualmente configurados no iOS e Android e revisar esse alinhamento sempre que houver renome do app.

- **Descricao da pendencia**
- O ticket ANI-41 explicita Google em `Sign In` e `Sign Up`, mas a tela atual de `sign_up` ainda nao possui nenhum CTA visual equivalente nem referencia de layout externa (`screen_id` / Stitch).
- **Impacto na implementacao**
- A distribuicao visual do novo bloco em `sign_up` precisara seguir os padroes da tela atual, sem uma referencia externa formal de spacing/hierarquia para o estado final.
- **Acao sugerida:** manter consistencia com `sign_in_form_view.dart` e, se houver design dedicado depois, revisar apenas o layout sem mudar contratos tecnicos.

---

# Restricoes

- **Nao inclua testes automatizados na spec.**
- A `View` nao deve conter logica de negocio; toda orquestracao do fluxo Google, persistencia de sessao e navegacao fica no `Presenter`.
- Presenters nao fazem chamadas diretas a `RestClient`; consomem sempre `AuthService` e `GoogleAuthDriver`.
- Todos os caminhos citados existem no projeto ou estao explicitamente marcados como **novo arquivo**.
- Esta spec nao inventa DTO novo para sessao social; reutiliza `SessionDto` e `TokenDto`, ja existentes na codebase.
- Toda referencia a codigo existente usa caminho relativo real (`lib/...`, `ios/...`, `android/...`, `pubspec.yaml`, `.env.example`).
- O SDK `google_sign_in` deve permanecer encapsulado na camada `drivers`.
- O CTA Google deve ser compartilhado entre `sign_in` e `sign_up`, evitando duplicidade de widget e imports cruzados entre telas.
- A nomenclatura deve seguir a codebase: arquivos em `snake_case`, classes em `PascalCase`, providers e metodos em `camelCase`.
