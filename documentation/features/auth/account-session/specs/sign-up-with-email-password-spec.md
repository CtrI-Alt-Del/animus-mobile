---
title: Sign Up com E-mail e Senha
prd: https://joaogoliveiragarcia.atlassian.net/wiki/x/AwACAQ
ticket: https://joaogoliveiragarcia.atlassian.net/browse/ANI-40
status: closed
last_updated_at: 2026-03-25
---

# 1. Objetivo

Esta spec define a implementação do fluxo de cadastro via e-mail e senha no `animus`, evoluindo o bootstrap atual de autenticação para um fluxo funcional com formulário reativo, indicador visual de força de senha, integração com `POST /auth/sign-up`, tratamento de erros inline e navegação para uma tela dedicada de confirmação de e-mail por OTP de 6 dígitos com opção de reenvio do código. A entrega precisa respeitar a arquitetura em camadas já prevista no projeto, introduzindo a primeira implementação concreta de `AuthService` na camada `rest` e alinhando a UI ao uso de Flutter Material, `Riverpod`, `signals` e `reactive_forms`.

---

# 2. Escopo

## 2.1 In-scope

- Refatorar `lib/ui/auth/widgets/pages/sign_up_screen/` para um fluxo MVP com `reactive_forms`, `signals`, `Riverpod` e componentes Flutter Material.
- Exibir campos de `name`, `email`, `password` e `confirmPassword` com validação client-side e mensagens inline.
- Manter checkbox de aceite de Termos de Uso e Politica de Privacidade como parte do formulario de cadastro.
- Exibir indicador visual de força de senha em tempo real com base nas três regras explícitas do produto: tamanho mínimo, presença de letra maiúscula e presença de número.
- Implementar o contrato `AuthService.signUp(...)` e sua primeira implementação REST usando `DioRestClient`.
- Implementar os contratos `AuthService.verifyEmail(...)` e `AuthService.resendVerificationEmail(...)` para suportar a confirmação por OTP no pós-cadastro.
- Criar a tela `email_confirmation_screen` com campo OTP e a rota correspondente para o estado pós-cadastro.
- Persistir os tokens da sessão em cache local após `verifyEmail` bem-sucedido usando `CacheDriver` + `SharedPreferences` com `CacheKeys`.
- Ajustar `RestResponse` e `DioRestClient` para preservar payload estruturado de erro, permitindo mapear erros de backend para a UI sem vazar `Json` cru para a View.
- Manter o bootstrap visual da app com Flutter Material no root (`app.dart` / `theme.dart`).

## 2.2 Out-of-scope

- Implementação do login via e-mail e senha.
- Implementação do login com Google.
- Logout e limpeza de sessão local.
- Redefinição de senha e edição de perfil.
- Alterações no backend, contratos HTTP fora de `sign-up` e `resend-verification-email`, ou automação de testes.

---

# 3. Requisitos

## 3.1 Funcionais

- O usuário deve conseguir preencher `name`, `email`, `password` e `confirmPassword` na tela de cadastro.
- O formulário deve exigir aceite explicito dos Termos de Uso e da Politica de Privacidade antes da submissao.
- O formulário deve validar localmente: nome obrigatório, e-mail em formato válido, senha com no mínimo 8 caracteres, ao menos 1 letra maiúscula e ao menos 1 número, além de confirmação de senha idêntica.
- A força da senha deve ser exibida em tempo real, sem depender de resposta do backend.
- Ao submeter com dados válidos, o app deve chamar `POST /auth/sign-up` com payload `{ "name", "email", "password" }`.
- Em `201`, o app deve redirecionar para a tela de confirmação de e-mail, exibindo o e-mail usado no cadastro, campo OTP de 6 dígitos, CTA de confirmação e CTA para reenvio do código.
- Em `409`, o app deve exibir erro inline no campo `email`.
- Em `422`, o app deve mapear erros estruturados do backend para os campos correspondentes sempre que houver chave reconhecível (`name`, `email`, `password`); quando não houver chave reconhecível, deve exibir `generalError`.
- Ao confirmar OTP válido em `POST /auth/verify-email`, o app deve finalizar a confirmação sem exigir novo cadastro.
- Após sucesso em `verifyEmail`, o app deve salvar `accessToken.value` e `refreshToken.value` em cache local via `CacheDriver` usando `CacheKeys.accessToken` e `CacheKeys.refreshToken` antes de navegar.
- Após salvar os tokens, o app deve aguardar um pequeno timer antes do redirecionamento para `Routes.home`.
- Quando o OTP for inválido ou expirado, o app deve exibir erro inline no campo OTP e manter opção de reenvio.
- Durante `signUp`, `verifyEmail` e `resendVerificationEmail`, o CTA correspondente deve ficar desabilitado e com feedback visual de carregamento.

## 3.2 Não funcionais

- **Performance:** cada CTA remoto (`signUp`, `verifyEmail` e `resendVerificationEmail`) deve permitir apenas uma requisição em voo por vez.
- **Acessibilidade:** labels e mensagens de erro devem ser textuais; o indicador de força de senha não pode depender apenas de cor.
- **Offline/Conectividade:** falhas de rede não podem limpar os campos já preenchidos; a tela deve permanecer no estado atual com `generalError` visível.
- **Segurança:** `password` e `confirmPassword` não devem ser persistidos fora do estado em memória do `FormGroup` do presenter; `AccountDto` não deve expor senha em texto puro.
- **Compatibilidade:** a integração remota deve continuar dependente de `ANIMUS_SERVER_APP_URL`, sem URL hardcoded, e a navegação deve continuar compatível com `go_router`.

---

# 4. O que já existe?

## Camada Core

- **`AuthService`** (`lib/core/auth/interfaces/auth_service.dart`) — contrato já expõe `signUp(...)`, `verifyEmail(...)` e `resendVerificationEmail(...)`; falta completar implementação REST para confirmação OTP.
- **`AccountDto`** (`lib/core/auth/dtos/account_dto.dart`) — DTO de conta já existente, mas com shape desalinhado do backend (`password` obrigatório e `isActive` sem evidência no domínio documentado).
- **`RestClient`** (`lib/core/shared/interfaces/rest_client.dart`) — contrato base para operações HTTP a ser reutilizado pelo service de autenticação.
- **`RestResponse`** (`lib/core/shared/responses/rest_response.dart`) — wrapper comum de sucesso/falha; hoje não preserva payload estruturado de erro, o que limita o mapeamento inline na UI.

## Camada REST

- **`DioRestClient`** (`lib/rest/dio/dio_rest_client.dart`) — implementação concreta de `RestClient` com `Dio`; será reutilizada como cliente base para `sign-up`.
- **`lib/rest/mappers/auth/`** — pasta já prevista, mas ainda sem mappers implementados.
- **`lib/rest/services/`** — pasta já prevista, mas ainda sem services implementados.

## Camada UI

- **`SignUpScreenView`** (`lib/ui/auth/widgets/pages/sign_up_screen/sign_up_screen_view.dart`) — primeira tela de auth do bootstrap; hoje usa `Material` direto, não integra backend e não contempla confirmação de senha nem pós-cadastro.
- **`SignUpScreenPresenter`** (`lib/ui/auth/widgets/pages/sign_up_screen/sign_up_screen_presenter.dart`) — presenter atual com `TextEditingController`, validações mínimas e `SnackBar` placeholder.
- **`SignUpScreen`** (`lib/ui/auth/widgets/pages/sign_up_screen/index.dart`) — barrel file existente e válido como referência de organização.

## App / Router

- **`Routes`** (`lib/constants/routes.dart`) — concentra caminhos conhecidos do app; ainda não possui rota para confirmação de e-mail.
- **`appRouter`** (`lib/router.dart`) — roteador atual com `GoRouter`; hoje registra apenas `Routes.signUp` e o redirect de `Routes.home`.
- **`Env`** (`lib/constants/env.dart`) — expõe `ANIMUS_SERVER_APP_URL`, que deve continuar sendo a origem do `baseUrl` HTTP.
- **`AnimusApp`** (`lib/app.dart`) e **`AppTheme`** (`lib/theme.dart`) — bootstrap visual atual em `MaterialApp.router`; devem permanecer como base visual da feature.

---

# 5. O que deve ser criado?

## Camada REST (Services)

- **Localização:** `lib/rest/services/auth_rest_service.dart` (**novo arquivo**)
- **Interface implementada:** `AuthService`
- **Dependências:** `RestClient`
- **Provider Riverpod:** `authServiceProvider`
- **Métodos:**
  - `Future<RestResponse<AccountDto>> signUp({required String name, required String email, required String password})` — envia `POST /auth/sign-up`, converte `201` em `AccountDto` e preserva `statusCode`, `errorMessage` e `errorBody` em falhas.
  - `Future<RestResponse<SessionDto>> verifyEmail({required String email, required String otp})` — envia `POST /auth/verify-email`, converte resposta de sucesso para `SessionDto` e preserva payload de erro estruturado em falhas de OTP.
  - `Future<RestResponse<void>> resendVerificationEmail({required String email})` — envia `POST /auth/resend-verification-email` e retorna o status tipado de reenvio sem expor payload cru.

## Camada REST (Mappers)

- **Localização:** `lib/rest/mappers/auth/account_mapper.dart` (**novo arquivo**)
- **Métodos:**
  - `AccountDto toDto(Map<String, dynamic> json)` — mapeia `id`, `name`, `email`, `is_verified` e `social_accounts` para `AccountDto`.
  - `SessionDto toDto(Map<String, dynamic> json)` em `session_mapper.dart` — mapeia `access_token` e `refresh_token` para `SessionDto`, convertendo cada token para `TokenDto` (`value`, `expiresAt`).
  - Payloads de request (`sign-up`, `verify-email`, `resend-verification-email`) devem ser montados diretamente no `AuthRestService` como `Map<String, dynamic>` inline do método.

## Camada Core (Cache)

- **Localização:** `lib/core/shared/interfaces/cache_driver.dart`
- **Contrato:**
  - `String? get(String key)`
  - `void set(String key, String value)`
  - `void delete(String key)`

## Camada Drivers (Cache)

- **Localização:** `lib/drivers/cache-driver/shared_preferences_cache_driver.dart` (**novo arquivo**)
- **Implementa:** `CacheDriver`
- **Detalhes:** usa `SharedPreferences` para implementar `get/set/delete` e persistir `CacheKeys.accessToken` e `CacheKeys.refreshToken`.

## Camada UI (Presenters)

- **Localização:** `lib/ui/auth/widgets/pages/email_confirmation_screen/email_confirmation_screen_presenter.dart` (**novo arquivo**)
- **Dependências injetadas:** `AuthService`
- **Estado (`signals`):**
  - Signals simples: `signal<bool> isResending`, `signal<bool> isVerifying`, `signal<String?> generalError`, `signal<String?> feedbackMessage`
  - Formulário: `FormGroup` com controle `otp` e validação de 6 dígitos numéricos.
  - Computeds: não aplicável
- **Provider Riverpod:** `emailConfirmationScreenPresenterProvider`
- **Métodos:**
  - `Future<void> verifyOtp(BuildContext context)` — valida formulário OTP, chama `AuthService.verifyEmail(...)`, salva `accessToken.value` e `refreshToken.value` em cache (`CacheKeys`) via `SharedPreferencesCacheDriver`, aguarda pequeno timer e só então navega para `Routes.home`.
  - `Future<void> resendVerificationEmail()` — dispara o reenvio do código OTP para o `email` recebido pela tela, controla loading e atualiza `feedbackMessage` ou `generalError`.

## Camada UI (Views)

- **Localização:** `lib/ui/auth/widgets/pages/email_confirmation_screen/email_confirmation_screen_view.dart` (**novo arquivo**)
- **Base class:** `ConsumerWidget`
- **Props:** `required String email`
- **Bibliotecas de UI:** `flutter_riverpod`, `signals_flutter`, `reactive_forms`
- **Estados visuais:**
  - `Content` — texto explicativo com o e-mail cadastrado, campo OTP de 6 dígitos e CTAs de confirmar/reenviar código.
  - `Loading` — botões de confirmar e reenvio desabilitados com indicador visual no CTA em execução.
  - `Error` — erro inline no campo OTP e alerta textual para erros gerais.

## Camada UI (Widgets Internos)

- **Localização:** `lib/ui/auth/widgets/pages/sign_up_screen/password_strength_indicator/` (**novo arquivo** em pasta nova)
- **Tipo:** View only
- **Props:** `required int score`, `required bool hasMinLength`, `required bool hasUppercaseLetter`, `required bool hasNumber`
- **Responsabilidade:** renderizar o indicador de força de senha com checklist das três regras explícitas do produto, sem conter lógica de negócio.
- **Widget interno obrigatório:** `lib/ui/auth/widgets/pages/sign_up_screen/password_strength_indicator/rule_item/rule_item_view.dart` para substituir qualquer classe privada local (`_RuleItem`).

- **Localização:** `lib/ui/auth/widgets/pages/sign_up_screen/sign_up_form/` (**novo arquivo** em pasta nova)
- **Tipo:** widget interno com presenter dedicado
- **Arquivos:** `sign_up_form_view.dart`, `sign_up_form_presenter.dart`, `index.dart`
- **Responsabilidade:** encapsular o formulário reativo de cadastro, incluindo checkbox de aceite dos termos, coordenar o estado visual do formulário e isolar a composição de campos/CTA da tela raiz `sign_up_screen`.

- **Localização:** `lib/ui/auth/widgets/pages/sign_up_screen/sign_up_form/general_error_alert/` e `lib/ui/auth/widgets/pages/sign_up_screen/sign_up_form/sign_up_submit_button/` (**novos arquivos** em pastas novas)
- **Tipo:** widgets internos do formulário
- **Responsabilidade:** separar feedback de erro geral e CTA de submissão em componentes com responsabilidade única, sem criar pasta intermediária `widgets/`.

- **Localização:** `lib/ui/auth/widgets/pages/sign_up_screen/top_progress_bar/` (**novo arquivo** em pasta nova)
- **Tipo:** view only
- **Arquivos:** `top_progress_bar_view.dart`, `index.dart`
- **Responsabilidade:** renderizar a barra visual superior de progresso da tela de cadastro como widget interno dedicado, substituindo classe privada local em `sign_up_screen_view.dart`.

## Camada UI (Barrel Files / `index.dart`)

- **Localização:** `lib/ui/auth/widgets/pages/email_confirmation_screen/index.dart` (**novo arquivo**)
- **`typedef` exportado:** `typedef EmailConfirmationScreen = EmailConfirmationScreenView`
- **Widgets internos exportados:** não aplicável
- **Localização:** `lib/ui/auth/widgets/pages/sign_up_screen/password_strength_indicator/index.dart` (**novo arquivo**)
- **`typedef` exportado:** `typedef PasswordStrengthIndicator = PasswordStrengthIndicatorView`
- **Widgets internos exportados:** não aplicável

## Camada UI (Providers Riverpod — se isolados)

- **Localização:** `lib/ui/auth/widgets/pages/email_confirmation_screen/email_confirmation_screen_presenter.dart` (**novo arquivo**)
- **Nome do provider:** `emailConfirmationScreenPresenterProvider`
- **Tipo:** `AutoDisposeProviderFamily<EmailConfirmationScreenPresenter, String>`
- **Dependências:** `ref.watch(authServiceProvider)`

## Rotas (`go_router`) — se aplicável

- **Localização:** `lib/router.dart` e `lib/constants/routes.dart`
- **Caminho da rota:** `Routes.emailConfirmation = '/auth/email_confirmation'`
- **Widget principal:** `EmailConfirmationScreen`
- **Guards / redirecionamentos:** se `state.uri.queryParameters['email']` estiver ausente ou vazio, redirecionar para `Routes.signUp`; a rota deve receber o e-mail por query string para suportar refresh e deep-link interno da própria app.

## Estrutura de Pastas

```text
lib/ui/auth/widgets/pages/
  sign_up_screen/
    index.dart
    sign_up_screen_view.dart
    sign_up_screen_presenter.dart
    password_strength_indicator/
      index.dart
      password_strength_indicator_view.dart
      rule_item/
        index.dart
        rule_item_view.dart
    top_progress_bar/
      index.dart
      top_progress_bar_view.dart
      sign_up_form/
        index.dart
        sign_up_form_view.dart
        sign_up_form_presenter.dart
        terms_label/
          index.dart
          terms_label_view.dart
      general_error_alert/
        index.dart
        general_error_alert_view.dart
      sign_up_submit_button/
        index.dart
        sign_up_submit_button_view.dart
  email_confirmation_screen/
    index.dart
    email_confirmation_screen_view.dart
    email_confirmation_screen_presenter.dart
```

---

# 6. O que deve ser modificado?

## App / Bootstrap

- **Arquivo:** `pubspec.yaml`
- **Mudança:** adicionar as dependências de `signals` e `reactive_forms` compatíveis com o SDK atual do projeto.
- **Justificativa:** a spec exige `signals` para estado local e `reactive_forms` para validação de formulários.

- **Arquivo:** `lib/app.dart`
- **Mudança:** manter `MaterialApp.router`, preservando `title` e `routerConfig`.
- **Justificativa:** o projeto deve usar Flutter Material como base de UI.

- **Arquivo:** `lib/theme.dart`
- **Mudança:** manter `ThemeData` Material e ajustar somente tokens visuais necessários para a feature.
- **Justificativa:** preservar consistência visual sem introduzir toolkit de UI externo.

- **Arquivo:** `lib/constants/routes.dart`
- **Mudança:** adicionar a constante `emailConfirmation` e o helper `String emailConfirmation({required String email})` para construir a rota com query string de forma centralizada.
- **Justificativa:** o presenter precisa navegar para a tela de confirmação sem montar URLs manualmente em múltiplos pontos.

- **Arquivo:** `lib/router.dart`
- **Mudança:** registrar a rota de confirmação de e-mail e extrair o parâmetro `email` da query string antes de construir `EmailConfirmationScreen`.
- **Justificativa:** o fluxo pós-cadastro precisa de uma rota explícita e segura, com redirect quando o parâmetro obrigatório estiver ausente.

## Camada Core

- **Arquivo:** `lib/core/auth/interfaces/auth_service.dart`
- **Mudança:** substituir o método placeholder atual pelos contratos:
  - `Future<RestResponse<AccountDto>> signUp({required String name, required String email, required String password})`
  - `Future<RestResponse<SessionDto>> verifyEmail({required String email, required String otp})`
  - `Future<RestResponse<void>> resendVerificationEmail({required String email})`
- **Justificativa:** o contrato atual não atende o PRD nem o ticket ANI-40 e não possui uso real na codebase.

- **Arquivo:** `lib/core/auth/dtos/account_dto.dart`
- **Mudança:** alinhar o DTO ao retorno esperado do backend, removendo a obrigatoriedade de `password`, removendo `isActive` e mantendo apenas campos com evidência no domínio (`id`, `name`, `email`, `isVerified`, `socialAccounts`).
- **Justificativa:** o backend de cadastro retorna `AccountDto`, mas senha em texto puro não deve existir no retorno do mobile e `isActive` não aparece no modelo de domínio documentado.

- **Arquivo:** `lib/core/shared/responses/rest_response.dart`
- **Mudança:** adicionar suporte a `Json? errorBody` e ajustar `mapBody` para propagar falhas preservando `statusCode`, `errorMessage` e `errorBody` em vez de lançar exceção imediatamente.
- **Justificativa:** o presenter precisa mapear erros estruturados de `409/422` para erros inline sem depender de parsing na View e sem perder metadados durante o mapeamento REST -> DTO.

- **Arquivo:** `lib/core/shared/interfaces/cache_driver.dart`
- **Mudança:** manter o contrato string-based (`get/set/delete`) e reutilizá-lo para persistência de tokens de sessão.
- **Justificativa:** preservar compatibilidade do contrato compartilhado e evitar acoplamento do Core a um DTO específico de sessão.

## Camada REST

- **Arquivo:** `lib/rest/dio/dio_rest_client.dart`
- **Mudança:** expor `restClientProvider`, configurar o `baseUrl` a partir de `Env.animusServerAppUrl` e popular `errorBody` quando a resposta de erro vier em `Json`.
- **Justificativa:** o primeiro service concreto de auth precisa receber `RestClient` via Riverpod e preservar o payload de erro do backend para a UI.

- **Arquivo:** `lib/rest/services/auth_rest_service.dart`
- **Mudança:** implementar `verifyEmail(...)` com `POST /auth/verify-email`, mapeando sucesso para `SessionDto` e preservando `errorBody` para erros de OTP.
- **Justificativa:** o PRD RF01 exige confirmação por OTP no pós-cadastro antes de liberar acesso.

- **Arquivo:** `lib/rest/mappers/auth/account_mapper.dart` e `lib/rest/mappers/auth/session_mapper.dart` (**novo arquivo**)
- **Mudança:** manter `AccountMapper` restrito a `toDto(...)`, manter `SessionMapper` para `SessionDto` e mover a serialização de request para `AuthRestService`.
- **Justificativa:** preservar coesão de mapper por DTO e evitar mapper dedicado para payload de request pontual.

## Camada Drivers

- **Arquivo:** `lib/drivers/cache-driver/shared_preferences_cache_driver.dart` (**novo arquivo**)
- **Mudança:** implementar `CacheDriver` com `SharedPreferences` para `get/set/delete` de `String` e uso de `CacheKeys` para tokens.
- **Justificativa:** garantir persistência local de sessão sem vazar SDK externo para fora da camada de infraestrutura.

## Camada UI

- **Arquivo:** `lib/ui/auth/widgets/pages/sign_up_screen/sign_up_screen_presenter.dart`
- **Mudança:** reescrever o presenter atual para o fluxo real de cadastro, removendo `TextEditingController`, adotando `reactive_forms` como source of truth do formulário e usando `signals` apenas para estado auxiliar e derivado de UI, com injeção de `AuthService`.
- **Justificativa:** o presenter atual só valida superficialmente e exibe `SnackBar` placeholder; a feature precisa de validação reativa estruturada, integração remota e navegação pós-sucesso.
- **Detalhamento funcional esperado no arquivo:**
  - Formulário `reactive_forms`: `FormGroup form` com controles `name`, `email`, `password`, `confirmPassword`
  - Validators por controle:
    - `name`: `Validators.required`
    - `email`: `Validators.required` + `Validators.email`
    - `password`: validator customizado para mínimo de 8 caracteres, 1 letra maiúscula e 1 número
    - `confirmPassword`: `Validators.required`
  - Validator de grupo: garantir que `password` e `confirmPassword` sejam idênticos
  - Signals simples: `generalError`, `isSubmitting`, `isPasswordVisible`, `isConfirmPasswordVisible`
  - Computeds: `hasMinLength`, `hasUppercaseLetter`, `hasNumber`, `passwordStrengthScore`, `canSubmit`
  - Provider Riverpod: `signUpScreenPresenterProvider`, com dependências `ref.watch(authServiceProvider)`
  - Métodos:
    - `FormControl<String> get nameControl` — expõe o controle tipado de nome para a View.
    - `FormControl<String> get emailControl` — expõe o controle tipado de e-mail para a View.
    - `FormControl<String> get passwordControl` — expõe o controle tipado de senha para a View.
    - `FormControl<String> get confirmPasswordControl` — expõe o controle tipado de confirmação para a View.
    - `void onPasswordChanged(String? value)` — recalcula força da senha e força a revalidação de `confirmPassword`.
    - `void togglePasswordVisibility()` — alterna a visibilidade do campo `password`.
    - `void toggleConfirmPasswordVisibility()` — alterna a visibilidade do campo `confirmPassword`.
    - `String? fieldErrorMessage(FormControl<Object?> control)` — traduz erros do `reactive_forms` e erros remotos para texto de UI.
    - `void applyServerFieldErrors(RestResponse<Object?> response)` — converte `409/422` em `setErrors(...)` nos controles corretos.
    - `Future<void> submit(BuildContext context)` — marca o formulário como touched, valida o `FormGroup`, chama `AuthService.signUp`, mapeia erros de backend para os controles/`generalError` e navega para `Routes.emailConfirmation(email: email)` em caso de `201`.

- **Arquivo:** `lib/ui/auth/widgets/pages/email_confirmation_screen/email_confirmation_screen_presenter.dart`
- **Mudança:** evoluir o presenter para suportar validação e confirmação de OTP (`verifyOtp`), persistir tokens em cache (`CacheKeys`) e aguardar pequeno delay antes da navegação para `home`.
- **Justificativa:** a tela pós-cadastro precisa concluir verificação e inicializar sessão local com transição visual estável antes de trocar de rota.

- **Arquivo:** `lib/ui/auth/widgets/pages/email_confirmation_screen/email_confirmation_screen_view.dart`
- **Mudança:** incluir campo OTP de 6 dígitos com erro inline e CTA principal de confirmação, mantendo CTA secundário de reenvio.
- **Justificativa:** alinhamento com regra de UI/UX do PRD RF01 para confirmação de e-mail por código OTP.

- **Arquivo:** `lib/ui/auth/widgets/pages/sign_up_screen/sign_up_screen_view.dart`
- **Mudança:** transformar a tela raiz em composição enxuta (barra superior + header + container), delegando a barra de progresso para o widget interno `TopProgressBar` e toda a árvore do formulário para o widget interno `SignUpForm`.
- **Justificativa:** reduz complexidade da tela principal e reforça o padrão de componentização por pasta da camada UI.
- **Detalhamento funcional esperado no arquivo:**
  - Base class: `StatelessWidget`
  - Responsabilidade: layout estrutural e sem lógica reativa de formulário.
  - Hierarquia principal: `Scaffold` -> `SafeArea` -> `Center` -> `SingleChildScrollView` -> `Card` -> header -> `SignUpForm`.

- **Arquivo:** `lib/ui/auth/widgets/pages/sign_up_screen/sign_up_form/sign_up_form_presenter.dart` (**novo arquivo**)
- **Mudança:** criar presenter interno para o formulário, consumindo o `signUpScreenPresenterProvider` como fonte de estado e ações do fluxo de cadastro.
- **Justificativa:** isola responsabilidades de apresentação do formulário sem duplicar regras de negócio do presenter de tela.
- **Regra adicional:** todas as mensagens de validação do formulário devem ser providas pelo presenter (`nameValidationMessages`, `emailValidationMessages`, `passwordValidationMessages`, `confirmPasswordValidationMessages`), sem mapas locais de validação na View.

- **Arquivo:** `lib/ui/auth/widgets/pages/sign_up_screen/sign_up_form/sign_up_form_view.dart` (**novo arquivo**)
- **Mudança:** mover os campos `reactive_forms`, `PasswordStrengthIndicator`, feedback de erro e CTA para um widget interno dedicado.
- **Justificativa:** encapsula o conteúdo reativo do formulário e facilita evolução incremental dos componentes internos.

- **Arquivo:** `lib/ui/auth/widgets/pages/sign_up_screen/sign_up_form/general_error_alert/general_error_alert_view.dart` (**novo arquivo**)
- **Mudança:** extrair alerta de erro geral para widget interno reutilizável dentro do formulário.
- **Justificativa:** remove blocos visuais privados da view principal e melhora legibilidade.

- **Arquivo:** `lib/ui/auth/widgets/pages/sign_up_screen/sign_up_form/sign_up_submit_button/sign_up_submit_button_view.dart` (**novo arquivo**)
- **Mudança:** extrair botão de submissão com loading para widget interno.
- **Justificativa:** separa variação de estado visual do CTA em unidade própria.

- **Arquivo:** `lib/ui/auth/widgets/pages/sign_up_screen/index.dart`
- **Mudança:** manter o barrel público com `typedef SignUpScreen = SignUpScreenView`, ajustando apenas imports se necessário.
- **Justificativa:** o padrão já está correto e deve permanecer como fronteira pública da pasta.

- **Arquivo:** `lib/ui/auth/widgets/pages/sign_up_screen/top_progress_bar/top_progress_bar_view.dart` (**novo arquivo**)
- **Mudança:** extrair a barra superior de progresso da tela para widget interno dedicado (`TopProgressBarView`), com barrel local em `top_progress_bar/index.dart`.
- **Justificativa:** evita classe privada de responsabilidade visual própria dentro da view raiz e mantém consistência com a regra de componentização por pasta.

---

# 7. O que deve ser removido?

## Camada Core

- **Arquivo:** `lib/core/auth/interfaces/auth_service.dart`
- **Motivo da remoção:** o método `isLoggedInWithCredentialsAndToken` é um placeholder sem uso e não corresponde a nenhum requisito do PRD ou do ticket.
- **Impacto esperado:** todos os consumers passam a depender de `signUp`, `verifyEmail` e `resendVerificationEmail`.

- **Arquivo:** `lib/core/auth/dtos/account_dto.dart`
- **Motivo da remoção:** os campos `password` e `isActive` não têm evidência no retorno do backend documentado para o mobile.
- **Impacto esperado:** o DTO fica compatível com o payload real e deixa de induzir uso incorreto de senha em texto puro na app.

---

# 8. Decisões Técnicas e Trade-offs

## 8.1 Preservar erro estruturado em `RestResponse`

- **Decisão:** evoluir `RestResponse` para carregar `errorBody` e propagar falhas durante `mapBody`.
- **Alternativas consideradas:** mapear erros apenas por `statusCode` e `errorMessage`; fazer parsing ad hoc dentro do presenter.
- **Motivo da escolha:** o requisito de erro inline por campo exige acesso ao payload estruturado do backend sem violar a fronteira entre `rest` e `ui`.
- **Impactos / trade-offs:** a mudança toca uma abstração compartilhada, mas cria uma base reaproveitável para futuros fluxos de auth (`signIn`, `forgotPassword`, `verifyEmail`).

## 8.2 Manter a navegação no presenter, sem criar `NavigationDriver` nesta etapa

- **Decisão:** `submit(BuildContext context)` navega com `GoRouter` diretamente na camada UI após sucesso.
- **Alternativas consideradas:** criar um `NavigationDriver` genérico agora; mover a navegação para a View observando um efeito.
- **Motivo da escolha:** a codebase ainda não possui drivers concretos, o ticket original aponta impacto principal em `ui` e a introdução de um driver genérico agora adicionaria churn arquitetural sem ganho proporcional para um único fluxo.
- **Impactos / trade-offs:** a navegação continua acoplada à camada UI por enquanto, mas a orquestração permanece no presenter e pode ser abstraída depois se mais fluxos de auth passarem a compartilhar navegação complexa.

## 8.3 Criar uma tela dedicada de confirmação OTP

- **Decisão:** criar `email_confirmation_screen` com campo OTP e CTA de confirmação em vez de exibir apenas um `dialog`, `snackbar` ou confirmação textual sem input.
- **Alternativas consideradas:** exibir confirmação inline na mesma tela; navegar direto para login com mensagem transitória.
- **Motivo da escolha:** o PRD exige digitação de OTP de 6 dígitos, tratamento de código inválido/expirado e opção de reenvio no pós-cadastro; uma tela dedicada é o formato mais estável para esse comportamento.
- **Impactos / trade-offs:** adiciona validação de formulário e nova chamada remota (`verifyEmail`) na tela de confirmação, mas mantém o fluxo explícito e preparado para evoluções de autenticação.

## 8.4 Usar query string para transportar o e-mail até a rota de confirmação

- **Decisão:** a rota de confirmação recebe `email` via query string, construída por `Routes.emailConfirmation(...)`.
- **Alternativas consideradas:** passar `email` em `state.extra`; armazenar o e-mail temporariamente em estado global.
- **Motivo da escolha:** query string sobrevive melhor a refresh e mantém o contrato da rota explícito no `router.dart`.
- **Impactos / trade-offs:** o `router` precisa validar a presença do parâmetro e redirecionar quando ele estiver ausente.

## 8.5 Manter Flutter Material como base de UI

- **Decisão:** manter `lib/app.dart` com `MaterialApp.router` e preservar `lib/theme.dart` no ecossistema Material.
- **Alternativas consideradas:** adotar toolkit de UI externo para a tela de auth.
- **Motivo da escolha:** diretriz atual do projeto: manter UI em Flutter Material.
- **Impactos / trade-offs:** reduz dependencias externas e simplifica manutencao visual no app.

---

# 9. Diagramas e Referências

## Fluxo de dados

```text
SignUpScreenView
  -> SignUpScreenPresenter.submit(context)
      -> AuthService.signUp(name, email, password)
          -> AuthRestService.signUp(...)
              -> payload Map inline no service
              -> RestClient.post('/auth/sign-up')
              -> AccountMapper.toDto(...)
      -> [201] GoRouter.go(Routes.emailConfirmation(email: email))
      -> [409/422/rede] atualiza erros do `FormGroup` ou `generalError`

EmailConfirmationScreenView
  -> EmailConfirmationScreenPresenter.verifyOtp(context)
      -> AuthService.verifyEmail(email, otp)
          -> AuthRestService.verifyEmail(...)
              -> payload Map inline no service
              -> RestClient.post('/auth/verify-email')
              -> SessionMapper.toDto(...)
      -> [sucesso] SharedPreferencesCacheDriver.set(CacheKeys.accessToken, session.accessToken.value)
      -> [sucesso] SharedPreferencesCacheDriver.set(CacheKeys.refreshToken, session.refreshToken.value)
      -> [sucesso] aguarda pequeno timer
      -> [sucesso] GoRouter.go(Routes.home)
      -> [otp inválido/expirado] erro inline no campo OTP
      -> [falha geral] generalError
  -> EmailConfirmationScreenPresenter.resendVerificationEmail()
      -> AuthService.resendVerificationEmail(email)
          -> AuthRestService.resendVerificationEmail(...)
              -> payload Map inline no service
              -> RestClient.post('/auth/resend-verification-email')
      -> [204] feedbackMessage
      -> [falha] generalError
```

## Hierarquia de widgets

```text
SignUpScreenView
  Scaffold
    SafeArea
      TopProgressBarView
      Center
        SingleChildScrollView
          Card
            Column
              Title
              Description
              SignUpFormView
                NameField
                EmailField
                PasswordField
                PasswordStrengthIndicator
                ConfirmPasswordField
                GeneralErrorAlertView?
                SignUpSubmitButtonView

EmailConfirmationScreenView
  Scaffold
    SafeArea
      Center
        Card
          Column
            Title
            Description(email)
            OtpField(6 digitos)
            FeedbackAlert?
            ErrorAlert?
            ConfirmOtpButton
            ResendButton
```

## Referências

- `lib/ui/auth/widgets/pages/sign_up_screen/sign_up_screen_view.dart` — referência direta do widget que será evoluído.
- `lib/ui/auth/widgets/pages/sign_up_screen/top_progress_bar/top_progress_bar_view.dart` — referência do widget interno responsável pela barra superior de progresso.
- `lib/ui/auth/widgets/pages/sign_up_screen/sign_up_screen_presenter.dart` — referência direta do presenter que será refatorado.
- `lib/ui/auth/widgets/pages/email_confirmation_screen/email_confirmation_screen_view.dart` — referência da tela de confirmação OTP no app.
- `lib/ui/auth/widgets/pages/email_confirmation_screen/email_confirmation_screen_presenter.dart` — referência do presenter responsável por `verifyEmail` e reenvio de OTP.
- `lib/ui/auth/widgets/pages/sign_up_screen/index.dart` — referência do padrão de barrel file já adotado no módulo.
- `lib/core/shared/interfaces/cache_driver.dart` — contrato de cache string-based reutilizado para persistência de tokens de sessão.
- `lib/core/shared/responses/rest_response.dart` — base para a evolução do wrapper de erro/sucesso.
- `lib/rest/dio/dio_rest_client.dart` — base para a primeira implementação concreta de `AuthService`.
- `lib/drivers/cache-driver/shared_preferences_cache_driver.dart` — implementação concreta de cache com `SharedPreferences`.
- `lib/constants/cache_keys.dart` — chaves de persistência de `accessToken` e `refreshToken`.
- `lib/constants/routes.dart` e `lib/router.dart` — pontos de entrada para a nova rota pós-cadastro.

### Design (Pencil)

- Tela de confirmação OTP: `design/animus.pen` (Node ID: `FD7WK`).

> Observação de contexto: no diagnóstico inicial desta feature não havia services REST de auth, mappers de auth nem outras telas de auth além do bootstrap de `sign_up_screen`; esta spec consolidou a introdução desses padrões no mobile.

---

# 10. Pendências / Dúvidas

- **Descrição da pendência:** o shape exato do payload de erro de `409/422` (sign-up) e de OTP inválido/expirado (`verify-email`) não está documentado no repositório mobile nem no ticket ANI-40.
- **Impacto na implementação:** o mapeamento inline de erros server-side depende de reconhecer a estrutura de erro (`message`, `detail[]`, ou formato equivalente), inclusive no campo OTP.
- **Ação sugerida:** implementar suporte híbrido no mobile para `errorMessage` simples e para o padrão `detail[]` do FastAPI; validar o contrato final de erro de OTP com o backend assim que a integração for ligada em ambiente compartilhado.

---

# Restrições

- **Não inclua testes automatizados na spec.**
- A `View` não deve conter lógica de negócio; toda orquestração de validação, integração remota e navegação fica no `Presenter`.
- Presenters não fazem chamadas diretas a `RestClient`; consomem sempre `AuthService`.
- Todos os caminhos citados acima existem no projeto ou estão explicitamente marcados como **novo arquivo**.
- Esta spec não inventa novos fluxos de negócio além do que está evidenciado no PRD RF01, no ticket ANI-40 e no ticket técnico ANI-35.
- Toda referência a código existente usa caminho relativo real em `lib/...`.
- Toda widget com responsabilidade própria foi colocada em pasta própria com `index.dart` quando aplicável.
- A UI nova deve usar Flutter Material; nao introduzir toolkit de UI externo.
- A spec mantém a nomenclatura da codebase: arquivos em `snake_case`, classes em `PascalCase`, providers e métodos em `camelCase`.
