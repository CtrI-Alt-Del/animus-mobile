---
title: Busca assincrona de precedentes na tela de analise
prd: https://joaogoliveiragarcia.atlassian.net/wiki/x/AYAMAQ
ticket: https://joaogoliveiragarcia.atlassian.net/browse/ANI-49
status: closed
last_updated_at: 2026-04-04
---

# 1. Objetivo

Entregar o recorte mobile de `ANI-49` na tela `analysis_screen`: apos o usuario concluir a etapa de resumo da peticao e acionar `Buscar precedentes`, o app deve montar um widget dedicado (`RelevantPrecedentsBubble`) que dispara a busca assincrona de precedentes, acompanha o processamento por polling em `GET /intake/analyses/{analysis_id}`, e exibe a lista final ordenada por `applicabilityPercentage` com estados de loading, erro e vazio. Quando a busca terminar, a tela deve suportar os estados finais de visualizacao com dialog dedicado por precedente (`PrecedentDialog`) ao tocar em item da lista, seguindo os frames `Zd1cG` (nao escolhido) e `cUyY8` (escolhido), alem do dialog de configuracao da quantidade retornada (`aBP2X`). A implementacao deve reutilizar a arquitetura atual em camadas do modulo `intake`, manter a `AnalysisScreen` como orquestradora do fluxo de rota e concentrar a logica de busca, polling, configuracao e escolha em presenters filhos. Visualmente, o fluxo deve seguir os frames `AI Precedentes` (`9RKck`), `H - Visualizacao Sem Precedente Escolhido` (`Zd1cG`), `H - Visualizacao Final` (`cUyY8`) e `precedentsLimitModal` (`aBP2X`) em `design/animus.pen`.

---

# 2. Escopo

## 2.1 In-scope

- Integrar a etapa de busca de precedentes dentro de `lib/ui/intake/widgets/pages/analysis_screen/` apos `AnalysisStatusDto.petitionAnalyzed`.
- Criar o widget `RelevantPrecedentsBubble` com pasta propria, `index.dart`, `*_view.dart` e `*_presenter.dart`.
- Disparar `POST /intake/analyses/{analysis_id}/precedents/search` com body `{ courts: [], precedent_kinds: [], limit: 5 }` quando o fluxo de precedentes for iniciado pela primeira vez.
- Fazer polling de `GET /intake/analyses/{analysis_id}` a cada `3s` enquanto a `analysis` estiver em `searchingPrecedents`, `analyzingPrecedentsApplicability` ou `generatingSynthesis`.
- Tratar reentrada da tela: se a `analysis` ja estiver em status de precedentes ao abrir novamente, o widget deve continuar do estado corrente sem redisparar o `POST`.
- Buscar a lista final via `GET /intake/analyses/{analysis_id}/precedents` quando o status chegar a `waitingPrecedentChoice` ou `precedentChosen`.
- Confirmar a escolha do precedente via `PATCH /intake/analyses/{analysis_id}/precedents/choose` com query params `court`, `kind` e `number`, retornando `AnalysisStatusDto`.
- Ordenar os precedentes por `applicabilityPercentage` decrescente antes de renderizar.
- Exibir header do bubble com icone judicial, titulo `Precedentes Relevantes` e badge com quantidade total retornada.
- Exibir cada item com badge visual de aplicabilidade, identificador do precedente (`court + kind + number`) e affordance de toque.
- Seguir a composicao visual do node `9RKck`: avatar circular amarelo fora do card principal, card escuro com header destacado e itens separados por divisoria superior.
- Exibir erro recuperavel com retry manual quando o `POST`, o polling ou o `GET` final falharem.
- Expor botao `Refazer busca` abaixo da lista de precedentes para reiniciar manualmente o fluxo de precedentes mesmo fora do estado de erro.
- Exibir estado vazio dentro do bubble quando a lista final vier vazia.
- Estender `IntakeService` e `IntakeRestService` com os contratos necessarios para busca e listagem de precedentes.
- Cobrir os estados finais de visualizacao do precedente com `PrecedentDialog` conforme `Zd1cG`, aberto por item da lista.
- Adicionar no menu de configuracao da analise as acoes `Qtd. precedentes` e `Filtros`, abrindo os modais conforme `7ZcG5`, `aBP2X` e frame de filtros criado no `design/animus.pen`.
- Exibir badge com quantidade de filtros aplicados no item `Filtros` do popover quando houver selecao ativa.
- Implementar modal de filtros de precedentes com selecao de `CourtDto.values` e `PrecedentKindDto.values`, incluindo `X` para fechar, limpar filtros e aplicar filtros.
- Implementar agrupamento expansivel de tribunais (`Superiores`, `TRFs`, `TJs`, `TRTs`) para evitar overflow no modal.
- No dialog de `Zd1cG`, exibir CTA fixo `Escolher Precedente`, link `Acessar Pangea` e secao `Síntese Explicativa` sempre visivel (com fallback quando vazia).
- Ao escolher precedente com sucesso, aplicar `jumpTo(maxScrollExtent)` na `analysis_screen` para revelar o card de precedente escolhido.

## 2.2 Out-of-scope

- Persistencia local offline da escolha do precedente sem sincronizacao com backend.
- Agrupamento visual dos precedentes em secoes `Aplicavel`, `Possivelmente aplicavel` e `Não aplicável`; nesta task a lista sera unica e ordenada por percentual.
- Criacao da rota de detalhe do precedente; o item deve apenas expor ponto de integracao para toque.
- Exportacao em PDF e qualquer integracao com `RF 06`.
- Correcao dos valores string de `AnalysisStatusDto` (`WAITING_PRECEDENT_CHOISE`, `PRECEDENT_CHOSED`) ja alinhados ao backend atual.

---

# 3. Requisitos

## 3.1 Funcionais

- Enquanto `AnalysisScreenPresenter.status == AnalysisStatusDto.petitionAnalyzed`, o CTA principal da `AnalysisActionBar` deve continuar com o label `Buscar precedentes`.
- Ao tocar em `Buscar precedentes`, a tela deve entrar no passo de precedentes e montar `RelevantPrecedentsBubble` abaixo do `PetitionSummaryCard`, ocultando a `AnalysisActionBar` para evitar disparos duplicados.
- Ao abrir a tela com `AnalysisStatusDto.searchingPrecedents`, `analyzingPrecedentsApplicability`, `generatingSynthesis`, `waitingPrecedentChoice` ou `precedentChosen`, a tela deve montar o bubble automaticamente.
- Na primeira montagem do bubble para uma `analysis` ainda em `petitionAnalyzed`, o app deve chamar `IntakeService.searchAnalysisPrecedents(...)` usando filtros selecionados no fluxo; na ausencia de ajuste manual, usar filtros vazios e `limit` default `5`.
- Durante o processamento, o bubble deve exibir feedback textual aderente ao status atual:
- `searchingPrecedents` -> buscando na base nacional.
- `analyzingPrecedentsApplicability` -> analisando da proximidade/aplicabilidade.
- `generatingSynthesis` -> gerando as sínteses explicativas.
- O polling deve parar imediatamente quando o status chegar a `waitingPrecedentChoice`, `precedentChosen` ou `failed`.
- Ao chegar em `waitingPrecedentChoice` ou `precedentChosen`, o app deve buscar `GET /intake/analyses/{analysis_id}/precedents`, ordenar os itens por `applicabilityPercentage` desc e renderizar a lista.
- Ao tocar em um item da lista final, o app deve abrir `PrecedentDialog` em full screen seguindo o estado visual do node `Zd1cG` para aquele precedente.
- O `PrecedentDialog` deve manter o link `Acessar Pangea`, CTA inferior `Escolher Precedente` e a secao `Síntese Explicativa` sempre renderizada.
- Ao tocar no CTA `Escolher Precedente` no `PrecedentDialog`, o app deve chamar `IntakeService.chooseAnalysisPrecedent(...)` usando `precedent.identifier` (`court`, `kind`, `number`) e fechar o dialog apenas em sucesso.
- Quando `precedent.isChosen == true`, o `PrecedentDialog` deve aplicar o estado visual de escolhido conforme node `cUyY8` (label `Precedente Escolhido`, badge verde e CTA final de estado concluido).
- O link `Acessar Pangea` deve ser construido a partir de `PrecedentDto.identifier` (`PrecedentIdentifierDto`) usando a base `PANGEA_URL` vinda do `env`, no formato `PANGEA_URL/pesquisa?orgao=<court>&tipo=<kind>&nr=<number>`; exemplo: `https://pangeabnp.pdpj.jus.br/pesquisa?orgao=trt07&tipo=NT&nr=0`.
- O menu de configuracao da analise deve incluir a acao `Qtd. precedentes`, conforme o popover `7ZcG5`.
- Ao tocar em `Qtd. precedentes`, o app deve abrir um dialog modal conforme `aBP2X`, com slider para ajustar `limit` no intervalo definido pelo produto/backend.
- O valor selecionado no slider deve ser refletido visualmente no chip do dialog e usado na proxima chamada de `searchAnalysisPrecedents(...)`.
- O valor selecionado no slider deve ser persistido em cache (`CacheDriver` + `CacheKeys.precedentsLimit`) e recarregado na abertura da `analysis_screen`.
- O menu de configuracao deve exibir a acao `Filtros`, com badge numerico quando houver filtros aplicados.
- Ao tocar em `Filtros`, o app deve abrir modal dedicado com selecao de tribunais e tipos de precedente, e deve persistir a selecao no `AnalysisScreenPresenter` para reutilizacao nas proximas buscas.
- A busca (`searchAnalysisPrecedents`) deve enviar `courts` e `precedent_kinds` conforme o estado atual dos filtros aplicados.
- O header do bubble deve mostrar o total retornado apenas no estado final de `content` ou `empty`.
- O bubble deve seguir a composicao do node `9RKck`: container externo horizontal com `avatar` a esquerda e `bubble card` a direita.
- O `bubble card` deve usar fundo escuro, borda sutil e raio assimetrico com canto superior esquerdo reto e demais cantos arredondados, conforme o design.
- O header interno do bubble deve conter icone `scale`, texto `Precedentes Relevantes` e badge amarela de contagem.
- Cada `PrecedentListItem` deve exibir um badge com percentual + label derivada por faixa:
- `Aplicavel` para percentual `>= 85`.
- `Possivelmente aplicavel` para percentual entre `70` e `84.99`.
- `Não aplicável` para percentual `< 70`.
- Cada item deve exibir o identificador (`precedent.identifier.court + precedent.identifier.kind + precedent.identifier.number`) como texto principal.
- Cada item deve seguir a hierarquia visual do node `9RKck`: bloco horizontal com coluna de conteudo a esquerda e `chevron-right` muted a direita.
- Os itens devem ser separados por stroke superior interna a partir do segundo item, como no frame `Precedentes Bubble` (`LM2cA`).
- Toque em um item deve disparar um callback de integracao no widget, sem conhecer rota diretamente.
- Em falha HTTP, timeout do polling ou status `failed`, o bubble deve exibir mensagem de erro e CTA de retry no proprio componente.
- Em retry, o componente deve limpar o estado atual, cancelar o timer anterior e reiniciar o fluxo de forma idempotente.
- O estado de `content` de `RelevantPrecedentsBubble` deve manter um CTA `Refazer busca` (icone `refresh`) abaixo da lista; ao tocar, deve executar `retry()` e redisparar `POST + polling + GET final`.
- Em falha na escolha (`PATCH /precedents/choose`), o dialog deve permanecer aberto e o presenter deve expor erro recuperavel para nova tentativa.
- `ChosenPrecedentSummary` deve ser exibido na `analysis_screen` apenas quando existir precedente efetivamente escolhido (`isChosen == true`).
- `ChosenPrecedentSummary` deve exibir o titulo textual `Precedente escolhido` no topo do card.
- O badge de aplicabilidade no `ChosenPrecedentSummary` deve ficar abaixo do identificador do precedente.
- Ao confirmar a escolha no dialog, o estado local do bubble nao pode regredir para `searchingPrecedents`; regressao de status no sync com `analysisStatus` deve ser ignorada.
- Se a lista final vier vazia, o bubble deve exibir mensagem informativa contextualizada e nao deve mostrar itens fantasmas.
- `AnalysisScreenPresenter.load()` deve continuar carregando `petition` e `summary` para estados de precedentes, garantindo reentrada da tela com o contexto do caso ainda visivel acima do bubble.

## 3.2 Nao funcionais

- **Performance:** o polling deve usar intervalo fixo de `3s` e existir no maximo um timer ativo por `RelevantPrecedentsBubblePresenter`.
- **Performance:** o bubble nao deve redisparar `POST /precedents/search` quando a `analysis` ja estiver em algum status posterior a `petitionAnalyzed`.
- **Offline/Conectividade:** falhas de rede no `POST`, no polling ou no `GET` final devem resultar em erro recuperavel com retry manual no proprio bubble.
- **Usabilidade:** o usuario deve continuar vendo o contexto da analise (`PetitionSummaryCard`) enquanto o bubble processa ou exibe os precedentes.
- **Usabilidade:** o app deve impedir reenvio duplicado escondendo a `AnalysisActionBar` depois que o passo de precedentes for aberto.
- **Seguranca:** o mobile deve continuar usando `Bearer token` via `CacheDriver` no `IntakeRestService`, sem vazar detalhes de `Dio` ou payload cru para a UI.
- **Compatibilidade:** a implementacao deve permanecer aderente a `flutter_riverpod`, `signals_flutter`, `go_router` e `dio` ja presentes no projeto.

---

# 4. O que ja existe?

## Core

- **`AnalysisDto`** (`lib/core/intake/dtos/analysis_dto.dart`) - DTO atual da analise, ja contendo `status`, `summary`, `name` e `id`; sera reutilizado no polling via `getAnalysis`.
- **`AnalysisStatusDto`** (`lib/core/intake/dtos/analysis_status_dto.dart`) - enum com todos os estados do fluxo de peticao e precedentes; ja contem `searchingPrecedents`, `analyzingPrecedentsApplicability`, `generatingSynthesis`, `waitingPrecedentChoice`, `precedentChosen` e `failed`.
- **`AnalysisPrecedentDto`** (`lib/core/intake/dtos/analysis_precedent_dto.dart`) - DTO ja existente para precedentes associados a uma analise, com `analysisId`, `precedent`, `isChosen`, `applicabilityPercentage` e `synthesis`.
- **`PrecedentDto`** (`lib/core/intake/dtos/precedent_dto.dart`) - DTO base do precedente, contendo `identifier`, `status`, `enunciation`, `thesis`, `lastUpdatedInPangeaAt` e `id`.
- **`PrecedentIdentifierDto`** (`lib/core/intake/dtos/precedent_identifier_dto.dart`) - estrutura tipada com `court`, `kind` e `number` para a identificacao unica do precedente.
- **`PrecedentIdentifierDto`** (`lib/core/intake/dtos/precedent_identifier_dto.dart`) - estrutura tipada com `court`, `kind` e `number`, que deve ser usada para montar a URL externa do `Pangea`.
- **`CourtDto`** (`lib/core/intake/dtos/court_dto.dart`) - enum dos tribunais aceitos no dominio.
- **`PrecedentKindDto`** (`lib/core/intake/dtos/precedent_kind_dto.dart`) - enum dos tipos de precedente aceitos no dominio.
- **`IntakeService`** (`lib/core/intake/interfaces/intake_service.dart`) - contrato remoto do modulo `intake`, com operacoes de precedentes para `search`, `list` e `choose`.
- **`RestResponse`** (`lib/core/shared/responses/rest_response.dart`) - wrapper padrao de sucesso/falha; sera mantido como retorno dos novos metodos do service.
- **`ListResponse`** (`lib/core/shared/responses/list_response.dart`) - wrapper simples ja existente para colecoes; deve ser usado como retorno da listagem final de precedentes.

## REST

- **`IntakeRestService`** (`lib/rest/services/intake_rest_service.dart`) - implementacao concreta de `IntakeService`, ja autenticando requests com `CacheDriver` e usando `RestClient`.
- **`AnalysisMapper`** (`lib/rest/mappers/intake/analysis_mapper.dart`) - mapper atual de `AnalysisDto`, usado no `GET /intake/analyses/{analysis_id}` para polling.
- **`Service`** (`lib/rest/services/service.dart`) - classe base com `setAuthHeader()`, `unauthorizedResponse<T>()` e `toVoidResponse(...)`, util para o `POST` que retorna `202` sem body.
- **`intakeServiceProvider`** (`lib/rest/services/index.dart`) - provider Riverpod ja usado pelos presenters do modulo `intake`.
- **`lib/rest/mappers/intake/`** - pasta existente para mappers do dominio, ainda sem mapper de precedente.

## UI

- **`AnalysisScreenPresenter`** (`lib/ui/intake/widgets/pages/analysis_screen/analysis_screen_presenter.dart`) - presenter atual da tela, ja controla upload, resumo, erro geral e o CTA `Buscar precedentes`; hoje `confirmAndViewPrecedents()` esta vazio.
- **`CacheDriver`** (`lib/core/shared/interfaces/cache_driver.dart`) + `CacheKeys.precedentsLimit` (`lib/constants/cache_keys.dart`) - contrato e chave para persistencia local do limite de precedentes.
- **`AnalysisScreenView`** (`lib/ui/intake/widgets/pages/analysis_screen/analysis_screen_view.dart`) - tela atual que ja renderiza `AiBubble`, `PetitionFileBubble`, `PetitionSummaryCard`, `MessageBox` e `AnalysisActionBar`.
- **`AiBubble`** (`lib/ui/intake/widgets/pages/analysis_screen/ai_bubble/ai_bubble_view.dart`) - referencia visual do bubble de IA com avatar, texto e estado `isTyping`.
- **`PetitionSummaryCard`** (`lib/ui/intake/widgets/pages/analysis_screen/petition_summary_card/petition_summary_card_view.dart`) - card expandivel de resumo que deve permanecer visivel durante o fluxo de precedentes.
- **`AnalysisActionBar`** (`lib/ui/intake/widgets/pages/analysis_screen/analysis_action_bar/analysis_action_bar_view.dart`) - barra inferior de acao que hoje centraliza `Selecionar peticao` e `Buscar precedentes`.
- **`HomeScreenPresenter`** (`lib/ui/intake/widgets/pages/home_screen/home_screen_presenter.dart`) - referencia real de uso de `NavigationDriver` em presenter, caso a navegacao de detalhe seja conectada futuramente.
- **`MessageBox`** (`lib/ui/intake/widgets/pages/analysis_screen/message_box/message_box_view.dart`) - referencia visual de bloco textual reutilizavel, util caso o fluxo precise comunicar bloqueios ou erros de escolha.

## Drivers

- **`env` / configuracao de ambiente** (`lib/drivers/` e implementacao concreta ja usada pelo app) - deve expor `PANGEA_URL` para montagem do link externo do precedente sem hardcode de host na UI/presenter.

## Design

- **`AI Precedentes`** (`design/animus.pen`, node `9RKck`) - referencia visual principal do bubble de precedentes, incluindo avatar lateral, header do card e lista de itens.
- **`Precedentes Bubble`** (`design/animus.pen`, node `LM2cA`) - frame interno do card principal, com canto superior esquerdo reto, borda externa e lista vertical clipada.
- **`aiPheader`** (`design/animus.pen`, node `fOIYa`) - header interno do bubble com icone `scale`, titulo e badge de contagem.
- **`Prec 1` a `Prec 5`** (`design/animus.pen`, nodes `wunuq`, `CqmXI`, `GFxyo`, `R8RkW`, `r1yCO`) - referencias da anatomia dos itens da lista, incluindo `chevron-right` e divisorias.
- **`H - Visualizacao Sem Precedente Escolhido`** (`design/animus.pen`, node `Zd1cG`) - referencia visual do `PrecedentDialog`, com card do precedente, link `Acessar Pangea`, secao de sintese e CTA inferior `Escolher Precedente`.
- **`H - Visualizacao Final`** (`design/animus.pen`, node `cUyY8`) - referencia visual do `PrecedentDialog` no estado de precedente ja escolhido.
- **`Resumo`** (`design/animus.pen`, node `lBi2m`) - referencia visual da secao `Síntese Explicativa` sempre visivel no dialog.
- **`popover`** (`design/animus.pen`, node `7ZcG5`) - referencia visual da acao adicional `Qtd. precedentes` no menu de configuracao.
- **`precedentsLimitModal`** (`design/animus.pen`, node `aBP2X`) - referencia visual do dialog modal com slider para configuracao do `limit`.

## App / Router

- **`Routes.analysis`** (`lib/constants/routes.dart`) - rota atual de analise por `analysisId`; continuara sendo o ponto de entrada da tela.
- **`appRouter`** (`lib/router.dart`) - registro atual da tela `AnalysisScreen` em `/analyses/:analysisId`; nao existe rota de detalhe de precedente no app hoje.
- **`NavigationDriver`** (`lib/core/shared/interfaces/navigation_driver.dart`) - contrato de navegacao existente, mas ainda sem capacidade especifica para abrir precedente.

---

# 5. O que deve ser criado?

## Camada Core (DTOs)

- **Localizacao:** `lib/core/intake/dtos/analysis_precedents_search_filters_dto.dart` (**novo arquivo**)
- **Atributos:**
- `final List<CourtDto> courts` - tribunais selecionados para a busca; neste recorte inicia sempre vazio.
- `final List<PrecedentKindDto> precedentKinds` - tipos de precedente selecionados; neste recorte inicia sempre vazio.
- `final int limit` - quantidade maxima solicitada ao backend; nesta task usar `10` como valor padrao.
- **Factory `fromJson` (se aplicavel):** Não aplicável.

## Camada REST (Mappers)

- **Localizacao:** `lib/rest/mappers/intake/precedent_mapper.dart` (**novo arquivo**)
- **Metodos:**
- `PrecedentDto toDto(Map<String, dynamic> json)` - mapeia `id`, `status`, `enunciation`, `thesis`, `last_updated_in_pangea_at` e o identificador do precedente para `PrecedentDto`.
- `Map<String, dynamic> toJson(PrecedentDto dto)` - Não aplicável.

- **Localizacao:** `lib/rest/mappers/intake/analysis_precedent_mapper.dart` (**novo arquivo**)
- **Metodos:**
- `AnalysisPrecedentDto toDto(Map<String, dynamic> json) -> AnalysisPrecedentDto` - mapeia `analysis_id`, `precedent`, `is_chosen`, `applicability_percentage` e `synthesis` para `AnalysisPrecedentDto`, reutilizando `PrecedentMapper.toDto`.
- `Map<String, dynamic> toJson(AnalysisPrecedentDto dto) -> Map<String, dynamic>` - Não aplicável.

## Camada UI (Presenters)

- **Localizacao:** `lib/ui/intake/widgets/pages/analysis_screen/relevant_precedents_bubble/relevant_precedents_bubble_presenter.dart` (**novo arquivo**)
- **Dependencias injetadas:** `IntakeService`
- **Estado (`signals`):**
- `signal<List<AnalysisPrecedentDto>> precedents` - lista final ordenada de precedentes carregados, derivada de `ListResponse.items`.
- `signal<AnalysisStatusDto?> processingStatus` - ultimo status observado da `analysis` durante o fluxo de precedentes.
- `signal<bool> isLoading` - controla o estado de carregamento do bubble entre disparo, polling e carga final.
- `signal<String?> generalError` - mensagem de falha recuperavel exibida no proprio bubble.
- `signal<int> selectedLimit` - quantidade configurada para a proxima busca de precedentes.
- `computed<String> loadingMessage` - traduz `processingStatus` para a mensagem de progresso visivel no bubble.
- `computed<int> totalCount` - quantidade de precedentes retornados para o badge do header.
- `computed<bool> showEmptyState` - estado vazio quando `!isLoading && generalError == null && precedents.isEmpty`.
- **Provider Riverpod:** `relevantPrecedentsBubblePresenterProvider`
- **Metodos:**
- `Future<void> initialize()` - identifica o status atual da `analysis`; se ainda estiver em `petitionAnalyzed`, dispara `searchAnalysisPrecedents`, senao retoma polling ou carrega a lista final sem redisparo do `POST`.
- `void openLimitDialog()` - abre o dialog de configuracao da quantidade de precedentes a partir da acao `Qtd. precedentes` do menu da analise.
- `void updateSelectedLimit(int value)` - atualiza o valor corrente do slider antes da confirmacao.
- `Future<void> applySelectedLimit()` - fecha o dialog, persiste o valor em estado local e usa o novo `limit` na proxima busca.
- `Future<void> retry()` - cancela polling ativo, limpa estado local e reinicia o fluxo completo do bubble.
- `Future<void> refreshProcessingStatus()` - consulta `IntakeService.getAnalysis(analysisId)` e atualiza `processingStatus`, decidindo entre continuar polling, finalizar com erro ou carregar a lista.
- `Future<void> loadPrecedents()` - chama `IntakeService.listAnalysisPrecedents(analysisId)`, consome `ListResponse.items`, ordena por `applicabilityPercentage` desc e popular `precedents`.
- `void choosePrecedent(AnalysisPrecedentDto precedent)` - marca o precedente selecionado localmente para uso no `PrecedentDialog` e etapa de confirmacao.
- `Uri buildPangeaUri(PrecedentIdentifierDto identifier)` - constroi a URL do `Pangea` a partir de `PANGEA_URL` + `court`, `kind` e `number`, no formato `PANGEA_URL/pesquisa?orgao=<court>&tipo=<kind>&nr=<number>`.
- `void openPangea(AnalysisPrecedentDto precedent)` - constroi a URL via `buildPangeaUri(precedent.precedent.identifier)` e dispara a abertura do destino externo no `Pangea`.
- `Future<void> confirmPrecedentChoice()` - executa a acao final do CTA `Confirmar Precedente` quando o fluxo de backend existir; ate la, deve permanecer como ponto de integracao controlado pelo presenter.
- `Future<bool> confirmPrecedentChoice()` - confirma a escolha no backend via `IntakeService.chooseAnalysisPrecedent(...)` e retorna `true` em sucesso para permitir fechamento do dialog.
- `void dispose()` - cancela `Timer` interno e libera todos os `signals` do presenter.

## Camada UI (Views)

- **Localizacao:** `lib/ui/intake/widgets/pages/analysis_screen/relevant_precedents_bubble/relevant_precedents_bubble_view.dart` (**novo arquivo**)
- **Base class:** `ConsumerWidget`
- **Props:** `String analysisId`, `ValueChanged<AnalysisPrecedentDto>? onPrecedentTap`
- **Bibliotecas de UI:** `flutter/material.dart`, `flutter_riverpod`, `signals_flutter`
- **Composicao interna (promovida para pastas proprias):** `loading_state`, `error_state`, `empty_state`, `content_state`.
- **Estados visuais:**
- `Loading` - header do bubble visivel + mensagem de progresso + indicacao visual de processamento.
- `Error` - mensagem de erro + CTA `Tentar novamente` dentro do proprio bubble.
- `Empty` - header do bubble + mensagem informando que nenhum precedente foi encontrado.
- `Content` - header do bubble + lista vertical de `PrecedentListItem`.
- **Acoes de content:** incluir CTA `Refazer busca` abaixo da lista para reinicializar o fluxo pelo presenter quando `isLoading == false`.
- **Hierarquia visual baseada no design `9RKck`:** `Row(avatar lateral, Expanded(bubble card))`, com header proprio e lista clipada no card.

- **Localizacao:** `lib/ui/intake/widgets/pages/analysis_screen/precedent_dialog/precedent_dialog_view.dart` (**novo arquivo**)
- **Base class:** `ConsumerWidget`
- **Props:** `required String analysisId`, `required AnalysisPrecedentDto precedent`
- **Bibliotecas de UI:** `flutter/material.dart`, `flutter_riverpod`, `signals_flutter`
- **Estados visuais:**
- `Zd1cG` em dialog full screen para precedente nao escolhido.
- `cUyY8` em dialog full screen para precedente escolhido.

- **Localizacao:** `lib/ui/intake/widgets/pages/analysis_screen/chosen_precedent_summary/` (**novo arquivo**)
- **Tipo:** View only
- **Responsabilidade:** encapsular o resumo do precedente escolhido fora do arquivo da `analysis_screen_view`, sendo renderizado somente quando houver precedente efetivamente escolhido.

- **Localizacao:** `lib/ui/intake/widgets/pages/analysis_screen/precedents_filters_dialog/precedents_filters_dialog_view.dart` (**novo arquivo**)
- **Base class:** `StatelessWidget`
- **Props:** `selectedCourts`, `selectedKinds`, callbacks de toggle/clear/apply
- **Responsabilidade:** renderizar o modal de filtros de precedentes com agrupamento expansivel de tribunais e secao de tipos.

- **Localizacao:** `lib/ui/intake/widgets/pages/analysis_screen/precedents_limit_dialog/precedents_limit_dialog_view.dart` (**novo arquivo**)
- **Base class:** `StatelessWidget`
- **Props:** `required int currentValue`, `required int minValue`, `required int maxValue`, `required ValueChanged<int> onChanged`, `required VoidCallback onCancel`, `required VoidCallback onApply`
- **Bibliotecas de UI:** `flutter/material.dart`
- **Estados visuais:**
- `Content` - segue `aBP2X`, com titulo, texto auxiliar, slider, chip com valor corrente e botoes `Cancelar` / `Aplicar`.

## Camada UI (Widgets Internos)

- **Localizacao:** `lib/ui/intake/widgets/pages/analysis_screen/relevant_precedents_bubble/precedent_list_item/` (**novo arquivo**)
- **Tipo:** View only
- **Props:** `String title`, `double applicabilityPercentage`, `VoidCallback? onTap`
- **Responsabilidade:** renderiza o item de precedente com badge percentual, label textual derivada da faixa, estilo visual por faixa e affordance de toque.
- **Composicao visual baseada no design `9RKck`:** linha horizontal com coluna `left content` em `fill_container` e `Icon(Icons.chevron_right)` muted a direita.

- **Localizacao:** `lib/ui/intake/widgets/pages/analysis_screen/relevant_precedents_bubble/loading_state/`, `error_state/`, `empty_state/`, `content_state/` (**novos arquivos**)
- **Tipo:** View only
- **Responsabilidade:** decompor os estados do bubble em componentes dedicados para manter `relevant_precedents_bubble_view.dart` enxuta.

- **Localizacao:** `lib/ui/intake/widgets/pages/analysis_screen/precedent_dialog/` (**novo arquivo**)
- **Tipo:** View only
- **Responsabilidade:** encapsular a visualizacao de um precedente em dialog full screen, aberto por toque em item da lista e fiel ao frame `Zd1cG`.

- **Localizacao:** `lib/ui/intake/widgets/pages/analysis_screen/precedents_limit_dialog/` (**novo arquivo**)
- **Tipo:** View only
- **Props:** `required int currentValue`, `required int minValue`, `required int maxValue`, `required ValueChanged<int> onChanged`, `required VoidCallback onCancel`, `required VoidCallback onApply`
- **Responsabilidade:** renderiza o dialog modal com slider para definicao do `limit` conforme `aBP2X`.

## Camada UI (Barrel Files / `index.dart`)

- **Localizacao:** `lib/ui/intake/widgets/pages/analysis_screen/relevant_precedents_bubble/index.dart` (**novo arquivo**)
- **`typedef` exportado:** `typedef RelevantPrecedentsBubble = RelevantPrecedentsBubbleView`
- **Widgets internos exportados:** `precedent_list_item`

- **Localizacao:** `lib/ui/intake/widgets/pages/analysis_screen/relevant_precedents_bubble/precedent_list_item/index.dart` (**novo arquivo**)
- **`typedef` exportado:** `typedef PrecedentListItem = PrecedentListItemView`
- **Widgets internos exportados:** Não aplicável.

- **Localizacao:** `lib/ui/intake/widgets/pages/analysis_screen/precedent_dialog/index.dart` (**novo arquivo**)
- **`typedef` exportado:** `typedef PrecedentDialog = PrecedentDialogView`
- **Widgets internos exportados:** Não aplicável.

- **Localizacao:** `lib/ui/intake/widgets/pages/analysis_screen/precedents_limit_dialog/index.dart` (**novo arquivo**)
- **`typedef` exportado:** `typedef PrecedentsLimitDialog = PrecedentsLimitDialogView`
- **Widgets internos exportados:** Não aplicável.

- **Localizacao:** `lib/ui/intake/widgets/pages/analysis_screen/precedents_filters_dialog/index.dart` (**novo arquivo**)
- **`typedef` exportado:** `typedef PrecedentsFiltersDialog = PrecedentsFiltersDialogView`
- **Widgets internos exportados:** Não aplicável.

## Camada UI (Providers Riverpod - se isolados)

- **Localizacao:** `lib/ui/intake/widgets/pages/analysis_screen/relevant_precedents_bubble/relevant_precedents_bubble_presenter.dart`
- **Nome do provider:** `relevantPrecedentsBubblePresenterProvider`
- **Tipo:** `Provider.autoDispose.family<RelevantPrecedentsBubblePresenter, String>`
- **Dependencias:** `ref.watch(intakeServiceProvider)`, `unawaited(presenter.initialize())`, `ref.onDispose(presenter.dispose)`

## Rotas (`go_router`) - se aplicavel

**Não aplicável**.

## Estrutura de Pastas

```text
lib/ui/intake/widgets/pages/analysis_screen/
  index.dart
  analysis_screen_view.dart
  analysis_screen_presenter.dart
  ai_bubble/
    index.dart
    ai_bubble_view.dart
  chosen_precedent_summary/
    index.dart
    chosen_precedent_summary_view.dart
  petition_summary_card/
    index.dart
    petition_summary_card_view.dart
  relevant_precedents_bubble/
    index.dart
    relevant_precedents_bubble_view.dart
    relevant_precedents_bubble_presenter.dart
    loading_state/
      index.dart
      loading_state_view.dart
    error_state/
      index.dart
      error_state_view.dart
    empty_state/
      index.dart
      empty_state_view.dart
    content_state/
      index.dart
      content_state_view.dart
    precedent_list_item/
      index.dart
      precedent_list_item_view.dart
  precedent_dialog/
    index.dart
    precedent_dialog_view.dart
  precedents_limit_dialog/
    index.dart
    precedents_limit_dialog_view.dart
```

---

# 6. O que deve ser modificado?

## Core

- **Arquivo:** `lib/core/intake/interfaces/intake_service.dart`
- **Mudanca:** adicionar `Future<RestResponse<void>> searchAnalysisPrecedents({required String analysisId, required AnalysisPrecedentsSearchFiltersDto filters})`.
- **Justificativa:** a UI nao pode chamar `RestClient` diretamente; o disparo do `POST /precedents/search` precisa entrar pelo contrato do `core`.

- **Arquivo:** `lib/core/intake/interfaces/intake_service.dart`
- **Mudanca:** adicionar `Future<RestResponse<ListResponse<AnalysisPrecedentDto>>> listAnalysisPrecedents({required String analysisId})`.
- **Justificativa:** o bubble precisa carregar a lista final tipada de precedentes quando o backend concluir o processamento, preservando o envelope padrao de colecoes do projeto.

## REST

- **Arquivo:** `lib/rest/services/intake_rest_service.dart`
- **Mudanca:** implementar `searchAnalysisPrecedents(...)` com `POST /intake/analyses/{analysisId}/precedents/search`, body serializado a partir de `AnalysisPrecedentsSearchFiltersDto` e retorno `RestResponse<void>` via `toVoidResponse(...)`.
- **Justificativa:** o controller backend real retorna `202` sem body; a camada REST precisa encapsular esse contrato sem vazar detalhes tecnicos para a UI.

- **Arquivo:** `lib/rest/services/intake_rest_service.dart`
- **Mudanca:** implementar `listAnalysisPrecedents(...)` chamando `GET /intake/analyses/{analysisId}/precedents` e convertendo o payload para `ListResponse<AnalysisPrecedentDto>`.
- **Justificativa:** a listagem final de precedentes precisa ser entregue como colecao tipada no envelope padrao do `core`, respeitando a borda da camada REST.

- **Arquivo:** `lib/core/intake/interfaces/intake_service.dart`
- **Mudanca:** adicionar `Future<RestResponse<AnalysisStatusDto>> chooseAnalysisPrecedent({required String analysisId, required PrecedentIdentifierDto identifier})`.
- **Justificativa:** a confirmacao de escolha deve entrar pelo contrato do `core`, sem chamada direta a cliente HTTP na UI.

- **Arquivo:** `lib/rest/services/intake_rest_service.dart`
- **Mudanca:** implementar `chooseAnalysisPrecedent(...)` com `PATCH /intake/analyses/{analysisId}/precedents/choose`, enviando `court`, `kind` e `number` em `queryParams`, com retorno mapeado para `AnalysisStatusDto`.
- **Justificativa:** o controller backend oficial expoe esse endpoint para consolidar a escolha do precedente e atualizar o status da analise.

- **Arquivo:** `lib/rest/services/index.dart`
- **Mudanca:** Não aplicável.
- **Justificativa:** `intakeServiceProvider` ja compoe `IntakeRestService`; a extensao do contrato nao exige novo provider.

## UI

- **Arquivo:** `lib/ui/intake/widgets/pages/analysis_screen/analysis_screen_presenter.dart`
- **Mudanca:** adicionar `signal<bool> showRelevantPrecedents` para controlar a montagem do novo bubble e evoluir `confirmAndViewPrecedents()` para abrir o passo de precedentes apenas quando o resumo ja estiver disponivel.
- **Justificativa:** a tela precisa alternar entre a etapa de resumo e a etapa de precedentes sem concentrar o polling no presenter pai.

- **Arquivo:** `lib/ui/intake/widgets/pages/analysis_screen/analysis_screen_presenter.dart`
- **Mudanca:** ajustar `load()` para tratar `searchingPrecedents`, `analyzingPrecedentsApplicability`, `generatingSynthesis`, `waitingPrecedentChoice` e `precedentChosen` como estados pos-resumo, carregando `petition`, `summary` e abrindo `showRelevantPrecedents` automaticamente.
- **Justificativa:** sem esse ajuste, a tela nao consegue ser reaberta no meio ou no fim do fluxo de precedentes mantendo o contexto da analise.

- **Arquivo:** `lib/ui/intake/widgets/pages/analysis_screen/analysis_screen_presenter.dart`
- **Mudanca:** expor estado derivado para `selectedPrecedent`, `isPendingPrecedentChoice`, `isLimitDialogOpen` e callbacks `openLimitDialog()`, `updateSelectedLimit(int value)`, `applySelectedLimit()`, `choosePrecedent(AnalysisPrecedentDto precedent)`, `openPangea(...)` e `confirmPrecedentChoice()`.
- **Justificativa:** a `analysis_screen` agora precisa cobrir os estados visuais `Zd1cG` e `aBP2X` sem empurrar logica para a `View`.

- **Arquivo:** `lib/ui/intake/widgets/pages/analysis_screen/analysis_screen_view.dart`
- **Mudanca:** renderizar `RelevantPrecedentsBubble` abaixo de `PetitionSummaryCard` quando `showRelevantPrecedents == true`.
- **Justificativa:** o novo recorte precisa viver dentro da mesma tela de analise, mantendo o contexto do caso acima da busca.

- **Arquivo:** `lib/ui/intake/widgets/pages/analysis_screen/analysis_screen_view.dart`
- **Mudanca:** abrir `PrecedentDialog` em full screen ao tocar em um item de `RelevantPrecedentsBubble`, passando o `AnalysisPrecedentDto` selecionado.
- **Justificativa:** a escolha passa a ser orientada por item e o dialog representa fielmente o frame `Zd1cG` para cada precedente.

- **Arquivo:** `lib/ui/intake/widgets/pages/analysis_screen/analysis_screen_view.dart`
- **Mudanca:** abrir `PrecedentsLimitDialogView` quando a acao `Qtd. precedentes` for selecionada no menu da analise.
- **Justificativa:** a configuracao de `limit` agora faz parte do fluxo visual aprovado em `7ZcG5` e `aBP2X`.

- **Arquivo:** `lib/ui/intake/widgets/pages/analysis_screen/analysis_screen_view.dart`
- **Mudanca:** ocultar `AnalysisActionBar` quando `showRelevantPrecedents == true`.
- **Justificativa:** evita que o usuario dispare o fluxo de busca mais de uma vez e deixa o bubble dono do estado de loading/erro/retry.

- **Arquivo:** `lib/ui/intake/widgets/pages/analysis_screen/relevant_precedents_bubble/relevant_precedents_bubble_view.dart`
- **Mudanca:** adicionar botao `Refazer busca` abaixo da lista (estado `content`) com icone `refresh`, conectado ao `retry()` do `RelevantPrecedentsBubblePresenter`.
- **Justificativa:** permite refazer a busca completa de precedentes sob demanda, sem depender de erro para expor a acao de retry.

- **Arquivo:** `lib/ui/intake/widgets/pages/analysis_screen/relevant_precedents_bubble/relevant_precedents_bubble_presenter.dart`
- **Mudanca:** implementar `confirmPrecedentChoice()` consumindo `IntakeService.chooseAnalysisPrecedent(...)`, com atualizacao de `processingStatus`, lista local (`isChosen`) e erro recuperavel em falha.
- **Justificativa:** centraliza a regra de confirmacao no presenter do widget de precedentes, mantendo a view fina.

- **Arquivo:** `lib/ui/intake/widgets/pages/analysis_screen/precedent_dialog/precedent_dialog_view.dart`
- **Mudanca:** fechar o dialog somente quando `confirmPrecedentChoice()` retornar sucesso.
- **Justificativa:** evita mascarar falha de confirmacao e permite retry imediato no proprio dialog.

---

# 7. O que deve ser removido?

**Não aplicável**.

---

# 8. Decisoes Tecnicas e Trade-offs

- **Decisao:** concentrar o fluxo de `POST + polling + GET final` em `RelevantPrecedentsBubblePresenter`, e nao em `AnalysisScreenPresenter`.
- **Alternativas consideradas:** manter todo o fluxo no presenter da screen; disparar o polling diretamente na View.
- **Motivo da escolha:** segue as regras da camada UI do projeto, que pedem presenter proprio para widget filho com estado e side effects relevantes.
- **Impactos / trade-offs:** adiciona um provider e uma pasta interna nova, mas evita inflar o presenter da tela principal com uma segunda responsabilidade grande.

- **Decisao:** abrir o bubble somente depois que o usuario acionar `Buscar precedentes` ou quando a tela for reaberta com a `analysis` ja em status de precedentes.
- **Alternativas consideradas:** disparar a busca automaticamente assim que o resumo da peticao ficasse pronto.
- **Motivo da escolha:** preserva o passo explicito do fluxo atual da screen e continua aderente ao `PRD RF 03`, no qual a busca acontece depois da etapa da analise inicial.
- **Impactos / trade-offs:** o usuario precisa confirmar a transicao para precedentes manualmente na primeira vez, mas a reentrada continua automatica para estados ja avancados.

- **Decisao:** criar `AnalysisPrecedentsSearchFiltersDto` no `core` em vez de expor listas primitivas diretamente no metodo do service.
- **Alternativas consideradas:** usar apenas parametros `List<CourtDto> courts`, `List<PrecedentKindDto> precedentKinds` e `int limit` no contrato de `IntakeService`.
- **Motivo da escolha:** o controller backend real recebido para a task ja modela um DTO especifico para filtros; espelhar isso no mobile estabiliza o contrato para a futura sprint de filtros.
- **Impactos / trade-offs:** adiciona um DTO novo ao `core`, mas evita quebrar a assinatura do service quando a UI de filtros entrar no escopo.

- **Decisao:** nao criar rota placeholder de detalhe de precedente nesta spec; o item expora apenas callback de toque.
- **Alternativas consideradas:** adicionar rota fake agora; acoplar o item diretamente ao `NavigationDriver`.
- **Motivo da escolha:** o ticket explicita que o contrato da rota esta fora do escopo, e o projeto nao possui rota existente para precedente.
- **Impactos / trade-offs:** a navegacao final permanece pendente de integracao posterior, mas a UI fica pronta para conectar o destino correto sem retrabalho estrutural.

- **Decisao:** usar `PrecedentDialog` full screen por item tocado da lista para representar `Zd1cG`.
- **Alternativas consideradas:** abrir dialog automaticamente por status; manter bloco inline para resumo final.
- **Motivo da escolha:** reduz ambiguidade do fluxo e vincula a abertura diretamente ao precedente selecionado pelo usuario.
- **Impactos / trade-offs:** adiciona uma navegacao modal por item, mas simplifica estado da `analysis_screen` e melhora aderencia visual ao design.

- **Decisao:** integrar a confirmacao do CTA `Escolher Precedente` ao endpoint `PATCH /precedents/choose` retornando `AnalysisStatusDto`.
- **Alternativas consideradas:** manter confirmacao apenas local; postergar integracao backend.
- **Motivo da escolha:** o controller backend ja existe e permite concluir o fluxo fim-a-fim sem workaround local.
- **Impactos / trade-offs:** adiciona dependencia de resposta de rede no dialog, mas garante consistencia de status entre app e servidor.

- **Decisao:** expor a configuracao de `limit` por dialog modal com slider, acessado via popover da analise.
- **Alternativas consideradas:** deixar `limit` fixo; mover a configuracao para uma tela de filtros completa.
- **Motivo da escolha:** o design aprovado (`7ZcG5` + `aBP2X`) introduz um controle de ajuste fino sem abrir o escopo completo de filtros.
- **Impactos / trade-offs:** adiciona um estado visual e uma configuracao local a mais, mas reduz a necessidade de nova tela e deixa o recorte aderente ao design atual.

- **Decisao:** promover widgets privados de estado para pastas proprias (`loading_state`, `error_state`, `empty_state`, `content_state`) e centralizar a visualizacao final em `PrecedentDialog`.
- **Alternativas consideradas:** manter classes privadas em arquivos monoliticos de view.
- **Motivo da escolha:** aderencia ao padrao de UI do projeto e eliminacao de camada intermediaria desnecessaria apos adocao do `PrecedentDialog`.
- **Impactos / trade-offs:** reduz acoplamento da `analysis_screen` e centraliza a experiencia de selecao no dialog dedicado.

- **Decisao:** preservar os valores string ja existentes de `AnalysisStatusDto` mesmo com os typos `CHOISE` e `CHOSED`.
- **Alternativas consideradas:** corrigir o enum Dart agora.
- **Motivo da escolha:** o backend atual ja publica esses mesmos valores, e a task nao deve introduzir uma quebra de compatibilidade de protocolo.
- **Impactos / trade-offs:** o typo permanece no contrato interno por enquanto, mas o mobile continua aderente ao servidor real.

---

# 9. Diagramas e Referencias

- **Fluxo de dados:**

```text
AnalysisScreenView
  -> AnalysisScreenPresenter.confirmAndViewPrecedents()
  -> showRelevantPrecedents = true
  -> menu action 'Qtd. precedentes'
      -> PrecedentsLimitDialogView
      -> updateSelectedLimit(value)
      -> applySelectedLimit()
  -> RelevantPrecedentsBubbleView
      -> relevantPrecedentsBubblePresenterProvider(analysisId)
      -> RelevantPrecedentsBubblePresenter.initialize()
          -> IntakeService.searchAnalysisPrecedents(filters)
              -> IntakeRestService.searchAnalysisPrecedents(...)
                  -> RestClient.post('/intake/analyses/{analysisId}/precedents/search')
          -> Timer.periodic(3s)
              -> IntakeService.getAnalysis(analysisId)
                  -> AnalysisMapper.toDto(...)
              -> status intermediario
                  -> signals (processingStatus, loadingMessage)
              -> status final waitingPrecedentChoice | precedentChosen
                  -> IntakeService.listAnalysisPrecedents(analysisId)
                      -> IntakeRestService.listAnalysisPrecedents(...)
                          -> ListResponse<AnalysisPrecedentDto>
                  -> signals (precedents <- items)
      -> PrecedentListItemView
          -> onTap(precedent)
          -> open PrecedentDialog(precedent)
              -> choosePrecedent(precedent)
              -> confirmPrecedentChoice()
                  -> IntakeService.chooseAnalysisPrecedent(analysisId, identifier)
                      -> IntakeRestService.chooseAnalysisPrecedent(...)
                          -> RestClient.patch('/intake/analyses/{analysisId}/precedents/choose', queryParams: court/kind/number)
                      -> AnalysisStatusDto
```

- **Hierarquia de widgets:**

```text
AnalysisScreenView
  AnalysisHeader
  SingleChildScrollView
    AiBubble
    PetitionFileBubble
    MessageBox (quando houver erro do fluxo da peticao)
    PetitionSummaryCard
    RelevantPrecedentsBubble
      avatar lateral
      bubble card
        bubble header
          scale icon
          title
          count badge
      loading | error | empty | list
        PrecedentListItem*
          badge de aplicabilidade
          title
          chevron-right
    PrecedentDialog
      precedent highlighted card
      pangea link
      explanatory summary (always visible)
      bottom CTA choose precedent
  PrecedentsLimitDialogView
    title
    helper text
    slider
    value chip
    cancel/apply actions
```

- **Referencias:**
- `lib/ui/intake/widgets/pages/analysis_screen/analysis_screen_presenter.dart`
- `lib/ui/intake/widgets/pages/analysis_screen/analysis_screen_view.dart`
- `lib/ui/intake/widgets/pages/analysis_screen/ai_bubble/ai_bubble_view.dart`
- `lib/ui/intake/widgets/pages/analysis_screen/petition_summary_card/petition_summary_card_view.dart`
- `design/animus.pen` (node `9RKck`)
- `design/animus.pen` (node `LM2cA`)
- `design/animus.pen` (node `Zd1cG`)
- `design/animus.pen` (node `lBi2m`)
- `design/animus.pen` (node `7ZcG5`)
- `design/animus.pen` (node `aBP2X`)
- `lib/core/intake/interfaces/intake_service.dart`
- `lib/core/shared/responses/list_response.dart`
- `lib/core/intake/dtos/analysis_status_dto.dart`
- `lib/core/intake/dtos/analysis_precedent_dto.dart`
- `lib/core/intake/dtos/precedent_dto.dart`
- `lib/rest/services/intake_rest_service.dart`
- `lib/rest/services/service.dart`
- `lib/rest/mappers/intake/analysis_mapper.dart`
- `lib/constants/routes.dart`
- `lib/router.dart`

---

# 10. Pendencias / Duvidas

- **Resolucao aplicada:** considerar `POST /intake/analyses/{analysis_id}/precedents/search` como endpoint acionado pelo fluxo de busca de precedentes.
- **Impacto na implementacao:** `IntakeService.searchAnalysisPrecedents(...)` e `IntakeRestService.searchAnalysisPrecedents(...)` ficam fechados com esse contrato.

- **Resolucao aplicada:** considerar `ListResponse<AnalysisPrecedentDto>` como retorno de `GET /intake/analyses/{analysis_id}/precedents`.
- **Impacto na implementacao:** `IntakeService.listAnalysisPrecedents(...)`, `IntakeRestService.listAnalysisPrecedents(...)` e o mapper REST devem consumir o envelope `items` como contrato definitivo.

- **Resolucao aplicada:** usar `PATCH /intake/analyses/{analysis_id}/precedents/choose` para confirmar escolha com `court`, `kind` e `number` em query params.
- **Impacto na implementacao:** `IntakeService.chooseAnalysisPrecedent(...)`, `IntakeRestService.chooseAnalysisPrecedent(...)` e `confirmPrecedentChoice()` ficam sincronizados com o controller backend oficial.

---

# Restricoes

- **Nao inclua testes automatizados na spec.**
- A `View` nao deve conter logica de negocio; o disparo da busca, o polling e o retry ficam no `RelevantPrecedentsBubblePresenter`.
- Presenters nao fazem chamadas diretas a `RestClient`; `AnalysisScreenPresenter` e `RelevantPrecedentsBubblePresenter` devem consumir somente `IntakeService`.
- Todos os caminhos citados nesta spec existem no projeto ou estao explicitamente marcados como **novo arquivo**.
- Esta spec reutiliza `AnalysisPrecedentDto`, `PrecedentDto`, `AnalysisStatusDto`, `IntakeService`, `AnalysisScreenPresenter` e `AnalysisScreenView`; nao inventa novo gateway nem nova tela de rota para substituir estruturas existentes.
- O fluxo de busca deve usar `POST /intake/analyses/{analysis_id}/precedents/search`, e a listagem final deve consumir `ListResponse<AnalysisPrecedentDto>`.
- O uso de `AnalysisStatusDto` deve respeitar os valores atuais publicados pelo backend, inclusive `WAITING_PRECEDENT_CHOISE` e `PRECEDENT_CHOSED`.
- O `POST /precedents/search` deve seguir o controller real informado para a task: body JSON com `courts`, `precedent_kinds` e `limit`.
- O widget `RelevantPrecedentsBubble` deve seguir o padrao de pasta propria com `index.dart`, `relevant_precedents_bubble_view.dart` e `relevant_precedents_bubble_presenter.dart`.
- O widget interno `precedent_list_item` deve ficar em pasta propria com `index.dart` e `precedent_list_item_view.dart`.
- Use componentes Flutter Material alinhados ao tema atual do projeto.
