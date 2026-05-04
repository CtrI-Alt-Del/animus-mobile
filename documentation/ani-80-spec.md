---
title: Setup do OneSignal no app mobile
prd: https://joaogoliveiragarcia.atlassian.net/wiki/x/kgAC
ticket: https://joaogoliveiragarcia.atlassian.net/browse/ANI-80
last_updated_at: 2026-05-03
---

# 1. Objetivo

Implementar a fundação técnica de `push notifications` no app Flutter usando `OneSignal`, mantendo o SDK encapsulado em um `driver` próprio, inicializando a integração no bootstrap do app, associando a instalação ao usuário autenticado e limpando essa identidade no logout. A entrega deve deixar o mobile apto a receber notificações disparadas pelo backend para fluxos assíncronos de análise de petição e busca/síntese de precedentes, sem criar regras de produto de notificação, handlers de clique ou notificações locais nesta etapa.

---

# 2. Escopo

## 2.1 In-scope

- Adicionar a dependência `onesignal_flutter` ao projeto e atualizar o `pubspec.lock`.
- Declarar `ONESIGNAL_APP_ID` em `.env.example` e expor `Env.oneSignalAppId`.
- Criar contrato `PushNotificationDriver` no `core` sem dependência de SDK externo.
- Criar `OneSignalPushNotificationDriver` em `drivers`, encapsulando `OneSignal.initialize`, `OneSignal.Notifications.requestPermission`, `OneSignal.login` e `OneSignal.logout`.
- Expor `pushNotificationDriverProvider` como fronteira Riverpod do novo driver.
- Inicializar o `OneSignal` no bootstrap após `WidgetsFlutterBinding.ensureInitialized()` e `dotenv.load`.
- Identificar o usuário autenticado no `OneSignal` quando houver `AccountDto.id` válido.
- Solicitar permissão de notificação uma única vez após sessão válida, sem bloquear navegação, Home ou fluxos de análise.
- Persistir localmente que o prompt de permissão já foi tentado.
- Limpar a identidade do `OneSignal` no logout.
- Ajustar configuração Android necessária para permissão de notificação, preservando deep link `animus://reset-password` e login Google.

## 2.2 Out-of-scope

- Implementar envio de notificações pelo mobile.
- Criar notificações locais.
- Implementar handlers de clique em notificações ou deep links vindos de push.
- Criar telas, cards, inbox, central de notificações ou histórico de notificações.
- Criar regras de produto para mensagens, títulos, corpo ou payload das notificações.
- Alterar contratos do backend ou endpoints REST.
- Implementar configuração iOS nesta entrega.
- Pedir permissão antes de sessão válida ou logo na abertura fria do app sem contexto de autenticação.
- Criar testes automatizados nesta spec.

---

# 3. Requisitos

## 3.1 Funcionais

- O app deve inicializar o SDK `OneSignal` com `ONESIGNAL_APP_ID` vindo de env/configuração.
- O app deve associar a instalação/dispositivo ao usuário autenticado usando `AccountDto.id` como `external_id`.
- O app deve limpar a identidade de push notification ao sair da conta.
- O app deve solicitar permissão de notificação em ponto controlado após sessão válida.
- A negação da permissão deve ser tratada como estado esperado e não deve exibir erro crítico.
- O app deve manter os fluxos de login por e-mail/senha, login Google, confirmação de e-mail, reentrada por sessão local e logout funcionando.
- O app não deve expor tipos do pacote `onesignal_flutter` para `core`, `ui` ou presenters.

## 3.2 Não funcionais

- **Segurança:** `clearUser()` deve ser chamado no logout para evitar associação indevida entre contas no mesmo dispositivo.
- **Conectividade:** falhas técnicas do SDK ou permissão negada não devem bloquear login, Home, perfil, análise ou navegação.
- **Performance:** inicialização e sincronização de identidade devem ser leves; a solicitação de permissão deve ser disparada de forma não bloqueante na Home.
- **Compatibilidade:** Android deve declarar suporte à permissão de notificação em runtime para Android 13+ por meio do manifest do app.
- **Configuração:** `ONESIGNAL_APP_ID` deve ser obrigatório via `Env._validateValue`, sem hardcode em `main.dart`, drivers ou arquivos nativos.

---

# 4. O que já existe?

## Core

- **`CacheDriver`** (`lib/core/shared/interfaces/cache_driver.dart`) — contrato de cache usado para tokens e preferências técnicas simples.
- **`ExternalLinkDriver`** (`lib/core/shared/interfaces/external_link_driver.dart`) — referência de contrato pequeno para capacidade externa encapsulada por driver.
- **`NavigationDriver`** (`lib/core/shared/interfaces/navigation_driver.dart`) — contrato consumido por presenters para navegação sem acoplar `go_router`.
- **`AuthService`** (`lib/core/auth/interfaces/auth_service.dart`) — contrato usado para autenticação e `getAccount()`.
- **`AccountDto`** (`lib/core/auth/dtos/account_dto.dart`) — contém `id`, `name`, `email` e será a fonte de `external_id` para `OneSignal.login`.
- **`SessionDto`** (`lib/core/auth/dtos/session_dto.dart`) — contém tokens da sessão, mas não contém `AccountDto.id`; por isso a identificação depende de `getAccount()`.

## Drivers

- **`SharedPreferencesCacheDriver`** (`lib/drivers/caches/shared_preferences/shared_preferences_cache_driver.dart`) — implementação atual de `CacheDriver`.
- **`cacheDriverProvider`** (`lib/drivers/caches/shared_preferences/shared_preferences_cache_driver.dart`) — provider usado por presenters e services.
- **`externalLinkDriverProvider`** (`lib/drivers/external-link-driver/index.dart`) — referência de provider Riverpod na fronteira de driver.
- **`UrlLauncherExternalLinkDriver`** (`lib/drivers/external-link-driver/url_launcher/url_launcher_external_link_driver.dart`) — referência de adapter que encapsula plugin externo.
- **`GoogleSignInGoogleAuthDriver`** (`lib/drivers/google-auth-driver/google_sign_in/google_sign_in_google_auth_driver.dart`) — referência de driver com provider e configuração por `Env`.

## UI / Auth

- **`SignInScreenPresenter`** (`lib/ui/auth/widgets/pages/sign_in_screen/sign_in_screen_presenter.dart`) — persiste tokens e navega para Home em login por senha e Google.
- **`SignUpScreenPresenter`** (`lib/ui/auth/widgets/pages/sign_up_screen/sign_up_screen_presenter.dart`) — persiste tokens e navega para Home no login/cadastro via Google.
- **`EmailConfirmationScreenPresenter`** (`lib/ui/auth/widgets/pages/email_confirmation_screen/email_confirmation_screen_presenter.dart`) — persiste tokens após OTP e navega para Home.
- **`ProfileScreenPresenter`** (`lib/ui/auth/widgets/pages/profile_screen/profile_screen_presenter.dart`) — ponto atual de logout e remoção de tokens.
- **`HomeScreenPresenter`** (`lib/ui/intake/widgets/pages/home_screen/home_screen_presenter.dart`) — primeiro presenter executado após sessão válida; já carrega `AccountDto` via `AuthService.getAccount()`.

## Bootstrap / Configuração

- **`main.dart`** (`lib/main.dart`) — carrega `.env`, cria `SharedPreferences`, valida sessão local e executa `runApp`.
- **`Env`** (`lib/constants/env.dart`) — centraliza leitura de variáveis obrigatórias.
- **`CacheKeys`** (`lib/constants/cache_keys.dart`) — centraliza chaves de cache local.
- **`.env.example`** (`.env.example`) — template de env do projeto.
- **`pubspec.yaml`** (`pubspec.yaml`) — dependências Flutter do app.
- **`pubspec.lock`** (`pubspec.lock`) — lockfile que deve refletir a dependência nova.

## Android

- **`AndroidManifest.xml`** (`android/app/src/main/AndroidManifest.xml`) — contém `MainActivity`, launcher intent e deep link `animus://reset-password`.
- **`build.gradle.kts`** (`android/app/build.gradle.kts`) — define `applicationId = "br.com.animus.app"` e configuração Android atual.

---

# 5. O que deve ser criado?

## Camada Core (Interfaces / Contratos)

- **Localização:** `lib/core/shared/interfaces/push_notification_driver.dart` (**novo arquivo**)
- **Interface:** `abstract class PushNotificationDriver`
- **Métodos:**
  - `Future<void> initialize()` — inicializa a integração de push notification do app.
  - `Future<bool> requestPermission({bool fallbackToSettings = false})` — solicita permissão de notificação e retorna se foi concedida.
  - `Future<void> identifyUser(String accountId)` — associa a instalação/dispositivo ao usuário autenticado.
  - `Future<void> clearUser()` — limpa a identidade de push notification ao sair da conta.

## Camada Drivers (Adaptadores)

- **Localização:** `lib/drivers/push-notification-driver/onesignal/onesignal_push_notification_driver.dart` (**novo arquivo**)
- **Classe:** `OneSignalPushNotificationDriver`
- **Interface implementada:** `PushNotificationDriver`
- **Biblioteca/pacote utilizado:** `onesignal_flutter`
- **Dependências:** `Env.oneSignalAppId`, `kDebugMode`, `OneSignal`
- **Métodos:**
  - `Future<void> initialize()` — em debug configura `OneSignal.Debug.setLogLevel(OSLogLevel.verbose)` e chama `OneSignal.initialize(Env.oneSignalAppId)`.
  - `Future<bool> requestPermission({bool fallbackToSettings = false})` — delega para `OneSignal.Notifications.requestPermission(fallbackToSettings)`.
  - `Future<void> identifyUser(String accountId)` — ignora `accountId` vazio; caso contrário chama `OneSignal.login(accountId.trim())`.
  - `Future<void> clearUser()` — chama `OneSignal.logout()`.

## Camada Drivers (Barrel Files / `index.dart`)

- **Localização:** `lib/drivers/push-notification-driver/index.dart` (**novo arquivo**)
- **Provider Riverpod:** `pushNotificationDriverProvider`
- **Tipo:** `Provider<PushNotificationDriver>`
- **Dependências:** nenhuma dependência de runtime além da classe concreta.
- **Responsabilidade:** expor `OneSignalPushNotificationDriver` como implementação padrão do contrato.
- **Export público:**
  - `export 'package:animus/drivers/push-notification-driver/onesignal/onesignal_push_notification_driver.dart';`

## Estrutura de Pastas

```text
lib/drivers/push-notification-driver/
  index.dart
  onesignal/
    onesignal_push_notification_driver.dart
```

---

# 6. O que deve ser modificado?

## Dependências

- **Arquivo:** `pubspec.yaml`
- **Mudança:** adicionar `onesignal_flutter` em `dependencies`; preferir `flutter pub add onesignal_flutter`, que deve resolver a versão estável atual. Em 2026-05-03, o pub.dev lista `onesignal_flutter: ^5.5.2` como versão estável mais recente.
- **Justificativa:** disponibilizar o SDK oficial de Flutter usado pelo driver concreto.

- **Arquivo:** `pubspec.lock`
- **Mudança:** atualizar lockfile pelo fluxo normal do Flutter após adicionar a dependência.
- **Justificativa:** garantir build reproduzível com a versão resolvida.

## Configuração

- **Arquivo:** `.env.example`
- **Mudança:** adicionar `ONESIGNAL_APP_ID=`.
- **Justificativa:** documentar a variável obrigatória sem expor segredo ou hardcode.

- **Arquivo:** `lib/constants/env.dart`
- **Mudança:** adicionar getter `static String get oneSignalAppId => _validateValue('ONESIGNAL_APP_ID');`.
- **Justificativa:** manter o padrão atual de validação obrigatória de envs.

- **Arquivo:** `lib/constants/cache_keys.dart`
- **Mudança:** adicionar `static const String pushNotificationPermissionPromptAttempted = 'notification:permission_prompt_attempted';`.
- **Justificativa:** registrar localmente que o prompt de permissão já foi tentado, evitando prompts repetidos.

## Bootstrap

- **Arquivo:** `lib/main.dart`
- **Mudança:** instanciar `OneSignalPushNotificationDriver`, chamar `initialize()` após `dotenv.load`, passar o driver para `_validateSessionOnAppLoad` e sobrescrever `pushNotificationDriverProvider` no `ProviderScope`.
- **Justificativa:** inicializar o SDK antes de `runApp` e reutilizar a mesma instância do driver no restante da aplicação.

- **Arquivo:** `lib/main.dart`
- **Mudança:** alterar `_validateSessionOnAppLoad` para receber `PushNotificationDriver`; quando `AuthService.getAccount()` retornar sucesso com `AccountDto.id` válido, chamar `identifyUser(id)`; quando a sessão local existir mas for inválida, remover tokens e chamar `clearUser()`.
- **Justificativa:** cobrir reentrada por sessão local sem duplicar a lógica de autenticação existente.

## UI / Fluxos autenticados

- **Arquivo:** `lib/ui/intake/widgets/pages/home_screen/home_screen_presenter.dart`
- **Mudança:** injetar `PushNotificationDriver` via `pushNotificationDriverProvider`; após `getAccount()` bem-sucedido, chamar `identifyUser(account.id)` quando houver id válido.
- **Justificativa:** a Home é o destino comum dos fluxos de login, login Google, confirmação de e-mail e sessão local; isso cobre os fluxos autenticados sem duplicar lógica nos presenters de autenticação.

- **Arquivo:** `lib/ui/intake/widgets/pages/home_screen/home_screen_presenter.dart`
- **Mudança:** após sessão válida, solicitar permissão com `requestPermission(fallbackToSettings: false)` apenas se `CacheKeys.pushNotificationPermissionPromptAttempted` ainda não estiver setada; gravar a chave antes de disparar a solicitação e não preencher `generalError` em caso de negação/falha.
- **Justificativa:** manter ponto único e não bloqueante de prompt de permissão.

- **Arquivo:** `lib/ui/auth/widgets/pages/profile_screen/profile_screen_presenter.dart`
- **Mudança:** injetar `PushNotificationDriver` via `pushNotificationDriverProvider`; em `signOut()`, chamar `clearUser()` de forma best-effort antes ou junto da remoção dos tokens.
- **Justificativa:** evitar que uma conta seguinte no mesmo dispositivo herde associação de push da conta anterior.

## Android

- **Arquivo:** `android/app/src/main/AndroidManifest.xml`
- **Mudança:** adicionar `<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />` no nível de `<manifest>`, sem alterar os `intent-filter` existentes.
- **Justificativa:** garantir suporte explícito à permissão runtime de notificações em Android 13+ e preservar deep link `animus://reset-password`.

- **Arquivo:** `android/app/build.gradle.kts`
- **Mudança:** **Não aplicável** inicialmente; manter `applicationId = "br.com.animus.app"` e revisar apenas se o build do `onesignal_flutter` exigir ajuste documentado.
- **Justificativa:** o setup mobile não deve introduzir mudança nativa sem necessidade comprovada.

---

# 7. O que deve ser removido?

**Não aplicável**.

---

# 8. Decisões Técnicas e Trade-offs

- **Decisão:** criar `PushNotificationDriver` em `lib/core/shared/interfaces/`.
- **Alternativas consideradas:** criar `lib/core/notification/interfaces/` como **novo diretório hipotético não adotado** para um novo domínio mobile de notification.
- **Motivo da escolha:** a codebase atual mantém contratos de capacidades externas transversais em `core/shared/interfaces`, como `CacheDriver`, `ExternalLinkDriver` e `NavigationDriver`; ainda não existe módulo mobile `notification`.
- **Impactos / trade-offs:** evita criar um domínio vazio cedo demais, mas uma futura central de notificações pode justificar mover ou complementar contratos em `core/notification`.

- **Decisão:** sincronizar identidade e permissão na `HomeScreenPresenter`.
- **Alternativas consideradas:** chamar `OneSignal.login` em cada presenter de autenticação (`SignIn`, `SignUp`, `EmailConfirmation`) ou criar um coordinator novo de sessão.
- **Motivo da escolha:** a Home já busca `AccountDto` após sessão válida e é destino comum dos fluxos autenticados, reduzindo duplicidade e evitando uma abstração nova sem padrão local estabelecido.
- **Impactos / trade-offs:** a identidade é sincronizada após entrada na Home, não imediatamente no retorno do endpoint de login; para reentrada fria, `main.dart` cobre a identificação durante validação da sessão local.

- **Decisão:** solicitar permissão com `fallbackToSettings: false`.
- **Alternativas consideradas:** usar `fallbackToSettings: true`.
- **Motivo da escolha:** abrir configurações do sistema após negação é intrusivo para o primeiro prompt; a entrega pede permissão sem bloquear o uso principal.
- **Impactos / trade-offs:** usuários que negarem permissão não serão redirecionados automaticamente para settings; uma futura tela de preferências pode oferecer essa ação explicitamente.

- **Decisão:** gravar `notification:permission_prompt_attempted` antes de chamar o SDK.
- **Alternativas consideradas:** gravar apenas quando o SDK retornar sucesso.
- **Motivo da escolha:** o requisito principal é evitar prompts repetidos; permissão negada ou falha técnica não deve degradar a experiência com novas tentativas automáticas.
- **Impactos / trade-offs:** se ocorrer erro técnico antes do prompt nativo aparecer, o app não tentará novamente automaticamente; isso deve ser tratado futuramente por configuração manual ou tela de preferências.

- **Decisão:** não criar handlers de clique em notificações.
- **Alternativas consideradas:** registrar `OneSignal.Notifications.addClickListener`.
- **Motivo da escolha:** o ticket define fundação de transporte push, não navegação por payload.
- **Impactos / trade-offs:** notificações podem chegar ao dispositivo, mas tocar nelas não terá roteamento específico nesta entrega.

---

# 9. Diagramas e Referências

- **Fluxo de dados: bootstrap e sessão local**

```text
main.dart
  → dotenv.load('.env')
  → OneSignalPushNotificationDriver.initialize()
       → OneSignal.initialize(Env.oneSignalAppId)
  → _validateSessionOnAppLoad(sharedPreferences, pushNotificationDriver)
       → AuthRestService.getAccount()
       → AccountDto.id
       → PushNotificationDriver.identifyUser(id)
            → OneSignal.login(id)
```

- **Fluxo de dados: Home após autenticação**

```text
HomeScreenView
  → HomeScreenPresenter.initialize()
       → AuthService.getAccount()
       → AccountDto.id
       → PushNotificationDriver.identifyUser(id)
            → OneSignal.login(id)
       → CacheDriver.get('notification:permission_prompt_attempted')
       → CacheDriver.set('notification:permission_prompt_attempted', 'true')
       → PushNotificationDriver.requestPermission(fallbackToSettings: false)
            → OneSignal.Notifications.requestPermission(false)
```

- **Fluxo de dados: logout**

```text
ProfileScreenView
  → ProfileScreenPresenter.signOut()
       → PushNotificationDriver.clearUser()
            → OneSignal.logout()
       → CacheDriver.delete(CacheKeys.accessToken)
       → CacheDriver.delete(CacheKeys.refreshToken)
       → NavigationDriver.goTo(Routes.signIn)
```

- **Referências de codebase**
  - `lib/core/shared/interfaces/external_link_driver.dart`
  - `lib/core/shared/interfaces/cache_driver.dart`
  - `lib/drivers/external-link-driver/index.dart`
  - `lib/drivers/external-link-driver/url_launcher/url_launcher_external_link_driver.dart`
  - `lib/drivers/google-auth-driver/google_sign_in/google_sign_in_google_auth_driver.dart`
  - `lib/ui/intake/widgets/pages/home_screen/home_screen_presenter.dart`
  - `lib/ui/auth/widgets/pages/profile_screen/profile_screen_presenter.dart`
  - `lib/main.dart`
  - `lib/constants/env.dart`
  - `lib/constants/cache_keys.dart`

- **Referências externas**
  - `https://github.com/OneSignal/OneSignal-Flutter-SDK`
  - `https://documentation.onesignal.com/docs/flutter-sdk-setup`
  - `https://pub.dev/packages/onesignal_flutter`
  - `https://joaogoliveiragarcia.atlassian.net/browse/ANI-80`
  - `https://joaogoliveiragarcia.atlassian.net/browse/ANI-84`
  - `https://joaogoliveiragarcia.atlassian.net/browse/ANI-64`

---

# 10. Pendências / Dúvidas

- **Impacto na implementação:** baixo para a implementação técnica, mas pode gerar confusão em rastreabilidade, branch e PR.


- **Descrição da pendência:** o PRD vinculado por `https://joaogoliveiragarcia.atlassian.net/wiki/x/kgAC` é o documento geral de requisitos do produto, não um PRD específico de notificações push.
- **Impacto na implementação:** médio; a spec depende do detalhamento do ticket `ANI-80` para requisitos técnicos e comportamento de permissão.
- **Ação sugerida:** manter `ANI-80` como fonte do escopo técnico e registrar follow-up se produto criar PRD específico de notificações.

- **Descrição da pendência:** o valor real de `ONESIGNAL_APP_ID` e a configuração da plataforma Android/Firebase no dashboard OneSignal não estão versionados no app.
- **Impacto na implementação:** alto para validação manual de recebimento de push, mas não bloqueia criação do driver e bootstrap.
- **Ação sugerida:** validar com o responsável pelo ambiente OneSignal antes de testar em dispositivo.

- **Descrição da pendência:** não há asset de ícone/cor de notificação Android definido no design ou no repositório.
- **Impacto na implementação:** baixo para transporte push; notificações podem usar ícone padrão/gerado pelo SDK, mas a apresentação visual pode ficar genérica.
- **Ação sugerida:** abrir follow-up de branding de notificação se o produto exigir ícone customizado.

- **Descrição da pendência:** configuração iOS não foi solicitada no ticket mobile atual.
- **Impacto na implementação:** médio se a entrega esperada também incluir iOS; sem APNs e ajustes iOS, a validação de push fica restrita ao Android.
- **Ação sugerida:** confirmar plataforma-alvo da entrega ou abrir ticket separado para iOS.

---

# Restrições

- **Não incluir testes automatizados na spec.**
- `PushNotificationDriver` no `core` não deve importar `onesignal_flutter`, Flutter, Riverpod ou tipos nativos.
- Presenters não devem importar `onesignal_flutter`; devem consumir apenas `PushNotificationDriver`.
- O App ID do OneSignal não deve ser hardcoded.
- `OneSignal.Debug.setLogLevel(OSLogLevel.verbose)` deve ficar restrito a modo debug.
- Falhas do SDK, ausência de permissão ou `AccountDto.id` vazio não devem bloquear login, Home, perfil ou análise.
- `requestPermission` não deve ser chamado repetidamente a cada abertura da Home.
- O deep link `animus://reset-password` existente no Android não deve ser removido ou alterado.
- A entrega não deve criar handlers de clique em notificação nem navegar por payload de push.
- Todos os arquivos novos devem seguir `snake_case` para arquivos e `PascalCase` para classes.
