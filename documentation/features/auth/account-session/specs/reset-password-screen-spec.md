---
title: Redefinicao de senha via Sign In
prd: https://joaogoliveiragarcia.atlassian.net/wiki/spaces/anm/pages/16908291/PRD+RF+01+Gerenciamento+de+sess+o+do+usu+rio
ticket: https://joaogoliveiragarcia.atlassian.net/browse/ANI-42
status: closed
last_updated_at: 2026-03-27
screen_ids: [a0rfv, i6r8t, 82PSB]  # Pencil: Forgot - Email | Forgot - Codigo | Forgot - Nova Senha
---

# 1. Objetivo

Esta spec define a implementacao tecnica do fluxo de redefinicao de senha iniciado a partir de `Sign In` no `animus`, cobrindo a tela de pedido do link, a tela de confirmacao de envio, a captura do deep link `animus://reset-password?token=...`, a validacao remota do token e o formulario compartilhado de nova senha. A entrega precisa respeitar a arquitetura em camadas ja consolidada no modulo `auth`, mantendo `MVP`, `Riverpod`, `signals`, `reactive_forms`, `AuthService` como port do `core`, implementacao HTTP em `rest`, navegacao via `NavigationDriver` e isolamento do deep link atras de um driver dedicado.

---

# 2. Escopo

## 2.1 In-scope

- Tornar o CTA `Esqueceu a senha?` da tela de `sign in` funcional e navegar para uma tela dedicada de recuperacao.
- Criar a tela `forgot_password_screen` com formulario de e-mail, CTA `Enviar link` e CTA secundario `Lembrou? Entrar`.
- Implementar `AuthService.forgotPassword(...)` para `POST /auth/password/forgot` e navegar para `check_email_screen` em sucesso, sem expor se o e-mail existe ou nao.
- Criar a tela `check_email_screen` com exibicao do e-mail informado, feedback textual e CTA `Nao recebeu? Reenviar` bloqueado por countdown de 60 segundos.
- Implementar um listener app-scoped para capturar o deep link `animus://reset-password?token=...`, validar o token com `POST /auth/password/verify-reset-token` e redirecionar para `new_password_screen` com `accountId`.
- Criar a tela `new_password_screen` com campos `newPassword` e `confirmPassword`, toggle de visibilidade, indicador de forca em tempo real e submissao via `POST /auth/password/reset`.
- Adicionar as rotas e helpers de navegacao para `forgotPassword`, `checkEmail` e `newPassword`.
- Configurar Android e iOS para aceitar o custom scheme `animus://reset-password` usando o driver de deep link escolhido.

## 2.2 Out-of-scope

- Ponto de entrada `Alterar Senha` via tela de Configuracoes/Perfil; a codebase atual nao possui esse modulo e o recorte foi explicitamente limitado para esta spec.
- Criacao de uma tela de Configuracoes/Perfil ou implementacao de `Routes.profile`.
- Login com Google, logout, refresh token automatico, expiracao de sessao e qualquer auth guard global adicional.
- Universal Links/App Links HTTP(S); esta spec cobre apenas o custom scheme `animus://reset-password` descrito na task.
- Alteracoes no backend alem dos contratos ja definidos em `ANI-36`.

---

# 3. Requisitos

## 3.1 Funcionais

- O usuario deve conseguir tocar em `Esqueceu a senha?` na tela de login e abrir a tela de recuperacao.
- A tela de recuperacao deve aceitar apenas `email` valido e enviar `POST /auth/password/forgot` com payload `{ "email": ... }`.
- Em `204` de `forgotPassword`, o app deve sempre navegar para `check_email_screen`, mesmo quando o backend opta por nao revelar se a conta existe.
- A tela `check_email_screen` deve exibir o e-mail informado na etapa anterior e permitir reenvio do link apenas apos o countdown regressivo de 60 segundos chegar a zero.
- O app deve interceptar `animus://reset-password?token=...`, extrair `token`, chamar `AuthService.verifyResetToken(...)` e, em `200`, navegar para `Routes.getNewPassword(accountId: ...)`.
- Quando `verifyResetToken` falhar, o app deve redirecionar para `forgot_password_screen` com feedback visivel de link invalido ou expirado.
- A tela `new_password_screen` deve validar localmente: senha obrigatoria, minimo de 8 caracteres, ao menos 1 letra maiuscula, ao menos 1 numero e confirmacao identica.
- Ao submeter `new_password_screen` com dados validos, o app deve chamar `POST /auth/password/reset` com payload `{ "account_id": ..., "new_password": ... }`.
- Em `204` de `resetPassword`, o app deve navegar de volta para `Routes.signIn`.
- Todos os CTAs remotos (`Enviar link`, `Reenviar`, `Redefinir senha`) devem bloquear duplo clique enquanto a requisicao correspondente estiver em voo.

## 3.2 Nao funcionais

- **Performance:** permitir apenas uma requisicao em voo por acao (`forgotPassword`, `verifyResetToken`, `resetPassword`, `resend forgotPassword`) e apenas uma validacao de token por deep link recebido.
- **Acessibilidade:** labels, placeholders, mensagens de erro e countdown devem ser textuais; estados desabilitados nao podem depender apenas de cor.
- **Offline/Conectividade:** falhas de rede nao podem limpar o e-mail nem as senhas digitadas; a tela deve permanecer no estado atual com `generalError` visivel.
- **Seguranca:** o app nao deve revelar se o e-mail existe; o token do deep link nao deve ser persistido em cache; `newPassword` e `confirmPassword` devem existir apenas em memoria no `FormGroup` do presenter.
- **Compatibilidade:** a solucao deve continuar usando `go_router`, `NavigationDriver`, `signals`, `Riverpod`, `reactive_forms` e `Dio`; o custom scheme `animus` deve ser configurado em `android` e `ios`.

---

# 4. O que ja existe?

## Camada Core

- **`AuthService`** (`lib/core/auth/interfaces/auth_service.dart`) — contrato de auth ja cobre `signIn`, `signUp`, `verifyEmail` e `resendVerificationEmail`, mas ainda nao expõe os tres casos de uso de reset de senha.
- **`RestResponse`** (`lib/core/shared/responses/rest_response.dart`) — wrapper tipado de sucesso/falha ja usado pela UI para decidir fluxo por `statusCode`.
- **`NavigationDriver`** (`lib/core/shared/interfaces/navigation_driver.dart`) — contrato usado pelos presenters para navegar sem acoplamento direto a `GoRouter`.

## Camada REST

- **`AuthRestService`** (`lib/rest/services/auth_rest_service.dart`) — implementacao unica do `AuthService`; sera estendida com os endpoints de password reset.
- **`DioRestClient`** (`lib/rest/dio/dio_rest_client.dart`) — cliente HTTP concreto que ja concentra `baseUrl`, status code e `errorBody`.
- **`authServiceProvider`** (`lib/rest/services/index.dart`) — provider Riverpod que entrega `AuthService` aos presenters de `auth`.

## Camada Drivers

- **`GoRouterNavigationDriver`** (`lib/drivers/navigation/go_router/go_router_navigation_driver.dart`) — implementacao concreta de `NavigationDriver`, adequada para redirecionar a app a partir dos novos fluxos de reset.
- **`navigationDriverProvider`** (`lib/drivers/navigation/go_router/go_router_navigation_driver.dart`) — fronteira publica atual de navegacao por provider.

## Camada UI

- **`SignInScreenPresenter`** (`lib/ui/auth/widgets/pages/sign_in_screen/sign_in_screen_presenter.dart`) — presenter atual da tela de login; ja conhece `NavigationDriver`, `AuthService`, `FormGroup` e precisa apenas ganhar o handler para `forgot password`.
- **`SignInFormPresenter`** (`lib/ui/auth/widgets/pages/sign_in_screen/sign_in_form/sign_in_form_presenter.dart`) — presenter interno do formulario de login, hoje sem acao para `Esqueceu a senha?`.
- **`ForgotPasswordHintView`** (`lib/ui/auth/widgets/pages/sign_in_screen/sign_in_form/forgot_password_hint/forgot_password_hint_view.dart`) — CTA visual ja renderizado em `sign in`, mas ainda sem `onTap`.
- **`EmailConfirmationScreenPresenter`** (`lib/ui/auth/widgets/pages/email_confirmation_screen/email_confirmation_screen_presenter.dart`) — referencia direta para countdown de reenvio, estados `isResending`/`feedbackMessage` e `generalError` em um fluxo de auth assicrono.
- **`MessageBoxView`** (`lib/ui/auth/widgets/pages/email_confirmation_screen/message_box/message_box_view.dart`) — componente textual simples de feedback que pode ser reutilizado nas novas telas sem introduzir outro alerta ad hoc.
- **`SignUpInputDecorationBuilder`** (`lib/ui/auth/widgets/pages/sign_up_screen/sign_up_form/input_decoration/sign_up_input_decoration.dart`) — helper de decoracao visual ja alinhado ao tema dos formularios de `auth`.
- **`BrandHeaderView`** (`lib/ui/auth/widgets/pages/sign_up_screen/brand_header/brand_header_view.dart`) e **`AuthHeaderView`** (`lib/ui/auth/widgets/components/auth_header/auth_header_view.dart`) — componentes de cabecalho ja consolidados no envelope visual das telas de autenticacao.

## App / Router

- **`Routes`** (`lib/constants/routes.dart`) — concentra as rotas atuais de `auth`, mas ainda nao possui caminhos para o fluxo de reset.
- **`appRouter`** (`lib/router.dart`) — roteador atual com `signIn`, `signUp` e `emailConfirmation`; sera estendido com novas rotas e guards de query string.
- **`AnimusApp`** (`lib/app.dart`) — ponto de montagem ideal para um listener app-scoped via `MaterialApp.router(builder: ...)`.

## Lacunas encontradas

- Nao existe modulo/tela de Configuracoes ou Perfil em `lib/ui/`; apenas a constante `Routes.profile` existe em `lib/constants/routes.dart`.
- Nao existe nenhum driver ou provider de deep link na codebase.
- Nao existe suporte atual no `AuthService` para `forgotPassword`, `verifyResetToken` ou `resetPassword`.

---

# 5. O que deve ser criado?

## Camada Core (Interfaces / Contratos)

- **Localizacao:** `lib/core/auth/interfaces/password_reset_link_driver.dart` (**novo arquivo**)
- **Metodos:**
  - `Stream<String> watchResetTokens()` — emite apenas tokens validos extraidos de URIs `animus://reset-password?token=...`, escondendo o pacote concreto de deep link da UI.

## Camada Drivers (Adaptadores)

- **Localizacao:** `lib/drivers/password-reset-link-driver/app_links/app_links_password_reset_link_driver.dart` (**novo arquivo**)
- **Interface implementada (port do `core`):** `PasswordResetLinkDriver`
- **Biblioteca/pacote utilizado:** `app_links`
- **Metodos:**
  - `Stream<String> watchResetTokens()` — observa `AppLinks().uriLinkStream`, filtra links com `scheme == 'animus'`, host `reset-password` e query param `token`, e devolve apenas o token limpo.
- **Localizacao:** `lib/drivers/password-reset-link-driver/index.dart` (**novo arquivo**)
- **Responsabilidade:** exportar o driver e o provider `passwordResetLinkDriverProvider` para consumo pela camada UI.

## Camada UI (Presenters)

- **Localizacao:** `lib/ui/auth/widgets/components/password_reset_link_listener/password_reset_link_listener_presenter.dart` (**novo arquivo**)
- **Dependencias injetadas:** `PasswordResetLinkDriver`, `AuthService`, `NavigationDriver`
- **Estado (`signals`):**
  - Signals simples: `signal<bool> isHandlingToken`
- **Provider Riverpod:** `passwordResetLinkListenerPresenterProvider`
- **Metodos:**
  - `void start()` — inicia a inscricao unica no stream de tokens do driver.
  - `Future<void> handleToken(String token)` — chama `AuthService.verifyResetToken`, navega para `Routes.getNewPassword(accountId: ...)` em sucesso e retorna para `Routes.getForgotPassword(errorCode: 'invalid_reset_link')` em falha.
  - `void dispose()` — cancela a inscricao do stream.

- **Localizacao:** `lib/ui/auth/widgets/pages/forgot_password_screen/forgot_password_screen_presenter.dart` (**novo arquivo**)
- **Dependencias injetadas:** `AuthService`, `NavigationDriver`, `String? initialErrorCode`
- **Estado (`signals`):**
  - Signals simples: `signal<String?> generalError`, `signal<bool> isSubmitting`, `signal<int> _formVersion`
  - Computeds: `computed<bool> canSubmit` — verdadeiro quando o formulario estiver valido e `isSubmitting == false`
- **Provider Riverpod:** `forgotPasswordScreenPresenterProvider`
- **Metodos:**
  - `FormControl<String> get emailControl` — expoe o controle tipado de e-mail.
  - `Future<void> submit()` — valida o formulario, chama `AuthService.forgotPassword`, navega para `Routes.getCheckEmail(email: ...)` em `204` e atualiza `generalError` em falhas tecnicas.
  - `void goToSignIn()` — navega para `Routes.signIn`.
  - `void dispose()` — limpa `FormGroup`, subscriptions e `signals`.

- **Localizacao:** `lib/ui/auth/widgets/pages/forgot_password_screen/forgot_password_form/forgot_password_form_presenter.dart` (**novo arquivo**)
- **Dependencias injetadas:** `ForgotPasswordScreenPresenter`
- **Estado (`signals`):** proxys de `generalError`, `isSubmitting` e `canSubmit`
- **Provider Riverpod:** `forgotPasswordFormPresenterProvider`
- **Metodos:**
  - `Future<void> submit()` — delega para `ForgotPasswordScreenPresenter.submit`.
  - `void goToSignIn()` — delega para `ForgotPasswordScreenPresenter.goToSignIn`.
  - Getters de `validationMessages` para `email` — concentram as mensagens consumidas pela View.

- **Localizacao:** `lib/ui/auth/widgets/pages/check_email_screen/check_email_screen_presenter.dart` (**novo arquivo**)
- **Dependencias injetadas:** `AuthService`, `String email`
- **Estado (`signals`):**
  - Signals simples: `signal<bool> isResending`, `signal<int> resendCountdown`, `signal<String?> generalError`, `signal<String?> feedbackMessage`
- **Provider Riverpod:** `checkEmailScreenPresenterProvider`
- **Metodos:**
  - `Future<void> resend()` — chama `AuthService.forgotPassword(email: email)` quando `resendCountdown == 0`, reinicia o countdown de 60 segundos e atualiza feedback.
  - `String get resendCountdownLabel` — devolve o texto formatado `00:SS` para a View.
  - `void dispose()` — cancela o timer e libera `signals`.

- **Localizacao:** `lib/ui/auth/widgets/pages/new_password_screen/new_password_screen_presenter.dart` (**novo arquivo**)
- **Dependencias injetadas:** `AuthService`, `NavigationDriver`, `String accountId`
- **Estado (`signals`):**
  - Signals simples: `signal<String?> generalError`, `signal<bool> isSubmitting`, `signal<bool> isPasswordVisible`, `signal<bool> isConfirmPasswordVisible`, `signal<String> _passwordValue`, `signal<int> _formVersion`
  - Computeds: `computed<bool> hasMinLength`, `computed<bool> hasUppercaseLetter`, `computed<bool> hasNumber`, `computed<int> passwordStrengthScore`, `computed<bool> canSubmit`
- **Provider Riverpod:** `newPasswordScreenPresenterProvider`
- **Metodos:**
  - `FormControl<String> get newPasswordControl` — expoe o controle tipado da nova senha.
  - `FormControl<String> get confirmPasswordControl` — expoe o controle tipado da confirmacao.
  - `void onPasswordChanged(String? value)` — recalcula o estado derivado da senha e revalida `confirmPassword`.
  - `void togglePasswordVisibility()` — alterna a visibilidade do campo `newPassword`.
  - `void toggleConfirmPasswordVisibility()` — alterna a visibilidade do campo `confirmPassword`.
  - `Future<void> submit()` — valida o formulario, chama `AuthService.resetPassword`, navega para `Routes.signIn` em `204` e atualiza `generalError` quando o backend negar o reset.
  - `void goToSignIn()` — navega para `Routes.signIn` sem resetar estado externo.
  - `void dispose()` — limpa `FormGroup`, subscriptions e `signals`.

- **Localizacao:** `lib/ui/auth/widgets/pages/new_password_screen/new_password_form/new_password_form_presenter.dart` (**novo arquivo**)
- **Dependencias injetadas:** `NewPasswordScreenPresenter`
- **Estado (`signals`):** proxys de `generalError`, `isSubmitting`, `isPasswordVisible`, `isConfirmPasswordVisible`, `hasMinLength`, `hasUppercaseLetter`, `hasNumber`, `passwordStrengthScore`, `canSubmit`
- **Provider Riverpod:** `newPasswordFormPresenterProvider`
- **Metodos:**
  - `void onPasswordChanged(String? value)` — delega para `NewPasswordScreenPresenter.onPasswordChanged`.
  - `void togglePasswordVisibility()` — delega para `NewPasswordScreenPresenter.togglePasswordVisibility`.
  - `void toggleConfirmPasswordVisibility()` — delega para `NewPasswordScreenPresenter.toggleConfirmPasswordVisibility`.
  - `Future<void> submit()` — delega para `NewPasswordScreenPresenter.submit`.
  - `void goToSignIn()` — delega para `NewPasswordScreenPresenter.goToSignIn`.
  - Getters de `validationMessages` para `newPassword` e `confirmPassword` — centralizam mensagens da View.

## Camada UI (Views)

- **Localizacao:** `lib/ui/auth/widgets/components/password_reset_link_listener/password_reset_link_listener_view.dart` (**novo arquivo**)
- **Base class:** `ConsumerStatefulWidget`
- **Props:** `required Widget child`
- **Bibliotecas de UI:** `flutter_riverpod`
- **Estados visuais:** Não aplicável; atua apenas como wrapper estrutural da app.

- **Localizacao:** `lib/ui/auth/widgets/pages/forgot_password_screen/forgot_password_screen_view.dart` (**novo arquivo**)
- **Base class:** `StatelessWidget`
- **Props:** `String? initialErrorCode`
- **Bibliotecas de UI:** `flutter/material.dart`
- **Icones:** `Icons.arrow_back` (nav row), `Icons.lock_keyhole` (amber, 48px)
- **Textos:** `"Recuperar Senha"` (nav title), `"Esqueceu sua senha?"` (titulo Fraunces 22px), `"Digite seu e-mail cadastrado e enviaremos um link para redefinir sua senha."` (subtitulo)
- **Composicao visual:** NavBackRow + BrandHeader (opcional — ou direto Icon Circle + Header Text) + ForgotPasswordForm
- **Estados visuais:**
  - `Content` — icone de cadeado em circulo, header textual, formulario.
  - `Error` — `MessageBox` ou toast de erro generico quando `generalError` estiver preenchido.

- **Localizacao:** `lib/ui/auth/widgets/pages/forgot_password_screen/forgot_password_form/forgot_password_form_view.dart` (**novo arquivo**)
- **Base class:** `ConsumerWidget`
- **Props:** nenhuma
- **Bibliotecas de UI:** `flutter_riverpod`, `signals_flutter`, `reactive_forms`
- **Estados visuais:**
  - `Loading` — CTA `Enviar link` desabilitado e com label de progresso.
  - `Content` — campo de e-mail, erro geral opcional e link `Lembrou? Entrar`.

- **Localizacao:** `lib/ui/auth/widgets/pages/check_email_screen/check_email_screen_view.dart` (**novo arquivo**)
- **Base class:** `ConsumerWidget`
- **Props:** `required String email`
- **Bibliotecas de UI:** `flutter_riverpod`, `signals_flutter`
- **Icones:** `Icons.mail_check` (amber, 48px)
- **Textos:** `"Verifique seu E-mail"` (titulo Fraunces 22px), `"Enviamos um link de recuperacao para $email. Verifique sua caixa de entrada."` (subtitulo), `"Nao recebeu?"` + `"Reenviar"` (amber, 13px), `"Reenviar em SSs"` (muted, 12px)
- **Nota de design:** esta tela NAO tem botao back nav — e um endpoint do fluxo de recuperacao sem caminho de volta natural; o unico CTA e reenviar ou aguardar.
- **Estados visuais:**
  - `Content` — icone mail-check, mensagem com e-mail dinamico, CTA de reenvio ativo/inativo com countdown.
  - `Loading` — texto `"Reenviando..."` bloqueado enquanto a requisicao estiver em voo.
  - `Error` — `MessageBox` quando houver falha de rede/servidor no reenvio.

- **Localizacao:** `lib/ui/auth/widgets/pages/new_password_screen/new_password_screen_view.dart` (**novo arquivo**)
- **Base class:** `StatelessWidget`
- **Props:** `required String accountId`
- **Bibliotecas de UI:** `flutter/material.dart`
- **Icones:** `Icons.arrow_back` (nav row), `Icons.shield_check` (amber, 48px, com stroke sutil)
- **Textos:** `"Nova Senha"` (nav title e titulo Fraunces 22px), `"Crie uma nova senha segura."` (subtitulo), `"Nova Senha"` / `"Confirmar Senha"` (placeholders)
- **Composicao visual:** NavBackRow + Icon Circle (shield-check) + Header Text + NewPasswordForm
- **Estados visuais:**
  - `Content` — icone de escudo, header textual, formulario de senha com strength meter.
  - `Error` — `MessageBox` ou toast quando `generalError` estiver preenchido.

- **Localizacao:** `lib/ui/auth/widgets/pages/new_password_screen/new_password_form/new_password_form_view.dart` (**novo arquivo**)
- **Base class:** `ConsumerWidget`
- **Props:** nenhuma
- **Bibliotecas de UI:** `flutter_riverpod`, `signals_flutter`, `reactive_forms`
- **Nota sobre indicador de forca:** o design (`82PSB`) define um strength meter de **3 barras** horizontais (`str1`, `str2`, `str3`) com cores verde (`#32D583`) / amber (`#FFB547`) que funcionam como score 1-3. Isso difere do `PasswordStrengthIndicatorView` existente em sign-up, que usa `RuleItem` com checks por regra. O presenter deve expor `passwordStrengthScore` (1-3) calculado: score = 1 se apenas minLength, score = 2 se minLength + uppercase, score = 3 se todos. A View consume esse score para colorir as barras (1=verde, 2=verde, 3=amber). Os requisitos textuais (`8 caracteres`, `Letra maiuscula`, `Numero`) sao stateless com check icon `Icons.check` verde quando satisfeito.
- **Estados visuais:**
  - `Loading` — CTA `Redefinir Senha` desabilitado e com label de progresso.
  - `Content` — campos de senha com toggle `eye-off`, strength meter 3 barras, requisitos com checks, erro geral opcional e CTA principal.

## Camada UI (Widgets Internos)

- **Localizacao:** `lib/ui/auth/widgets/pages/forgot_password_screen/nav_back_row/` (**novo arquivo** em pasta nova)
- **Tipo:** View only
- **Arquivos:** `index.dart`, `nav_back_row_view.dart`
- **Props:** `required VoidCallback onBack`
- **Responsabilidade:** renderizar a linha de navegacao com `arrow_back` icon e titulo centralizado; usado em `ForgotPasswordScreen` e `NewPasswordScreen`.

- **Localizacao:** `lib/ui/auth/widgets/pages/forgot_password_screen/forgot_password_form/forgot_password_submit_button/` (**novo arquivo** em pasta nova)
- **Tipo:** View only
- **Arquivos:** `index.dart`, `forgot_password_submit_button_view.dart`
- **Props:** `required bool isSubmitting`, `required bool enabled`, `required VoidCallback? onPressed`
- **Responsabilidade:** renderizar o CTA `Enviar link` com estados de loading e disabled.

- **Localizacao:** `lib/ui/auth/widgets/pages/forgot_password_screen/forgot_password_form/remembered_sign_in_hint/` (**novo arquivo** em pasta nova)
- **Tipo:** View only
- **Arquivos:** `index.dart`, `remembered_sign_in_hint_view.dart`
- **Props:** `required VoidCallback onTap`
- **Responsabilidade:** renderizar o CTA secundario `Lembrou? Entrar`.

- **Localizacao:** `lib/ui/auth/widgets/pages/new_password_screen/new_password_form/reset_password_submit_button/` (**novo arquivo** em pasta nova)
- **Tipo:** View only
- **Arquivos:** `index.dart`, `reset_password_submit_button_view.dart`
- **Props:** `required bool isSubmitting`, `required bool enabled`, `required VoidCallback? onPressed`
- **Responsabilidade:** renderizar o CTA `Redefinir senha` com estados de loading e disabled.

## Camada UI (Barrel Files / `index.dart`)

- **Localizacao:** `lib/ui/auth/widgets/components/password_reset_link_listener/index.dart` (**novo arquivo**)
- **`typedef` exportado:** `typedef PasswordResetLinkListener = PasswordResetLinkListenerView`
- **Widgets internos exportados:** Não aplicável

- **Localizacao:** `lib/ui/auth/widgets/pages/forgot_password_screen/index.dart` (**novo arquivo**)
- **`typedef` exportado:** `typedef ForgotPasswordScreen = ForgotPasswordScreenView`
- **Widgets internos exportados:** Não aplicável

- **Localizacao:** `lib/ui/auth/widgets/pages/forgot_password_screen/forgot_password_form/index.dart` (**novo arquivo**)
- **`typedef` exportado:** `typedef ForgotPasswordForm = ForgotPasswordFormView`
- **Widgets internos exportados:** `ForgotPasswordSubmitButton`, `RememberedSignInHint`

- **Localizacao:** `lib/ui/auth/widgets/pages/check_email_screen/index.dart` (**novo arquivo**)
- **`typedef` exportado:** `typedef CheckEmailScreen = CheckEmailScreenView`
- **Widgets internos exportados:** Não aplicável

- **Localizacao:** `lib/ui/auth/widgets/pages/new_password_screen/index.dart` (**novo arquivo**)
- **`typedef` exportado:** `typedef NewPasswordScreen = NewPasswordScreenView`
- **Widgets internos exportados:** Não aplicável

- **Localizacao:** `lib/ui/auth/widgets/pages/new_password_screen/new_password_form/index.dart` (**novo arquivo**)
- **`typedef` exportado:** `typedef NewPasswordForm = NewPasswordFormView`
- **Widgets internos exportados:** `ResetPasswordSubmitButton`

## Camada UI (Providers Riverpod — se isolados)

- **Localizacao:** `lib/ui/auth/widgets/components/password_reset_link_listener/password_reset_link_listener_presenter.dart` (**novo arquivo**)
- **Nome do provider:** `passwordResetLinkListenerPresenterProvider`
- **Tipo:** `Provider<PasswordResetLinkListenerPresenter>`
- **Dependencias:** `ref.watch(passwordResetLinkDriverProvider)`, `ref.watch(authServiceProvider)`, `ref.watch(navigationDriverProvider)`

- **Localizacao:** `lib/ui/auth/widgets/pages/forgot_password_screen/forgot_password_screen_presenter.dart` (**novo arquivo**)
- **Nome do provider:** `forgotPasswordScreenPresenterProvider`
- **Tipo:** `Provider.autoDispose.family<ForgotPasswordScreenPresenter, String?>`
- **Dependencias:** `ref.watch(authServiceProvider)`, `ref.watch(navigationDriverProvider)`

- **Localizacao:** `lib/ui/auth/widgets/pages/forgot_password_screen/forgot_password_form/forgot_password_form_presenter.dart` (**novo arquivo**)
- **Nome do provider:** `forgotPasswordFormPresenterProvider`
- **Tipo:** `Provider.autoDispose.family<ForgotPasswordFormPresenter, String?>`
- **Dependencias:** `ref.watch(forgotPasswordScreenPresenterProvider(initialErrorCode))`

- **Localizacao:** `lib/ui/auth/widgets/pages/check_email_screen/check_email_screen_presenter.dart` (**novo arquivo**)
- **Nome do provider:** `checkEmailScreenPresenterProvider`
- **Tipo:** `Provider.autoDispose.family<CheckEmailScreenPresenter, String>`
- **Dependencias:** `ref.watch(authServiceProvider)`

- **Localizacao:** `lib/ui/auth/widgets/pages/new_password_screen/new_password_screen_presenter.dart` (**novo arquivo**)
- **Nome do provider:** `newPasswordScreenPresenterProvider`
- **Tipo:** `Provider.autoDispose.family<NewPasswordScreenPresenter, String>`
- **Dependencias:** `ref.watch(authServiceProvider)`, `ref.watch(navigationDriverProvider)`

- **Localizacao:** `lib/ui/auth/widgets/pages/new_password_screen/new_password_form/new_password_form_presenter.dart` (**novo arquivo**)
- **Nome do provider:** `newPasswordFormPresenterProvider`
- **Tipo:** `Provider.autoDispose.family<NewPasswordFormPresenter, String>`
- **Dependencias:** `ref.watch(newPasswordScreenPresenterProvider(accountId))`

## Estrutura de Pastas

```text
lib/core/auth/interfaces/
  auth_service.dart
  password_reset_link_driver.dart

lib/drivers/password-reset-link-driver/
  index.dart
  app_links/
    app_links_password_reset_link_driver.dart

lib/ui/auth/widgets/components/
  password_reset_link_listener/
    index.dart
    password_reset_link_listener_view.dart
    password_reset_link_listener_presenter.dart

lib/ui/auth/widgets/pages/
  forgot_password_screen/
    index.dart
    forgot_password_screen_view.dart
    forgot_password_screen_presenter.dart
    forgot_password_form/
      index.dart
      forgot_password_form_view.dart
      forgot_password_form_presenter.dart
      forgot_password_submit_button/
        index.dart
        forgot_password_submit_button_view.dart
      remembered_sign_in_hint/
        index.dart
        remembered_sign_in_hint_view.dart
  check_email_screen/
    index.dart
    check_email_screen_view.dart
    check_email_screen_presenter.dart
  new_password_screen/
    index.dart
    new_password_screen_view.dart
    new_password_screen_presenter.dart
    new_password_form/
      index.dart
      new_password_form_view.dart
      new_password_form_presenter.dart
      reset_password_submit_button/
        index.dart
        reset_password_submit_button_view.dart
```

---

# 6. O que deve ser modificado?

## Camada Core

- **Arquivo:** `lib/core/auth/interfaces/auth_service.dart`
- **Mudanca:** adicionar os contratos:
  - `Future<RestResponse<void>> forgotPassword({required String email})`
  - `Future<RestResponse<String>> verifyResetToken({required String token})`
  - `Future<RestResponse<void>> resetPassword({required String accountId, required String newPassword})`
- **Justificativa:** a UI precisa consumir o fluxo de reset de senha exclusivamente via port do `core`, sem acessar `RestClient` diretamente.

## Camada REST

- **Arquivo:** `lib/rest/services/auth_rest_service.dart`
- **Mudanca:** implementar `forgotPassword(...)` com `POST /auth/password/forgot`, `verifyResetToken(...)` com `POST /auth/password/verify-reset-token` e `resetPassword(...)` com `POST /auth/password/reset`.
- **Justificativa:** o fluxo de password reset pertence ao mesmo agregado remoto de autenticacao ja centralizado em `AuthRestService`.
- **Detalhamento funcional esperado no arquivo:**
  - `Future<RestResponse<void>> forgotPassword({required String email})` — envia payload inline `{ "email": email }` e devolve apenas status/error metadata.
  - `Future<RestResponse<String>> verifyResetToken({required String token})` — envia payload inline `{ "token": token }`, extrai `account_id` da resposta `200` e devolve `RestResponse<String>`.
  - `Future<RestResponse<void>> resetPassword({required String accountId, required String newPassword})` — envia payload inline `{ "account_id": accountId, "new_password": newPassword }` e devolve status tipado.

- **Arquivo:** `lib/rest/services/index.dart`
- **Mudanca:** manter `authServiceProvider` como fronteira publica, apenas garantindo que a instancia entregue suporte os tres novos metodos.
- **Justificativa:** preservar o mesmo padrao de composicao ja adotado no modulo `auth`.

## Camada UI

- **Arquivo:** `lib/ui/auth/widgets/pages/sign_in_screen/sign_in_screen_presenter.dart`
- **Mudanca:** adicionar `void goToForgotPassword()` navegando para `Routes.forgotPassword`.
- **Justificativa:** o CTA `Esqueceu a senha?` ja existe visualmente, mas ainda nao dispara fluxo funcional.

- **Arquivo:** `lib/ui/auth/widgets/pages/sign_in_screen/sign_in_form/sign_in_form_presenter.dart`
- **Mudanca:** expor `void goToForgotPassword()` delegando para o presenter de tela.
- **Justificativa:** a View do formulario deve continuar consumindo apenas o presenter interno.

- **Arquivo:** `lib/ui/auth/widgets/pages/sign_in_screen/sign_in_form/sign_in_form_view.dart`
- **Mudanca:** ligar `ForgotPasswordHint` ao handler do presenter e remover o uso puramente visual do componente.
- **Justificativa:** concluir a navegacao do fluxo a partir da tela ja existente de login.

- **Arquivo:** `lib/ui/auth/widgets/pages/sign_in_screen/sign_in_form/forgot_password_hint/forgot_password_hint_view.dart`
- **Mudanca:** receber `required VoidCallback onTap` e renderizar o texto como CTA clicavel.
- **Justificativa:** o componente atual e apenas texto estatico e nao atende a task `ANI-42`.

- **Arquivo:** `lib/app.dart`
- **Mudanca:** envolver o `child` do `MaterialApp.router` com `PasswordResetLinkListener` via propriedade `builder`.
- **Justificativa:** o listener do deep link precisa viver no nivel da app para capturar link inicial e links recebidos com o app aberto, sem acoplar esse ciclo de vida a uma tela especifica.

- **Arquivo:** `lib/router.dart`
- **Mudanca:** registrar as rotas de `forgotPassword`, `checkEmail` e `newPassword`, incluindo guards para query params obrigatorios (`email`, `accountId`).
- **Justificativa:** o fluxo depende de navegacao explicita entre tres telas novas e de parametrizacao segura por query string.

- **Arquivo:** `lib/constants/routes.dart`
- **Mudanca:** adicionar as constantes `forgotPassword`, `checkEmail`, `newPassword` e os helpers:
  - `String getForgotPassword({String? errorCode})`
  - `String getCheckEmail({required String email})`
  - `String getNewPassword({required String accountId})`
- **Justificativa:** evitar montagem manual de URIs em presenters e no listener de deep link.

## App / Plataforma

- **Arquivo:** `pubspec.yaml`
- **Mudanca:** adicionar a dependencia `app_links`.
- **Justificativa:** a codebase atual nao possui pacote para escutar custom schemes; a task exige suporte a `animus://reset-password`.

- **Arquivo:** `android/app/src/main/AndroidManifest.xml`
- **Mudanca:** adicionar `intent-filter` na `MainActivity` para `scheme="animus"` e `host="reset-password"`.
- **Justificativa:** o Android precisa reconhecer o custom scheme e encaminha-lo para a app.

- **Arquivo:** `ios/Runner/Info.plist`
- **Mudanca:** adicionar `CFBundleURLTypes` para registrar o scheme `animus`.
- **Justificativa:** o iOS precisa conhecer o custom scheme antes do `app_links` conseguir entregar a URI ao Flutter.

---

# 7. O que deve ser removido?

**Não aplicável**.

---

# 8. Decisoes Tecnicas e Trade-offs

## 8.1 Limitar a spec ao fluxo via `Sign In`

- **Decisao:** implementar nesta spec apenas o fluxo iniciado em `Sign In`, mantendo `new_password_screen` reutilizavel para futura entrada por Configuracoes.
- **Alternativas consideradas:** incluir ja o ponto de entrada `Alterar Senha` e criar um modulo de perfil/configuracoes nesta mesma task.
- **Motivo da escolha:** a codebase nao possui tela/modulo de Configuracoes/Perfil; expandir o escopo agora misturaria duas entregas sem evidencia estrutural suficiente.
- **Impactos / trade-offs:** a tela `new_password_screen` fica pronta para reuso futuro, mas a entrada via `Routes.profile` continua dependente de outra task.

## 8.2 Introduzir um driver de deep link especifico de `auth`

- **Decisao:** criar `PasswordResetLinkDriver` no `core/auth` e implementa-lo com `app_links` na camada `drivers`.
- **Alternativas consideradas:** consumir `AppLinks` diretamente na View; colocar parsing da URI dentro do `router.dart`.
- **Motivo da escolha:** o deep link e uma concern de infraestrutura e nao deve vazar pacote concreto nem parse de URI para a UI.
- **Impactos / trade-offs:** adiciona um contrato novo no `core`, mas preserva a arquitetura em camadas e deixa o fluxo testavel por mock do driver.

## 8.3 Escutar o deep link no nivel da app

- **Decisao:** montar `PasswordResetLinkListener` em `lib/app.dart`, envolvendo o `child` do `MaterialApp.router`.
- **Alternativas consideradas:** iniciar a escuta dentro de uma tela especifica; depender apenas de `GoRouter` para interpretar a URI externa.
- **Motivo da escolha:** o link precisa ser capturado mesmo quando o usuario estiver fora das telas de auth e tambem no cold start da aplicacao.
- **Impactos / trade-offs:** cria um componente app-scoped sem UI propria, mas evita comportamento intermitente por lifecycle de tela.

## 8.4 Reusar componentes ja existentes de `auth`

- **Decisao:** reutilizar `MessageBox` e `SignUpInputDecorationBuilder` em vez de abrir um refactor transversal para componentes compartilhados novos. **NAO** reutilizar `PasswordStrengthIndicatorView` porque o design de `Forgot - Nova Senha` usa um strength meter de 3 barras diferente do sign-up.
- **Alternativas consideradas:** mover agora todos esses elementos para `lib/ui/auth/widgets/components/` antes de implementar o fluxo.
- **Motivo da escolha:** a task principal e entregar o reset password; o reuso direto reduz churn e segue o padrao visual ja consolidado na codebase. O strength meter diverge visualmente do existente, entao sera implementado inline na View.
- **Impactos / trade-offs:** as novas telas passam a importar alguns artefatos localizados em pastas internas de outros fluxos, o que nao e ideal a longo prazo, mas reduz escopo imediato. O novo strength meter inline precisa ser mantido em sincronia com as regras de validacao do presenter.

## 8.5 Tratar qualquer falha de `verifyResetToken` como link invalido/expirado para a UX

- **Decisao:** qualquer `statusCode` diferente de `200` em `verifyResetToken` redireciona para `forgot_password_screen` com feedback generico de link invalido ou expirado.
- **Alternativas consideradas:** diferenciar mensagens por `statusCode`; exibir uma tela tecnica intermediaria de erro.
- **Motivo da escolha:** a task define um caminho unico de recuperacao para o usuario; a melhor UX e levá-lo de volta ao inicio do fluxo para pedir novo link.
- **Impactos / trade-offs:** simplifica a UI, mas perde granularidade caso o backend no futuro diferencie motivos de falha com semantica propria.

---

# 9. Diagramas e Referencias

- **Fluxo de dados:**

```text
SignInFormView
  -> SignInFormPresenter.goToForgotPassword()
  -> SignInScreenPresenter.goToForgotPassword()
  -> NavigationDriver.goTo(Routes.forgotPassword)

ForgotPasswordFormView
  -> ForgotPasswordFormPresenter.submit()
  -> ForgotPasswordScreenPresenter.submit()
  -> AuthService.forgotPassword(email)
      -> AuthRestService.forgotPassword(...)
      -> RestClient.post('/auth/password/forgot')
  -> [204] NavigationDriver.goTo(Routes.getCheckEmail(email))

CheckEmailScreenView
  -> CheckEmailScreenPresenter.resend()
  -> AuthService.forgotPassword(email)
      -> AuthRestService.forgotPassword(...)
      -> RestClient.post('/auth/password/forgot')
  -> [204] reinicia countdown 60s

PasswordResetLinkListenerView
  -> PasswordResetLinkListenerPresenter.start()
  -> PasswordResetLinkDriver.watchResetTokens()
      -> AppLinks.uriLinkStream
  -> PasswordResetLinkListenerPresenter.handleToken(token)
      -> AuthService.verifyResetToken(token)
          -> AuthRestService.verifyResetToken(...)
          -> RestClient.post('/auth/password/verify-reset-token')
  -> [200] NavigationDriver.goTo(Routes.getNewPassword(accountId))
  -> [falha] NavigationDriver.goTo(Routes.getForgotPassword(errorCode))

NewPasswordFormView
  -> NewPasswordFormPresenter.submit()
  -> NewPasswordScreenPresenter.submit()
  -> AuthService.resetPassword(accountId, newPassword)
      -> AuthRestService.resetPassword(...)
      -> RestClient.post('/auth/password/reset')
  -> [204] NavigationDriver.goTo(Routes.signIn)
  -> [falha] generalError
```

- **Hierarquia de widgets (validado no Pencil — nodes `a0rfv`, `i6r8t`, `82PSB`):**

```text
AnimusApp
  MaterialApp.router
    builder
      PasswordResetLinkListenerView
        Router child

ForgotPasswordScreenView (node: a0rfv)
  Scaffold
    SafeArea
      Center
        SingleChildScrollView
          Column (gap: 24, padding: [0, 24, 24, 24])
            NavBackRow(arrow_left + "Recuperar Senha")
            Icon Circle (lock_keyhole, 48px, amber, bg: #16161A, r: 40)
            Header Text
              "Esqueceu sua senha?" (Fraunces 22px)
              "Digite seu e-mail cadastrado..." (muted 14px)
            ForgotPasswordFormView
              EmailField (Icons.mail, placeholder "Email")
              MessageBox? (generalError)
              ForgotPasswordSubmitButtonView (gradient: #FBE26D->#C4A535, shadow)
              RememberedSignInHintView ("Lembrou?" + "Entrar" amber)

CheckEmailScreenView (node: i6r8t)
  Scaffold
    SafeArea
      Center
        SingleChildScrollView
          Column (gap: 24, padding: [0, 24, 24, 24])
            Icon Circle (mail_check, 48px, amber, bg: #16161A, r: 40)
            Header Text
              "Verifique seu E-mail" (Fraunces 22px)
              "Enviamos um link de recuperacao para $email..." (muted 14px)
            Resend Row
              "Nao recebeu?" + "Reenviar" (amber) | "Reenviar em SSs" (muted 12px)
            MessageBox? (feedback/error)

NewPasswordScreenView (node: 82PSB)
  Scaffold
    SafeArea
      Center
        SingleChildScrollView
          Column (gap: 24, padding: [0, 24, 24, 24])
            NavBackRow(arrow_left + "Nova Senha")
            Icon Circle (shield_check, 48px, amber, bg: #16161A, r: 40, stroke amber 20%)
            Header Text
              "Nova Senha" (Fraunces 22px)
              "Crie uma nova senha segura." (muted 14px)
            NewPasswordFormView
              NovaSenhaInput (Icons.lock + Icons.eye_off toggle, stroke amber 35%)
              StrengthMeter (3 bars: str1, str2, str3 | verde/amber)
              Requirements (8 caracteres | Letra maiuscula | Numero — cada um com Icons.check verde)
              ConfirmarSenhaInput (Icons.lock + Icons.eye_off toggle, stroke amber 35%)
              MessageBox? (generalError)
              ResetPasswordSubmitButtonView (gradient: #FBE26D->#C4A535, shadow)
```

- **Referencias:**
  - `lib/ui/auth/widgets/pages/sign_in_screen/sign_in_screen_presenter.dart` — referencia do padrao de presenter com `NavigationDriver`, `signals`, `FormGroup` e `AuthService`.
  - `lib/ui/auth/widgets/pages/sign_in_screen/sign_in_form/sign_in_form_presenter.dart` — referencia do presenter interno que apenas delega acoes e mensagens de validacao.
  - `lib/ui/auth/widgets/pages/email_confirmation_screen/email_confirmation_screen_presenter.dart` — referencia para countdown, `feedbackMessage`, `generalError` e bloqueio de CTA assicrono.
  - `lib/ui/auth/widgets/pages/email_confirmation_screen/message_box/message_box_view.dart` — referencia de feedback textual reutilizavel.
  - `lib/ui/auth/widgets/pages/sign_up_screen/sign_up_screen_presenter.dart` — referencia das regras de senha, `signals` derivados e submit com `reactive_forms`.
  - `lib/ui/auth/widgets/pages/sign_up_screen/password_strength_indicator/password_strength_indicator_view.dart` — referencia visual direta para o indicador de forca.
  - `lib/ui/auth/widgets/pages/sign_up_screen/sign_up_form/input_decoration/sign_up_input_decoration.dart` — referencia de `InputDecoration` alinhada ao visual atual de auth.
  - `lib/rest/services/auth_rest_service.dart` — implementacao REST a ser estendida com os endpoints de reset.
  - `lib/rest/dio/dio_rest_client.dart` — referencia de como preservar `statusCode`, `errorMessage` e `errorBody`.
  - `lib/router.dart` e `lib/constants/routes.dart` — pontos de extensao do roteamento do novo fluxo.
  - `android/app/src/main/AndroidManifest.xml` e `ios/Runner/Info.plist` — arquivos de plataforma que precisarao reconhecer o custom scheme.
  - Jira `ANI-42` — descreve as telas de `Recuperar Senha`, `Verifique seu E-mail` e `Nova Senha`, alem do deep link `animus://reset-password?token=...`.
- Pencil `design/animus.pen` — nodes `a0rfv` (Forgot - Email), `i6r8t` (Forgot - Codigo), `82PSB` (Forgot - Nova Senha) — hierarquia, textos, espacamento e composicao validados.

---

# 10. Pendencias / Duvidas

- **Descricao da pendencia (RESOLVIDA):** hierarquia visual validada no Pencil nos nodes `a0rfv` (Forgot - Email), `i6r8t` (Forgot - Codigo) e `82PSB` (Forgot - Nova Senha). Detalhes de espacamento (`gap: 24`, `padding: [0, 24, 24, 24]`), icones (`lock_keyhole`, `mail_check`, `shield_check`, `arrow_back`), textos e composicao ja incorporados na spec.

- **Descricao da pendencia (NOVA):** o `PasswordStrengthIndicatorView` existente em sign-up usa `RuleItem` por regra com checks visuais, mas o design de `Forgot - Nova Senha` define um strength meter de **3 barras horizontais** com score 1-3. A implementacao escolheu um indicador inline de 3 barras com cores verde/amber (score 1-2 = verde, score 3 = amber). Se o design evoluir para rules com checks como sign-up, sera necessario refatorar.
- **Impacto na implementacao:** o presenter `NewPasswordScreenPresenter` ja expõe `passwordStrengthScore` (1-3) com logica alinhada ao comportamento do meter; qualquer mudanca no design do meter exige revisao do presenter e da View.
- **Acao sugerida:** confirmar com design se o meter de 3 barras e a representacao final ou se sera migrado para rules com checks.

- **Descricao da pendencia:** `ANI-36` ainda aparece como dependencia critica do backend para estabilizar os contratos de `POST /auth/password/forgot`, `POST /auth/password/verify-reset-token` e `POST /auth/password/reset`.
- **Impacto na implementacao:** qualquer mudanca nos status codes ou no shape de sucesso de `verify-reset-token` (principalmente `account_id`) afeta diretamente o mapeamento do `AuthRestService` e o redirecionamento do listener.
- **Acao sugerida:** confirmar com backend, antes da implementacao, se `verify-reset-token` retorna exatamente `200 { account_id: string }` e se todos os demais cenarios de falha podem continuar sendo tratados como link invalido/expirado na UX mobile.

---

# Restricoes

- **Nao inclua testes automatizados na spec.**
- A `View` nao deve conter logica de negocio; toda orquestracao de formulario, deep link, countdown e navegacao fica no `Presenter`.
- Presenters nao fazem chamadas diretas a `RestClient`; consomem sempre `AuthService` e, no caso do listener, `PasswordResetLinkDriver`.
- Todos os caminhos citados acima existem no projeto ou estao explicitamente marcados como **novo arquivo**.
- Esta spec nao inclui o ponto de entrada por Configuracoes/Perfil; esse fluxo fica dependente de uma task futura para o modulo inexistente na codebase atual.
- Toda referencia a codigo existente usa caminho relativo real em `lib/...`, `android/...` ou `ios/...`.
- Toda widget com responsabilidade propria foi colocada em pasta propria com `index.dart` quando necessario.
- A UI deve permanecer em Flutter Material e alinhada ao tema escuro atual do projeto.
- A nomenclatura deve seguir a codebase: arquivos em `snake_case`, classes em `PascalCase`, providers e metodos em `camelCase`.
