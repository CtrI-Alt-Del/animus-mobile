---
title: Interceptor Dio com refresh automático de sessão
prd:
ticket: https://joaogoliveiragarcia.atlassian.net/browse/ANI-125
status: closed
last_updated_at: 2026-05-30
---

# 1. Objetivo

Implementar a renovação automática de sessão no `animus` centralizando a gestão de `access_token` e `refresh_token` em um `AuthTokenInterceptor` da camada `rest`. A entrega deve injetar `Authorization: Bearer <accessToken>` nas requests do `DioRestClient`, detectar `401` em requests protegidas, renovar a sessão via `POST /auth/refresh`, retentar a request original com o novo token e redirecionar para `Routes.signIn` apenas quando o refresh falhar ou não houver `refresh_token` válido.

---

# 2. Escopo

## 2.1 In-scope

- Criar `AuthTokenInterceptor` em `lib/rest/dio/auth_token_interceptor.dart` para autenticação e refresh automático.
- Registrar o interceptor no `DioRestClient` usado por `restClientProvider`.
- Usar `CacheDriver` para ler e persistir `CacheKeys.accessToken` e `CacheKeys.refreshToken`.
- Usar `NavigationDriver` para redirecionar para `Routes.signIn` quando a sessão não puder ser renovada.
- Retentar automaticamente requests protegidas que falharem com `401` após refresh bem-sucedido.
- Serializar refreshes concorrentes com mutex baseado em `Completer<void>?`, garantindo uma única chamada a `POST /auth/refresh` por rajada de `401`.
- Não tentar refresh para `401` de endpoints públicos de autenticação, preservando erros de credenciais inválidas, OTP inválido e reset de senha.
- Remover `setAuthHeader()`, `requireAuth()` e `unauthorizedResponse()` do `Service` base.
- Remover as chamadas a `requireAuth()` dos services REST protegidos existentes.
- Atualizar a composição dos providers em `lib/rest/services/index.dart` para deixar `CacheDriver` e `NavigationDriver` apenas no `restClientProvider`.
- Ajustar `_validateSessionOnAppLoad` em `lib/main.dart` para continuar validando a sessão após a remoção de `requireAuth()`.

## 2.2 Out-of-scope

- Alterar o contrato público de `RestClient` no `core`.
- Alterar presenters, views, rotas visuais ou hierarquia de widgets.
- Criar nova tela de sessão expirada.
- Implementar logout global ou revogação remota de refresh token.
- Alterar regras de expiração no backend.
- Alterar `router.dart` ou o guard `_hasLocalSession()` nesta entrega.
- Renovar sessão em clients não autenticados, como `gcsRestClientProvider`, salvo se uma futura task exigir.

---

# 3. Requisitos

## 3.1 Funcionais

- O app deve anexar `Authorization: Bearer <accessToken>` em requests enviadas pelo `DioRestClient` quando `CacheKeys.accessToken` existir e não estiver vazio.
- Requests sem `access_token` devem seguir sem header; se uma request protegida retornar `401`, o interceptor deve tentar refresh usando o `refresh_token` quando disponível.
- Ao receber `401` em endpoint protegido, o interceptor deve comparar o token usado pela request original com o token atual do cache.
- Se o token atual do cache já for diferente do token usado na request original, o interceptor deve retentar a request com o token atual, sem chamar `POST /auth/refresh`.
- Se o token atual for o mesmo da request original, o interceptor deve chamar `POST /auth/refresh` com payload `{ "refresh_token": refreshToken }`.
- Em refresh bem-sucedido, o interceptor deve mapear a resposta com `SessionMapper.toDto`, persistir `session.accessToken.value` e `session.refreshToken.value` no cache e retentar a request original.
- Em refresh com `401`, `403`, erro técnico ou resposta sem tokens válidos, o interceptor deve limpar os tokens locais e navegar para `Routes.signIn`.
- Múltiplas requests concorrentes com `401` devem aguardar o refresh em andamento e retentar com o token renovado, sem disparar refresh duplicado.
- `401` de endpoints públicos de auth deve ser propagado para o service original, sem tentativa de refresh.
- `AuthRestService.getAccount()` e demais métodos protegidos devem deixar de validar cache manualmente e depender do interceptor para autenticação.

## 3.2 Não funcionais

- **Performance:** em rajadas concorrentes de `401`, executar no máximo uma request de `POST /auth/refresh` por vez.
- **Segurança:** persistir apenas `access_token` e `refresh_token`; não registrar tokens em logs nem propagar valores em mensagens de erro.
- **Segurança:** limpar `CacheKeys.accessToken` e `CacheKeys.refreshToken` quando o refresh falhar de forma definitiva.
- **Offline/Conectividade:** falhas de rede durante refresh devem ser tratadas como falha de renovação, com limpeza local de sessão e redirecionamento para login.
- **Compatibilidade:** preservar `RestResponse<T>` como wrapper retornado aos services e manter `Dio`, `RequestOptions` e `Response` confinados à camada `rest/dio`.

---

# 4. O que já existe?

## Camada Core

- **`RestClient`** (`lib/core/shared/interfaces/rest_client.dart`) — contrato HTTP consumido pelos services; não expõe interceptors nem tipos do `Dio`.
- **`CacheDriver`** (`lib/core/shared/interfaces/cache_driver.dart`) — contrato síncrono para `get`, `set` e `delete` de strings em cache local.
- **`NavigationDriver`** (`lib/core/shared/interfaces/navigation_driver.dart`) — contrato usado para navegar para `Routes.signIn` sem acoplar a camada `rest` ao `go_router`.
- **`SessionDto`** (`lib/core/auth/dtos/session_dto.dart`) — DTO com `accessToken` e `refreshToken`.
- **`TokenDto`** (`lib/core/auth/dtos/token_dto.dart`) — DTO de token com `value` e `expiresAt`.
- **`RestResponse`** (`lib/core/shared/responses/rest_response.dart`) — envelope tipado usado por todos os services REST.

## Camada REST

- **`DioRestClient`** (`lib/rest/dio/dio_rest_client.dart`) — implementação atual de `RestClient` com `Dio`, `BaseOptions(listFormat: ListFormat.multi)`, parse de resposta e tratamento de `DioException`.
- **`restClientProvider`** (`lib/rest/clients/rest_client_provider.dart`) — provider que instancia `DioRestClient` e aplica `Env.animusServerAppUrl`.
- **`Service`** (`lib/rest/services/service.dart`) — classe base atual com `setAuthHeader()`, `requireAuth()`, `unauthorizedResponse()`, `toVoidResponse()` e `resolveErrorMessage()`.
- **`AuthRestService`** (`lib/rest/services/auth_rest_service.dart`) — service de auth; `getAccount()` e `updateAccount()` hoje dependem de `requireAuth()`.
- **`IntakeRestService`** (`lib/rest/services/intake_rest_service.dart`) — service protegido com múltiplas chamadas a `requireAuth()`.
- **`StorageRestService`** (`lib/rest/services/storage_rest_service.dart`) — service protegido com chamada a `requireAuth()` em `generateAnalysisDocumentUploadUrl()`.
- **`LibraryRestService`** (`lib/rest/services/library_rest_service.dart`) — service protegido com chamadas a `requireAuth()`; precisa ser incluído apesar de não estar citado no ticket, porque a remoção do método no `Service` base quebraria este arquivo.
- **`services/index.dart`** (`lib/rest/services/index.dart`) — composição Riverpod atual injeta `CacheDriver` e `NavigationDriver` diretamente nos services.
- **`SessionMapper`** (`lib/rest/mappers/auth/session_mapper.dart`) — mapper existente para converter `access_token` e `refresh_token` em `SessionDto`.

## Camada Drivers

- **`SharedPreferencesCacheDriver`** (`lib/drivers/caches/shared_preferences/shared_preferences_cache_driver.dart`) — implementação concreta de `CacheDriver` baseada em `shared_preferences`.
- **`cacheDriverProvider`** (`lib/drivers/caches/shared_preferences/shared_preferences_cache_driver.dart`) — provider de composição do cache local.
- **`GoRouterNavigationDriver`** (`lib/drivers/navigation/go_router/go_router_navigation_driver.dart`) — implementação concreta de `NavigationDriver` baseada em `go_router`.
- **`navigationDriverProvider`** (`lib/drivers/navigation/go_router/go_router_navigation_driver.dart`) — provider de composição da navegação.

## Constants / App

- **`CacheKeys`** (`lib/constants/cache_keys.dart`) — possui `accessToken` e `refreshToken`.
- **`Routes`** (`lib/constants/routes.dart`) — possui `Routes.signIn`.
- **`Env`** (`lib/constants/env.dart`) — fornece `Env.animusServerAppUrl`.
- **`_validateSessionOnAppLoad`** (`lib/main.dart`) — valida sessão no boot usando `AuthRestService.getAccount()`; depende hoje de `requireAuth()` para setar `Authorization`.
- **`_hasLocalSession`** (`lib/router.dart`) — guard local que verifica apenas presença de tokens em `SharedPreferences`.

---

# 5. O que deve ser criado?

## Camada REST (Dio / Interceptor)

- **Localização:** `lib/rest/dio/auth_token_interceptor.dart` (**novo arquivo**)
- **Classe:** `AuthTokenInterceptor extends Interceptor`
- **Dependências:** `CacheDriver`, `NavigationDriver`, `Dio`, `SessionMapper`, `CacheKeys`, `Routes`
- **Biblioteca/pacote utilizado:** `dio`
- **Estado interno:**
  - `final CacheDriver _cacheDriver` — lê e persiste tokens.
  - `final NavigationDriver _navigationDriver` — redireciona para login em falha definitiva.
  - `final Dio _refreshDio` — client interno sem interceptors para chamar `POST /auth/refresh` e retentar requests sem recursão.
  - `Completer<void>? _refreshCompleter` — mutex para serializar refreshes concorrentes.
- **Construtor:** `AuthTokenInterceptor({required CacheDriver cacheDriver, required NavigationDriver navigationDriver, required String baseUrl})` — inicializa dependências e configura `_refreshDio` com `BaseOptions(baseUrl: baseUrl, listFormat: ListFormat.multi)`.
- **Métodos:**
  - `void onRequest(RequestOptions options, RequestInterceptorHandler handler)` — lê `CacheKeys.accessToken`, injeta `Authorization: Bearer <token>` quando houver token e salva o token usado em `options.extra['auth_access_token']` para comparação posterior.
  - `Future<void> onError(DioException error, ErrorInterceptorHandler handler)` — intercepta apenas `401` de endpoints protegidos, coordena mutex, tenta refresh quando necessário, retenta com `handler.resolve(response)` em sucesso e propaga o erro original com `handler.next(error)` quando não aplicável.
  - `Future<bool> _refreshTokens()` — lê `CacheKeys.refreshToken`, chama `POST /auth/refresh`, mapeia a resposta com `SessionMapper.toDto`, valida tokens não vazios e persiste os novos valores no cache.
  - `Future<Response<dynamic>> _retry(RequestOptions requestOptions, String accessToken)` — recria a request original com `Authorization: Bearer <accessToken>` e executa via `_refreshDio.fetch<dynamic>(requestOptions)`.
  - `Future<void> _waitForRunningRefresh()` — aguarda `_refreshCompleter?.future` quando outro fluxo já estiver renovando a sessão.
  - `bool _shouldSkipRefresh(RequestOptions requestOptions)` — retorna `true` para endpoints públicos de auth e para `/auth/refresh`.
  - `String _readAccessToken()` — retorna `CacheKeys.accessToken` normalizado com `trim()`.
  - `String _readRefreshToken()` — retorna `CacheKeys.refreshToken` normalizado com `trim()`.
  - `void _clearSessionAndRedirect()` — remove `CacheKeys.accessToken` e `CacheKeys.refreshToken` e executa `_navigationDriver.goTo(Routes.signIn)`.
- **Endpoints públicos sem refresh:**
  - `/auth/sign-in`
  - `/auth/sign-up`
  - `/auth/sign-up/google`
  - `/auth/password/forgot`
  - `/auth/password/resend-reset-otp`
  - `/auth/password/verify-reset-otp`
  - `/auth/password/reset`
  - `/auth/resend-verification-email`
  - `/auth/verify-email`
  - `/auth/refresh`

---

# 6. O que deve ser modificado?

## Camada REST

- **Arquivo:** `lib/rest/dio/dio_rest_client.dart`
- **Mudança:** adicionar suporte a interceptors no construtor, por exemplo `DioRestClient({List<Interceptor> interceptors = const <Interceptor>[]})`, mantendo `_dio` privado e registrando cada interceptor em `_dio.interceptors`.
- **Justificativa:** permitir que `restClientProvider` componha o `AuthTokenInterceptor` sem expor `Dio` pelo contrato `RestClient` do `core`.

- **Arquivo:** `lib/rest/clients/rest_client_provider.dart`
- **Mudança:** injetar `CacheDriver` via `cacheDriverProvider` e `NavigationDriver` via `navigationDriverProvider`, criar `AuthTokenInterceptor(cacheDriver: cacheDriver, navigationDriver: navigationDriver, baseUrl: Env.animusServerAppUrl)`, instanciar `DioRestClient(interceptors: <Interceptor>[authTokenInterceptor])` e manter `client.setBaseUrl(Env.animusServerAppUrl)`.
- **Justificativa:** centralizar autenticação no client REST e retirar essa responsabilidade dos services.

- **Arquivo:** `lib/rest/services/service.dart`
- **Mudança:** simplificar o construtor para `Service(this.restClient)` e manter apenas `toVoidResponse(RestResponse<Map<String, dynamic>> response)` e `String? resolveErrorMessage(RestResponse<Map<String, dynamic>> response)`.
- **Justificativa:** `Service` não deve mais ler cache, setar header nem navegar; essa responsabilidade passa a ser do interceptor.

- **Arquivo:** `lib/rest/services/auth_rest_service.dart`
- **Mudança:** alterar o construtor para receber apenas `required RestClient restClient`, remover imports de `CacheDriver` e `NavigationDriver`, remover blocos de `requireAuth()` de `getAccount()` e `updateAccount()`.
- **Justificativa:** requests protegidas de auth passam a depender do header injetado pelo interceptor.

- **Arquivo:** `lib/rest/services/intake_rest_service.dart`
- **Mudança:** alterar o construtor para receber apenas `required RestClient restClient`, remover imports de `CacheDriver` e `NavigationDriver`, remover todos os blocos `final authFailure = requireAuth<...>(); if (authFailure != null) return authFailure;`.
- **Justificativa:** evitar validação duplicada de sessão e permitir retry automático em `401` para fluxos protegidos de intake.

- **Arquivo:** `lib/rest/services/storage_rest_service.dart`
- **Mudança:** alterar o construtor para receber apenas `required RestClient restClient`, remover imports de `CacheDriver` e `NavigationDriver`, remover o bloco de `requireAuth<UploadUrlDto>()` de `generateAnalysisDocumentUploadUrl()`.
- **Justificativa:** permitir que upload URL use a autenticação centralizada pelo interceptor.

- **Arquivo:** `lib/rest/services/library_rest_service.dart`
- **Mudança:** alterar o construtor para receber apenas `required RestClient restClient`, remover imports de `CacheDriver` e `NavigationDriver`, remover todos os blocos de `requireAuth()`.
- **Justificativa:** a codebase atual usa `LibraryRestService` com `requireAuth()`; se este arquivo não for atualizado, a remoção do método no `Service` base quebrará a build.

- **Arquivo:** `lib/rest/services/index.dart`
- **Mudança:** remover imports e leituras de `CacheDriver`, `cacheDriverProvider`, `NavigationDriver` e `navigationDriverProvider`; atualizar `authServiceProvider`, `intakeServiceProvider`, `storageServiceProvider` e `libraryServiceProvider` para instanciar seus services apenas com `restClient`.
- **Justificativa:** as dependências de sessão migram para `restClientProvider`; services passam a depender somente do contrato HTTP.

## App / Bootstrap

- **Arquivo:** `lib/main.dart`
- **Mudança:** ajustar `_validateSessionOnAppLoad` para criar um `SharedPreferencesCacheDriver`, instanciar `DioRestClient` com `AuthTokenInterceptor` e criar `AuthRestService(restClient: restClient)` sem `CacheDriver`/`NavigationDriver` no construtor.
- **Justificativa:** após remover `requireAuth()`, `getAccount()` não setará mais o header manualmente; sem esse ajuste, a validação de sessão no cold start chamaria `/auth/account` sem `Authorization` e limparia sessões válidas.
- **Observação:** com o interceptor no cold start, a validação pode renovar sessão antes do `runApp`; se o refresh falhar, o fluxo existente de limpeza dos tokens e `pushNotificationDriver.clearUser()` deve permanecer.

---

# 7. O que deve ser removido?

## Camada REST

- **Arquivo:** `lib/rest/services/service.dart`
- **Motivo da remoção:** remover `setAuthHeader()`, `requireAuth()` e `unauthorizedResponse()` porque autenticação, refresh e redirecionamento deixam de ser responsabilidade da classe base de services.
- **Impacto esperado:** todos os services que chamam `requireAuth()` precisam remover esses blocos antes da remoção do método.

- **Arquivo:** `lib/rest/services/auth_rest_service.dart`
- **Motivo da remoção:** remover validação manual de autenticação em `getAccount()` e `updateAccount()`.
- **Impacto esperado:** `401` passa a ser tratado pelo interceptor e, se não resolvido, volta como `RestResponse<AccountDto>` de falha.

- **Arquivo:** `lib/rest/services/intake_rest_service.dart`
- **Motivo da remoção:** remover validações manuais repetidas de autenticação em métodos protegidos.
- **Impacto esperado:** todas as operações protegidas de intake passam a ter retry automático após refresh.

- **Arquivo:** `lib/rest/services/storage_rest_service.dart`
- **Motivo da remoção:** remover validação manual de autenticação antes de gerar upload URL.
- **Impacto esperado:** a request dependerá do header injetado pelo interceptor.

- **Arquivo:** `lib/rest/services/library_rest_service.dart`
- **Motivo da remoção:** remover validações manuais repetidas de autenticação em listagem e operações de pastas/biblioteca.
- **Impacto esperado:** operações de biblioteca passam a ter o mesmo comportamento de refresh automático dos demais services protegidos.

---

# 8. Decisões Técnicas e Trade-offs

- **Decisão:** centralizar autenticação no `AuthTokenInterceptor` registrado no `DioRestClient`.
- **Alternativas consideradas:** manter `requireAuth()` em cada service e adicionar refresh dentro do `Service` base.
- **Motivo da escolha:** o ticket ANI-125 pede consolidar sessão no interceptor; isso evita duplicidade, permite retry transparente da request original e mantém services focados em endpoints e mappers.
- **Impactos / trade-offs:** a camada `rest` passa a depender de `CacheDriver` e `NavigationDriver` na composição do client, o que é aceitável pelas regras da camada REST para dependência técnica controlada.

- **Decisão:** usar `_refreshDio` interno sem interceptors para refresh e retry.
- **Alternativas consideradas:** usar o mesmo `_dio` do `DioRestClient` para chamar `/auth/refresh`.
- **Motivo da escolha:** evita recursão do interceptor quando o próprio refresh retorna `401`.
- **Impactos / trade-offs:** o interceptor precisa recriar a request original com cuidado, preservando método, path, query, body, headers e opções relevantes de `RequestOptions`.

- **Decisão:** não tentar refresh para `401` de endpoints públicos de autenticação.
- **Alternativas consideradas:** tentar refresh em qualquer `401`.
- **Motivo da escolha:** `signIn`, reset de senha e OTP usam `401`/falhas como resposta funcional do próprio fluxo; tentar refresh nesses casos poderia mascarar credenciais inválidas ou retentar fluxos públicos indevidamente.
- **Impactos / trade-offs:** o interceptor precisa manter uma lista explícita de endpoints públicos de auth; novos endpoints públicos de auth devem ser adicionados à lista quando surgirem.

- **Decisão:** comparar o token usado na request original com o token atual do cache antes de chamar refresh.
- **Alternativas consideradas:** sempre chamar refresh quando receber `401`.
- **Motivo da escolha:** em concorrência, uma request pode receber `401` enquanto outra já renovou a sessão; a comparação evita refresh duplicado.
- **Impactos / trade-offs:** `onRequest` deve gravar o token usado em `RequestOptions.extra` para que `onError` consiga decidir corretamente.

- **Decisão:** incluir `lib/main.dart` no escopo.
- **Alternativas consideradas:** manter a observação do ticket de que o cold start seria tratado futuramente.
- **Motivo da escolha:** a codebase atual mostra que `_validateSessionOnAppLoad` depende de `requireAuth()` para setar o header; remover `requireAuth()` sem ajustar o bootstrap causaria falha de autenticação em sessões válidas.
- **Impactos / trade-offs:** o cold start também poderá tentar refresh antes do `runApp`, mas sem impacto visual; em falha definitiva, o fluxo existente de limpeza local permanece.

---

# 9. Diagramas e Referências

- **Fluxo de dados:**

```text
Service REST -> RestClient (DioRestClient) -> AuthTokenInterceptor.onRequest
                                           -> CacheDriver.get(accessToken)
                                           -> Authorization: Bearer <token>
                                           -> API

API 401 protegido -> AuthTokenInterceptor.onError
                  -> compara token original com token atual do cache
                  -> [token mudou] retenta request com token atual
                  -> [token igual] mutex -> CacheDriver.get(refreshToken)
                                  -> _refreshDio.post('/auth/refresh')
                                  -> SessionMapper.toDto
                                  -> CacheDriver.set(accessToken/refreshToken)
                                  -> _refreshDio.fetch(request original)
                                  -> handler.resolve(response)

Refresh falha -> CacheDriver.delete(accessToken/refreshToken)
              -> NavigationDriver.goTo(Routes.signIn)
              -> handler.next(error original)
```

- **Hierarquia de widgets:** Não aplicável.

- **Referências:**
  - `lib/rest/dio/dio_rest_client.dart` — ponto de integração do novo interceptor com `Dio`.
  - `lib/rest/clients/rest_client_provider.dart` — provider que deve compor `CacheDriver`, `NavigationDriver` e `AuthTokenInterceptor`.
  - `lib/rest/services/service.dart` — classe base que terá autenticação manual removida.
  - `lib/rest/services/auth_rest_service.dart` — referência de uso de `SessionMapper` e service protegido `getAccount()`.
  - `lib/rest/services/intake_rest_service.dart` — maior conjunto atual de chamadas a `requireAuth()`.
  - `lib/rest/services/library_rest_service.dart` — service impactado encontrado na codebase, apesar de não citado no ticket.
  - `lib/rest/mappers/auth/session_mapper.dart` — mapper para resposta de refresh.
  - `lib/constants/cache_keys.dart` — chaves de tokens persistidos.
  - `lib/constants/routes.dart` — rota `Routes.signIn` usada em falha definitiva.
  - `lib/main.dart` — validação de sessão no cold start que precisa acompanhar a refatoração.

---

# Restrições

- A `View` não deve conter lógica de negócio — não há alteração de UI nesta spec.
- Presenters não fazem chamadas diretas a `RestClient` — não há alteração de presenters nesta spec.
- Services REST não devem acessar `CacheDriver` ou `NavigationDriver` diretamente após esta refatoração.
- `Dio`, `RequestOptions`, `Response`, `DioException` e `Interceptor` devem permanecer confinados à camada `rest/dio`.
- Todos os caminhos citados existem no projeto ou estão marcados como **novo arquivo**.
- A implementação deve preservar `RestResponse<T>` como retorno público dos services.
- A implementação não deve adicionar widgets, rotas visuais ou arquivos de UI.
- A implementação não deve registrar tokens em logs, exceptions expostas ou mensagens de erro.
