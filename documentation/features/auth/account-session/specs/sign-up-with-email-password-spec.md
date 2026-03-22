---
title: Sign Up com E-mail e Senha
prd: documentation/features/auth/account-session/prd.md
ticket: https://joaogoliveiragarcia.atlassian.net/browse/ANI-40
status: open
last_updated_at: 2026-03-20
---

# 1. Objetivo

Esta spec define a implementação do fluxo de cadastro via e-mail e senha no `animus_mobile`, evoluindo o bootstrap atual de autenticação para um fluxo funcional com formulário reativo, indicador visual de força de senha, integração com `POST /auth/sign-up`, tratamento de erros inline e navegação para uma tela dedicada de confirmação de e-mail com reenvio do link. A entrega precisa respeitar a arquitetura em camadas já prevista no projeto, introduzindo a primeira implementação concreta de `AuthService` na camada `rest` e alinhando a UI ao uso de `shadcn_flutter`, `Riverpod`, `signals` e `reactive_forms`.

---

# 2. Escopo

## 2.1 In-scope

- Refatorar `lib/ui/auth/widgets/pages/sign_up_screen/` para um fluxo MVP com `reactive_forms`, `signals`, `Riverpod` e componentes de `shadcn_flutter`.
- Exibir campos de `name`, `email`, `password` e `confirmPassword` com validação client-side e mensagens inline.
- Exibir indicador visual de força de senha em tempo real com base nas três regras explícitas do produto: tamanho mínimo, presença de letra maiúscula e presença de número.
- Implementar o contrato `AuthService.signUp(...)` e sua primeira implementação REST usando `DioRestClient`.
- Implementar o contrato `AuthService.resendVerificationEmail(...)` para suportar a tela pós-cadastro.
- Criar a tela `email_confirmation_screen` e a rota correspondente para o estado pós-cadastro.
- Ajustar `RestResponse` e `DioRestClient` para preservar payload estruturado de erro, permitindo mapear erros de backend para a UI sem vazar `Json` cru para a View.
- Atualizar o bootstrap visual da app para suportar `shadcn_flutter` no root (`app.dart` / `theme.dart`).

## 2.2 Out-of-scope

- Implementação do login via e-mail e senha.
- Implementação do login com Google.
- Implementação do fluxo de clique no link de verificação de e-mail (`POST /auth/verify-email`).
- Persistência de sessão, refresh token e logout.
- Redefinição de senha e edição de perfil.
- Alterações no backend, contratos HTTP fora de `sign-up` e `resend-verification-email`, ou automação de testes.

---

# 3. Requisitos

## 3.1 Funcionais

- O usuário deve conseguir preencher `name`, `email`, `password` e `confirmPassword` na tela de cadastro.
- O formulário deve validar localmente: nome obrigatório, e-mail em formato válido, senha com no mínimo 8 caracteres, ao menos 1 letra maiúscula e ao menos 1 número, além de confirmação de senha idêntica.
- A força da senha deve ser exibida em tempo real, sem depender de resposta do backend.
- Ao submeter com dados válidos, o app deve chamar `POST /auth/sign-up` com payload `{ "name", "email", "password" }`.
- Em `201`, o app deve redirecionar para a tela de confirmação de e-mail, exibindo o e-mail usado no cadastro e CTA para reenvio do link.
- Em `409`, o app deve exibir erro inline no campo `email`.
- Em `422`, o app deve mapear erros estruturados do backend para os campos correspondentes sempre que houver chave reconhecível (`name`, `email`, `password`); quando não houver chave reconhecível, deve exibir `generalError`.
- Durante `signUp` e `resendVerificationEmail`, o CTA correspondente deve ficar desabilitado e com feedback visual de carregamento.

## 3.2 Não funcionais

- **Performance:** cada CTA remoto (`signUp` e `resendVerificationEmail`) deve permitir apenas uma requisição em voo por vez.
- **Acessibilidade:** labels e mensagens de erro devem ser textuais; o indicador de força de senha não pode depender apenas de cor.
- **Offline/Conectividade:** falhas de rede não podem limpar os campos já preenchidos; a tela deve permanecer no estado atual com `generalError` visível.
- **Segurança:** `password` e `confirmPassword` não devem ser persistidos fora do estado em memória do `FormGroup` do presenter; `AccountDto` não deve expor senha em texto puro.
- **Compatibilidade:** a integração remota deve continuar dependente de `ANIMUS_SERVER_APP_URL`, sem URL hardcoded, e a navegação deve continuar compatível com `go_router`.

---

# 4. O que já existe?

## Camada Core

- **`AuthService`** (`lib/core/auth/interfaces/auth_service.dart`) — contrato placeholder e sem uso; hoje expõe apenas `isLoggedInWithCredentialsAndToken`, incompatível com o PRD desta feature.
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
- **`AnimusApp`** (`lib/app.dart`) e **`AppTheme`** (`lib/theme.dart`) — bootstrap visual atual em `MaterialApp.router`; precisam acomodar `shadcn_flutter` para esta feature.

---

# 5. O que deve ser criado?

## Camada REST (Services)

- **Localização:** `lib/rest/services/auth_rest_service.dart` (**novo arquivo**)
- **Interface implementada:** `AuthService`
- **Dependências:** `RestClient`
- **Provider Riverpod:** `authServiceProvider`
- **Métodos:**
  - `Future<RestResponse<AccountDto>> signUp({required String name, required String email, required String password})` — envia `POST /auth/sign-up`, converte `201` em `AccountDto` e preserva `statusCode`, `errorMessage` e `errorBody` em falhas.
  - `Future<RestResponse<void>> resendVerificationEmail({required String email})` — envia `POST /auth/resend-verification-email` e retorna o status tipado de reenvio sem expor payload cru.

## Camada REST (Mappers)

- **Localização:** `lib/rest/mappers/auth/account_mapper.dart` (**novo arquivo**)
- **Métodos:**
  - `AccountDto toDto(Map<String, dynamic> json)` — mapeia `id`, `name`, `email`, `is_verified` e `social_accounts` para `AccountDto`.
  - `Map<String, dynamic> toSignUpJson({required String name, required String email, required String password})` — produz o payload de `POST /auth/sign-up`.
  - `Map<String, dynamic> toResendVerificationEmailJson({required String email})` — produz o payload de `POST /auth/resend-verification-email`.

## Camada UI (Presenters)

- **Localização:** `lib/ui/auth/widgets/pages/email_confirmation_screen/email_confirmation_screen_presenter.dart` (**novo arquivo**)
- **Dependências injetadas:** `AuthService`
- **Estado (`signals`):**
  - Signals simples: `signal<bool> isResending`, `signal<String?> generalError`, `signal<String?> feedbackMessage`
  - Computeds: não aplicável
- **Provider Riverpod:** `emailConfirmationScreenPresenterProvider`
- **Métodos:**
  - `Future<void> resendVerificationEmail()` — dispara o reenvio do link para o `email` recebido pela tela, controla loading e atualiza `feedbackMessage` ou `generalError`.

## Camada UI (Views)

- **Localização:** `lib/ui/auth/widgets/pages/email_confirmation_screen/email_confirmation_screen_view.dart` (**novo arquivo**)
- **Base class:** `ConsumerWidget`
- **Props:** `required String email`
- **Bibliotecas de UI:** `flutter_riverpod`, `signals_flutter`, `shadcn_flutter`, `reactive_forms`
- **Estados visuais:**
  - `Content` — texto explicativo com o e-mail cadastrado e CTA de reenvio.
  - `Loading` — botão de reenvio desabilitado com indicador visual.
  - `Error` — alerta textual acima do CTA.

## Camada UI (Widgets Internos)

- **Localização:** `lib/ui/auth/widgets/pages/sign_up_screen/password_strength_indicator/` (**novo arquivo** em pasta nova)
- **Tipo:** View only
- **Props:** `required int score`, `required bool hasMinLength`, `required bool hasUppercaseLetter`, `required bool hasNumber`
- **Responsabilidade:** renderizar o indicador de força de senha com checklist das três regras explícitas do produto, sem conter lógica de negócio.

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
  email_confirmation_screen/
    index.dart
    email_confirmation_screen_view.dart
    email_confirmation_screen_presenter.dart
```

---

# 6. O que deve ser modificado?

## App / Bootstrap

- **Arquivo:** `pubspec.yaml`
- **Mudança:** adicionar as dependências de `shadcn_flutter`, `signals` e `reactive_forms` compatíveis com o SDK atual do projeto.
- **Justificativa:** a spec exige `shadcn_flutter` para UI, `signals` para estado local e `reactive_forms` para validação de formulários; essas bibliotecas ainda não estão declaradas no app bootstrap.

- **Arquivo:** `lib/app.dart`
- **Mudança:** substituir `MaterialApp.router` por `ShadcnApp.router`, preservando `title` e `routerConfig`.
- **Justificativa:** os componentes de `shadcn_flutter` precisam ser inicializados no root da aplicação para que a tela de auth use o mesmo sistema visual e de tema.

- **Arquivo:** `lib/theme.dart`
- **Mudança:** trocar o tema Material atual por um `ThemeData` de `shadcn_flutter` focado em light theme, mantendo uma direção visual neutra e consistente com o bootstrap.
- **Justificativa:** sem um tema de `shadcn_flutter`, a nova UI de auth ficaria visualmente inconsistente e parcialmente acoplada ao tema Material anterior.

- **Arquivo:** `lib/constants/routes.dart`
- **Mudança:** adicionar a constante `emailConfirmation` e o helper `String emailConfirmationLocation({required String email})` para construir a rota com query string de forma centralizada.
- **Justificativa:** o presenter precisa navegar para a tela de confirmação sem montar URLs manualmente em múltiplos pontos.

- **Arquivo:** `lib/router.dart`
- **Mudança:** registrar a rota de confirmação de e-mail e extrair o parâmetro `email` da query string antes de construir `EmailConfirmationScreen`.
- **Justificativa:** o fluxo pós-cadastro precisa de uma rota explícita e segura, com redirect quando o parâmetro obrigatório estiver ausente.

## Camada Core

- **Arquivo:** `lib/core/auth/interfaces/auth_service.dart`
- **Mudança:** substituir o método placeholder atual pelos contratos:
  - `Future<RestResponse<AccountDto>> signUp({required String name, required String email, required String password})`
  - `Future<RestResponse<void>> resendVerificationEmail({required String email})`
- **Justificativa:** o contrato atual não atende o PRD nem o ticket ANI-40 e não possui uso real na codebase.

- **Arquivo:** `lib/core/auth/dtos/account_dto.dart`
- **Mudança:** alinhar o DTO ao retorno esperado do backend, removendo a obrigatoriedade de `password`, removendo `isActive` e mantendo apenas campos com evidência no domínio (`id`, `name`, `email`, `isVerified`, `socialAccounts`).
- **Justificativa:** o backend de cadastro retorna `AccountDto`, mas senha em texto puro não deve existir no retorno do mobile e `isActive` não aparece no modelo de domínio documentado.

- **Arquivo:** `lib/core/shared/responses/rest_response.dart`
- **Mudança:** adicionar suporte a `Json? errorBody` e ajustar `mapBody` para propagar falhas preservando `statusCode`, `errorMessage` e `errorBody` em vez de lançar exceção imediatamente.
- **Justificativa:** o presenter precisa mapear erros estruturados de `409/422` para erros inline sem depender de parsing na View e sem perder metadados durante o mapeamento REST -> DTO.

## Camada REST

- **Arquivo:** `lib/rest/dio/dio_rest_client.dart`
- **Mudança:** expor `restClientProvider`, configurar o `baseUrl` a partir de `Env.animusServerAppUrl` e popular `errorBody` quando a resposta de erro vier em `Json`.
- **Justificativa:** o primeiro service concreto de auth precisa receber `RestClient` via Riverpod e preservar o payload de erro do backend para a UI.

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
    - `Future<void> submit(BuildContext context)` — marca o formulário como touched, valida o `FormGroup`, chama `AuthService.signUp`, mapeia erros de backend para os controles/`generalError` e navega para `Routes.emailConfirmationLocation(email: email)` em caso de `201`.

- **Arquivo:** `lib/ui/auth/widgets/pages/sign_up_screen/sign_up_screen_view.dart`
- **Mudança:** substituir os widgets Material atuais por composição com `shadcn_flutter`, adicionar `confirmPassword`, indicador de força e feedbacks inline ligados a `reactive_forms` e ao estado auxiliar do presenter.
- **Justificativa:** a View atual não atende os requisitos do ticket nem o guideline visual definido para novas features.
- **Detalhamento funcional esperado no arquivo:**
  - Base class: `ConsumerWidget`
  - Bibliotecas de UI: `flutter_riverpod`, `signals_flutter`, `shadcn_flutter`, `reactive_forms`
  - Estados visuais: `Content`, `Loading` no CTA, `Error` inline por campo via `reactive_forms` e `generalError`
  - Hierarquia principal: `Scaffold` -> `SafeArea` -> `Center` -> `SingleChildScrollView` -> `Card` -> `ReactiveForm` -> campos -> `PasswordStrengthIndicator` -> CTA

- **Arquivo:** `lib/ui/auth/widgets/pages/sign_up_screen/index.dart`
- **Mudança:** manter o barrel público com `typedef SignUpScreen = SignUpScreenView`, ajustando apenas imports se necessário.
- **Justificativa:** o padrão já está correto e deve permanecer como fronteira pública da pasta.

---

# 7. O que deve ser removido?

## Camada Core

- **Arquivo:** `lib/core/auth/interfaces/auth_service.dart`
- **Motivo da remoção:** o método `isLoggedInWithCredentialsAndToken` é um placeholder sem uso e não corresponde a nenhum requisito do PRD ou do ticket.
- **Impacto esperado:** todos os consumers passam a depender exclusivamente de `signUp` e `resendVerificationEmail`.

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

## 8.3 Criar uma tela dedicada de confirmação de e-mail

- **Decisão:** criar `email_confirmation_screen` como nova tela em vez de exibir um `dialog` ou `snackbar` de sucesso na própria `sign_up_screen`.
- **Alternativas consideradas:** exibir confirmação inline na mesma tela; navegar direto para login com mensagem transitória.
- **Motivo da escolha:** o PRD exige um estado pós-cadastro com instrução clara e opção de reenvio; uma tela dedicada é o formato mais estável para esse comportamento e reaproveita melhor o fluxo futuro de e-mail não confirmado.
- **Impactos / trade-offs:** adiciona uma rota e um presenter a mais, mas reduz acoplamento do fluxo pós-cadastro com o formulário original.

## 8.4 Usar query string para transportar o e-mail até a rota de confirmação

- **Decisão:** a rota de confirmação recebe `email` via query string, construída por `Routes.emailConfirmationLocation(...)`.
- **Alternativas consideradas:** passar `email` em `state.extra`; armazenar o e-mail temporariamente em estado global.
- **Motivo da escolha:** query string sobrevive melhor a refresh e mantém o contrato da rota explícito no `router.dart`.
- **Impactos / trade-offs:** o `router` precisa validar a presença do parâmetro e redirecionar quando ele estiver ausente.

## 8.5 Adotar `shadcn_flutter` já no bootstrap do app

- **Decisão:** migrar `lib/app.dart` para `ShadcnApp.router` e ajustar `lib/theme.dart` agora, junto com a feature.
- **Alternativas consideradas:** manter `MaterialApp.router` e usar `shadcn_flutter` apenas localmente na tela; adiar a migração visual para outra tarefa.
- **Motivo da escolha:** a diretriz da spec exige `shadcn_flutter` para novas features e a mudança é pequena no estado atual do bootstrap.
- **Impactos / trade-offs:** a feature deixa de ser puramente de auth e toca o bootstrap visual, mas evita retrabalho imediato nas próximas telas do módulo.

---

# 9. Diagramas e Referências

## Fluxo de dados

```text
SignUpScreenView
  -> SignUpScreenPresenter.submit(context)
      -> AuthService.signUp(name, email, password)
          -> AuthRestService.signUp(...)
              -> AccountMapper.toSignUpJson(...)
              -> RestClient.post('/auth/sign-up')
              -> AccountMapper.toDto(...)
      -> [201] GoRouter.go(Routes.emailConfirmationLocation(email: email))
      -> [409/422/rede] atualiza erros do `FormGroup` ou `generalError`

EmailConfirmationScreenView
  -> EmailConfirmationScreenPresenter.resendVerificationEmail()
      -> AuthService.resendVerificationEmail(email)
          -> AuthRestService.resendVerificationEmail(...)
              -> AccountMapper.toResendVerificationEmailJson(...)
              -> RestClient.post('/auth/resend-verification-email')
      -> [204] feedbackMessage
      -> [falha] generalError
```

## Hierarquia de widgets

```text
SignUpScreenView
  Scaffold
    SafeArea
      Center
        SingleChildScrollView
          Card
            Column
              Title
              Description
              NameField
              EmailField
              PasswordField
              PasswordStrengthIndicator
              ConfirmPasswordField
              GeneralErrorAlert?
              SubmitButton

EmailConfirmationScreenView
  Scaffold
    SafeArea
      Center
        Card
          Column
            Title
            Description(email)
            FeedbackAlert?
            ErrorAlert?
            ResendButton
```

## Referências

- `lib/ui/auth/widgets/pages/sign_up_screen/sign_up_screen_view.dart` — referência direta do widget que será evoluído.
- `lib/ui/auth/widgets/pages/sign_up_screen/sign_up_screen_presenter.dart` — referência direta do presenter que será refatorado.
- `lib/ui/auth/widgets/pages/sign_up_screen/index.dart` — referência do padrão de barrel file já adotado no módulo.
- `lib/core/shared/responses/rest_response.dart` — base para a evolução do wrapper de erro/sucesso.
- `lib/rest/dio/dio_rest_client.dart` — base para a primeira implementação concreta de `AuthService`.
- `lib/constants/routes.dart` e `lib/router.dart` — pontos de entrada para a nova rota pós-cadastro.

> Lacuna identificada na codebase: não foram encontrados services REST de auth, mappers de auth nem outras telas de auth além do bootstrap de `sign_up_screen`; esta feature inaugura esses padrões no mobile.

---

# 10. Pendências / Dúvidas

- **Descrição da pendência:** o shape exato do payload de erro de `409/422` do backend não está documentado no repositório mobile nem no ticket ANI-40.
- **Impacto na implementação:** o mapeamento inline de erros server-side depende de reconhecer a estrutura de erro (`message`, `detail[]`, ou formato equivalente).
- **Ação sugerida:** implementar suporte híbrido no mobile para `errorMessage` simples e para o padrão `detail[]` do FastAPI; validar o contrato final com o backend assim que a integração for ligada em ambiente compartilhado.

---

# Restrições

- **Não inclua testes automatizados na spec.**
- A `View` não deve conter lógica de negócio; toda orquestração de validação, integração remota e navegação fica no `Presenter`.
- Presenters não fazem chamadas diretas a `RestClient`; consomem sempre `AuthService`.
- Todos os caminhos citados acima existem no projeto ou estão explicitamente marcados como **novo arquivo**.
- Esta spec não inventa novos fluxos de negócio além do que está evidenciado no PRD RF01, no ticket ANI-40 e no ticket técnico ANI-35.
- Toda referência a código existente usa caminho relativo real em `lib/...`.
- Toda widget com responsabilidade própria foi colocada em pasta própria com `index.dart` quando aplicável.
- A UI nova deve usar `shadcn_flutter`; componentes Material atuais da tela de cadastro precisam ser removidos na implementação.
- A spec mantém a nomenclatura da codebase: arquivos em `snake_case`, classes em `PascalCase`, providers e métodos em `camelCase`.
