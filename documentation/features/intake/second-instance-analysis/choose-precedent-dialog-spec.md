---
title: Escolha, desescolha e adição manual de precedentes no AnalysisPrecedentsBubble
prd: https://joaogoliveiragarcia.atlassian.net/wiki/spaces/ANM/pages/16351240
ticket: https://joaogoliveiragarcia.atlassian.net/browse/ANI-117
status: closed
last_updated_at: 2026-05-20
---

# 1. Objetivo

Evoluir o componente compartilhado `AnalysisPrecedentsBubble` para encapsular a experiência completa de visualizar, escolher, adicionar manualmente por identificador, destacar e desescolher precedentes em telas de análise. A implementação deve remover a semântica pública singular de `selectedPrecedent`, expor um contrato público de seleção múltipla baseado em `chosenPrecedents`, sincronizar esse estado a partir de `AnalysisPrecedentDto.isChosen` retornado pela API, propagar a origem manual do precedente via `AnalysisPrecedentDto.isManuallyAdded` e incluir um dialog próprio para consulta prévia e inclusão manual com `court` e `kind` selecionados a partir de enums tipados.

---

# 2. Escopo

## 2.1 In-scope

- Evoluir `AnalysisPrecedentsBubblePresenter` para suportar **múltiplos precedentes escolhidos**.
- Substituir o contrato público `selectedPrecedent` por `chosenPrecedents` e `focusedPrecedent`.
- Implementar desescolha via `IntakeService.unchooseAnalysisPrecedent(...)` dentro do fluxo do componente compartilhado.
- Atualizar `PrecedentDialog` para alternar entre CTA de escolha e CTA de desescolha conforme `precedent.isChosen`.
- Incluir fluxo de adição manual de precedente por identificador dentro do componente compartilhado.
- Consultar `PrecedentDto` por identificador antes de confirmar a inclusão manual.
- Persistir a inclusão manual via `POST /analyses/precedents`.
- Destacar visualmente precedentes escolhidos na lista do `AnalysisPrecedentsBubble`.
- Exibir badge `Manualmente adicionado` no lugar do badge de aplicabilidade quando `AnalysisPrecedentDto.isManuallyAdded == true`.
- Reutilizar dialogs compartilhados de filtros e quantidade de precedentes como `components`, servidos pelo header das telas de análise em vez do corpo do bubble.
- Trocar os campos livres de `court` e `kind` por selects tipados com `CourtDto` e `PrecedentKindDto` no dialog de adição manual.
- Ajustar `SecondInstanceAnalysisScreenPresenter` para liberar `Gerar minuta` apenas quando existir ao menos um precedente escolhido.
- Ajustar `FirstInstanceAnalysisScreenView` para parar de observar `selectedPrecedent` diretamente.
- Ajustar a 2ª instância para tentar carregar `SecondInstanceJudgmentDraftDto` também durante estados intermediários do fluxo de precedentes e exibir o card imediatamente quando o draft já existir.

## 2.2 Out-of-scope

- Alterar a busca semântica de precedentes ou seus filtros.
- Alterar o ranking, ordenação ou cálculo de aplicabilidade dos precedentes.
- Criar novos endpoints além dos dois contratos informados para consulta por identificador e inclusão manual.
- Alterar o fluxo de upload, análise do caso ou geração da minuta.
- Alterar o `design/animus.pen`.
- Incluir testes automatizados nesta spec.

---

# 3. Requisitos

## 3.1 Funcionais

- Ao carregar/reentrar na tela, o app deve reconstruir visualmente os precedentes escolhidos a partir de `AnalysisPrecedentDto.isChosen` retornado por `listAnalysisPrecedents`.
- O `AnalysisPrecedentsBubble` deve destacar todos os itens com `isChosen == true` na lista.
- Quando `AnalysisPrecedentDto.isManuallyAdded == true`, o badge visual do precedente deve exibir `Manualmente adicionado` no lugar do badge baseado em `applicabilityLevel`.
- Ao tocar em um precedente da lista, o usuário deve continuar abrindo o dialog fullscreen de detalhes.
- O `AnalysisPrecedentsBubble` deve expor CTA para abrir um dialog de adição manual por identificador apenas quando o componente não estiver em estado de loading.
- No dialog de adição manual, o usuário deve selecionar `court` e `kind` a partir de `CourtDto` e `PrecedentKindDto`, e informar `number` manualmente.
- Antes da confirmação da inclusão, o app deve consultar `GET /precedents/identifier?court={court}&kind={kind}&number={number}`.
- O dialog deve exibir preview do `PrecedentDto` retornado antes de habilitar a confirmação, limitado a `status`, `enunciation` e `thesis`.
- `enunciation` deve aparecer truncado por padrão, com CTA local `Mostrar mais` para expandir o texto completo.
- `thesis` deve aparecer truncado por padrão, com CTA local `Mostrar mais` para expandir o texto completo.
- Ao confirmar a inclusão manual, o app deve persistir o item via `POST /analyses/precedents` com body `{ analysis_id, identifier }`.
- Após inclusão bem-sucedida, o item deve passar a integrar `precedents` e ficar elegível a escolha/desescolha no fluxo normal.
- Se o precedente em foco não estiver escolhido, o dialog de detalhe deve exibir CTA para escolher e persistir via `chooseAnalysisPrecedent(...)`.
- Se o precedente em foco já estiver escolhido, o dialog de detalhe deve exibir CTA para desescolher e persistir via `unchooseAnalysisPrecedent(...)`.
- Escolher um novo precedente não deve limpar automaticamente escolhas anteriores no estado local, salvo se a resposta/listagem posterior da API vier com outro conjunto de `isChosen`.
- Desescolher um precedente deve atualizar apenas o item afetado e recalcular `chosenPrecedents`.
- Em falha de rede, o app deve preservar o estado anterior e exibir erro recuperável, sem aplicar escolha/desescolha otimista definitiva.
- Em falha `404` na consulta por identificador, o dialog deve exibir a mensagem `Precedente não encontrado.`.
- Em falha diferente de `404` na consulta por identificador ou inclusão manual, o dialog deve preservar os campos preenchidos e impedir confirmação inválida.
- A 2ª instância só deve habilitar `Gerar minuta` quando existir ao menos um item em `chosenPrecedents`.
- A aplicação de filtros no header da 2ª instância deve atualizar apenas o estado selecionado do `AnalysisPrecedentsBubblePresenter`, sem disparar nova busca imediatamente.
- Mesmo durante `SEARCHING_PRECEDENTS`, `PRECEDENTS_SEARCHED`, `ANALYZING_PRECEDENTS_SIMILARITY`, `ANALYZING_PRECEDENTS_APPLICABILITY`, `GENERATING_JUDGMENT_DRAFT` e `GENERATING_SYNTHESIS`, a 2ª instância deve tentar carregar `SecondInstanceJudgmentDraftDto` e exibir o card assim que ele já existir.

## 3.2 Não funcionais

- **Performance:** `chosenPrecedents` deve ser um `computed<List<AnalysisPrecedentDto>>` derivado de `precedents`, evitando estado duplicado manual.
- **Acessibilidade:** itens escolhidos devem expor indicação textual além de cor, como label `Escolhido` e ícone inline na lista.
- **Conectividade:** falhas de `choose`/`unchoose` devem manter a lista anterior e permitir nova tentativa sem recarregar a tela inteira.
- **Conectividade:** falhas de `getPrecedent`/`addAnalysisPrecedent` devem preservar os campos digitados no dialog para nova tentativa.
- **Arquitetura:** `View` não deve acessar `RestClient`; escolha, desescolha, preview e inclusão manual devem passar por presenters e `IntakeService`.
- **Arquitetura:** os dialogs de filtros e quantidade devem existir como `components` compartilhados do `AnalysisPrecedentsBubble`, mesmo quando forem servidos pelo header das telas consumidoras.

---

# 4. O que já existe?

## Core

- **`AnalysisPrecedentDto`** (`lib/core/intake/dtos/analysis_precedent_dto.dart`) - DTO da relação análise/precedente, já contém `isChosen`, `synthesis`, `similarityScore`, `finalRank`, `applicabilityLevel` e `isManuallyAdded`.
- **`PrecedentIdentifierDto`** (`lib/core/intake/dtos/precedent_identifier_dto.dart`) - identificador usado para enviar `court`, `kind` e `number` nos endpoints de escolha/desescolha.
- **`PrecedentDto`** (`lib/core/intake/dtos/precedent_dto.dart`) - DTO base do precedente, com `identifier`, `status`, `enunciation`, `thesis`, `synthesis` e `lastUpdatedInPangeaAt`; no preview da inclusão manual serão usados apenas `status`, `enunciation` e `thesis`.
- **`AnalysisStatusDto`** (`lib/core/intake/dtos/analysis_status_dto.dart`) - enum de status da análise usado para sincronizar o estado visual do fluxo de precedentes.
- **`IntakeService`** (`lib/core/intake/interfaces/intake_service.dart`) - contrato já expõe `chooseAnalysisPrecedent(...)`, `unchooseAnalysisPrecedent(...)` e `listAnalysisPrecedents(...)`; será estendido para consulta e inclusão manual por identificador.

## REST

- **`IntakeRestService`** (`lib/rest/services/intake_rest_service.dart`) - já implementa `PATCH /intake/analyses/{analysisId}/precedents/choose`, `PATCH /intake/analyses/{analysisId}/precedents/unchoose` e `GET /intake/analyses/{analysisId}/precedents`.
- **`AnalysisPrecedentMapper`** (`lib/rest/mappers/intake/analysis_precedent_mapper.dart`) - já mapeia `is_chosen` para `AnalysisPrecedentDto.isChosen` e `is_manually_added` para `AnalysisPrecedentDto.isManuallyAdded`.
- **`PrecedentMapper`** (`lib/rest/mappers/intake/precedent_mapper.dart`) - mapper já existente para `PrecedentDto`, reutilizável no preview remoto do precedente por identificador.

## UI

- **`AnalysisPrecedentsBubblePresenter`** (`lib/ui/intake/widgets/components/analysis_precedents_bubble/analysis_precedents_bubble_presenter.dart`) - presenter compartilhado da lista; já expõe `focusedPrecedent`, `chosenPrecedents`, `hasChosenPrecedents`, `reloadPrecedents()` e preserva `isManuallyAdded` ao recriar itens localmente.
- **`AnalysisPrecedentsBubbleView`** (`lib/ui/intake/widgets/components/analysis_precedents_bubble/analysis_precedents_bubble_view.dart`) - componente pai da lista de precedentes; hoje renderiza loading/error/empty/content, CTA de adição manual fora do loading e callback externo de item, sem card resumo interno de escolhidos.
- **`ContentStateView`** (`lib/ui/intake/widgets/components/analysis_precedents_bubble/content_state/content_state_view.dart`) - renderiza a lista de precedentes e delega tap do item.
- **`PrecedentListItemView`** (`lib/ui/intake/widgets/components/analysis_precedents_bubble/precedent_list_item/precedent_list_item_view.dart`) - item visual da lista; já recebe estado de escolhido e origem manual para trocar o badge exibido.
- **`AnalysisPrecedentDialogView`** (`lib/ui/intake/widgets/components/analysis_precedents_bubble/precedent_dialog/precedent_dialog_view.dart`) - dialog fullscreen que já alterna entre escolher e desescolher, refletindo o estado atual local do precedente e trocando o badge quando `isManuallyAdded == true`.
- **`PrecedentsFiltersDialogView`** (`lib/ui/intake/widgets/components/analysis_precedents_bubble/precedents_filters_dialog/precedents_filters_dialog_view.dart`) - dialog compartilhado de filtros, servido pelos headers das telas de análise; os arquivos de `pages/first_instance_analysis_screen/...` atuam apenas como aliases para compatibilidade de import.
- **`PrecedentsLimitDialogView`** (`lib/ui/intake/widgets/components/analysis_precedents_bubble/precedents_limit_dialog/precedents_limit_dialog_view.dart`) - dialog compartilhado de quantidade de precedentes, servido pelos headers das telas de análise; os arquivos de `pages/first_instance_analysis_screen/...` atuam apenas como aliases para compatibilidade de import.
- **`FirstInstanceAnalysisScreenView`** (`lib/ui/intake/widgets/pages/first_instance_analysis_screen/first_instance_analysis_screen_view.dart`) - consumidora que já usa o contrato público atualizado do bubble, sem renderizar resumo externo singular.
- **`ChosenPrecedentSummaryView`** - **Não aplicável** neste recorte; a implementação atual não usa card resumo persistente de escolhidos no bubble nem na 1ª instância.
- **`SecondInstanceAnalysisScreenView`** (`lib/ui/intake/widgets/pages/second_instance_analysis_screen/second_instance_analysis_screen_view.dart`) - renderiza `AnalysisPrecedentsBubble`, observa `chosenPrecedents` e serve os dialogs de filtros/quantidade no header da tela.
- **`SecondInstanceFirstInstanceAnalysisScreenPresenter`** (`lib/ui/intake/widgets/pages/second_instance_analysis_screen/second_instance_analysis_screen_presenter.dart`) - `canGenerateJudgmentDraft` já depende de `precedentsReady` e de ao menos um precedente escolhido, e tenta carregar `SecondInstanceJudgmentDraftDto` também durante estados intermediários do fluxo de precedentes.

---

# 5. O que deve ser criado?

## Camada UI (Presenters)

- **Localização:** `lib/ui/intake/widgets/components/analysis_precedents_bubble/add_precedent_dialog/add_precedent_dialog_presenter.dart` (**novo arquivo**)
- **Dependências injetadas:** `IntakeService` e `AnalysisPrecedentsBubblePresenter` (via provider do bubble)
- **Estado (`signals`):**
  - `signal<bool> isFetchingPreview`
  - `signal<bool> isSubmitting`
  - `signal<PrecedentDto?> previewPrecedent`
  - `signal<String?> generalError`
- **Provider Riverpod:** `addPrecedentDialogPresenterProvider`
- **Form (`reactive_forms`):**
  - `final FormGroup form`
  - `FormControl<CourtDto> get courtControl`
  - `FormControl<PrecedentKindDto> get kindControl`
  - `FormControl<String> get numberControl`
- **Computeds:**
  - `computed<bool> canFetchPreview` - habilita consulta quando o identificador estiver válido e não houver request em andamento.
  - `computed<bool> canSubmit` - habilita inclusão apenas quando existir `previewPrecedent` válido para o identificador atual e não houver submit em andamento.
- **Métodos:**
  - `Future<void> fetchPreview()` - valida o form, consulta `IntakeService.getPrecedent(...)` e preenche `previewPrecedent`.
  - `Future<bool> submit()` - chama `IntakeService.addAnalysisPrecedent(...)`, força refresh da lista do bubble e retorna sucesso/falha.
  - `void clearPreviewOnIdentifierChange()` - invalida o preview atual quando algum campo do identificador mudar.
  - `String? fieldErrorMessage(FormControl<Object?> control)` - devolve mensagem de validação para a View.

- **Localização:** `lib/ui/intake/widgets/components/analysis_precedents_bubble/precedents_filters_dialog/court_filter_section/court_filter_section_presenter.dart` (**novo arquivo**)
- **Dependências injetadas:** não aplicável
- **Provider Riverpod:** `courtFilterSectionPresenterProvider`
- **Métodos:**
  - `void toggleGroup(String title)` - expande/recolhe grupos de tribunais no dialog de filtros.

## Camada UI (Views)

- **Localização:** `lib/ui/intake/widgets/components/analysis_precedents_bubble/add_precedent_dialog/add_precedent_dialog_view.dart` (**novo arquivo**)
- **Base class:** `ConsumerWidget`
- **Props:**
  - `final String analysisId`
- **Bibliotecas de UI:** `flutter_riverpod`, `signals_flutter`, `reactive_forms`
- **Estados visuais:**
  - Form inicial sem preview
  - Carregando preview
  - Erro de preview
  - Preview do `PrecedentDto` com `status`, `enunciation` truncado/expansível e `thesis` truncado/expansível
  - Submit em andamento

- **Localização:** `lib/ui/intake/widgets/components/analysis_precedents_bubble/precedents_filters_dialog/precedents_filters_dialog_view.dart` (**novo arquivo**)
- **Base class:** `StatelessWidget`
- **Props:**
  - `final List<CourtDto> selectedCourts`
  - `final List<PrecedentKindDto> selectedKinds`
  - `final ValueChanged<CourtDto> onToggleCourt`
  - `final ValueChanged<PrecedentKindDto> onToggleKind`
  - `final VoidCallback onClear`
  - `final VoidCallback onApply`
- **Estados visuais:** content apenas; o estado expansível dos grupos de tribunais fica delegado ao widget interno `CourtFilterSection`.

- **Localização:** `lib/ui/intake/widgets/components/analysis_precedents_bubble/precedents_limit_dialog/precedents_limit_dialog_view.dart` (**novo arquivo**)
- **Base class:** `StatelessWidget`
- **Props:**
  - `final int currentValue`
  - `final int minValue`
  - `final int maxValue`
  - `final ValueChanged<int> onChanged`
  - `final VoidCallback onCancel`
  - `final VoidCallback onApply`
- **Estados visuais:** content apenas.

## Camada UI (Widgets Internos)

- **Localização:** `lib/ui/intake/widgets/components/analysis_precedents_bubble/add_precedent_dialog/` (**novo arquivo**)
- **Tipo:** `View + Presenter`
- **Responsabilidade:** capturar identificador, buscar preview do precedente e confirmar a inclusão manual na análise.

- **Localização:** `lib/ui/intake/widgets/components/analysis_precedents_bubble/add_precedent_dialog/preview_card/` (**novo arquivo**)
- **Tipo:** `View`
- **Responsabilidade:** renderizar o card de preview do precedente retornado antes da confirmação.

- **Localização:** `lib/ui/intake/widgets/components/analysis_precedents_bubble/add_precedent_dialog/preview_text_block/` (**novo arquivo**)
- **Tipo:** `View` com estado local encapsulado no próprio `StatefulWidget`
- **Responsabilidade:** renderizar blocos de texto truncáveis/expansíveis para `status`, `enunciation` e `thesis`.

- **Localização:** `lib/ui/intake/widgets/components/analysis_precedents_bubble/precedents_filters_dialog/court_filter_section/` (**novo arquivo**)
- **Tipo:** `View + Presenter`
- **Responsabilidade:** manter estado local dos grupos expandidos de tribunais no dialog de filtros.

- **Localização:** `lib/ui/intake/widgets/components/analysis_precedents_bubble/precedents_filters_dialog/filter_section/` (**novo arquivo**)
- **Tipo:** `View`
- **Responsabilidade:** renderizar seções genéricas de filtros em lista de chips.

- **Localização:** `lib/ui/intake/widgets/components/analysis_precedents_bubble/precedents_filters_dialog/filter_chip/` (**novo arquivo**)
- **Tipo:** `View`
- **Responsabilidade:** renderizar chip selecionável de filtro.

- **Localização:** `lib/ui/intake/widgets/components/analysis_precedents_bubble/precedents_filters_dialog/section_header/` (**novo arquivo**)
- **Tipo:** `View`
- **Responsabilidade:** renderizar o cabeçalho reutilizável das seções de filtro.

## Camada UI (Barrel Files / `index.dart`)

- **Localização:** `lib/ui/intake/widgets/components/analysis_precedents_bubble/add_precedent_dialog/index.dart` (**novo arquivo**)
- **`typedef` exportado:** `typedef AddPrecedentDialog = AddPrecedentDialogView`
- **Widgets internos exportados:** não aplicável.

- **Localização:** `lib/ui/intake/widgets/components/analysis_precedents_bubble/precedents_filters_dialog/index.dart` (**novo arquivo**)
- **`typedef` exportado:** `typedef PrecedentsFiltersDialog = AnalysisPrecedentsBubblePrecedentsFiltersDialogView`
- **Widgets internos exportados:** `court_filter_section`, `filter_section`, `filter_chip`, `section_header`.

- **Localização:** `lib/ui/intake/widgets/components/analysis_precedents_bubble/precedents_limit_dialog/index.dart` (**novo arquivo**)
- **`typedef` exportado:** `typedef PrecedentsLimitDialog = AnalysisPrecedentsBubblePrecedentsLimitDialogView`
- **Widgets internos exportados:** não aplicável.

## Estrutura de Pastas

```text
lib/ui/intake/widgets/components/analysis_precedents_bubble/
  index.dart
  analysis_precedents_bubble_view.dart
  analysis_precedents_bubble_presenter.dart
  add_precedent_dialog/
    index.dart
    add_precedent_dialog_view.dart
    add_precedent_dialog_presenter.dart
    preview_card/
      index.dart
      preview_card_view.dart
    preview_text_block/
      index.dart
      preview_text_block_view.dart
  content_state/
    index.dart
    content_state_view.dart
  empty_state/
    index.dart
    empty_state_view.dart
  error_state/
    index.dart
    error_state_view.dart
  loading_state/
    index.dart
    loading_state_view.dart
  precedent_dialog/
    index.dart
    precedent_dialog_view.dart
  precedents_filters_dialog/
    index.dart
    precedents_filters_dialog_view.dart
    court_group.dart
    court_filter_section/
      index.dart
      court_filter_section_view.dart
      court_filter_section_presenter.dart
    filter_section/
      index.dart
      filter_section_view.dart
    filter_chip/
      index.dart
      filter_chip_view.dart
    section_header/
      index.dart
      section_header_view.dart
  precedents_limit_dialog/
    index.dart
    precedents_limit_dialog_view.dart
  precedent_list_item/
    index.dart
    precedent_list_item_view.dart
```

---

# 6. O que deve ser modificado?

## Core

- **Arquivo:** `lib/core/intake/interfaces/intake_service.dart`
- **Mudança:** manter `Future<RestResponse<AnalysisStatusDto>> unchooseAnalysisPrecedent({required String analysisId, required PrecedentIdentifierDto identifier})`; remover o corpo default `=> throw UnimplementedError()` se a implementação exigir contrato abstrato puro.
- **Justificativa:** o contrato já existe e é implementado por `IntakeRestService`; deixá-lo abstrato evita fallback silencioso em futuras implementações de `IntakeService`.
- **Mudança:** adicionar `Future<RestResponse<PrecedentDto>> getPrecedent({required PrecedentIdentifierDto identifier})`.
- **Justificativa:** o preview do precedente antes da inclusão manual precisa de contrato tipado no `core`.
- **Mudança:** adicionar `Future<RestResponse<AnalysisPrecedentDto>> addAnalysisPrecedent({required String analysisId, required PrecedentIdentifierDto identifier})`.
- **Justificativa:** a inclusão manual do `analysis_precedent` precisa ficar disponível para a UI por meio do `IntakeService`.

## REST

- **Arquivo:** `lib/rest/services/intake_rest_service.dart`
- **Mudança:** manter `chooseAnalysisPrecedent(...)` e `unchooseAnalysisPrecedent(...)` enviando `court`, `kind` e `number` a partir de `PrecedentIdentifierDto`.
- **Justificativa:** o fluxo atual continua válido e não deve mudar de semântica.
- **Mudança:** implementar `getPrecedent(...)` usando `GET /precedents/identifier?court={court}&kind={kind}&number={number}` e mapear a resposta com `PrecedentMapper.toDto`.
- **Justificativa:** o dialog precisa mostrar o `PrecedentDto` real antes da confirmação da inclusão.
- **Mudança:** implementar `addAnalysisPrecedent(...)` usando `POST /analyses/precedents` com body `{ "analysis_id": analysisId, "identifier": { ... } }` e mapear a resposta com `AnalysisPrecedentMapper.toDto`.
- **Justificativa:** o item precisa ser persistido na análise antes de poder ser escolhido/desescolhido no fluxo normal.

- **Arquivo:** `lib/rest/mappers/intake/analysis_precedent_mapper.dart`
- **Mudança:** mapear `is_manually_added` para `AnalysisPrecedentDto.isManuallyAdded`.
- **Justificativa:** a UI precisa distinguir precedentes adicionados manualmente para trocar o badge exibido.

## UI

- **Arquivo:** `lib/ui/intake/widgets/components/analysis_precedents_bubble/analysis_precedents_bubble_presenter.dart`
- **Mudança:** substituir `selectedPrecedent` por `focusedPrecedent` como estado transitório do dialog.
- **Justificativa:** `selectedPrecedent` mistura item em foco com precedente escolhido persistido, contrariando a nova semântica de seleção múltipla.
- **Mudança:** adicionar `late final ReadonlySignal<List<AnalysisPrecedentDto>> chosenPrecedents = computed(...)` derivado de `precedents.value.where((item) => item.isChosen)`.
- **Justificativa:** expor contrato público reutilizável para telas consumidoras reagirem à existência/lista de escolhidos sem duplicar lógica.
- **Mudança:** adicionar `late final ReadonlySignal<bool> hasChosenPrecedents = computed(() => chosenPrecedents.value.isNotEmpty)`.
- **Justificativa:** facilitar consumo por telas que precisam apenas da regra booleana, como a 2ª instância.
- **Mudança:** alterar `choosePrecedent(AnalysisPrecedentDto precedent)` para `focusPrecedent(AnalysisPrecedentDto precedent)`.
- **Justificativa:** nomear explicitamente o item em foco sem sugerir persistência.
- **Mudança:** alterar `Future<bool> confirmPrecedentChoice()` para atualizar apenas o item escolhido com `isChosen: true`, preservando outros itens já escolhidos.
- **Justificativa:** a seleção passa a ser múltipla; escolher um item não deve limpar os anteriores localmente.
- **Mudança:** criar `Future<bool> unchoosePrecedent(AnalysisPrecedentDto precedent)`.
- **Justificativa:** centralizar a desescolha no presenter compartilhado, chamando `IntakeService.unchooseAnalysisPrecedent(...)`, preservando o estado anterior em falha e removendo `isChosen` apenas do item afetado em sucesso.
- **Mudança:** criar `Future<void> reloadPrecedents()` como API pública de refresh não destrutivo da lista após inclusão manual.
- **Justificativa:** o dialog de adição manual precisa recarregar a coleção após `addAnalysisPrecedent(...)` sem reiniciar a busca.
- **Mudança:** em `_loadPrecedents(...)`, remover a lógica que escolhe apenas o primeiro `isChosen` como `selectedPrecedent`.
- **Justificativa:** a fonte pública de escolhidos passa a ser `chosenPrecedents`, derivada da lista completa.
- **Mudança:** descartar `focusedPrecedent`, `chosenPrecedents` e `hasChosenPrecedents` em `dispose()`.
- **Justificativa:** manter ciclo de vida dos `signals`/`computed` consistente.

- **Arquivo:** `lib/ui/intake/widgets/components/analysis_precedents_bubble/analysis_precedents_bubble_view.dart`
- **Mudança:** ajustar `onPrecedentTap` para chamar `presenter.focusPrecedent(precedent)` antes de delegar a abertura do dialog.
- **Justificativa:** manter o item em foco sincronizado para o dialog sem expor semântica de escolha.
- **Mudança:** adicionar CTA `Adicionar precedente` no cabeçalho ou rodapé do bubble para abrir `AddPrecedentDialog`.
- **Justificativa:** a inclusão manual deve nascer dentro do mesmo componente compartilhado de precedentes.
- **Mudança:** omitir o CTA `Adicionar precedente` quando o bubble estiver em estado de loading.
- **Justificativa:** evita concorrência com o fluxo assíncrono principal do componente.
- **Mudança:** remover os CTAs de filtros e quantidade do corpo do bubble.
- **Justificativa:** essas ações passaram a ser servidas pelos headers das telas consumidoras.

- **Arquivo:** `lib/ui/intake/widgets/components/analysis_precedents_bubble/content_state/content_state_view.dart`
- **Mudança:** repassar `precedent.isChosen` e `precedent.isManuallyAdded` para `PrecedentListItem`.
- **Justificativa:** a lista precisa refletir visualmente tanto a escolha quanto a origem manual do precedente.

- **Arquivo:** `lib/ui/intake/widgets/components/analysis_precedents_bubble/precedent_list_item/precedent_list_item_view.dart`
- **Mudança:** adicionar prop `final bool isChosen`.
- **Justificativa:** permitir destaque visual reutilizável no item.
- **Mudança:** quando `isChosen == true`, exibir label/ícone `Escolhido`, borda ou fundo com `tokens.accent` e sem depender apenas de cor.
- **Justificativa:** atender ao requisito visual e de acessibilidade.
- **Mudança:** quando `isManuallyAdded == true`, exibir badge cinza `Manualmente adicionado` no lugar do badge de `applicabilityLevel`.
- **Justificativa:** diferenciar precedentes adicionados manualmente dos precedentes classificados automaticamente.

- **Arquivo:** `lib/ui/intake/widgets/components/analysis_precedents_bubble/precedent_dialog/precedent_dialog_view.dart`
- **Mudança:** derivar o estado atual do precedente a partir de `presenter.precedents` ou `focusedPrecedent`, não apenas da prop recebida inicialmente.
- **Justificativa:** após escolher/desescolher, o dialog deve refletir o estado atualizado localmente.
- **Mudança:** se o item estiver escolhido, o CTA deve executar `presenter.unchoosePrecedent(currentPrecedent)` e fechar apenas em sucesso.
- **Justificativa:** implementar desescolha explícita sem deixar a UI inconsistente.
- **Mudança:** se o item não estiver escolhido, o CTA deve executar `presenter.focusPrecedent(currentPrecedent)` e `presenter.confirmPrecedentChoice()`.
- **Justificativa:** manter escolha persistida pelo presenter compartilhado.
- **Mudança:** quando `precedent.isManuallyAdded == true`, exibir badge cinza `Manualmente adicionado` no lugar do badge de aplicabilidade.
- **Justificativa:** manter consistência visual entre a lista e o dialog de detalhe.

- **Arquivo:** `lib/ui/intake/widgets/components/analysis_precedents_bubble/add_precedent_dialog/add_precedent_dialog_presenter.dart` (**novo arquivo**)
- **Mudança:** criar presenter com `FormGroup`, preview remoto, submit, invalidação do preview ao editar o identificador, sincronização reativa da validade do formulário via `signals` e tratamento específico de `404` para `Precedente não encontrado.`.
- **Justificativa:** o dialog possui estado próprio, validação, handlers e integração assíncrona; não deve sobrecarregar o presenter pai.

- **Arquivo:** `lib/ui/intake/widgets/components/analysis_precedents_bubble/add_precedent_dialog/add_precedent_dialog_view.dart` (**novo arquivo**)
- **Mudança:** criar dialog com selects tipados para `court` e `kind`, campo de `number`, CTA `Buscar precedente`, card de preview com `status`, `enunciation` truncado/expansível, `thesis` truncado/expansível e CTA `Adicionar precedente`.
- **Justificativa:** o fluxo exige confirmação visual do precedente antes da inclusão.

- **Arquivo:** `lib/ui/intake/widgets/pages/second_instance_analysis_screen/second_instance_analysis_screen_presenter.dart`
- **Mudança:** adicionar `final Signal<bool> hasChosenPrecedents = signal<bool>(false)`.
- **Justificativa:** a tela precisa de estado público simples para liberar geração de minuta sem acoplar a View a detalhes internos do componente.
- **Mudança:** alterar `canGenerateJudgmentDraft` para exigir `precedentsReady.value && hasChosenPrecedents.value`.
- **Justificativa:** `precedentsReady` indica lista carregada/disponível, não escolha efetiva.
- **Mudança:** adicionar `void syncChosenPrecedents(List<AnalysisPrecedentDto> precedents)`.
- **Justificativa:** receber do componente compartilhado o estado público de escolhidos e atualizar `hasChosenPrecedents`.
- **Mudança:** quando `hasChosenPrecedents` mudar para `false`, manter `precedentsReady` se a lista existir, mas impedir `requestJudgmentDraft()`.
- **Justificativa:** desescolher o último precedente não deve esconder a lista nem permitir minuta sem precedente.
- **Mudança:** tentar carregar `SecondInstanceJudgmentDraftDto` também durante estados intermediários do fluxo de precedentes, sem tratar `404` como falha fatal.
- **Justificativa:** permitir exibir o card da minuta assim que o backend já tiver gerado o draft, mesmo antes do status final `DONE`.

- **Arquivo:** `lib/ui/intake/widgets/pages/second_instance_analysis_screen/second_instance_analysis_screen_view.dart`
- **Mudança:** observar `analysisPrecedentsBubblePresenterProvider(widget.analysisId).chosenPrecedents` em um `Watch` próximo ao bubble e chamar `presenter.syncChosenPrecedents(chosenPrecedents)` por `addPostFrameCallback` quando houver alteração.
- **Justificativa:** a tela consome apenas o contrato público do componente, sem recalcular `isChosen` por conta própria.
- **Mudança:** remover dependência de `precedentsReady` como fallback para `Gerar minuta` no handler de status `failed` quando não houver escolhido.
- **Justificativa:** retry de geração da minuta também precisa respeitar a existência de precedente escolhido.
- **Mudança:** servir os dialogs de filtros e quantidade no `AnalysisHeader`, consumindo o estado do `AnalysisPrecedentsBubblePresenter`.
- **Justificativa:** essas ações pertencem ao header das telas de análise, não ao corpo do bubble.
- **Mudança:** ao aplicar filtros na 2ª instância, atualizar apenas o estado selecionado sem disparar nova busca automaticamente.
- **Justificativa:** evita reexecução implícita do fluxo de precedentes no momento do ajuste de filtros.

- **Arquivo:** `lib/ui/intake/widgets/pages/first_instance_analysis_screen/first_instance_analysis_screen_view.dart`
- **Mudança:** substituir leituras de `precedentsPresenter.selectedPrecedent` por `precedentsPresenter.chosenPrecedents`.
- **Justificativa:** remover consumo do contrato singular descontinuado.
- **Mudança:** remover a renderização externa de `ChosenPrecedentSummary` abaixo do bubble, deixando a identificação de escolha inline na própria lista.
- **Justificativa:** evitar duplicidade entre telas e reduzir ruído visual no fluxo de precedentes.
- **Mudança:** em `_showPrecedentDialog(...)`, detectar transição de zero para um ou mais escolhidos via `chosenPrecedents.value.isEmpty` antes/depois do dialog para chamar `presenter.markPrecedentChosen()`.
- **Justificativa:** manter compatibilidade do status da 1ª instância sem depender de estado singular.
- **Mudança:** não adicionar lógica própria para inclusão manual; apenas consumir o bubble compartilhado evoluído.
- **Justificativa:** a responsabilidade do novo fluxo continua centralizada no componente reutilizável.

- **Arquivo:** `lib/ui/intake/widgets/pages/first_instance_analysis_screen/precedents_filters_dialog/precedents_filters_dialog_view.dart`
- **Mudança:** manter apenas como alias para `lib/ui/intake/widgets/components/analysis_precedents_bubble/precedents_filters_dialog/precedents_filters_dialog_view.dart`.
- **Justificativa:** preservar compatibilidade de imports enquanto o dialog passa a existir como component compartilhado.

- **Arquivo:** `lib/ui/intake/widgets/pages/first_instance_analysis_screen/precedents_limit_dialog/precedents_limit_dialog_view.dart`
- **Mudança:** manter apenas como alias para `lib/ui/intake/widgets/components/analysis_precedents_bubble/precedents_limit_dialog/precedents_limit_dialog_view.dart`.
- **Justificativa:** preservar compatibilidade de imports enquanto o dialog passa a existir como component compartilhado.

---

# 7. O que deve ser removido?

## UI

- **Arquivo:** `lib/ui/intake/widgets/components/analysis_precedents_bubble/analysis_precedents_bubble_presenter.dart`
- **Motivo da remoção:** remover `selectedPrecedent` como contrato público porque ele representa semântica singular incompatível com seleção múltipla.
- **Impacto esperado:** consumidores devem migrar para `chosenPrecedents`, `hasChosenPrecedents` e `focusedPrecedent`.

- **Arquivo:** `lib/ui/intake/widgets/pages/first_instance_analysis_screen/first_instance_analysis_screen_view.dart`
- **Motivo da remoção:** remover renderização externa de `ChosenPrecedentSummary` para evitar duplicar o resumo agora encapsulado no `AnalysisPrecedentsBubble`.
- **Impacto esperado:** a identificação de escolhidos permanece inline na lista, sem card resumo dedicado nas telas consumidoras.

---

# 8. Decisões Técnicas e Trade-offs

- **Decisão:** `chosenPrecedents` será `computed` derivado de `precedents`.
- **Alternativas consideradas:** manter uma `Signal<List<AnalysisPrecedentDto>>` separada; manter `selectedPrecedent` singular.
- **Motivo da escolha:** evita divergência entre lista renderizada e resumo, e representa diretamente a regra do DTO (`isChosen`).
- **Impactos / trade-offs:** todo update de escolha/desescolha deve recriar a lista `precedents` de forma imutável para disparar recomputação.

- **Decisão:** `focusedPrecedent` substitui `selectedPrecedent` apenas para o item aberto no dialog.
- **Alternativas consideradas:** manter `selectedPrecedent` com novo significado; não manter estado de foco no presenter.
- **Motivo da escolha:** separa foco transiente de escolha persistida e reduz ambiguidade nos consumidores.
- **Impactos / trade-offs:** requer renomear chamadas atuais de `choosePrecedent(...)` para `focusPrecedent(...)`.

- **Decisão:** a lista de precedentes exibe o estado escolhido inline e não renderiza card resumo persistente no bubble.
- **Alternativas consideradas:** manter um card resumo interno; renderizar resumo por tela consumidora.
- **Motivo da escolha:** reduz ruído visual no bubble e mantém a identificação de estado diretamente onde o usuário interage.
- **Impactos / trade-offs:** a identificação de escolhidos depende da leitura dos próprios itens da lista e de seus labels auxiliares.

- **Decisão:** escolha e desescolha não serão otimistas definitivas.
- **Alternativas consideradas:** atualizar UI antes da resposta e reverter em erro.
- **Motivo da escolha:** o requisito pede preservar estado anterior em falha de rede; aplicar só após sucesso reduz inconsistência.
- **Impactos / trade-offs:** o feedback visual depende do tempo de resposta, então o dialog deve exibir loading e desabilitar CTA durante a operação.

- **Decisão:** a inclusão manual por identificador exige preview remoto antes do submit final.
- **Alternativas consideradas:** confirmar inclusão diretamente após digitação do identificador; adicionar precedente sem mostrar detalhes prévios.
- **Motivo da escolha:** o requisito explícito pede que o precedente seja informado ao usuário antes da confirmação da inclusão.
- **Impactos / trade-offs:** o fluxo ganha uma etapa extra e mais uma chamada remota, mas reduz risco de adicionar o precedente errado.

- **Decisão:** o preview da inclusão manual mostrará apenas `status`, `enunciation` e `thesis`.
- **Alternativas consideradas:** mostrar identificador completo, síntese e data de atualização; exibir todo o `PrecedentDto` bruto.
- **Motivo da escolha:** este é o recorte validado para confirmação da inclusão, evitando sobrecarregar o dialog com informações que não ajudam na decisão.
- **Impactos / trade-offs:** exige truncamento com expansão local para textos longos de `enunciation` e `thesis`.

- **Decisão:** o form do dialog usará `reactive_forms`.
- **Alternativas consideradas:** `TextEditingController` puro dentro da View; validação manual no presenter pai.
- **Motivo da escolha:** o projeto já usa `reactive_forms` para fluxos com validação de campos, e o dialog tem estado próprio suficiente para justificar presenter dedicado.
- **Impactos / trade-offs:** adiciona boilerplate de form, mas mantém validação, mensagens e habilitação de CTAs centralizadas.

- **Decisão:** `court` e `kind` do dialog de inclusão manual serão selects tipados a partir de `CourtDto` e `PrecedentKindDto`.
- **Alternativas consideradas:** manter inputs textuais livres; converter `String` em enum manualmente no presenter.
- **Motivo da escolha:** reduz erros de digitação e garante que apenas identificadores suportados pela API sejam enviados.
- **Impactos / trade-offs:** o dialog perde flexibilidade para valores arbitrários, mas ganha consistência e previsibilidade de validação.

- **Decisão:** os dialogs de filtros e quantidade existem como `components` compartilhados, mas são servidos pelo header das telas de análise.
- **Alternativas consideradas:** manter dialogs acoplados à 1ª instância; acionar os dialogs a partir do corpo do bubble.
- **Motivo da escolha:** preserva reuso real entre 1ª e 2ª instância e mantém as ações de configuração no header, onde já existem affordances para esse tipo de ajuste.
- **Impactos / trade-offs:** exige pequenos aliases de compatibilidade na 1ª instância e sincronização explícita com o presenter compartilhado.

- **Decisão:** a 2ª instância tenta carregar `SecondInstanceJudgmentDraftDto` também durante estados intermediários do fluxo de precedentes.
- **Alternativas consideradas:** carregar o draft apenas em `DONE`.
- **Motivo da escolha:** permite exibir o card imediatamente quando o backend já tiver material pronto, reduzindo latência percebida.
- **Impactos / trade-offs:** o presenter precisa tolerar `404` como ausência temporária do draft, sem transformar isso em erro fatal.

- **Decisão:** a 2ª instância mantém `precedentsReady` e adiciona `hasChosenPrecedents`.
- **Alternativas consideradas:** substituir `precedentsReady` por `hasChosenPrecedents`; fazer a View chamar diretamente `requestJudgmentDraft` conforme o estado do bubble.
- **Motivo da escolha:** `precedentsReady` ainda representa disponibilidade da lista; `hasChosenPrecedents` representa regra de negócio para minuta.
- **Impactos / trade-offs:** exige sincronização explícita entre presenter da tela e presenter do componente, mas preserva MVP e evita regra na View.

---

# 9. Diagramas e Referências

- **Fluxo de dados:**

```text
AnalysisPrecedentsBubbleView
  -> AnalysisPrecedentsBubblePresenter
      -> analysisPrecedentsBubblePresenterProvider
          -> IntakeService.listAnalysisPrecedents(...)
          -> IntakeService.chooseAnalysisPrecedent(...)
          -> IntakeService.unchooseAnalysisPrecedent(...)
              -> IntakeRestService
                  -> RestClient (Dio) -> API

signals/computeds:
precedents -> chosenPrecedents -> hasChosenPrecedents
focusedPrecedent -> PrecedentDialog
```

- **Fluxo de adição manual por identificador:**

```text
AnalysisHeader
  -> PrecedentsFiltersDialog | PrecedentsLimitDialog
      -> state local da tela consumidora / AnalysisPrecedentsBubblePresenter

AnalysisPrecedentsBubbleView
  -> CTA "Adicionar precedente" (apenas fora de loading)
      -> AddPrecedentDialogView
          -> AddPrecedentDialogPresenter
              -> form(court: CourtDto, kind: PrecedentKindDto, number)
              -> fetchPreview()
                  -> IntakeService.getPrecedent(...)
                       -> IntakeRestService GET /precedents/identifier
              -> submit()
                  -> IntakeService.addAnalysisPrecedent(...)
                      -> IntakeRestService POST /analyses/precedents
                  -> AnalysisPrecedentsBubblePresenter.reloadPrecedents()
```

- **Fluxo de sincronização da 2ª instância:**

```text
AnalysisPrecedentsBubblePresenter.chosenPrecedents
  -> SecondInstanceAnalysisScreenView observa contrato público
      -> SecondInstanceFirstInstanceAnalysisScreenPresenter.syncChosenPrecedents(...)
          -> hasChosenPrecedents
              -> canGenerateJudgmentDraft
                  -> AnalysisActionBar CTA "Gerar minuta"

SecondInstanceFirstInstanceAnalysisScreenPresenter
  -> IntakeService.getSecondInstanceJudgmentDraft(...)
      -> card da minuta exibido assim que houver payload disponível
```

- **Hierarquia de widgets:**

```text
AnalysisPrecedentsBubbleView
  Row
    Avatar IA
    Card
      Header "Precedentes Relevantes"
      CTA "Adicionar precedente" (oculto durante loading)
      LoadingState | ErrorState | EmptyState | Content
        ContentState
          PrecedentListItem(isChosen, isManuallyAdded)
        Refazer busca

AnalysisHeader
  CTA quantidade de precedentes
  CTA filtros

PrecedentDialog
  Header
  Card do precedente em foco
  Badge de aplicabilidade | Badge "Manualmente adicionado"
  Síntese explicativa
  CTA Escolher Precedente | Desescolher Precedente

AddPrecedentDialog
  Header
  Form(select court, select kind, number)
  CTA Buscar precedente
  Preview
    Status
    Enunciado truncado + Mostrar mais
    Tese firmada truncada + Mostrar mais
  CTA Adicionar precedente
```

- **Referências:**
  - `lib/ui/intake/widgets/components/analysis_precedents_bubble/analysis_precedents_bubble_presenter.dart`
  - `lib/ui/intake/widgets/components/analysis_precedents_bubble/analysis_precedents_bubble_view.dart`
  - `lib/ui/intake/widgets/components/analysis_precedents_bubble/precedents_filters_dialog/precedents_filters_dialog_view.dart`
  - `lib/ui/intake/widgets/components/analysis_precedents_bubble/precedents_limit_dialog/precedents_limit_dialog_view.dart`
  - `lib/ui/intake/widgets/components/analysis_precedents_bubble/content_state/content_state_view.dart`
  - `lib/ui/intake/widgets/components/analysis_precedents_bubble/precedent_list_item/precedent_list_item_view.dart`
  - `lib/ui/intake/widgets/components/analysis_precedents_bubble/precedent_dialog/precedent_dialog_view.dart`
  - `lib/ui/intake/widgets/pages/first_instance_analysis_screen/first_instance_analysis_screen_view.dart`
  - `lib/ui/intake/widgets/pages/second_instance_analysis_screen/second_instance_analysis_screen_presenter.dart`
  - `lib/ui/intake/widgets/pages/second_instance_analysis_screen/second_instance_analysis_screen_view.dart`
  - `lib/core/intake/dtos/analysis_precedent_dto.dart`
  - `lib/core/intake/interfaces/intake_service.dart`
  - `lib/core/intake/dtos/precedent_dto.dart`
  - `lib/rest/services/intake_rest_service.dart`
  - `lib/rest/mappers/intake/analysis_precedent_mapper.dart`
  - `lib/rest/mappers/intake/precedent_mapper.dart`

---

# 10. Pendências / Dúvidas

- **Descrição da pendência:** o PRD vinculado no arquivo é o RF 02 de análise de petições iniciais, enquanto o detalhamento funcional específico veio do ticket `ANI-117` e do refinamento adicional desta conversa.
- **Impacto na implementação:** baixo para esta spec, porque os requisitos técnicos estão completos; ainda assim, deve ser validado se existe PRD/RF mais específico para precedentes.
- **Ação sugerida:** validar com produto/Jira se `ANI-117` deve apontar para um PRD/RF específico de precedentes ou se o RF 02 permanece como referência guarda-chuva.

- **Descrição da pendência:** o ticket menciona endpoint `/analyses/{analysis_id}/precedents/...`, mas a codebase implementa `/intake/analyses/{analysisId}/precedents/...`.
- **Impacto na implementação:** baixo, pois `IntakeRestService` já usa o prefixo atual do mobile/server e outros fluxos de intake seguem `/intake/analyses`.
- **Ação sugerida:** confirmar apenas se o texto do ticket omitiu o prefixo `/intake` por abreviação.

- **Descrição da pendência:** o preview manual usa `GET /precedents/identifier` sem `analysisId`, enquanto a inclusão continua em `POST /analyses/precedents` com `analysis_id` no body.
- **Impacto na implementação:** baixo; a spec assume exatamente esses formatos para evitar inventar variações.
- **Ação sugerida:** validar apenas se o backend devolverá erro semântico distinto para precedente inexistente versus precedente já adicionado, para orientar a copy final do dialog.

---

# Restrições

- Não inclua testes automatizados na spec.
- A `View` não deve conter lógica de negócio; toda orquestração de escolha, desescolha, preview e inclusão fica nos presenters.
- Presenters não fazem chamadas diretas a `RestClient`; devem consumir `IntakeService`.
- Todos os caminhos existentes citados foram localizados na codebase; caminhos novos estão marcados como **novo arquivo**.
- Não criar DTO ou driver novo neste recorte; apenas estender `IntakeService` e `IntakeRestService` com os dois contratos remotos informados.
- `selectedPrecedent` não deve permanecer como API pública do componente compartilhado.
- O resumo persistente de escolhidos deve pertencer ao `AnalysisPrecedentsBubble`, não às telas consumidoras.
- `SecondInstanceFirstInstanceAnalysisScreenPresenter.canGenerateJudgmentDraft` deve depender de ao menos um precedente escolhido.
- Widgets novos devem seguir `snake_case` para arquivos/pastas, `PascalCase` para classes e barrel `index.dart` por widget.
- Use componentes Flutter Material alinhados aos tokens de tema do projeto.
