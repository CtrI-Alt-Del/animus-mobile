---
title: Plano de Implementação — Archived Analyses Screen (ANI-107)
spec: ../specs/archived-analyses-screen-spec.md
created_at: 2026-05-18
status: closed
---

---

## Análise de Dependências

### Artefatos do `core` que desbloqueiam outras camadas

- Nenhum artefato novo do `core` é necessário. Todos os contratos consumidos (`IntakeService.listAnalyses` com `isArchived`, `IntakeService.unarchiveAnalysis`, `AnalysisDto.isArchived`, `AnalysisTypeDto`, `CursorPaginationResponse<AnalysisDto>`, `RestResponse<T>`, `NavigationDriver`) já existem.

### Partes de `rest` e `drivers` independentes entre si

- Nenhum novo artefato de `rest` ou `drivers`. O `IntakeRestService` já implementa `listAnalyses(isArchived: true)` e `unarchiveAnalysis`; o `GoRouterNavigationDriver` já cobre `pushTo`, `goBack` e `goTo`.

### Presenters/widgets/screens paralelizáveis

- O `ArchivedAnalysesScreenPresenter` precisa existir antes da `View` da Screen, mas os widgets internos puramente visuais (`ArchivedAnalysesLoadingState`, `EmptyState`, `ErrorState`, `SkeletonCard`, `InlineError`, `LoadingMore`, `Card`) e o `SearchBar` podem ser desenvolvidos em paralelo entre si, pois não compartilham estado.
- O ajuste em `AnalysisHeaderView` é totalmente independente da tela nova e pode rodar em paralelo desde o início.
- O ajuste em `ProfileSettingsGroupView` + `ProfileScreenPresenter`/`View` é independente da tela nova (basta `Routes.archivedAnalyses` existir) e pode rodar em paralelo após F1.

### Tarefas iniciáveis com stub

- A `ArchivedAnalysesScreenView` (montagem do Scaffold, integração com Presenter e widgets internos) pode iniciar com stubs/placeholders dos widgets internos enquanto eles são finalizados em paralelo, desde que o presenter (F2) já esteja pronto.

---

## ⚠️ Gargalos identificados

- **F1 — Constants + Router**: bloqueia a navegação a partir do perfil e o registro da rota. Deve ser a primeira a ser entregue para permitir testes manuais e composição final.
- **F2 — `ArchivedAnalysesScreenPresenter`**: bloqueia toda a montagem da `ArchivedAnalysesScreenView` (F3) e dos widgets internos que recebem signals/callbacks (F4). É o segundo gargalo crítico.

---

## Mapa de Paralelização

| Fase | Objetivo                                                       | Depende de | Pode rodar em paralelo com |
|------|----------------------------------------------------------------|------------|----------------------------|
| F1   | Constants + Router (`Routes.archivedAnalyses` + GoRoute)        | -          | F5, F6                     |
| F2   | `ArchivedAnalysesScreenPresenter` + Riverpod providers          | F1         | F5, F6, F7                 |
| F3   | `ArchivedAnalysesScreenView` + `index.dart`                     | F2, F4     | -                          |
| F4   | Widgets internos puramente visuais e `SearchBar`                | -          | F1, F2, F5, F6, F7         |
| F5   | `AnalysisHeaderView` (prop `isArchived` + badge)                 | -          | F1, F2, F4, F6, F7         |
| F6   | `AnalysisScreenView` + `SecondInstanceAnalysisScreenView` (consumo da prop `isArchived`) | F5 | F1, F2, F4, F7 |
| F7   | `ProfileSettingsGroupView` + `ProfileScreenPresenter`/`View` (entrada na rota) | F1 | F2, F4, F5, F6 |

---

## Fases e Tarefas

### F1 — Constants + Router

- [x] **F1-T1** — Adicionar `Routes.archivedAnalyses = '/archived-analyses'` em `lib/constants/routes.dart`.
  - Camada: `constants`
  - Artefato: `lib/constants/routes.dart`
  - Depende de: —
  - Desbloqueia: F1-T2, F2-T1, F7-T1

- [x] **F1-T2** — Registrar `GoRoute(path: Routes.archivedAnalyses, builder: ...)` no nível raiz de `appRouter`, importando `archived_analyses_screen/index.dart`.
  - Camada: `app/router`
  - Artefato: `lib/router.dart`
  - Depende de: F1-T1, F3-T1 (o builder referencia `ArchivedAnalysesScreen`; pode ser deixado como stub temporário se F3-T1 ainda não estiver pronto)
  - Desbloqueia: F7-T1 (navegação ponta-a-ponta)

### F2 — Presenter da Screen

- [x] **F2-T1** — Implementar `ArchivedAnalysesScreenPresenter` com todos os signals, computeds, métodos (`initialize`, `loadNextPage`, `refresh`, `updateSearchQuery`, `clearSearch`, `unarchive`, `openAnalysis`, `goBack`, `formatCreatedAt`, `dispose`, `_resolveErrorMessage`) e os Riverpod providers (`archivedAnalysesScreenPresenterProvider` e `archivedAnalysesScreenInitializationProvider`).
  - Camada: `ui` (presenter)
  - Artefato: `lib/ui/intake/widgets/pages/archived_analyses_screen/archived_analyses_screen_presenter.dart`
  - Depende de: F1-T1
  - Desbloqueia: F3-T1

### F3 — View da Screen

- [x] **F3-T1** — Implementar `ArchivedAnalysesScreenView` (`ConsumerWidget`), montar `Scaffold + SafeArea + AppBar/header com back + título`, integrar `ArchivedAnalysesSearchBar`, e reagir aos signals do presenter via `Watch` para alternar entre `LoadingState`, `ErrorState`, `EmptyState` (geral/busca) e `ArchivedAnalysesList`. Implementar SnackBars para `unarchive` (sucesso e erro). Criar `index.dart` exportando `typedef ArchivedAnalysesScreen = ArchivedAnalysesScreenView;` e re-exportando os barrels dos widgets internos.
  - Camada: `ui` (view)
  - Artefato: `lib/ui/intake/widgets/pages/archived_analyses_screen/archived_analyses_screen_view.dart`, `lib/ui/intake/widgets/pages/archived_analyses_screen/index.dart`
  - Depende de: F2-T1, F4-T1..T8
  - Desbloqueia: F1-T2 (passar a referenciar o widget real), F7-T1 (navegação ponta-a-ponta funciona)

### F4 — Widgets internos da Screen

- [x] **F4-T1** — Implementar `ArchivedAnalysesLoadingState` (`View only`) com 4 `ArchivedAnalysesSkeletonCard`. Criar `index.dart`.
  - Camada: `ui` (widget interno)
  - Artefato: `lib/ui/intake/widgets/pages/archived_analyses_screen/archived_analyses_loading_state/`
  - Depende de: F4-T4
  - Desbloqueia: F3-T1

- [x] **F4-T2** — Implementar `ArchivedAnalysesEmptyState` (`View only`) com props `message` e `icon` (default `Icons.inbox_outlined`). Criar `index.dart`.
  - Camada: `ui` (widget interno)
  - Artefato: `lib/ui/intake/widgets/pages/archived_analyses_screen/archived_analyses_empty_state/`
  - Depende de: —
  - Desbloqueia: F3-T1

- [x] **F4-T3** — Implementar `ArchivedAnalysesErrorState` (`View only`) com props `message` e `onRetry`. Criar `index.dart`.
  - Camada: `ui` (widget interno)
  - Artefato: `lib/ui/intake/widgets/pages/archived_analyses_screen/archived_analyses_error_state/`
  - Depende de: —
  - Desbloqueia: F3-T1

- [x] **F4-T4** — Implementar `ArchivedAnalysesSkeletonCard` (`View only`). Criar `index.dart`.
  - Camada: `ui` (widget interno)
  - Artefato: `lib/ui/intake/widgets/pages/archived_analyses_screen/archived_analyses_skeleton_card/`
  - Depende de: —
  - Desbloqueia: F4-T1

- [x] **F4-T5** — Implementar `ArchivedAnalysesInlineError` (`View only`) com prop `message`. Criar `index.dart`.
  - Camada: `ui` (widget interno)
  - Artefato: `lib/ui/intake/widgets/pages/archived_analyses_screen/archived_analyses_inline_error/`
  - Depende de: —
  - Desbloqueia: F4-T8

- [x] **F4-T6** — Implementar `ArchivedAnalysesLoadingMore` (`View only`). Criar `index.dart`.
  - Camada: `ui` (widget interno)
  - Artefato: `lib/ui/intake/widgets/pages/archived_analyses_screen/archived_analyses_loading_more/`
  - Depende de: —
  - Desbloqueia: F4-T8

- [x] **F4-T7** — Implementar `ArchivedAnalysesSearchBar` (`View + Presenter`) com `TextEditingController`, prefix `search`, suffix `clear` condicional, props `initialQuery`, `onQueryChanged`, `onClear`. Criar `index.dart`.
  - Camada: `ui` (widget interno)
  - Artefato: `lib/ui/intake/widgets/pages/archived_analyses_screen/archived_analyses_search_bar/`
  - Depende de: —
  - Desbloqueia: F3-T1

- [x] **F4-T8** — Implementar `ArchivedAnalysesList` (`View only`) com `NotificationListener<ScrollNotification>` para `onLoadMore`, `ListView.separated` com `ArchivedAnalysisCard`, `ArchivedAnalysesInlineError` no topo quando `errorMessage != null`, `ArchivedAnalysesLoadingMore` no footer quando `isLoadingMore`. Criar `index.dart`.
  - Camada: `ui` (widget interno)
  - Artefato: `lib/ui/intake/widgets/pages/archived_analyses_screen/archived_analyses_list/`
  - Depende de: F4-T5, F4-T6, F4-T9
  - Desbloqueia: F3-T1

- [x] **F4-T9** — Implementar `ArchivedAnalysisCard` (`View only`) com `InkWell` (tap), título, dateLabel, `IconButton` trailing de `Desarquivar` que abre um `AlertDialog` de confirmação e em seguida chama `onUnarchive`. Criar `index.dart`.
  - Camada: `ui` (widget interno)
  - Artefato: `lib/ui/intake/widgets/pages/archived_analyses_screen/archived_analysis_card/`
  - Depende de: —
  - Desbloqueia: F4-T8

### F5 — Analysis Header (badge `Analise arquivada`)

- [x] **F5-T1** — Adicionar prop `final bool isArchived` (default `false`) ao `AnalysisHeaderView` e renderizar um chip/badge inline com texto `Analise arquivada` quando `isArchived = true`.
  - Camada: `ui` (componente compartilhado)
  - Artefato: `lib/ui/intake/widgets/components/analysis_header/analysis_header_view.dart`
  - Depende de: —
  - Desbloqueia: F6-T1, F6-T2

### F6 — Consumo do badge nas screens de análise

- [x] **F6-T1** — Em `FirstInstanceAnalysisScreenView`, ler o estado de `presenter.analysis?.isArchived` (signal correspondente) e repassar para `AnalysisHeader.isArchived`.
  - Camada: `ui` (view)
  - Artefato: `lib/ui/intake/widgets/pages/first_instance_analysis_screen/first_instance_analysis_screen_view.dart`
  - Depende de: F5-T1
  - Desbloqueia: —

- [x] **F6-T2** — Em `SecondInstanceAnalysisScreenView`, ler `presenter.analysis?.isArchived` (signal correspondente) e repassar para `AnalysisHeader.isArchived`.
  - Camada: `ui` (view)
  - Artefato: `lib/ui/intake/widgets/pages/second_instance_analysis_screen/second_instance_analysis_screen_view.dart`
  - Depende de: F5-T1
  - Desbloqueia: —

### F7 — Entrada no perfil

- [x] **F7-T1** — Adicionar tile `Analises arquivadas` (com `Icons.inventory_2_outlined`) em `ProfileSettingsGroupView`, expor callback `onArchivedAnalysesTap` no construtor; adicionar metodo `goToArchivedAnalyses()` em `ProfileScreenPresenter` que chama `_navigationDriver.pushTo(Routes.archivedAnalyses)`; repassar `presenter.goToArchivedAnalyses` em `ProfileScreenView`.
  - Camada: `ui` (presenter + view)
  - Artefato: `lib/ui/auth/widgets/pages/profile_screen/profile_settings_group/profile_settings_group_view.dart`, `lib/ui/auth/widgets/pages/profile_screen/profile_screen_presenter.dart`, `lib/ui/auth/widgets/pages/profile_screen/profile_screen_view.dart`
  - Depende de: F1-T1
  - Desbloqueia: —

---

## Pendências

- O design especifico da tela arquivada ainda nao foi publicado; a implementacao seguira o padrao da Home com adaptacoes. Quando o design vier, ajustes visuais podem ser feitos sem impacto arquitetural.
- Confirmar durante a implementacao se `FirstInstanceAnalysisScreenPresenter` e `SecondInstanceAnalysisScreenPresenter` ja expoem um signal direto para `analysis` (ou equivalente que permita derivar `isArchived`). Se nao, derivar do estado existente sem alterar o contrato do presenter.
