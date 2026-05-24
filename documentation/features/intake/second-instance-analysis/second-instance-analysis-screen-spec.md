---
title: Tela de análise de segunda instância
prd: https://joaogoliveiragarcia.atlassian.net/wiki/spaces/ANM/pages/49348609
ticket: https://joaogoliveiragarcia.atlassian.net/browse/ANI-104
last_updated_at: 2026-05-22
---

# 1. Objetivo

Manter a tela mobile dedicada ao fluxo de **Análise para 2ª Instância** do perfil Juiz, cobrindo upload dos autos em PDF, criação e leitura de `AnalysisDocumentDto`, processamento do caso, exibição do resumo, busca e nova busca de precedentes, geração e regeneração da minuta, preview da minuta com abertura em fullscreen e tratamento dos estados `PETITION_NOT_FOUND`, `PRECEDENTS_SEARCHED`, `GENERATING_SYNTHESIS` e `FAILED` com retry contextual.

---

# 2. Escopo

## 2.1 In-scope

- Tela dedicada em `lib/ui/intake/widgets/pages/second_instance_analysis_screen/` com padrão MVP.
- Upload de um único PDF com limite local de **100MB**.
- Criação de `AnalysisDocumentDto` após upload bem-sucedido.
- Reentrada da tela com leitura de `AnalysisDocumentDto` quando o documento já existir.
- Processamento do caso via trigger de sumarização de 2ª instância, com polling até `CASE_ANALYZED`, `PETITION_NOT_FOUND` ou `FAILED`.
- Exibição de `CaseSummaryDto` ao atingir `CASE_ANALYZED`.
- CTA **Regerar análise do processo** a partir de `CASE_ANALYZED`, sem novo upload.
- Busca de precedentes a partir de `CASE_ANALYZED`, com retry da etapa sem novo upload.
- Exibição da lista de precedentes em `PRECEDENTS_SEARCHED` e nos estados posteriores do fluxo.
- Abertura do dialog fullscreen do precedente ao tocar em um item da lista.
- Geração e regeneração da minuta a partir dos precedentes disponíveis.
- Exibição de card de loading para a minuta durante `GENERATING_JUDGMENT_DRAFT` e `GENERATING_SYNTHESIS`.
- Exibição de preview da minuta no card principal e visualização completa em dialog fullscreen próprio.
- Retry contextual em `FAILED` para a etapa que parou: análise do caso, busca de precedentes ou geração da minuta.
- Componentização global de `analysis_precedents_bubble`, `document_file_bubble`, `case_summary_card`, `analysis_action_bar`, `analysis_header`, `ai_bubble` e `message_box` no módulo `intake`.

## 2.2 Out-of-scope

- Exportação da minuta em PDF.
- Edição inline da minuta dentro do app.
- Upload de múltiplos arquivos.
- Suporte a DOCX ou imagens no fluxo da 2ª instância.
- Alterações no `design/animus.pen`.

---

# 3. Requisitos

## 3.1 Funcionais

- O app deve aceitar apenas PDF e bloquear arquivos acima de **100MB** antes do upload.
- Após upload válido, o app deve persistir `AnalysisDocumentDto` e avançar para `DOCUMENT_UPLOADED`.
- Ao reabrir a tela em estados posteriores, o app deve buscar `AnalysisDocumentDto` e exibir o nome do documento já salvo.
- Ao acionar **Analisar**, o app deve disparar a sumarização de 2ª instância e refletir `EXTRACTING_PETITION` e `ANALYZING_CASE` como processamento.
- Ao atingir `CASE_ANALYZED`, o app deve carregar `CaseSummaryDto`.
- Ao atingir `PETITION_NOT_FOUND`, o app deve exibir CTA para reenviar documento.
- Ao atingir `FAILED`, o app deve exibir CTA de retry contextual para a etapa corrente.
- A partir de `CASE_ANALYZED`, o app deve permitir **Regerar análise do processo** e **Buscar precedentes**.
- Durante `SEARCHING_PRECEDENTS`, `ANALYZING_PRECEDENTS_SIMILARITY`, `ANALYZING_PRECEDENTS_APPLICABILITY` e `GENERATING_SYNTHESIS`, o app deve exibir estado de processamento da lista de precedentes/minuta.
- Ao atingir `PRECEDENTS_SEARCHED`, o app deve exibir a lista de precedentes buscados.
- O app deve permitir **Refazer busca** e **Gerar minuta** quando houver precedentes disponíveis.
- Ao atingir `DONE`, o app deve carregar `SecondInstanceJudgmentDraftDto` e exibir preview da minuta com CTA `Ver completa`.
- O dialog fullscreen da minuta deve exibir as seções completas do DTO estruturado.

## 3.2 Não funcionais

- Polling com intervalo mínimo de **3 segundos**.
- Timeout local de **10 segundos** por tentativa de polling/trigger.
- A View não monta payload nem acessa `RestClient` diretamente.
- O presenter consome `IntakeService`, `StorageService`, `DocumentPickerDriver` e `FileStorageDriver` via providers.
- Widgets internos com responsabilidade própria devem ter pasta dedicada, seguindo as rules da UI.

---

# 4. O que já existe?

## Core

- `AnalysisDto` (`lib/core/intake/dtos/analysis_dto.dart`)
- `AnalysisDocumentDto` (`lib/core/intake/dtos/analysis_document_dto.dart`)
- `CaseSummaryDto` (`lib/core/intake/dtos/case_summary_dto.dart`)
- `AnalysisPrecedentDto` (`lib/core/intake/dtos/analysis_precedent_dto.dart`)
- `AnalysisPrecedentsSearchFiltersDto` (`lib/core/intake/dtos/analysis_precedents_search_filters_dto.dart`)
- `SecondInstanceAnalysisStatusDto` (`lib/core/intake/dtos/second_instance_analysis_status_dto.dart`) com `PRECEDENTS_SEARCHED`, `GENERATING_SYNTHESIS` e `PETITION_NOT_FOUND`
- `AnalysisStatusDto` (`lib/core/intake/dtos/analysis_status_dto.dart`) com mapeamento para `precedentsSearched`, `generatingSynthesis`, `petitionNotFound` e uso unificado de `caseAnalyzed`
- `SecondInstanceJudgmentDraftDto` (`lib/core/intake/dtos/second_instance_judgment_draft_dto.dart`) com:
  - `analysisId`
  - `report`
  - `meritAnalysis`
  - `precedentAdherenceAnalysis`
  - `ruling`
  - `preliminaryIssues`
  - `noApplicablePrecedentNotice`
- `IntakeService` (`lib/core/intake/interfaces/intake_service.dart`) com:
  - `createAnalysisDocument(...)`
  - `getAnalysisDocument(...)`
  - `getAnalysisStatus(...)`
  - `triggerSecondInstanceCaseSummarization(...)`
  - `triggerSecondInstanceJudgmentDraftGeneration(...)`
  - `getSecondInstanceJudgmentDraft(...)`
  - `searchAnalysisPrecedents(...)`
  - `listAnalysisPrecedents(...)`
  - `chooseAnalysisPrecedent(...)`
  - `unchooseAnalysisPrecedent(...)`
- `StorageService` (`lib/core/storage/interfaces/storage_service.dart`) com `generateAnalysisDocumentUploadUrl(...)`

## REST

- `IntakeRestService` (`lib/rest/services/intake_rest_service.dart`) já implementa:
  - `POST /intake/analyses/{analysis_id}/documents`
  - `GET /intake/analyses/{analysis_id}/documents`
  - `GET /intake/analyses/{analysis_id}/case-summaries`
  - `POST /intake/analyses/{analysis_id}/case-summaries`
  - `POST /intake/analyses/{analysis_id}/petition-extraction`
  - `POST /intake/analyses/{analysis_id}/second-instance-judgment-drafts`
  - `GET /intake/analyses/{analysis_id}/second-instance-judgment-drafts`
  - `GET /intake/analyses/{analysis_id}/status`
- `StorageRestService` implementa `generateAnalysisDocumentUploadUrl(...)`
- `SecondInstanceJudgmentDraftMapper` (`lib/rest/mappers/intake/second_instance_judgment_draft_mapper.dart`) já mapeia o DTO estruturado da minuta

## UI

- `SecondInstanceAnalysisScreenView` (`lib/ui/intake/widgets/pages/second_instance_analysis_screen/second_instance_analysis_screen_view.dart`)
- `SecondInstanceFirstInstanceAnalysisScreenPresenter` (`lib/ui/intake/widgets/pages/second_instance_analysis_screen/second_instance_analysis_screen_presenter.dart`)
- `GenerateJudgmentDraftCard` (`lib/ui/intake/widgets/pages/second_instance_analysis_screen/generate_judgment_draft_card/`)
- `JudgmentDraftCard` (`lib/ui/intake/widgets/pages/second_instance_analysis_screen/judgment_draft_card/`)
- `JudgmentDraftDialog` (`lib/ui/intake/widgets/pages/second_instance_analysis_screen/judgment_draft_dialog/`)
- `PreviewSection` (`lib/ui/intake/widgets/pages/second_instance_analysis_screen/judgment_draft_card/preview_section/`)
- `DraftSection` (`lib/ui/intake/widgets/pages/second_instance_analysis_screen/judgment_draft_dialog/draft_section/`)
- `AnalysisPrecedentsBubble` (`lib/ui/intake/widgets/components/analysis_precedents_bubble/`)
- `PrecedentDialog` (`lib/ui/intake/widgets/components/analysis_precedents_bubble/precedent_dialog/precedent_dialog_view.dart`)
- `AiBubble`, `AnalysisHeader`, `AnalysisActionBar`, `DocumentFileBubble`, `CaseSummaryCard` e `MessageBox` já estão globalizados em `lib/ui/intake/widgets/components/`

## Lacunas identificadas

Não aplicável.

---

# 5. O que deve ser criado?

## Camada UI (Presenters)

- **Localização:** `lib/ui/intake/widgets/pages/second_instance_analysis_screen/second_instance_analysis_screen_presenter.dart`
- **Estado (`signals`):**
  - `status`
  - `selectedFile`
  - `analysisDocument`
  - `isUploading`
  - `uploadProgress`
  - `caseSummary`
  - `judgmentDraft`
  - `generalError`
  - `analysisName`
  - `isManagingAnalysis`
  - `precedentsReady`
- **Computeds:**
  - `canPickDocument`
  - `canAnalyzeCase`
  - `canRegenerateSummary`
  - `canSearchPrecedents`
  - `canGenerateJudgmentDraft`
  - `canRegenerateJudgmentDraft`
  - `showCaseProcessingBubble`
  - `showJudgmentDraftProcessingBubble`
  - `showPetitionNotFound`
  - `primaryActionLabel`
- **Provider:** `secondInstanceFirstInstanceAnalysisScreenPresenterProvider`
- **Métodos principais:**
  - `load()`
  - `pickDocument()`
  - `analyzeCase()`
  - `reanalyzeCase()`
  - `requestJudgmentDraft()`
  - `regenerateJudgmentDraft()`
  - `resendDocument()`
  - `renameAnalysis(...)`
  - `archiveAnalysis()`
  - `markPrecedentsReady()`
  - `dispose()`

- **Localização:** `lib/ui/intake/widgets/components/analysis_precedents_bubble/analysis_precedents_bubble_presenter.dart`
- **Estado:** lista de precedentes, status de processamento, loading, erro, filtros, limite e precedente selecionado
- **Provider:** `analysisPrecedentsBubblePresenterProvider`
- **Métodos principais:**
  - `initialize()`
  - `retry()`
  - `refreshProcessingStatus()`
  - `loadPrecedents()`
  - `syncAnalysisStatus(...)`
  - `syncSelectedLimit(...)`
  - `syncSelectedFilters(...)`
  - `choosePrecedent(...)`
  - `confirmPrecedentChoice()`
  - `openPangea(...)`

## Camada UI (Views)

- **Localização:** `lib/ui/intake/widgets/pages/second_instance_analysis_screen/second_instance_analysis_screen_view.dart`
- **Props:** `analysisId`
- **Estados visuais:**
  - Waiting document: `AiBubble` + action bar apenas com CTA de arquivo
  - Document ready: `DocumentFileBubble` + CTA `Analisar`
  - Processing case: `ProcessingBubble`
  - Petition not found: `PetitionNotFoundState`
  - Case analyzed: `CaseSummaryCard` + CTA `Regerar análise do processo`
  - Precedents: `AnalysisPrecedentsBubble`
  - Draft processing: `GenerateJudgmentDraftCard`
  - Done: `JudgmentDraftCard` + `JudgmentDraftDialog`
  - Failed: `MessageBox` + retry contextual

## Camada UI (Widgets Internos)

- `lib/ui/intake/widgets/pages/second_instance_analysis_screen/processing_bubble/`
- `lib/ui/intake/widgets/pages/second_instance_analysis_screen/petition_not_found_state/`
- `lib/ui/intake/widgets/pages/second_instance_analysis_screen/generate_judgment_draft_card/`
- `lib/ui/intake/widgets/pages/second_instance_analysis_screen/judgment_draft_card/`
- `lib/ui/intake/widgets/pages/second_instance_analysis_screen/judgment_draft_card/preview_section/`
- `lib/ui/intake/widgets/pages/second_instance_analysis_screen/judgment_draft_dialog/`
- `lib/ui/intake/widgets/pages/second_instance_analysis_screen/judgment_draft_dialog/draft_section/`

## Estrutura de Pastas

```text
lib/ui/intake/widgets/pages/second_instance_analysis_screen/
  index.dart
  second_instance_analysis_screen_view.dart
  second_instance_analysis_screen_presenter.dart
  processing_bubble/
    index.dart
    processing_bubble_view.dart
  petition_not_found_state/
    index.dart
    petition_not_found_state_view.dart
  generate_judgment_draft_card/
    index.dart
    generate_judgment_draft_card_view.dart
  judgment_draft_card/
    index.dart
    judgment_draft_card_view.dart
    preview_section/
      index.dart
      preview_section_view.dart
  judgment_draft_dialog/
    index.dart
    judgment_draft_dialog_view.dart
    draft_section/
      index.dart
      draft_section_view.dart

lib/ui/intake/widgets/components/
  ai_bubble/
  analysis_action_bar/
  analysis_header/
  analysis_precedents_bubble/
    index.dart
    analysis_precedents_bubble_view.dart
    analysis_precedents_bubble_presenter.dart
    precedent_dialog/
      index.dart
      precedent_dialog_view.dart
  case_summary_card/
  document_file_bubble/
  message_box/
```

---

# 6. O que deve ser modificado?

## Core

- `lib/core/intake/dtos/second_instance_analysis_status_dto.dart`
  - incluir `precedentsSearched`, `generatingSynthesis` e `petitionNotFound`

- `lib/core/intake/dtos/analysis_status_dto.dart`
  - mapear `precedentsSearched`, `generatingSynthesis` e `petitionNotFound`
  - usar `caseAnalyzed` como status unificado para a análise concluída

- `lib/core/intake/dtos/second_instance_judgment_draft_dto.dart`
  - expandir o DTO para o shape estruturado da minuta

- `lib/core/intake/interfaces/intake_service.dart`
  - expor contratos de documento, status, sumarização de 2ª instância e escolha/desescolha de precedente

- `lib/core/storage/interfaces/storage_service.dart`
  - expor `generateAnalysisDocumentUploadUrl(...)`

## REST

- `lib/rest/mappers/intake/analysis_mapper.dart`
  - aceitar os novos status de 2ª instância

- `lib/rest/mappers/intake/second_instance_judgment_draft_mapper.dart`
  - mapear o DTO estruturado da minuta

- `lib/rest/services/intake_rest_service.dart`
  - implementar endpoints de documento, sumarização de 2ª instância, status, precedentes e minuta conforme a implementação atual em `/intake/analyses/...`

- `lib/rest/services/storage_rest_service.dart`
  - implementar geração de upload do documento principal da análise

## UI

- `lib/constants/routes.dart`
  - manter `Routes.secondInstanceAnalysis` e `Routes.getSecondInstanceAnalysis(...)`

- `lib/router.dart`
  - manter `GoRoute` dedicada da 2ª instância com redirect local por `analysisId` vazio

- `lib/ui/intake/widgets/components/analysis_precedents_bubble/`
  - consolidar o componente global de precedentes, incluindo `precedent_dialog/`

- `lib/ui/intake/widgets/pages/first_instance_analysis_screen/precedent_dialog/`
  - manter apenas wrapper compatível apontando para o dialog global de precedentes

- `lib/ui/intake/widgets/pages/second_instance_analysis_screen/`
  - adicionar card de loading da minuta
  - adicionar dialog fullscreen da minuta
  - usar preview da minuta no card principal
  - exibir animação de entrada por card
  - fazer scroll para o fim ao acionar o CTA principal
  - oferecer retry contextual em `FAILED`

---

# 7. O que deve ser removido?

Não aplicável.

---

# 8. Decisões Técnicas e Trade-offs

- Tela dedicada de 2ª instância, sem adaptar a tela da 1ª instância.
- `AnalysisStatusDto` permanece como contrato compartilhado da UI, enriquecido para os estados específicos de 2ª instância.
- Lista de precedentes foi consolidada como componente global de `intake`.
- Documento da análise usa `AnalysisDocumentDto`, não `PetitionDto`.
- Minuta é exibida em preview no card e em leitura completa no dialog fullscreen próprio.
- Retry em `FAILED` é contextual, reaproveitando a etapa mais avançada conhecida pelo estado local da tela.

---

# 9. Diagramas e Referências

- **Fluxo de dados:**

```text
SecondInstanceAnalysisScreenView
  -> SecondInstanceFirstInstanceAnalysisScreenPresenter
      -> secondInstanceFirstInstanceAnalysisScreenPresenterProvider
          -> StorageService.generateAnalysisDocumentUploadUrl(...)
          -> FileStorageDriver.uploadFile(...)
          -> IntakeService.createAnalysisDocument(...)
          -> IntakeService.triggerSecondInstanceCaseSummarization(...)
          -> IntakeService.getAnalysis(...)
          -> IntakeService.getAnalysisDocument(...)
          -> IntakeService.getCaseSummary(...)
          -> IntakeService.triggerSecondInstanceJudgmentDraftGeneration(...)
          -> IntakeService.getSecondInstanceJudgmentDraft(...)

AnalysisPrecedentsBubbleView
  -> AnalysisPrecedentsBubblePresenter
      -> analysisPrecedentsBubblePresenterProvider
          -> IntakeService.searchAnalysisPrecedents(...)
          -> IntakeService.getAnalysis(...)
          -> IntakeService.listAnalysisPrecedents(...)
          -> IntakeService.chooseAnalysisPrecedent(...)
```

- **Hierarquia de widgets:**

```text
SecondInstanceAnalysisScreenView
  Scaffold
    SafeArea
      Stack
        DotGridBackground
        Column
          AnalysisHeader
          SingleChildScrollView
            AiBubble
            DocumentFileBubble
            ProcessingBubble
            PetitionNotFoundState
            MessageBox
            CaseSummaryCard
            AnalysisPrecedentsBubble
            GenerateJudgmentDraftCard
            JudgmentDraftCard (preview)
            JudgmentDraftDialog (fullscreen)
          AnalysisActionBar
```

- **Mapeamento de status para estados visuais:**

```text
WAITING_DOCUMENT_UPLOAD            -> WaitingDocument
DOCUMENT_UPLOADED                  -> DocumentReady
EXTRACTING_PETITION                -> ProcessingCase
ANALYZING_CASE                     -> ProcessingCase
CASE_ANALYZED                      -> CaseSummary
PETITION_NOT_FOUND                 -> PetitionNotFound
SEARCHING_PRECEDENTS               -> PrecedentsProcessing
PRECEDENTS_SEARCHED                -> PrecedentsReady
ANALYZING_PRECEDENTS_SIMILARITY    -> PrecedentsProcessing
ANALYZING_PRECEDENTS_APPLICABILITY -> PrecedentsReady
GENERATING_JUDGMENT_DRAFT          -> JudgmentDraftProcessing
GENERATING_SYNTHESIS               -> JudgmentDraftProcessing
DONE                               -> JudgmentDraftReady
FAILED                             -> Failed (retry contextual)
```

- **Referências:**
  - `documentation/architecture.md`
  - `documentation/rules/ui-layer-rules.md`
  - `documentation/rules/core-layer-rules.md`
  - `documentation/rules/rest-layer-rules.md`
  - `lib/core/intake/interfaces/intake_service.dart`
  - `lib/rest/services/intake_rest_service.dart`
  - `lib/ui/intake/widgets/pages/second_instance_analysis_screen/`
  - `lib/ui/intake/widgets/components/analysis_precedents_bubble/`

---

# 10. Pendências / Dúvidas

Não há pendências funcionais em aberto para esta spec.

- A implementação atual do mobile usa endpoints em `/intake/analyses/...` e `documents`, conforme materializado em `IntakeRestService`.
- Não há dependência de validação visual no Pencil para concluir esta spec.

---

# Restrições

- Não incluir exportação de PDF nesta spec.
- A `View` não deve conter lógica de negócio.
- Presenters não fazem chamadas diretas a `RestClient`.
- Todo widget novo com responsabilidade própria deve ter pasta própria com `index.dart` e `*_view.dart`.
- O `SecondInstanceFirstInstanceAnalysisScreenPresenter` deve permanecer enxuto e orquestrador; precedentes pertencem ao `AnalysisPrecedentsBubblePresenter`.
