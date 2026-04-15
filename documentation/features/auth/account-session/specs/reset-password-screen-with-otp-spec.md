---
title: Redefinicao de senha com verificacao OTP
prd: ../prd.md
ticket: https://joaogoliveiragarcia.atlassian.net/browse/ANI-71
status: open
last_updated_at: 2026-04-15
---

# 1. Objetivo

Esta spec define a refatoracao do fluxo de redefinicao de senha do modulo `auth` para substituir o modelo legado baseado em link/deep link por um fluxo baseado em `OTP`, mantendo a arquitetura em camadas do app. A entrega deve preservar a entrada via `forgot password`, evoluir a etapa intermediaria para verificacao do codigo enviado por e-mail, alterar o contrato final de reset para usar `resetContext` temporario em vez de `accountId`, e remover toda a infraestrutura mobile hoje dedicada a `animus://reset-password?token=...`.

---

# 2. Escopo

## 2.1 In-scope

- Manter a tela inicial de `forgot password` como porta de entrada do fluxo, com resposta neutra para existencia ou nao do e-mail.
- Refatorar a tela `check_email_screen` para virar a etapa de verificacao do `OTP` de reset, com campo de codigo, CTA de confirmacao, reenvio e countdown.
- Evoluir `AuthService` e `AuthRestService` para suportar `POST /auth/password/resend-reset-otp`, `POST /auth/password/verify-reset-otp` e `POST /auth/password/reset` com `reset_context`.
- Alterar `new_password_screen` para consumir `resetContext` temporario em vez de `accountId`.
- Ajustar `Routes`, `router.dart` e navegacao entre `forgot_password_screen`, `check_email_screen` e `new_password_screen`.
- Remover a infraestrutura legada de deep link de reset (`PasswordResetLinkDriver`, listener app-scoped e dependencia `app_links`).

## 2.2 Out-of-scope

- Alteracoes no fluxo de confirmacao de e-mail (`email_confirmation_screen`), exceto como referencia de UX e validacao de `OTP`.
- Mudancas em `sign up`, `sign in`, login com Google, expiracao de sessao ou logout, alem dos ajustes estritamente necessarios de navegacao.
- Compatibilidade retroativa com links antigos `animus://reset-password?token=...` apos a remocao do fluxo legado.
- Alteracoes de backend fora dos contratos ja descritos em `ANI-71`.

---

# 3. Requisitos

## 3.1 Funcionais

- O usuario deve continuar iniciando o fluxo por `Esqueceu a senha?`, informando apenas o `email`.
- Em `forgotPassword`, o app deve sempre prosseguir para a etapa seguinte sem revelar se a conta existe.
- A etapa seguinte deve orientar o usuario a informar um `OTP` numerico de 6 digitos recebido por e-mail.
- O app deve validar localmente `OTP` obrigatorio, numerico e com 6 digitos antes de chamar o backend.
- O usuario deve poder reenviar o `OTP` apenas apos o countdown do fluxo chegar a zero.
- Ao confirmar um `OTP` valido, o app deve chamar `AuthService.verifyResetPasswordOtp`, receber um `resetContext` temporario e navegar para `new_password_screen`.
- Se o `OTP` for invalido ou expirado, o usuario deve permanecer na mesma tela com feedback inline e opcao de reenviar quando permitido.
- A tela `new_password_screen` deve validar localmente `newPassword` e `confirmPassword` com as mesmas regras atuais de senha.
- Ao submeter a nova senha com dados validos, o app deve chamar `AuthService.resetPassword(resetContext, newPassword)`.
- Em reset bem-sucedido, o app deve voltar para `Routes.signIn`.
- Todos os CTAs remotos do fluxo devem bloquear duplo envio enquanto a requisicao correspondente estiver em voo.

## 3.2 Nao funcionais

- **Performance:** permitir apenas uma requisicao em voo por acao (`forgotPassword`, `resendResetPasswordOtp`, `verifyResetPasswordOtp`, `resetPassword`).
- **Acessibilidade:** o estado desabilitado dos CTAs deve continuar textual e visual; erros de `OTP` e senha devem ser exibidos em texto legivel.
- **Offline/Conectividade:** falhas de rede nao devem limpar o `email`, o `OTP` digitado ou as senhas do formulario atual.
- **Seguranca:** o app nao deve expor se o e-mail existe; nao deve persistir `OTP` nem `resetContext` em cache local; o fluxo final nao deve mais trafegar `accountId` vindo do cliente.
- **Compatibilidade:** a implementacao deve continuar usando `Riverpod`, `signals`, `reactive_forms`, `go_router`, `NavigationDriver` e `Dio`, removendo apenas a dependencia `app_links` do fluxo de reset.

---

# 4. O que ja existe?

## Camada Core

- **`AuthService`** (`lib/core/auth/interfaces/auth_service.dart`) — contrato atual ja cobre `forgotPassword`, `verifyResetToken` e `resetPassword`, mas ainda reflete o fluxo legado por token/account id.
- **`PasswordResetLinkDriver`** (`lib/core/auth/interfaces/password_reset_link_driver.dart`) — port legada usada exclusivamente para capturar deep links de reset; deve sair com a migracao para `OTP`.
- **`RestResponse`** (`lib/core/shared/responses/rest_response.dart`) — wrapper tipado ja usado pelos presenters para decidir navegacao, erro inline e feedback generico.
- **`NavigationDriver`** (`lib/core/shared/interfaces/navigation_driver.dart`) — contrato usado pelos presenters para navegar sem acoplamento direto a `GoRouter`.

## Camada REST

- **`AuthRestService`** (`lib/rest/services/auth_rest_service.dart`) — implementacao unica de `AuthService`; hoje chama `/auth/password/forgot`, `/auth/password/verify-reset-token` e `/auth/password/reset` com `account_id`.
- **`authServiceProvider`** (`lib/rest/services/index.dart`) — provider Riverpod que injeta `AuthService` nos presenters de `auth`.
- **`DioRestClient`** (`lib/rest/dio/dio_rest_client.dart`) — cliente HTTP concreto que ja encapsula payload, status code e `errorBody`.

## Camada Drivers

- **`AppLinksPasswordResetLinkDriver`** (`lib/drivers/password-reset-link-driver/app_links/app_links_password_reset_link_driver.dart`) — implementacao concreta legada do reset por deep link.
- **`passwordResetLinkDriverProvider`** (`lib/drivers/password-reset-link-driver/index.dart`) — provider da infraestrutura de deep link que deixara de ser necessaria.
- **`GoRouterNavigationDriver`** (`lib/drivers/navigation/go_router/go_router_navigation_driver.dart`) — driver de navegacao que continuara sendo usado pelos presenters.

## Camada UI

- **`ForgotPasswordScreenPresenter`** (`lib/ui/auth/widgets/pages/forgot_password_screen/forgot_password_screen_presenter.dart`) — ja orquestra o formulario de e-mail e navega para `Routes.getCheckEmail(email: ...)` em sucesso.
- **`ForgotPasswordFormPresenter`** (`lib/ui/auth/widgets/pages/forgot_password_screen/forgot_password_form/forgot_password_form_presenter.dart`) — proxy atual do formulario de `forgot password`.
- **`CheckEmailScreenPresenter`** (`lib/ui/auth/widgets/pages/check_email_screen/check_email_screen_presenter.dart`) — hoje implementa apenas feedback de envio e reenvio com countdown; e o ponto mais direto para evoluir para verificacao de `OTP`.
- **`NewPasswordScreenPresenter`** (`lib/ui/auth/widgets/pages/new_password_screen/new_password_screen_presenter.dart`) — ja concentra regras de senha, visibilidade dos campos e submissao final, mas ainda depende de `accountId`.
- **`EmailConfirmationScreenPresenter`** (`lib/ui/auth/widgets/pages/email_confirmation_screen/email_confirmation_screen_presenter.dart`) — referencia pronta para validacao local de `OTP`, erro inline por campo, `OtpTextField` e reenvio controlado.
- **`MessageBoxView`** (`lib/ui/auth/widgets/pages/email_confirmation_screen/message_box/message_box_view.dart`) — componente de feedback reutilizavel ja usado nos fluxos atuais de auth.
- **`SignUpInputDecorationBuilder`** (`lib/ui/auth/widgets/pages/sign_up_screen/sign_up_form/input_decoration/sign_up_input_decoration.dart`) — helper visual reutilizado pelos formularios de auth.
- **`PasswordResetLinkListenerView`** (`lib/ui/auth/widgets/components/password_reset_link_listener/password_reset_link_listener_view.dart`) — wrapper app-scoped legado que observa tokens de deep link; deve ser removido.
- **`SignInScreenPresenter`** (`lib/ui/auth/widgets/pages/sign_in_screen/sign_in_screen_presenter.dart`) — dispara a navegacao para `forgot password` a partir do login.
- **`ProfileScreenPresenter`** (`lib/ui/auth/widgets/pages/profile_screen/profile_screen_presenter.dart`) — tambem abre `forgot password` a partir do perfil, reaproveitando o mesmo fluxo.

## App / Router

- **`Routes`** (`lib/constants/routes.dart`) — ja concentra `forgotPassword`, `checkEmail` e `newPassword`, mas ainda aceita `errorCode` legado e `accountId` no passo final.
- **`appRouter`** (`lib/router.dart`) — hoje trata as tres rotas publicas do reset e valida `accountId` na rota `newPassword`.
- **`AnimusApp`** (`lib/app.dart`) — registra o listener global de deep link no `builder` do `MaterialApp.router`.

## Lacunas relevantes

- O PRD local e o PRD do Confluence ainda descrevem reset por link/deep link, nao por `OTP`.
- Nao existe hoje no mobile um contrato para `resendResetPasswordOtp` nem para `verifyResetPasswordOtp`.
- Nao existe DTO de `resetContext` no mobile, e tambem nao ha evidencia de que esse payload precise de mais de um campo alem da string temporaria.

---

# 5. O que deve ser criado?

**Nao aplicavel.** A implementacao deve reutilizar a estrutura atual de `forgot_password_screen`, `check_email_screen` e `new_password_screen`, evoluindo contratos e removendo a infraestrutura legada de deep link sem introduzir novas pastas ou widgets obrigatorios.

---

# 6. O que deve ser modificado?

## Camada Core

- **Arquivo:** `lib/core/auth/interfaces/auth_service.dart`
- **Mudanca:** substituir `Future<RestResponse<String>> verifyResetToken({required String token})` por `Future<RestResponse<String>> verifyResetPasswordOtp({required String email, required String otp})`.
- **Justificativa:** o backend deixa de validar token vindo de deep link e passa a validar `OTP` com `email`.

- **Arquivo:** `lib/core/auth/interfaces/auth_service.dart`
- **Mudanca:** adicionar `Future<RestResponse<void>> resendResetPasswordOtp({required String email})`.
- **Justificativa:** o ticket `ANI-71` introduz um endpoint dedicado de reenvio com cooldown proprio.

- **Arquivo:** `lib/core/auth/interfaces/auth_service.dart`
- **Mudanca:** alterar `Future<RestResponse<void>> resetPassword({required String accountId, required String newPassword})` para `Future<RestResponse<void>> resetPassword({required String resetContext, required String newPassword})`.
- **Justificativa:** o passo final deixa de confiar em `accountId` vindo do cliente e passa a usar contexto temporario emitido apos validar o `OTP`.

## Camada REST

- **Arquivo:** `lib/rest/services/auth_rest_service.dart`
- **Mudanca:** manter `forgotPassword({required String email})` em `POST /auth/password/forgot`, sem alterar a semantica de resposta neutra.
- **Justificativa:** a entrada do fluxo continua a mesma no contrato de produto e no ticket tecnico.

- **Arquivo:** `lib/rest/services/auth_rest_service.dart`
- **Mudanca:** implementar `resendResetPasswordOtp({required String email})` chamando `POST /auth/password/resend-reset-otp` com payload `{ 'email': email }` e retorno `RestResponse<void>`.
- **Justificativa:** separar o reenvio do endpoint inicial alinha o app ao backend novo e evita continuar mascarando reenvio como `forgotPassword`.

- **Arquivo:** `lib/rest/services/auth_rest_service.dart`
- **Mudanca:** implementar `verifyResetPasswordOtp({required String email, required String otp})` chamando `POST /auth/password/verify-reset-otp` com payload `{ 'email': email, 'otp': otp }`, parseando `reset_context` do body para `RestResponse<String>`.
- **Justificativa:** o app precisa receber o contexto temporario para abrir a etapa de nova senha sem conhecer `accountId`.

- **Arquivo:** `lib/rest/services/auth_rest_service.dart`
- **Mudanca:** alterar `resetPassword(...)` para enviar `{ 'reset_context': resetContext, 'new_password': newPassword }` em `POST /auth/password/reset`.
- **Justificativa:** adequar o payload final ao novo contrato do backend.

## Camada UI

- **Arquivo:** `lib/ui/auth/widgets/pages/forgot_password_screen/forgot_password_screen_presenter.dart`
- **Mudanca:** remover a dependencia de `initialErrorCode` legado e manter apenas o contexto de volta (`previousRoute`), preservando `submit()`, `goBack()` e `goToSignIn()`.
- **Justificativa:** o fluxo por `OTP` nao depende mais de redirecionamento por link invalido via query string.

- **Arquivo:** `lib/ui/auth/widgets/pages/forgot_password_screen/forgot_password_screen_view.dart`
- **Mudanca:** atualizar a copy da tela para explicar envio de `OTP` por e-mail em vez de envio de link.
- **Justificativa:** alinhar a jornada visual ao fluxo novo sem alterar a estrutura do widget.

- **Arquivo:** `lib/ui/auth/widgets/pages/forgot_password_screen/forgot_password_form/forgot_password_form_presenter.dart`
- **Mudanca:** simplificar a family/provider para os parametros ainda usados pelo screen presenter e manter o formulario de `email` inalterado.
- **Justificativa:** a view continua igual em estrutura, mas o provider nao precisa mais trafegar `errorCode` legado.

- **Arquivo:** `lib/ui/auth/widgets/pages/forgot_password_screen/forgot_password_form/forgot_password_form_view.dart`
- **Mudanca:** manter o formulario de e-mail e CTA principal, sem criar novos widgets internos.
- **Justificativa:** a mudanca funcional acontece apos o envio bem-sucedido, nao na tela inicial.

- **Arquivo:** `lib/ui/auth/widgets/pages/check_email_screen/check_email_screen_presenter.dart`
- **Mudanca:** evoluir o presenter para conter `FormGroup` com `otp`, `Signal<bool> isVerifying`, `Signal<bool> isResending`, `Signal<int> resendCountdown`, `Signal<String?> generalError`, `Signal<String?> feedbackMessage`, getter `FormControl<String> otpControl`, getter de mensagens de validacao e metodos `Future<void> verifyOtp()`, `Future<void> resendResetOtp()`, `String? otpErrorMessage()` e `void dispose()`.
- **Justificativa:** esta tela passa a ser a etapa principal de verificacao do `OTP`, concentrando validacao local, reenvio e navegacao para a nova senha.

- **Arquivo:** `lib/ui/auth/widgets/pages/check_email_screen/check_email_screen_view.dart`
- **Mudanca:** substituir a tela passiva de confirmacao por uma tela com `OtpTextField`, CTA de confirmacao, erros inline de `OTP`, feedback de reenvio e countdown visual.
- **Justificativa:** o usuario agora precisa concluir a verificacao do codigo dentro do app antes de chegar ao formulario de nova senha.

- **Arquivo:** `lib/ui/auth/widgets/pages/new_password_screen/new_password_screen_presenter.dart`
- **Mudanca:** trocar a dependencia publica de `accountId` por `resetContext`, mantendo as regras atuais de senha, toggles de visibilidade, `passwordStrengthScore`, `canSubmit` e `submit()`.
- **Justificativa:** a tela continua reaproveitavel quase inteira; apenas o identificador do fluxo muda para o contexto temporario seguro.

- **Arquivo:** `lib/ui/auth/widgets/pages/new_password_screen/new_password_screen_view.dart`
- **Mudanca:** atualizar a prop obrigatoria para `resetContext` e repassar esse valor ao formulario.
- **Justificativa:** alinhar a view ao novo contrato de navegacao e ao presenter.

- **Arquivo:** `lib/ui/auth/widgets/pages/new_password_screen/new_password_form/new_password_form_presenter.dart`
- **Mudanca:** atualizar a family/provider para receber `resetContext` e continuar expondo os mesmos getters e handlers da tela.
- **Justificativa:** preservar a separacao MVP do formulario sem duplicar logica.

- **Arquivo:** `lib/ui/auth/widgets/pages/new_password_screen/new_password_form/new_password_form_view.dart`
- **Mudanca:** atualizar a prop obrigatoria para `resetContext`, sem alterar a composicao visual atual do form.
- **Justificativa:** o formulario continua o mesmo do ponto de vista de UX.

- **Arquivo:** `lib/ui/auth/widgets/pages/sign_in_screen/sign_in_screen_presenter.dart`
- **Mudanca:** ajustar `goToForgotPassword()` para usar a assinatura atualizada de `Routes.getForgotPassword(...)`.
- **Justificativa:** o ponto de entrada continua existindo e precisa permanecer funcional apos a limpeza do parametro legado.

- **Arquivo:** `lib/ui/auth/widgets/pages/profile_screen/profile_screen_presenter.dart`
- **Mudanca:** ajustar `goToForgotPassword()` para a assinatura atualizada de `Routes.getForgotPassword(...)`.
- **Justificativa:** o perfil continua oferecendo a mesma entrada para o fluxo de reset.

## App / Router

- **Arquivo:** `lib/constants/routes.dart`
- **Mudanca:** remover `errorCode` de `getForgotPassword(...)` e alterar `getNewPassword({required String accountId})` para `getNewPassword({required String resetContext})`.
- **Justificativa:** o roteamento deixa de carregar semantica de link invalido e passa a trafegar o contexto emitido apos o `OTP`.

- **Arquivo:** `lib/router.dart`
- **Mudanca:** manter `forgotPassword`, `checkEmail` e `newPassword` como rotas publicas, mas ajustar a validacao da rota final para exigir `resetContext` em vez de `accountId`.
- **Justificativa:** a navegacao do fluxo continua publica, mas o parametro necessario mudou.

- **Arquivo:** `lib/app.dart`
- **Mudanca:** remover o wrapper `PasswordResetLinkListener` do `builder` do `MaterialApp.router`.
- **Justificativa:** o app nao dependera mais de observar deep links para reset de senha.

- **Arquivo:** `pubspec.yaml`
- **Mudanca:** remover a dependencia `app_links` se ela nao tiver outro uso no projeto.
- **Justificativa:** apos eliminar o fluxo por deep link, a dependencia fica sem consumidor conhecido na codebase.

---

# 7. O que deve ser removido?

## Camada Core

- **Arquivo:** `lib/core/auth/interfaces/password_reset_link_driver.dart`
- **Motivo da remocao:** o fluxo `OTP` nao depende mais de captura de link externo.
- **Impacto esperado:** remover imports e providers associados na camada UI e drivers.

## Camada Drivers

- **Arquivo:** `lib/drivers/password-reset-link-driver/index.dart`
- **Motivo da remocao:** provider legado sem uso apos a retirada do reset por deep link.
- **Impacto esperado:** `PasswordResetLinkListenerPresenter` deixa de compor esse provider.

- **Arquivo:** `lib/drivers/password-reset-link-driver/app_links/app_links_password_reset_link_driver.dart`
- **Motivo da remocao:** implementacao concreta acoplada a `app_links` deixa de ter responsabilidade no app.
- **Impacto esperado:** `pubspec.yaml` pode remover `app_links` se nao houver outro uso.

## Camada UI

- **Arquivo:** `lib/ui/auth/widgets/components/password_reset_link_listener/index.dart`
- **Motivo da remocao:** barrel legado de um componente app-scoped que nao sera mais montado.
- **Impacto esperado:** `lib/app.dart` deixa de importar o componente.

- **Arquivo:** `lib/ui/auth/widgets/components/password_reset_link_listener/password_reset_link_listener_view.dart`
- **Motivo da remocao:** a app nao observara mais streams de token de reset.
- **Impacto esperado:** simplificacao do `builder` do `MaterialApp.router`.

- **Arquivo:** `lib/ui/auth/widgets/components/password_reset_link_listener/password_reset_link_listener_presenter.dart`
- **Motivo da remocao:** orquestracao legada de `verifyResetToken` e navegacao por deep link fica obsoleta.
- **Impacto esperado:** remove o ultimo consumidor de `PasswordResetLinkDriver` e `verifyResetToken` na UI.

## App / Router

- **Arquivo:** `lib/app.dart`
- **Motivo da remocao:** retirada do acoplamento global ao reset por deep link.
- **Impacto esperado:** app sobe sem listener extra no `builder`.

> Nao ha remocao de telas do fluxo. A limpeza e restrita a infraestrutura legada de deep link.

---

# 8. Decisoes Tecnicas e Trade-offs

- **Decisao:** reutilizar `check_email_screen` como etapa de verificacao do `OTP`, em vez de criar uma nova `reset_password_otp_screen`.
- **Alternativas consideradas:** criar uma pasta/tela nova para separar semanticamente o fluxo; renomear a pasta existente.
- **Motivo da escolha:** a tela ja ocupa exatamente a etapa intermediaria do reset, ja recebe `email` por rota e ja possui countdown/reenvio; a refatoracao minimiza churn estrutural.
- **Impactos / trade-offs:** o nome da pasta/rota continua mais generico que a responsabilidade final, mas evita renomeacao ampla de imports, barrels e rotas.

- **Decisao:** remover completamente a infraestrutura de deep link de reset, sem camada de compatibilidade temporaria.
- **Alternativas consideradas:** manter listener e endpoint legado por algum tempo; tratar links antigos com redirecionamento para `forgot password`.
- **Motivo da escolha:** `ANI-71` descreve a substituicao completa do fluxo legado e a remocao do endpoint antigo; manter compatibilidade adicionaria complexidade sem evidencia de necessidade ativa no mobile.
- **Impactos / trade-offs:** links antigos deixam de ser suportados pelo app; em contrapartida o fluxo fica mais simples, seguro e sem dependencia de infraestrutura nativa de link.

- **Decisao:** representar o retorno de `verifyResetPasswordOtp` como `RestResponse<String>` com `resetContext`, sem criar DTO novo.
- **Alternativas consideradas:** criar `ResetPasswordContextDto` em `lib/core/auth/dtos/`.
- **Motivo da escolha:** a evidencia atual aponta para um payload minimo contendo apenas o contexto temporario; um DTO novo acrescentaria estrutura sem ganho claro.
- **Impactos / trade-offs:** se o backend passar a devolver metadados extras no futuro, sera necessario introduzir DTO nessa evolucao.

- **Decisao:** espelhar na etapa de reset com `OTP` o mesmo padrao de validacao local e UX ja usado em `email_confirmation_screen`.
- **Alternativas consideradas:** usar `ReactiveTextField` simples para o codigo; criar componente de `OTP` separado para o reset.
- **Motivo da escolha:** a codebase ja possui referencia consistente com `OtpTextField`, erro inline por campo e CTA de reenvio; isso reduz ambiguidade de implementacao.
- **Impactos / trade-offs:** o fluxo de reset passa a depender do mesmo pacote e do mesmo estilo visual do fluxo de confirmacao de e-mail, o que aumenta consistencia e reduz liberdade de UX pontual.

---

# 9. Diagramas e Referencias

- **Fluxo de dados:**

```text
ForgotPasswordScreenView
  -> ForgotPasswordScreenPresenter
  -> AuthService.forgotPassword(email)
  -> AuthRestService.forgotPassword
  -> RestClient.post('/auth/password/forgot')
  -> API
  -> Routes.getCheckEmail(email)

CheckEmailScreenView
  -> CheckEmailScreenPresenter.verifyOtp()
  -> AuthService.verifyResetPasswordOtp(email, otp)
  -> AuthRestService.verifyResetPasswordOtp
  -> RestClient.post('/auth/password/verify-reset-otp')
  -> API
  -> RestResponse<String>(resetContext)
  -> Routes.getNewPassword(resetContext)

NewPasswordScreenView
  -> NewPasswordScreenPresenter.submit()
  -> AuthService.resetPassword(resetContext, newPassword)
  -> AuthRestService.resetPassword
  -> RestClient.post('/auth/password/reset')
  -> API
  -> Routes.signIn
```

- **Hierarquia de widgets:**

```text
forgot_password_screen/
  forgot_password_screen_view.dart
    NavBackRow
    ForgotPasswordForm
      ReactiveTextField(email)
      MessageBox (erro opcional)
      ForgotPasswordSubmitButton
      RememberedSignInHint

check_email_screen/
  check_email_screen_view.dart
    Header iconografico
    Texto com email dinamico
    OtpTextField
    Texto de erro inline do OTP
    Botao "Confirmar codigo"
    Linha de reenvio com countdown
    MessageBox (feedback / erro geral)

new_password_screen/
  new_password_screen_view.dart
    NavBackRow
    NewPasswordForm
      ReactiveTextField(newPassword)
      Barra de forca (3 segmentos)
      PasswordRuleRow x3
      ReactiveTextField(confirmPassword)
      MessageBox (erro opcional)
      ResetPasswordSubmitButton
```

- **Referencias:**

`lib/ui/auth/widgets/pages/email_confirmation_screen/email_confirmation_screen_presenter.dart`

`lib/ui/auth/widgets/pages/email_confirmation_screen/email_confirmation_screen_view.dart`

`lib/ui/auth/widgets/pages/forgot_password_screen/forgot_password_screen_presenter.dart`

`lib/ui/auth/widgets/pages/check_email_screen/check_email_screen_presenter.dart`

`lib/ui/auth/widgets/pages/new_password_screen/new_password_screen_presenter.dart`

`lib/rest/services/auth_rest_service.dart`

`lib/core/auth/interfaces/auth_service.dart`

`lib/constants/routes.dart`

`lib/router.dart`

---

# 10. Pendencias / Duvidas

- **Descricao da pendencia:** o PRD local `documentation/features/auth/account-session/prd.md` e o PRD do Confluence `PRD - RF 01: Gerenciamento de sessao do usuario` ainda descrevem o fluxo legado por link/deep link, enquanto `ANI-71` especifica migracao completa para `OTP`.
- **Impacto na implementacao:** alto. A spec abaixo foi consolidada com `ANI-71` e com a codebase atual como fonte principal de verdade para contratos e estrutura, mas a documentacao de produto segue inconsistente.
- **Acao sugerida:** atualizar o PRD oficial para refletir o fluxo `OTP` e remover referencias a `animus://reset-password?token=...`.

- **Descricao da pendencia:** o ticket define que o reenvio deve respeitar o countdown "definido pelo produto", mas nao fixa o valor no requisito tecnico do backend.
- **Impacto na implementacao:** medio. A codebase atual de reset usa `60` segundos em `check_email_screen`, enquanto `email_confirmation_screen` usa `30` segundos para outro fluxo.
- **Acao sugerida:** manter `60` segundos para este fluxo por coerencia com a implementacao atual de reset e validar com produto se esse valor continua correto.

---

# Restricoes

- **Nao inclua testes automatizados na spec.**
- A `View` nao deve conter logica de negocio; toda orquestracao fica no `Presenter`.
- Presenters nao fazem chamadas diretas a `RestClient`; consomem sempre `AuthService` e `NavigationDriver` via providers.
- Todos os caminhos citados nesta spec existem no projeto ou estao explicitamente marcados para remocao.
- **Nao invente** DTOs, arquivos, contratos ou integracoes sem evidencia no ticket `ANI-71` ou na codebase atual.
- Quando faltar informacao de produto, registrar em **Pendencias / Duvidas** e alinhar o PRD oficial.
- Toda referencia a codigo existente inclui caminho relativo real em `lib/...`.
- Se uma secao nao se aplicar, preencher explicitamente com **Nao aplicavel**.
- A refatoracao deve continuar consistente com o padrao `MVP`, `Riverpod`, `signals`, `snake_case` para arquivos, `PascalCase` para classes e `index.dart` como barrel publico quando a pasta ja usa esse padrao.
