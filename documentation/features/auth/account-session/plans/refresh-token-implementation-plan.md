---
title: Plano de Implementacao — Refresh automatico de sessao
spec: [documentation/features/auth/account-session/specs/refresh-token-spec.md](documentation/features/auth/account-session/specs/refresh-token-spec.md)
created_at: 2026-05-30
status: closed
---

## Mapa de Paralelizacao

| Fase | Objetivo | Depende de | Pode rodar em paralelo com |
|------|----------|------------|----------------------------|
| F1 | Preparar a infraestrutura REST para autenticacao centralizada | - | F3 |
| F2 | Compor o restClientProvider com cache, navegacao e interceptor | F1 | F3, F4 |
| F3 | Remover autenticacao manual dos services protegidos | - | F1, F2 |
| F4 | Ajustar o bootstrap de sessao no cold start | F1, F3 | F2 |

## Fases e Tarefas

### F1 — Preparar a infraestrutura REST para autenticacao centralizada

- [x] **F1-T1** — Criar `AuthTokenInterceptor` com injecao de header, refresh automatico, serializacao de refresh concorrente, retry da request original e limpeza de sessao em falha definitiva
  - Status: [em andamento] -> [x]
  - Artefato: `lib/rest/dio/auth_token_interceptor.dart`
  - Concluido em: 2026-05-30

- [x] **F1-T2** — Ajustar `DioRestClient` para aceitar `List<Interceptor>` no construtor e registrar os interceptors internamente, preservando compatibilidade com clients sem autenticacao
  - Status: [em andamento] -> [x]
  - Artefato: `lib/rest/dio/dio_rest_client.dart`
  - Concluido em: 2026-05-30

### F2 — Compor o `restClientProvider` com cache, navegacao e interceptor

- [x] **F2-T1** — Atualizar `restClientProvider` para ler `cacheDriverProvider` e `navigationDriverProvider`, instanciar `AuthTokenInterceptor` e compor `DioRestClient` com interceptors
  - Status: [em andamento] -> [x]
  - Artefato: `lib/rest/clients/rest_client_provider.dart`
  - Concluido em: 2026-05-30

### F3 — Remover autenticacao manual dos services protegidos

- [x] **F3-T1** — Simplificar a classe base `Service` para depender apenas de `RestClient` e remover `setAuthHeader()`, `requireAuth()` e `unauthorizedResponse()`
  - Artefato: `lib/rest/services/service.dart`
  - Concluido em: 2026-05-30

- [x] **F3-T2** — Atualizar `AuthRestService` para usar apenas `restClient` e remover a validacao manual de autenticacao em `getAccount()` e `updateAccount()`
  - Artefato: `lib/rest/services/auth_rest_service.dart`
  - Concluido em: 2026-05-30

- [x] **F3-T3** — Atualizar `IntakeRestService` para usar apenas `restClient` e remover todos os blocos de `requireAuth()`
  - Artefato: `lib/rest/services/intake_rest_service.dart`
  - Concluido em: 2026-05-30

- [x] **F3-T4** — Atualizar `StorageRestService` para usar apenas `restClient` e remover a validacao manual de autenticacao em `generateAnalysisDocumentUploadUrl()`
  - Artefato: `lib/rest/services/storage_rest_service.dart`
  - Concluido em: 2026-05-30

- [x] **F3-T5** — Atualizar `LibraryRestService` para usar apenas `restClient` e remover todos os blocos de `requireAuth()`
  - Artefato: `lib/rest/services/library_rest_service.dart`
  - Concluido em: 2026-05-30

- [x] **F3-T6** — Atualizar a composicao dos providers de services para remover `CacheDriver` e `NavigationDriver` dos construtores dos services protegidos
  - Artefato: `lib/rest/services/index.dart`
  - Concluido em: 2026-05-30

### F4 — Ajustar o bootstrap de sessao no cold start

- [x] **F4-T1** — Ajustar `_validateSessionOnAppLoad` para instanciar `DioRestClient` com `AuthTokenInterceptor` e construir `AuthRestService` com o novo construtor baseado apenas em `restClient`
  - Status: [em andamento] -> [x]
  - Artefato: `lib/main.dart`
  - Concluido em: 2026-05-30

## Pendencias

- Nenhuma

## Divergencias em relacao a Spec

- Nenhuma
