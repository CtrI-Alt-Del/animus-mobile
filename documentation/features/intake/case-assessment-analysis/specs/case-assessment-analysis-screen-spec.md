---
title: Tela de análise de caso pelo advogado (Case Assessment)
prd: ../prd.md
ticket: https://joaogoliveiragarcia.atlassian.net/browse/ANI-103
last_updated_at: 2026-05-24
status: closed
---

# 1. Objetivo

Implementar a tela mobile dedicada ao fluxo de **avaliação de caso pelo advogado** (`AnalysisTypeDto.caseAssessment`), em `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/`. A tela cobre upload do documento (PDF/DOCX, máx. 20MB), criação e leitura de `AnalysisDocumentDto`, sumarização do caso, busca de precedentes ranqueados por aplicabilidade, geração e regeneração da `PetitionDraftDto`, preview da minuta no card principal e visualização completa em modal fullscreen, exportação do relatório completo em PDF e retry contextual no estado `FAILED`. Inclui também o registro da nova rota dedicada e a correção do roteamento de `Routes.getAnalysis(analysisType: caseAssessment)` para apontar para essa tela.

---

# 2. Escopo

## 2.1 In-scope

- Tela dedicada em `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/` com padrão MVP.
- `CaseAssessmentAnalysisScreenView` (`ConsumerStatefulWidget`) e `CaseAssessmentAnalysisScreenPresenter` com provider Riverpod `caseAssessmentAnalysisScreenPresenterProvider`.
- Upload de **um único** documento (PDF ou DOCX) com limite local de **20MB**.
- Criação de `AnalysisDocumentDto` após upload bem-sucedido via `IntakeService.createAnalysisDocument`.
- Reentrada da tela com leitura de `AnalysisDocumentDto` (`getAnalysisDocument`) quando o documento já existir.
- Sumarização do caso via trigger de sumarização (`triggerFirstInstanceCaseSummarization` — ver decisão técnica 8.1) com polling até `CASE_ANALYZED` ou `FAILED`.
- Exibição de `CaseSummaryCard` ao atingir `CASE_ANALYZED`, com botão **Regerar resumo**.
- Busca de precedentes a partir de `CASE_ANALYZED`, reutilizando o componente global `AnalysisPrecedentsBubble`, com botão **Refazer busca** e CTA **Gerar minuta** quando houver precedentes prontos.
- Geração e regeneração da minuta com polling até `DONE` ou `FAILED`. O carregamento da minuta usa `IntakeService.getPetitionDraft`.
- Card de minuta (`PetitionDraftCard`) com preview truncado e botão **Ver minuta** que abre o `PetitionDraftModal` fullscreen.
- Card de loading da minuta (`GeneratePetitionDraftCard`) durante `GENERATING_PETITION_DRAFT`.
- Exportação do relatório completo em PDF habilitada apenas em `DONE`, consumindo `IntakeService.getCaseAssessmentAnalysisReport` e o `PdfDriver` (assumindo que o driver passe a expor `generateCaseAssessmentReport`).
- Retry contextual em `FAILED` reaproveitando a etapa mais avançada conhecida pelo estado local (resumo, precedentes ou minuta).
- Reuso integral dos componentes globais existentes em `lib/ui/intake/widgets/components/`: `AiBubble`, `AnalysisActionBar`, `AnalysisHeader` (com `archive_analysis_dialog` e `rename_analysis_dialog`), `AnalysisPrecedentsBubble`, `CaseSummaryCard`, `DocumentFileBubble`, `MessageBox`.
- Reuso do `dot_grid_background` e do `precedent_dialog` já hospedados em `first_instance_analysis_screen/` (mantidos onde estão, sem mover).
- Registro de `Routes.caseAssessmentAnalysis` e `Routes.getCaseAssessmentAnalysis(...)` em `lib/constants/routes.dart`.
- Registro do `GoRoute` correspondente em `lib/router.dart` com redirect local por `analysisId` vazio.
- Correção do switch em `Routes.getAnalysis(...)`: o branch `AnalysisTypeDto.caseAssessment` passa a apontar para `getCaseAssessmentAnalysis(...)`.

## 2.2 Out-of-scope

- Criação de novos contratos no `core` para trigger explícito de Case Assessment (sumarização e minuta). Decisão registrada em 8.1.
- Implementação no servidor de endpoints de trigger dedicados a Case Assessment.
- Edição inline da minuta dentro do app.
- Upload de múltiplos arquivos por análise.
- Alteração dos componentes globais (`AiBubble`, `AnalysisHeader`, `AnalysisPrecedentsBubble` etc.). Esta spec apenas os consome.
- Alterações nas telas `FirstInstanceAnalysisScreenView` e `SecondInstanceAnalysisScreenView`.
- Testes de `lib/core/`, `lib/rest/` e `lib/drivers/` (apenas UI conforme política do projeto).
- Telemetria, analytics e eventos de produto.

---

# 3. Requisitos

## 3.1 Funcionais

- A tela deve aceitar apenas PDF e DOCX e bloquear arquivos acima de **20MB** antes do upload.
- Após upload válido, o app deve criar `AnalysisDocumentDto`, atualizar o status da análise para `DOCUMENT_UPLOADED` (via `IntakeService.updateAnalysisStatus`) e habilitar o CTA **Analisar**.
- Ao reabrir a tela em estados posteriores, o app deve buscar `AnalysisDocumentDto` e exibir o nome do documento já salvo no `DocumentFileBubble`.
- Ao acionar **Analisar**, o app deve disparar a sumarização (`triggerFirstInstanceCaseSummarization`) e refletir `ANALYZING_CASE` como processamento (com `AiBubble` em estado de digitação).
- Ao atingir `CASE_ANALYZED`, o app deve carregar `CaseSummaryDto` via `getCaseSummary` e exibir o `CaseSummaryCard` com botão **Regerar resumo**.
- O CTA primário do `AnalysisActionBar` deve transicionar para **Buscar precedentes** em `CASE_ANALYZED`.
- Durante `SEARCHING_PRECEDENTS`, `ANALYZING_PRECEDENTS_SIMILARITY` e `ANALYZING_PRECEDENTS_APPLICABILITY`, o `AnalysisPrecedentsBubble` deve renderizar seu estado de loading.
- Ao receber precedentes, o `AnalysisPrecedentsBubble` deve exibir a lista ranqueada por aplicabilidade com botão **Refazer busca**.
- O CTA primário deve transicionar para **Gerar minuta** quando houver pelo menos um precedente carregado.
- Ao acionar **Gerar minuta**, o app deve transicionar para `GENERATING_PETITION_DRAFT` exibindo `GeneratePetitionDraftCard` e polling até `DONE` ou `FAILED`.
- Ao atingir `DONE`, o app deve carregar `PetitionDraftDto` via `getPetitionDraft` e exibir `PetitionDraftCard` com preview e botão **Ver minuta** abrindo `PetitionDraftModal` fullscreen.
- O `AnalysisHeader` deve expor o botão **Exportar PDF** habilitado apenas quando o status local for `DONE` e a minuta estiver carregada.
- Cada resultado parcial (resumo, precedentes, minuta) deve oferecer botão de **reload individual** próprio da sua etapa.
- Em `FAILED`, o app deve exibir `MessageBox` inline com a mensagem de erro e o CTA primário do `AnalysisActionBar` deve virar **Tentar novamente** com retry contextual à etapa interrompida (sumarização, busca de precedentes ou geração da minuta).
- O polling de `getAnalysis` deve ocorrer em qualquer estado de processamento e parar nos estados terminais (`CASE_ANALYZED`, `DONE`, `FAILED`) ou intermediários estáveis (`PRECEDENTS_SEARCHED` se aplicável ao fluxo do componente).
- A navegação de volta do header deve respeitar o stack: `Navigator.maybePop()` se houver, senão `context.go(Routes.home)`.
- O header deve oferecer **Renomear**, **Arquivar** e (quando aplicável) **Filtros** e **Quantidade de precedentes**, idênticos às demais telas de análise.
- `Routes.getAnalysis(analysisType: caseAssessment)` deve passar a retornar `Routes.getCaseAssessmentAnalysis(analysisId: ...)`.

## 3.2 Não funcionais

- Polling com intervalo mínimo de **3 segundos** entre chamadas.
- Timeout local de **10 segundos** por tentativa de polling/trigger.
- A View não deve montar payload nem acessar `RestClient` diretamente.
- O presenter consome `IntakeService`, `StorageService`, `DocumentPickerDriver`, `FileStorageDriver`, `CacheDriver` e `PdfDriver` via providers Riverpod.
- Widgets internos com responsabilidade própria devem ter pasta dedicada com `index.dart`, `*_view.dart` e `*_presenter.dart` quando houver estado.
- O presenter da Screen permanece enxuto e orquestrador; lógica específica de cards e modais vive em presenters próprios dos widgets internos quando houver estado.
- Strings em PT-BR acentuadas (padrão atual do app).

---

# 4. O que já existe?

## Core

- **`AnalysisDto`** (`lib/core/intake/dtos/analysis_dto.dart`) — DTO de análise consumido em `getAnalysis`/`load`.
- **`AnalysisDocumentDto`** (`lib/core/intake/dtos/analysis_document_dto.dart`) — DTO do documento da análise.
- **`AnalysisStatusDto`** (`lib/core/intake/dtos/analysis_status_dto.dart`) — enum de status compartilhado da UI, já cobre `WAITING_DOCUMENT_UPLOAD`, `DOCUMENT_UPLOADED`, `ANALYZING_CASE`, `CASE_ANALYZED`, `SEARCHING_PRECEDENTS`, `ANALYZING_PRECEDENTS_SIMILARITY`, `ANALYZING_PRECEDENTS_APPLICABILITY`, `GENERATING_PETITION_DRAFT`, `DONE` e `FAILED`.
- **`CaseAssessmentAnalysisStatusDto`** (`lib/core/intake/dtos/case_assessment_analysis_status_dto.dart`) — enum tipado dos status de Case Assessment, já mapeado em `AnalysisStatusDto.caseAssessment(...)`.
- **`AnalysisTypeDto.caseAssessment`** (`lib/core/intake/dtos/analysis_type_dto.dart`) — tipo de análise consumido na rota.
- **`CaseSummaryDto`** (`lib/core/intake/dtos/case_summary_dto.dart`) — DTO do resumo.
- **`PetitionDraftDto`** (`lib/core/intake/dtos/petition_draft_dto.dart`) — DTO da minuta de petição, com `analysisId` e `content` (String).
- **`CaseAssessmentAnalysisReportDto`** (`lib/core/intake/dtos/case_assessment_analysis_report_dto.dart`) — DTO de report agregado (análise, documento, resumo, precedentes, minuta) usado na exportação.
- **`AnalysisPrecedentDto`** (`lib/core/intake/dtos/analysis_precedent_dto.dart`) — DTO consumido pelo `AnalysisPrecedentsBubble`.
- **`IntakeService`** (`lib/core/intake/interfaces/intake_service.dart`) — contrato com `getAnalysis`, `createAnalysisDocument`, `getAnalysisDocument`, `updateAnalysisStatus`, `getCaseSummary`, `triggerFirstInstanceCaseSummarization`, `getPetitionDraft`, `getCaseAssessmentAnalysisReport`, `renameAnalysis`, `archiveAnalysis`.
- **`StorageService`** (`lib/core/storage/interfaces/storage_service.dart`) — com `generateAnalysisDocumentUploadUrl(...)`.
- **`DocumentPickerDriver`** (`lib/core/storage/interfaces/drivers/document_picker_driver.dart`) — porta para seleção de arquivos.
- **`FileStorageDriver`** (`lib/core/storage/interfaces/drivers/file_storage_driver.dart`) — porta para upload local/remoto.
- **`PdfDriver`** (`lib/core/shared/interfaces/pdf_driver.dart`) — porta para geração e share de PDFs.
- **`CacheDriver`** (`lib/core/shared/interfaces/cache_driver.dart`) — usado pelo `precedentsLimit`.

## REST

- **`IntakeRestService`** (`lib/rest/services/intake_rest_service.dart`) — implementa `createAnalysisDocument`, `getAnalysisDocument`, `getCaseSummary`, `triggerFirstInstanceCaseSummarization`, `getPetitionDraft`, `getCaseAssessmentAnalysisReport`, `updateAnalysisStatus`, `renameAnalysis`, `archiveAnalysis`.
- **`CaseAssessmentAnalysisReportMapper`** (`lib/rest/mappers/intake/case_assessment_analysis_report_mapper.dart`).
- **`PetitionDraftMapper`** (`lib/rest/mappers/intake/petition_draft_mapper.dart`).
- **`AnalysisMapper`**, **`AnalysisDocumentMapper`**, **`CaseSummaryMapper`**.

## Drivers

- **`DocumentPickerDriverImpl`** (`lib/drivers/document-picker-driver/`).
- **`FileStorageDriverImpl`** (`lib/drivers/file_storage/`).
- **`CacheDriverImpl`** (`lib/drivers/cache/`).
- **`PdfDriverImpl`** (`lib/drivers/pdf-driver/`) — usado pelos relatórios existentes (1ª instância).

## UI (componentes globais reutilizados)

- **`AiBubble`** (`lib/ui/intake/widgets/components/ai_bubble/`).
- **`AnalysisActionBar`** (`lib/ui/intake/widgets/components/analysis_action_bar/`).
- **`AnalysisHeader`** com `archive_analysis_dialog` e `rename_analysis_dialog` (`lib/ui/intake/widgets/components/analysis_header/`).
- **`AnalysisPrecedentsBubble`** com `precedents_filters_dialog`, `precedents_limit_dialog`, `precedent_dialog` (`lib/ui/intake/widgets/components/analysis_precedents_bubble/`).
- **`AnalysisPrecedentsBubblePresenter`** com `analysisPrecedentsBubblePresenterProvider` para gerenciamento do fluxo de precedentes.
- **`CaseSummaryCard`** (`lib/ui/intake/widgets/components/case_summary_card/`).
- **`DocumentFileBubble`** (`lib/ui/intake/widgets/components/document_file_bubble/`).
- **`MessageBox`** (`lib/ui/intake/widgets/components/message_box/`).
- **`DotGridBackground`** (`lib/ui/intake/widgets/pages/first_instance_analysis_screen/dot_grid_background/`) — mantido onde está, importado pela nova tela.
- **`PrecedentDialog`** (`lib/ui/intake/widgets/pages/first_instance_analysis_screen/precedent_dialog/`) — mantido onde está.

## Constants e Router

- **`Routes`** (`lib/constants/routes.dart`) — já possui `Routes.analysis` (1ª instância) e `Routes.secondInstanceAnalysis`. O switch de `getAnalysis(...)` hoje encaminha `caseAssessment` para a 2ª instância (legado a corrigir).
- **`appRouter`** (`lib/router.dart`) — registra rotas existentes; será estendido com a nova `GoRoute` de Case Assessment.

## Lacunas identificadas

- Não existe `triggerCaseAssessmentCaseSummarization(...)` nem `triggerCaseAssessmentPetitionDraftGeneration(...)` no `IntakeService`. Esta spec consome `triggerFirstInstanceCaseSummarization` para a sumarização (compatível server-side, pois o endpoint `POST /intake/analyses/{id}/case-summaries` é tipo-agnóstico) e baseia a geração da minuta apenas no polling do `getAnalysis` + leitura do `getPetitionDraft` quando `status == DONE`. Ver decisões 8.1 e 8.2.
- O método `PdfDriver.generateCaseAssessmentReport(...)` não existe hoje. Esta spec assume sua existência como pendência (`Pendências 10.1`) e, enquanto não for entregue, a exportação fica bloqueada com `MessageBox` informativo (ver decisão 8.5).

---

# 5. O que deve ser criado?

## Camada UI (Presenters)

### `CaseAssessmentAnalysisScreenPresenter`

- **Localização:** `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/case_assessment_analysis_screen_presenter.dart` (**novo arquivo**).
- **Dependências injetadas:** `IntakeService`, `StorageService`, `FileStorageDriver`, `DocumentPickerDriver`, `CacheDriver`, `PdfDriver` (todos via providers Riverpod).
- **Constantes:**
  - `allowedExtensions = <String>['pdf', 'docx']`
  - `maxFileSizeInBytes = 20 * 1024 * 1024`
  - `pollingInterval = Duration(seconds: 3)`
  - `requestTimeout = Duration(seconds: 10)`
  - `failedMessage` (PT-BR acentuado)
  - `exportFailedMessage` (PT-BR acentuado)
- **Estado (`Signal`):**
  - `status: Signal<AnalysisStatusDto>` — inicia em `waitingDocumentUpload`.
  - `selectedFile: Signal<File?>`
  - `analysisDocument: Signal<AnalysisDocumentDto?>`
  - `isUploading: Signal<bool>`
  - `uploadProgress: Signal<double?>`
  - `caseSummary: Signal<CaseSummaryDto?>`
  - `petitionDraft: Signal<PetitionDraftDto?>`
  - `generalError: Signal<String?>`
  - `analysisName: Signal<String>` — `'Nova Análise'`.
  - `isArchived: Signal<bool>`
  - `isManagingAnalysis: Signal<bool>`
  - `isExportingReport: Signal<bool>`
  - `precedentsReady: Signal<bool>` — virada para `true` quando o `AnalysisPrecedentsBubble` carregar precedentes.
- **Computeds (`ReadonlySignal`):**
  - `canPickDocument` — `true` se não está fazendo upload, não está gerenciando, não está processando caso/draft.
  - `canAnalyzeCase` — `true` se há documento + status `DOCUMENT_UPLOADED` ou `FAILED` (e a etapa falha era sumarização).
  - `canRegenerateSummary` — `true` em `CASE_ANALYZED` e não gerenciando.
  - `canSearchPrecedents` — `true` em `CASE_ANALYZED` com `caseSummary != null`.
  - `canGeneratePetitionDraft` — `true` quando `precedentsReady.value == true` e o status não é `GENERATING_PETITION_DRAFT`.
  - `canRegeneratePetitionDraft` — `true` em `DONE` com `petitionDraft != null`.
  - `showCaseProcessingBubble` — `status == ANALYZING_CASE`.
  - `showPetitionDraftProcessingCard` — `status == GENERATING_PETITION_DRAFT`.
  - `canExportReport` — `status == DONE` e `!isExportingReport.value`.
  - `primaryActionLabel` — label do CTA primário, conforme tabela em 9.2.
  - `fileActionLabel` — `'Selecionar petição'` (default), `'Enviar outro documento'` em `CASE_ANALYZED+`.
- **Provider:** `caseAssessmentAnalysisScreenPresenterProvider` (`Provider.autoDispose.family<CaseAssessmentAnalysisScreenPresenter, String>`).
- **Métodos:**
  - `Future<void> load()` — carrega `AnalysisDto`, popula `analysisName`/`isArchived`/`status`, carrega `AnalysisDocumentDto`/`CaseSummaryDto`/`PetitionDraftDto` conforme o status atual, retoma polling se necessário.
  - `Future<void> pickDocument()` — valida extensão e tamanho; chama `_uploadAnalysisDocument`.
  - `Future<void> analyzeCase()` — dispara `triggerFirstInstanceCaseSummarization` e inicia `_pollUntilCaseReady`.
  - `Future<void> reanalyzeCase()` — limpa `caseSummary`, `petitionDraft`, `precedentsReady`; reabre fluxo `analyzeCase`.
  - `Future<void> retrySummary()` — atalho do botão de reload do `CaseSummaryCard`; equivalente a `reanalyzeCase`.
  - `void confirmAndViewPrecedents()` — transição manual para `SEARCHING_PRECEDENTS` (delegando ao `AnalysisPrecedentsBubblePresenter` a chamada efetiva).
  - `void markPrecedentsReady()` — callback do `AnalysisPrecedentsBubble.onPrecedentsReady`.
  - `Future<void> requestPetitionDraft()` — transiciona para `GENERATING_PETITION_DRAFT` e inicia `_pollUntilPetitionDraftReady`.
  - `Future<void> regeneratePetitionDraft()` — limpa `petitionDraft`; chama `requestPetitionDraft`.
  - `Future<void> replaceDocument()` — reseta tudo e dispara `pickDocument`.
  - `Future<bool> renameAnalysis(String name)` — delega a `IntakeService.renameAnalysis`.
  - `Future<bool> archiveAnalysis()` — delega a `IntakeService.archiveAnalysis`.
  - `Future<bool> exportAnalysisReport()` — chama `getCaseAssessmentAnalysisReport` + `PdfDriver.generateCaseAssessmentReport` + `sharePdf`. Em caso de driver indisponível, seta `generalError = exportFailedMessage`.
  - `String fileName(File file)` / `String formatFileSize(int)` — helpers.
  - `void dispose()` — descarta todos os signals.
  - **Privados:**
    - `Future<void> _uploadAnalysisDocument(File file)`
    - `Future<void> _pollUntilCaseReady()`
    - `Future<void> _pollUntilPetitionDraftReady()`
    - `Future<bool> _tryLoadPetitionDraft()`
    - `Future<void> _applyFailure([String? message])`
    - `String _getExtension(String path)`
    - `String _buildTimeoutMessage()`
    - `String _buildReportFilename(String rawName)`

### Widgets internos com presenter

Nenhum widget interno desta tela exige presenter próprio na entrega inicial — os cards `GeneratePetitionDraftCard` e `PetitionDraftCard` são puramente visuais; o `PetitionDraftModal` apenas renderiza conteúdo recebido por prop.

> Observação: a lógica de filtros/limite de precedentes vive no `AnalysisPrecedentsBubblePresenter` (já existente). O presenter da Screen apenas delega `onFilters` e `onPrecedentsCount` ao bubble presenter, seguindo o padrão da `SecondInstanceAnalysisScreenView`.

## Camada UI (Views)

### `CaseAssessmentAnalysisScreenView`

- **Localização:** `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/case_assessment_analysis_screen_view.dart` (**novo arquivo**).
- **Base class:** `ConsumerStatefulWidget` (com `ScrollController` interno para auto-scroll ao acionar CTAs).
- **Props:** `final String analysisId`.
- **Bibliotecas de UI:** `flutter_riverpod`, `signals_flutter`, `flutter_animate` (entradas animadas), `go_router`.
- **Estados visuais:**
  - **Waiting document:** `AiBubble` de boas-vindas + `AnalysisActionBar` com apenas `FileActionButton`.
  - **Document ready:** `DocumentFileBubble` + CTA `Analisar`.
  - **Processing case:** `AiBubble` em modo digitação (mensagem "Analisando o caso...").
  - **Case analyzed:** `CaseSummaryCard` + botão **Regerar resumo** abaixo do card; CTA primário vira **Buscar precedentes**.
  - **Searching/analyzing precedents:** `AnalysisPrecedentsBubble` em loading.
  - **Precedents ready:** `AnalysisPrecedentsBubble` listando precedentes; CTA primário vira **Gerar minuta**; header recebe `onFilters` e `onPrecedentsCount`.
  - **Generating petition draft:** `GeneratePetitionDraftCard`.
  - **Done:** `PetitionDraftCard` com preview e botão **Ver minuta** que abre `PetitionDraftModal` fullscreen; header habilita **Exportar PDF**; CTA primário vira **Regerar minuta**.
  - **Failed:** `MessageBox` inline com erro; CTA primário vira **Tentar novamente** com retry contextual.
- **Responsabilidades:** apenas observar signals do presenter via `Watch`, renderizar componentes adequados ao estado, encaminhar eventos para o presenter, abrir os modais (precedent, rename, archive, filters, limit, petition draft) via `Navigator`/`showDialog`.

## Camada UI (Widgets internos)

### `GeneratePetitionDraftCard`

- **Localização:** `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/generate_petition_draft_card/` (**novo arquivo**).
- **Arquivos:** `index.dart`, `generate_petition_draft_card_view.dart`.
- **Tipo:** `View only`.
- **Props:** nenhum (mensagens fixas).
- **Responsabilidade:** card de loading exibido enquanto a minuta é gerada (`GENERATING_PETITION_DRAFT`). Inclui `CircularProgressIndicator`, título "Gerando minuta de petição" e texto auxiliar em PT-BR acentuado.

### `PetitionDraftCard`

- **Localização:** `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/petition_draft_card/` (**novo arquivo**).
- **Arquivos:** `index.dart`, `petition_draft_card_view.dart`, `preview_section/index.dart`, `preview_section/preview_section_view.dart`.
- **Tipo:** `View only` (estado de scroll/expand local, sem signals).
- **Props:**
  - `final PetitionDraftDto draft`.
  - `final VoidCallback? onRegenerate` — chamada quando o botão **Regerar minuta** é acionado (opcional para versões iniciais; o CTA principal já oferece a regeneração via `AnalysisActionBar`).
  - `final VoidCallback onOpenModal` — abre o `PetitionDraftModal`.
- **Responsabilidade:** card com cabeçalho "Minuta de petição", preview truncado do `draft.content` (até ~6 linhas com `TextOverflow.ellipsis`) e dois botões: **Ver minuta** e (opcional) **Regerar minuta**.

### `PetitionDraftModal`

- **Localização:** `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/petition_draft_modal/` (**novo arquivo**).
- **Arquivos:** `index.dart`, `petition_draft_modal_view.dart`.
- **Tipo:** `View only` — renderiza apenas o conteúdo recebido.
- **Props:** `final PetitionDraftDto draft`.
- **Responsabilidade:** `Scaffold` fullscreen com `AppBar`/cabeçalho e `SingleChildScrollView` exibindo o `draft.content` integral. Estilo alinhado ao `JudgmentDraftDialogView` da 2ª instância.

## Camada UI (Barrel Files / `index.dart`)

### `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/index.dart` (**novo arquivo**)

```dart
export 'package:animus/ui/intake/widgets/pages/case_assessment_analysis_screen/case_assessment_analysis_screen_presenter.dart'
    show CaseAssessmentAnalysisScreenPresenter, caseAssessmentAnalysisScreenPresenterProvider;

import 'package:animus/ui/intake/widgets/pages/case_assessment_analysis_screen/case_assessment_analysis_screen_view.dart';

typedef CaseAssessmentAnalysisScreen = CaseAssessmentAnalysisScreenView;
```

Cada widget interno terá seu próprio `index.dart` com `typedef`.

## Rotas (`go_router`) e Constants

### `lib/constants/routes.dart`

- Adicionar:
  - `static const String caseAssessmentAnalysis = '/analyses/:analysisId/case-assessment';`
  - `static String getCaseAssessmentAnalysis({required String analysisId}) => Uri(path: '/analyses/${Uri.encodeComponent(analysisId)}/case-assessment').toString();`

### `lib/router.dart`

- Adicionar `GoRoute` com `path: Routes.caseAssessmentAnalysis`, redirect local se `analysisId` vazio (para `Routes.home`), e `builder` retornando `CaseAssessmentAnalysisScreen(analysisId: analysisId)`.

## Estrutura de Pastas

```text
lib/ui/intake/widgets/pages/case_assessment_analysis_screen/
  index.dart
  case_assessment_analysis_screen_view.dart
  case_assessment_analysis_screen_presenter.dart
  generate_petition_draft_card/
    index.dart
    generate_petition_draft_card_view.dart
  petition_draft_card/
    index.dart
    petition_draft_card_view.dart
    preview_section/
      index.dart
      preview_section_view.dart
  petition_draft_modal/
    index.dart
    petition_draft_modal_view.dart
```

Componentes globais reutilizados (sem alteração):

```text
lib/ui/intake/widgets/components/
  ai_bubble/
  analysis_action_bar/
  analysis_header/
  analysis_precedents_bubble/
  case_summary_card/
  document_file_bubble/
  message_box/
```

Componentes reutilizados de outras telas (sem mover):

```text
lib/ui/intake/widgets/pages/first_instance_analysis_screen/
  dot_grid_background/         ← importado
  precedent_dialog/            ← importado (para abertura via Navigator)
```

---

# 6. O que deve ser modificado?

## Constants

- **Arquivo:** `lib/constants/routes.dart`
- **Mudança:** dentro do switch de `getAnalysis(...)`, o branch `AnalysisTypeDto.caseAssessment` passa a retornar `Routes.getCaseAssessmentAnalysis(analysisId: analysisId)`.
- **Justificativa:** hoje cai na rota de 2ª instância (workaround de ANI-115). Esta task corrige o roteamento, desbloqueando ANI-101 e ANI-102.

## Router

- **Arquivo:** `lib/router.dart`
- **Mudança:** importar `case_assessment_analysis_screen/index.dart` e adicionar `GoRoute` para `Routes.caseAssessmentAnalysis` (estrutura idêntica ao `GoRoute` de `secondInstanceAnalysis`).
- **Justificativa:** registrar a rota e seu widget de tela.

> Demais arquivos existentes (`IntakeService`, `IntakeRestService`, componentes globais, demais telas) **não são modificados** por esta spec.

---

# 7. O que deve ser removido?

**Não aplicável.**

---

# 8. Decisões Técnicas e Trade-offs

## 8.1 Trigger de sumarização: reaproveitar `triggerFirstInstanceCaseSummarization`

- **Decisão:** usar `IntakeService.triggerFirstInstanceCaseSummarization(analysisId)` para iniciar a sumarização da análise tipo `caseAssessment`.
- **Alternativas consideradas:** (a) criar `triggerCaseAssessmentCaseSummarization` no `core` + `rest`; (b) deixar a sumarização ser iniciada exclusivamente pelo servidor após criação do documento.
- **Motivo:** o endpoint REST `POST /intake/analyses/{analysisId}/case-summaries` é tipo-agnóstico no servidor — o tipo de análise é resolvido a partir do `AnalysisDto` no backend. Criar novo contrato no `core` apenas para mudar o nome seria duplicação sem ganho funcional. A nomenclatura atual é desalinhada (o método tem "FirstInstance" no nome), mas a refatoração foge ao escopo do ANI-103.
- **Impactos / trade-offs:** débito técnico de nomenclatura no `IntakeService`. Registrado para limpeza em ticket próprio.

## 8.2 Trigger de geração da minuta: não há método explícito

- **Decisão:** não existe `triggerCaseAssessmentPetitionDraftGeneration` no `IntakeService`. O fluxo assume que, após a escolha de precedentes ou após o avanço do servidor para `GENERATING_PETITION_DRAFT`, o polling de `getAnalysis` revela o status; ao chegar em `DONE`, o app chama `getPetitionDraft`.
- **Alternativas consideradas:** criar `triggerCaseAssessmentPetitionDraftGeneration` espelhando `triggerSecondInstanceJudgmentDraftGeneration`.
- **Motivo:** mantém o escopo cirúrgico de ANI-103 e respeita o contrato atual. Se o servidor não iniciar automaticamente a geração da minuta após precedentes prontos, este comportamento deve ser endereçado em ticket cross-repo (registrado em `Pendências 10.2`).
- **Impactos / trade-offs:** dependência externa de comportamento do servidor. Caso o trigger seja necessário, será adicionado em ticket próprio sem retrabalho na View/Presenter (basta inserir a chamada em `requestPetitionDraft`).

## 8.3 Nomenclatura: `CaseAssessment` em vez de `Lawyer`

- **Decisão:** todos os artefatos (classes, arquivos, rota) usam `CaseAssessment` (não `Lawyer`).
- **Alternativas consideradas:** seguir a Jira que cita "Advogado" e usar `LawyerAnalysisScreen`.
- **Motivo:** alinhamento com a nomenclatura consolidada no `core` (`CaseAssessmentAnalysisStatusDto`, `AnalysisTypeDto.caseAssessment`, `CaseAssessmentAnalysisReportDto`).
- **Impactos / trade-offs:** consistência > literalidade do título da Jira. Branch e Pasta refletem isso: `ANI-103-case-assessment-analysis-screen` e `case_assessment_analysis_screen/`.

## 8.4 Limite de upload: 20MB (vs. 50MB das outras telas)

- **Decisão:** `maxFileSizeInBytes = 20 * 1024 * 1024`.
- **Alternativas consideradas:** alinhar com as 1ª/2ª instâncias (50MB).
- **Motivo:** requisito explícito da Jira (ANI-103 menciona 20MB).
- **Impactos / trade-offs:** menor flexibilidade ao usuário, mas alinhado ao PRD.

## 8.5 Exportação de PDF: `PdfDriver.generateCaseAssessmentReport` ainda não existe

- **Decisão:** consumir o método como se existisse e tratar `UnimplementedError` (ou ausência do método) no presenter, retornando `exportFailedMessage` para a UI.
- **Alternativas consideradas:** bloquear o botão até o driver estar pronto.
- **Motivo:** a tela deve estar pronta para o momento em que o driver for entregue. Esconder o botão criaria divergência entre tipos de análise.
- **Impactos / trade-offs:** botão visível em `DONE` mas pode mostrar erro se o driver ainda não estiver implementado. Registrado em `Pendências 10.1`.

## 8.6 Reuso integral do `AnalysisPrecedentsBubble`

- **Decisão:** consumir `AnalysisPrecedentsBubble` com a mesma API usada pela 2ª instância (props `analysisId`, `analysisStatus`, `onPrecedentsReady`, `onPrecedentTap`). O bubble já gerencia internamente busca, retry, filtros e quantidade.
- **Alternativas consideradas:** criar uma variante específica para Case Assessment.
- **Motivo:** o componente é global e foi consolidado em ANI-117 para servir múltiplas telas.
- **Impactos / trade-offs:** zero duplicação; eventuais ajustes específicos do fluxo de advogado (se necessários no futuro) ficam confinados a props/callbacks do componente.

## 8.7 Persistência de `precedentsLimit` via `CacheDriver`

- **Decisão:** seguir o padrão da 1ª instância — `precedentsLimit` é lido/escrito no `CacheDriver` com chave `CacheKeys.precedentsLimit`, mas a Screen delega ao `AnalysisPrecedentsBubblePresenter` (que já implementa a persistência via `_syncSelectedLimit`).
- **Motivo:** não duplicar persistência.

---

# 9. Diagramas e Referências

## 9.1 Fluxo de dados

```text
CaseAssessmentAnalysisScreenView
  -> CaseAssessmentAnalysisScreenPresenter
      -> caseAssessmentAnalysisScreenPresenterProvider
          -> StorageService.generateAnalysisDocumentUploadUrl(...)
          -> FileStorageDriver.uploadFile(...)
          -> IntakeService.createAnalysisDocument(...)
          -> IntakeService.updateAnalysisStatus(..., DOCUMENT_UPLOADED)
          -> IntakeService.triggerFirstInstanceCaseSummarization(...)
          -> IntakeService.getAnalysis(...)        [polling]
          -> IntakeService.getAnalysisDocument(...)
          -> IntakeService.getCaseSummary(...)
          -> IntakeService.getPetitionDraft(...)
          -> IntakeService.getCaseAssessmentAnalysisReport(...)
          -> PdfDriver.generateCaseAssessmentReport(...)   [pendência 10.1]
          -> PdfDriver.sharePdf(...)
          -> IntakeService.renameAnalysis(...)
          -> IntakeService.archiveAnalysis(...)

AnalysisPrecedentsBubbleView (componente global, reutilizado)
  -> AnalysisPrecedentsBubblePresenter
      -> analysisPrecedentsBubblePresenterProvider
          -> IntakeService.searchAnalysisPrecedents(...)
          -> IntakeService.listAnalysisPrecedents(...)
          -> IntakeService.getAnalysis(...)
          -> IntakeService.chooseAnalysisPrecedent(...)
          -> IntakeService.unchooseAnalysisPrecedent(...)
```

## 9.2 Mapeamento de status → label do CTA primário

| Status local                                | Label do `primaryActionLabel` |
|---------------------------------------------|-------------------------------|
| `WAITING_DOCUMENT_UPLOAD`                   | `Analisar` (oculto até documento)
| `DOCUMENT_UPLOADED`                         | `Analisar`
| `ANALYZING_CASE`                            | `Analisar` (busy)
| `CASE_ANALYZED`                             | `Buscar precedentes`
| `SEARCHING_PRECEDENTS` / `ANALYZING_PRECEDENTS_*` | (action bar oculta — bubble cuida)
| `PRECEDENTS_SEARCHED` (precedentes prontos) | `Gerar minuta`
| `GENERATING_PETITION_DRAFT`                 | `Gerar minuta` (busy)
| `DONE`                                      | `Regerar minuta`
| `FAILED`                                    | `Tentar novamente` (contextual)

## 9.3 Hierarquia de widgets

```text
CaseAssessmentAnalysisScreenView
  Scaffold
    SafeArea
      Center
        ConstrainedBox (maxWidth: 402)
          Stack
            DotGridBackground
            Column
              AnalysisHeader (com Exportar PDF condicional)
              Expanded
                SingleChildScrollView
                  AiBubble (boas-vindas)
                  DocumentFileBubble (quando há arquivo/documento)
                  AiBubble (processing, em ANALYZING_CASE)
                  MessageBox (em FAILED)
                  CaseSummaryCard + botão Regerar resumo
                  AnalysisPrecedentsBubble
                  GeneratePetitionDraftCard (em GENERATING_PETITION_DRAFT)
                  PetitionDraftCard (em DONE) → abre PetitionDraftModal
              AnalysisActionBar
```

## 9.4 Referências de código

- `lib/ui/intake/widgets/pages/first_instance_analysis_screen/first_instance_analysis_screen_view.dart` — referência principal de orquestração de upload, polling, exportação e header.
- `lib/ui/intake/widgets/pages/first_instance_analysis_screen/first_instance_analysis_screen_presenter.dart` — referência de signals, computeds, polling, retry, export e cache de precedentsLimit.
- `lib/ui/intake/widgets/pages/second_instance_analysis_screen/second_instance_analysis_screen_view.dart` — referência de cards de draft + modal fullscreen, retry contextual, integração com `AnalysisPrecedentsBubble.onPrecedentsReady`.
- `lib/ui/intake/widgets/pages/second_instance_analysis_screen/second_instance_analysis_screen_presenter.dart` — referência de `precedentsReady`, polling de draft e retry contextual.
- `lib/ui/intake/widgets/pages/second_instance_analysis_screen/judgment_draft_card/judgment_draft_card_view.dart` — referência visual para o `PetitionDraftCard` (preview + botão "Ver completa").
- `lib/ui/intake/widgets/pages/second_instance_analysis_screen/judgment_draft_dialog/judgment_draft_dialog_view.dart` — referência visual para o `PetitionDraftModal`.
- `lib/ui/intake/widgets/pages/second_instance_analysis_screen/generate_judgment_draft_card/generate_judgment_draft_card_view.dart` — referência visual para o `GeneratePetitionDraftCard`.

---

# 10. Pendências / Dúvidas

## 10.1 `PdfDriver.generateCaseAssessmentReport(...)` não existe

- **Descrição da pendência:** o `PdfDriver` (`lib/core/shared/interfaces/pdf_driver.dart`) atualmente define apenas `generateAnalysisReport(...)` para 1ª instância. O método para Case Assessment ainda não foi acordado.
- **Impacto na implementação:** a exportação chamará `_pdfDriver.generateCaseAssessmentReport(...)`. Se o método não existir, o presenter captura o erro e exibe `exportFailedMessage` para o usuário. A UI permanece funcional para todos os outros estados.
- **Ação sugerida:** abrir ticket próprio (ex.: `ANI-XXX — Add CaseAssessment report support to PdfDriver`) para o time de drivers/exportação. Sem bloqueio para ANI-103 funcionar até `DONE`.

## 10.2 Comportamento do servidor após `PRECEDENTS_SEARCHED`

- **Descrição da pendência:** não é claro se o servidor avança automaticamente de `PRECEDENTS_SEARCHED` para `GENERATING_PETITION_DRAFT` ou se exige trigger explícito do cliente.
- **Impacto na implementação:** se o servidor não avançar sozinho, o botão **Gerar minuta** ficará inerte e o polling nunca observará `GENERATING_PETITION_DRAFT`.
- **Ação sugerida:** validar com o time backend; se trigger explícito for necessário, abrir ticket cross-repo para adicionar `triggerCaseAssessmentPetitionDraftGeneration` ao `IntakeService` (sem retrabalho na View/Presenter — basta plugar a chamada em `requestPetitionDraft`).

## 10.3 Nome ruim de `triggerFirstInstanceCaseSummarization` para Case Assessment

- **Descrição da pendência:** o método chama "FirstInstance" mas é usado também por Case Assessment.
- **Impacto na implementação:** apenas leitura — débito técnico de nomenclatura.
- **Ação sugerida:** abrir ticket de refactor para renomear (ex.: `IntakeService.triggerCaseSummarization`).

---

# Restrições

- A `View` não contém lógica de negócio — toda orquestração fica no `Presenter`.
- O `Presenter` consome apenas a interface `IntakeService` (e demais ports do `core`), nunca `RestClient` diretamente.
- Os componentes globais (`AiBubble`, `AnalysisHeader`, `AnalysisActionBar`, `CaseSummaryCard`, `DocumentFileBubble`, `AnalysisPrecedentsBubble`, `MessageBox`) **não são duplicados** — apenas consumidos.
- Não criar testes para `lib/core/`, `lib/rest/`, `lib/drivers/` (política do projeto).
- Nomes de arquivos em `snake_case`; classes em `PascalCase`; presenters, providers, métodos em `camelCase`.
- Strings da UI em PT-BR acentuadas, alinhadas ao padrão do app.
- Todo widget novo segue `View + Presenter`; o `Presenter` é opcional apenas em widgets puramente visuais.
- A pasta da tela possui `index.dart` com `typedef CaseAssessmentAnalysisScreen = CaseAssessmentAnalysisScreenView;` e `export` do presenter + provider.
- Cada widget interno tem seu próprio `index.dart`.
