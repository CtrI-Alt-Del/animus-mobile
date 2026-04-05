---
title: Plano de Implementacao — Busca Assincrona de Precedentes na Tela de Analise
spec: documentation\features\intake\analysis-precedents\specs\precedents-searching-spec.md
created_at: 2026-04-03
status: closed
---

## Analise de Dependencias

### Artefatos do `core` que desbloqueiam outras camadas
- Criar `AnalysisPrecedentsSearchFiltersDto` em `lib/core/intake/dtos/analysis_precedents_search_filters_dto.dart` para padronizar filtros (`courts`, `precedentKinds`, `limit`) usados por `rest` e `ui`.
- Estender `IntakeService` em `lib/core/intake/interfaces/intake_service.dart` com `searchAnalysisPrecedents(...)` para habilitar disparo do fluxo de busca.
- Estender `IntakeService` em `lib/core/intake/interfaces/intake_service.dart` com `listAnalysisPrecedents(...)` para habilitar consumo da lista final tipada.
- Criar contrato de abertura de link externo no `core` (ex.: `ExternalLinkDriver` em `lib/core/shared/interfaces/`) para suportar `Acessar Pangea` sem acoplamento da UI a SDK.

### Partes de `rest` e `drivers` independentes entre si
- Em `rest`, criacao de `precedent_mapper.dart` e `analysis_precedent_mapper.dart` e independente de configuracoes de `drivers`.
- Em `rest`, implementacoes de `POST /intake/analyses/{analysisId}/precedents/search` e `GET /intake/analyses/{analysisId}/precedents` no `IntakeRestService` nao dependem de `env` nem de navegacao.
- Em `drivers`, exposicao de `PANGEA_URL` no `Env` e `.env.example` e independente da camada `rest`.
- Em `drivers`, adaptador de abertura externa (URL launcher) e independente da implementacao HTTP de precedentes.

### Telas/widgets de `ui` paralelizaveis
- `relevant_precedents_bubble/precedent_list_item` (view puramente visual).
- `precedent_summary/precedent_summary_view.dart` (estados pendente e escolhido).
- `precedents_limit_dialog/precedents_limit_dialog_view.dart` (modal de limite).
- `relevant_precedents_bubble/relevant_precedents_bubble_view.dart` (estados loading/error/empty/content).
- Ajustes do menu de configuracao no header (`analysis_header_actions_view.dart`) podem evoluir em paralelo aos widgets de precedentes.

### Tarefas de `ui` iniciaveis com stub
- `RelevantPrecedentsBubblePresenter.initialize()` e polling podem iniciar com stub de `IntakeService.searchAnalysisPrecedents(...)` e `IntakeService.listAnalysisPrecedents(...)`.
- `RelevantPrecedentsBubbleView`, `PrecedentSummaryView` e `PrecedentsLimitDialogView` podem ser implementados com dados mockados sem aguardar `rest`.
- Integracao da `analysis_screen_view.dart` com os novos widgets pode comecar com callbacks stubs para escolha/confirmacao.

---

## ⚠️ Gargalos identificados

- **F1-T2 + F1-T3 (extensao de `IntakeService`)**: bloqueia 5 tarefas; deve ser iniciada primeiro.
- **F1-T4 + F3-T2 (contrato + driver para link externo)**: bloqueia 3 tarefas; priorizar para destravar `Acessar Pangea` sem violar arquitetura.
- **F6-T2 (alinhamento de design com IDs ausentes na spec, como `Zd1cG` e `e5r7e`)**: bloqueia validacao visual final; deve ser resolvida antes de concluir a fase de hardening.

---

## Mapa de Paralelizacao

| Fase | Objetivo | Depende de | Pode rodar em paralelo com |
|------|----------|------------|----------------------------|
| F1   | Definir contratos base no `core` para busca/listagem de precedentes e link externo | - | - |
| F2   | Implementar integracao REST de precedentes (mappers + endpoints) | F1 | F3, F4, F5 |
| F3   | Preparar `drivers`/config para `PANGEA_URL` e abertura de link externo | F1 (contrato) | F2, F4, F5 |
| F4   | Construir widgets filhos de precedentes (bubble, itens, resumo, dialog) | F1 | F2, F3, F5 |
| F5   | Orquestrar `analysis_screen` e menu para novo fluxo de precedentes | F1 | F2, F3, F4 |
| F6   | Integrar tudo, fechar gaps de design e validar fluxo completo | F2, F3, F4, F5 | - |

---

## Pendencias

- O plano original nao estava com checkboxes de acompanhamento por tarefa (`- [ ]` / `- [x]`) nem anotacoes de estado; tracking foi inicializado nesta execucao.
- A referencia de Confluence fornecida no AGENTS (`pageId=20480001`) retornou 404 nesta conta; contexto de dominio foi lido de `Requisitos do produto` (`pageId=131218`) e `Glossario Juridico` (`pageId=22478851`).

## Divergencias em relacao a Spec

- Os nodes `Zd1cG` e `e5r7e` citados na spec nao existem mais no `design/animus.pen`; os equivalentes usados na validacao visual final foram `VRVSz` (composicao da tela em precedentes), `cUyY8` (estado final escolhido), `9RKck` (bubble) e `7ZcG5` (popover de configuracoes).

## Fases e Tarefas

### F1 — Contratos do Core

- [x] **F1-T1** — Criar DTO `AnalysisPrecedentsSearchFiltersDto` com `courts`, `precedentKinds` e `limit`
  - Camada: `core`
  - Artefato: `lib/core/intake/dtos/analysis_precedents_search_filters_dto.dart`
  - Depende de: —
  - Desbloqueia: F2-T3, F4-T4
  - Artefatos:
    - `lib/core/intake/dtos/analysis_precedents_search_filters_dto.dart`
  - Concluido em: 2026-04-03

- [x] **F1-T2** — Adicionar `searchAnalysisPrecedents(...)` no contrato `IntakeService`
  - Camada: `core`
  - Artefato: `lib/core/intake/interfaces/intake_service.dart`
  - Depende de: F1-T1
  - Desbloqueia: F2-T3, F4-T4
  - Artefatos:
    - `lib/core/intake/interfaces/intake_service.dart`
  - Concluido em: 2026-04-03

- [x] **F1-T3** — Adicionar `listAnalysisPrecedents(...)` no contrato `IntakeService`
  - Camada: `core`
  - Artefato: `lib/core/intake/interfaces/intake_service.dart`
  - Depende de: F1-T1
  - Desbloqueia: F2-T4, F4-T4
  - Artefatos:
    - `lib/core/intake/interfaces/intake_service.dart`
  - Concluido em: 2026-04-03

- [x] **F1-T4** — Criar contrato de abertura externa de URL para links de precedente
  - Camada: `core`
  - Artefato: `lib/core/shared/interfaces/external_link_driver.dart`
  - Depende de: —
  - Desbloqueia: F3-T2, F4-T4
  - Artefatos:
    - `lib/core/shared/interfaces/external_link_driver.dart`
  - Concluido em: 2026-04-03

### F2 — REST de Precedentes

- [x] **F2-T1** — Criar `PrecedentMapper.toDto(...)` para payload de precedente
  - Camada: `rest`
  - Artefato: `lib/rest/mappers/intake/precedent_mapper.dart`
  - Depende de: F1-T1
  - Desbloqueia: F2-T2, F2-T4
  - Artefatos:
    - `lib/rest/mappers/intake/precedent_mapper.dart`
  - Concluido em: 2026-04-03

- [x] **F2-T2** — Criar `AnalysisPrecedentMapper.toDto(...)` reutilizando `PrecedentMapper`
  - Camada: `rest`
  - Artefato: `lib/rest/mappers/intake/analysis_precedent_mapper.dart`
  - Depende de: F2-T1
  - Desbloqueia: F2-T4
  - Artefatos:
    - `lib/rest/mappers/intake/analysis_precedent_mapper.dart`
  - Concluido em: 2026-04-03

- [x] **F2-T3** — Implementar `searchAnalysisPrecedents(...)` com `POST /intake/analyses/{analysisId}/precedents/search`
  - Camada: `rest`
  - Artefato: `lib/rest/services/intake_rest_service.dart`
  - Depende de: F1-T1, F1-T2
  - Desbloqueia: F6-T1
  - Artefatos:
    - `lib/rest/services/intake_rest_service.dart`
  - Concluido em: 2026-04-03

- [x] **F2-T4** — Implementar `listAnalysisPrecedents(...)` com `GET /intake/analyses/{analysisId}/precedents` retornando `ListResponse<AnalysisPrecedentDto>`
  - Camada: `rest`
  - Artefato: `lib/rest/services/intake_rest_service.dart`
  - Depende de: F1-T3, F2-T2
  - Desbloqueia: F6-T1
  - Artefatos:
    - `lib/rest/services/intake_rest_service.dart`
  - Concluido em: 2026-04-03

### F3 — Drivers e Configuracao de Pangea

- [x] **F3-T1** — Expor `PANGEA_URL` no `Env` e registrar na `.env.example`
  - Camada: `drivers`
  - Artefato: `lib/constants/env.dart`, `.env.example`
  - Depende de: —
  - Desbloqueia: F4-T4, F6-T1
  - Artefatos:
    - `lib/constants/env.dart`
    - `.env.example`
  - Concluido em: 2026-04-03

- [x] **F3-T2** — Implementar driver concreto para abrir URL externa (link do Pangea)
  - Camada: `drivers`
  - Artefato: `lib/drivers/external-link-driver/index.dart` e implementacao concreta
  - Depende de: F1-T4
  - Desbloqueia: F4-T4, F6-T1
  - Artefatos:
    - `lib/drivers/external-link-driver/url_launcher/url_launcher_external_link_driver.dart`
    - `pubspec.yaml`
  - Concluido em: 2026-04-03

- [x] **F3-T3** — Expor provider do driver externo para consumo na UI
  - Camada: `drivers`
  - Artefato: `lib/drivers/external-link-driver/index.dart`
  - Depende de: F3-T2
  - Desbloqueia: F6-T1
  - Artefatos:
    - `lib/drivers/external-link-driver/index.dart`
  - Concluido em: 2026-04-03

### F4 — Widgets Filhos de Precedentes

- [x] **F4-T1** — Criar widget interno `precedent_list_item` (item da lista com badge e chevron)
  - Camada: `ui`
  - Artefato: `lib/ui/intake/widgets/pages/analysis_screen/relevant_precedents_bubble/precedent_list_item/index.dart`, `lib/ui/intake/widgets/pages/analysis_screen/relevant_precedents_bubble/precedent_list_item/precedent_list_item_view.dart`
  - Depende de: F1-T1
  - Desbloqueia: F4-T5
  - Status: [em andamento] -> [x]

  - Artefatos:
    - `lib/ui/intake/widgets/pages/analysis_screen/relevant_precedents_bubble/precedent_list_item/index.dart`
    - `lib/ui/intake/widgets/pages/analysis_screen/relevant_precedents_bubble/precedent_list_item/precedent_list_item_view.dart`
  - Concluido em: 2026-04-03

- [x] **F4-T2** — Criar `PrecedentSummaryView` para estados `pending` e `chosen`
  - Camada: `ui`
  - Artefato: `lib/ui/intake/widgets/pages/analysis_screen/precedent_summary/index.dart`, `lib/ui/intake/widgets/pages/analysis_screen/precedent_summary/precedent_summary_view.dart`
  - Depende de: F1-T1
  - Desbloqueia: F5-T4
  - Status: [em andamento] -> [x]

  - Artefatos:
    - `lib/ui/intake/widgets/pages/analysis_screen/precedent_summary/index.dart`
    - `lib/ui/intake/widgets/pages/analysis_screen/precedent_summary/precedent_summary_view.dart`
  - Concluido em: 2026-04-03

- [x] **F4-T3** — Criar `PrecedentsLimitDialogView` com slider e acoes `Cancelar`/`Aplicar`
  - Camada: `ui`
  - Artefato: `lib/ui/intake/widgets/pages/analysis_screen/precedents_limit_dialog/index.dart`, `lib/ui/intake/widgets/pages/analysis_screen/precedents_limit_dialog/precedents_limit_dialog_view.dart`
  - Depende de: —
  - Desbloqueia: F5-T4
  - Status: [em andamento] -> [x]

  - Artefatos:
    - `lib/ui/intake/widgets/pages/analysis_screen/precedents_limit_dialog/index.dart`
    - `lib/ui/intake/widgets/pages/analysis_screen/precedents_limit_dialog/precedents_limit_dialog_view.dart`
  - Concluido em: 2026-04-03

- [x] **F4-T4** — Criar `RelevantPrecedentsBubblePresenter` + provider (polling 3s, retry idempotente, ordenacao, escolha local, abrir Pangea)
  - Camada: `ui`
  - Artefato: `lib/ui/intake/widgets/pages/analysis_screen/relevant_precedents_bubble/relevant_precedents_bubble_presenter.dart`
  - Depende de: F1-T1, F1-T2, F1-T3, F3-T1
  - Desbloqueia: F4-T5, F6-T1
  - Status: [em andamento] -> [x]

  - Artefatos:
    - `lib/ui/intake/widgets/pages/analysis_screen/relevant_precedents_bubble/relevant_precedents_bubble_presenter.dart`
  - Concluido em: 2026-04-03

- [x] **F4-T5** — Criar `RelevantPrecedentsBubbleView` com estados loading/error/empty/content
  - Camada: `ui`
  - Artefato: `lib/ui/intake/widgets/pages/analysis_screen/relevant_precedents_bubble/index.dart`, `lib/ui/intake/widgets/pages/analysis_screen/relevant_precedents_bubble/relevant_precedents_bubble_view.dart`
  - Depende de: F4-T1, F4-T4
  - Desbloqueia: F5-T4
  - Status: [em andamento] -> [x]

  - Artefatos:
    - `lib/ui/intake/widgets/pages/analysis_screen/relevant_precedents_bubble/index.dart`
    - `lib/ui/intake/widgets/pages/analysis_screen/relevant_precedents_bubble/relevant_precedents_bubble_view.dart`
  - Concluido em: 2026-04-03

### F5 — Orquestracao da Analysis Screen

- [x] **F5-T1** — Ajustar `load()` para reentrada nos estados de precedentes mantendo contexto (peticao + resumo)
  - Camada: `ui`
  - Artefato: `lib/ui/intake/widgets/pages/analysis_screen/analysis_screen_presenter.dart`
  - Depende de: F1-T1
  - Desbloqueia: F5-T2, F5-T4
  - Status: [em andamento] -> [x]
  - Artefatos:
    - `lib/ui/intake/widgets/pages/analysis_screen/analysis_screen_presenter.dart`
  - Concluido em: 2026-04-03

- [x] **F5-T2** — Implementar `showRelevantPrecedents` e evoluir `confirmAndViewPrecedents()`
  - Camada: `ui`
  - Artefato: `lib/ui/intake/widgets/pages/analysis_screen/analysis_screen_presenter.dart`
  - Depende de: F5-T1
  - Desbloqueia: F5-T4
  - Status: [em andamento] -> [x]
  - Artefatos:
    - `lib/ui/intake/widgets/pages/analysis_screen/analysis_screen_presenter.dart`
  - Concluido em: 2026-04-03

- [x] **F5-T3** — Incluir acao `Qtd. precedentes` no menu de configuracao da analise
  - Camada: `ui`
  - Artefato: `lib/ui/intake/widgets/pages/analysis_screen/analysis_header/analysis_header_actions/analysis_header_actions_view.dart`, `lib/ui/intake/widgets/pages/analysis_screen/analysis_header/analysis_header_view.dart`
  - Depende de: —
  - Desbloqueia: F5-T4
  - Status: [em andamento] -> [x]
  - Artefatos:
    - `lib/ui/intake/widgets/pages/analysis_screen/analysis_header/analysis_header_actions/analysis_header_actions_view.dart`
    - `lib/ui/intake/widgets/pages/analysis_screen/analysis_header/analysis_header_view.dart`
  - Concluido em: 2026-04-03

- [x] **F5-T4** — Integrar novos widgets na `analysis_screen_view` e ocultar `AnalysisActionBar` durante fluxo de precedentes
  - Camada: `ui`
  - Artefato: `lib/ui/intake/widgets/pages/analysis_screen/analysis_screen_view.dart`
  - Depende de: F5-T2, F5-T3, F4-T2, F4-T3, F4-T5
  - Desbloqueia: F6-T1, F6-T2
  - Status: [em andamento] -> [x]
  - Artefatos:
    - `lib/ui/intake/widgets/pages/analysis_screen/analysis_screen_view.dart`
  - Concluido em: 2026-04-03

- [x] **F5-T5** — Atualizar barrels `index.dart` da feature para fronteira publica consistente
  - Camada: `ui`
  - Artefato: `lib/ui/intake/widgets/pages/analysis_screen/index.dart` e novos `index.dart` internos
  - Depende de: F4-T1, F4-T2, F4-T3, F4-T5
  - Desbloqueia: F6-T1
  - Status: [em andamento] -> [x]
  - Artefatos:
    - `lib/ui/intake/widgets/pages/analysis_screen/index.dart`
  - Concluido em: 2026-04-03

### F6 — Integracao e Validacao Final

- [x] **F6-T1** — Substituir stubs por integracao real (`IntakeService` + driver externo) e validar fluxo fim a fim
  - Camada: `ui/rest/drivers`
  - Artefato: `lib/ui/intake/widgets/pages/analysis_screen/...`, `lib/rest/services/intake_rest_service.dart`, `lib/drivers/external-link-driver/...`
  - Depende de: F2-T3, F2-T4, F3-T3, F4-T4, F5-T4
  - Desbloqueia: F6-T3, F6-T4
  - Status: [em andamento] -> [x]
  - Artefatos:
    - `lib/ui/intake/widgets/pages/analysis_screen/analysis_screen_view.dart`
    - `lib/ui/intake/widgets/pages/analysis_screen/relevant_precedents_bubble/relevant_precedents_bubble_presenter.dart`
  - Concluido em: 2026-04-03

- [x] **F6-T2** — Ajustar aderencia visual com os nodes reais disponiveis no `design/animus.pen` (`9RKck`, `VRVSz`, `cUyY8`, `7ZcG5`) e mapear equivalentes para IDs ausentes da spec
  - Camada: `ui`
  - Artefato: `lib/ui/intake/widgets/pages/analysis_screen/...`
  - Depende de: F5-T4
  - Desbloqueia: F6-T4
  - Status: [em andamento] -> [x]
  - Artefatos:
    - `lib/ui/intake/widgets/pages/analysis_screen/relevant_precedents_bubble/relevant_precedents_bubble_view.dart`
    - `lib/ui/intake/widgets/pages/analysis_screen/relevant_precedents_bubble/precedent_list_item/precedent_list_item_view.dart`
    - `lib/ui/intake/widgets/pages/analysis_screen/precedent_summary/precedent_summary_view.dart`
  - Concluido em: 2026-04-03

- [x] **F6-T3** — Hardening de erros e resiliencia (retry, timer unico, mensagens de falha/empty)
  - Camada: `ui`
  - Artefato: `lib/ui/intake/widgets/pages/analysis_screen/relevant_precedents_bubble/relevant_precedents_bubble_presenter.dart`
  - Depende de: F6-T1
  - Desbloqueia: F6-T4
  - Status: [em andamento] -> [x]
  - Artefatos:
    - `lib/ui/intake/widgets/pages/analysis_screen/relevant_precedents_bubble/relevant_precedents_bubble_presenter.dart`
  - Concluido em: 2026-04-03

- [x] **F6-T4** — Validacao final tecnica e de regressao da feature
  - Camada: `ui/rest/drivers`
  - Artefato: `flutter analyze` e smoke manual do fluxo
  - Depende de: F6-T1, F6-T2, F6-T3
  - Desbloqueia: Entrega final
  - Status: [em andamento] -> [x]
  - Artefatos:
    - `dart format .`
    - `flutter analyze`
    - `flutter test`
  - Concluido em: 2026-04-03

---
