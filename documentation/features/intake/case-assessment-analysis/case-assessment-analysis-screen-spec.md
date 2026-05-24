---
title: Tela de avaliação de caso para advogado
prd: https://joaogoliveiragarcia.atlassian.net/wiki/x/AYDsAg
ticket: https://joaogoliveiragarcia.atlassian.net/browse/ANI-103
last_updated_at: 2026-05-24
---

# 1. Objetivo

Implementar a tela mobile dedicada ao fluxo de **Avaliação de Caso** do perfil Advogado, permitindo upload de petição em PDF ou DOCX, sumarização do caso, busca ranqueada de precedentes com justificativa de aderência, geração/regeneração de minuta de petição inicial e visualização completa da minuta, respeitando o padrão MVP, `Riverpod`, `Signals` e os contratos tipados do módulo `intake`.

---

# 2. Escopo

## 2.1 In-scope

- Tela dedicada em `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/` (**novo arquivo**) com padrão `View + Presenter`.
- Upload de um único documento `pdf` ou `docx`, com limite local de **20MB** antes do envio.
- Criação e leitura de `AnalysisDocumentDto` para reentrada na tela.
- Sumarização do caso via `IntakeService`, com polling de `AnalysisDto` até `CASE_ANALYZED` ou `FAILED`.
- Exibição de `CaseSummaryCard` com ação de **Regerar resumo**.
- Busca e nova busca de precedentes via `AnalysisPrecedentsBubble`, preservando filtros, limite e estados internos do componente global.
- Exibição de precedentes ranqueados por `finalRank`, percentual `similarityScore`, `applicabilityLevel`, status do precedente e justificativa explicativa no detalhe.
- Geração e regeneração de `PetitionDraftDto` com base nos precedentes confirmados.
- Exibição de preview truncado da minuta em `PetitionDraftCard` e leitura completa em `PetitionDraftDialog` fullscreen.
- Retry contextual por etapa: sumarização, busca de precedentes e geração de minuta.
- Reuso do `AnalysisHeader` com as mesmas ações das demais telas de análise: voltar, configurar quantidade de precedentes, abrir filtros, renomear análise e arquivar análise.
- Rota dedicada para `AnalysisTypeDto.caseAssessment`, corrigindo o fallback atual que envia esse tipo para a tela de segunda instância.

## 2.2 Out-of-scope

- Edição direta do conteúdo da minuta dentro do app.
- Geração de minuta sem documento enviado.
- Geração automática de minuta antes da confirmação de precedentes.
- Suporte a múltiplas versões simultâneas de minuta.
- Envio automático por e-mail.
- Exportação ou geração de PDF da minuta/relatório.
- Ação de exportação no `AnalysisHeader`.
- Alterações no `design/animus.pen`.
- Mudanças no fluxo de `FirstInstanceAnalysis` ou `SecondInstanceAnalysis` fora do roteamento por tipo.

---

# 3. Requisitos

## 3.1 Funcionais

- O app deve abrir `CaseAssessmentAnalysisScreen` para análises com `AnalysisTypeDto.caseAssessment`.
- O `AnalysisHeader` deve preservar as ações disponíveis nas outras análises: voltar, quantidade de precedentes, filtros, renomear e arquivar; a ação de exportação deve permanecer oculta.
- O advogado deve poder selecionar apenas `pdf` ou `docx` com tamanho máximo de **20MB**.
- Após upload válido, o app deve criar `AnalysisDocumentDto` e refletir `DOCUMENT_UPLOADED`.
- Ao acionar **Analisar**, o app deve disparar a sumarização do caso e exibir loading até `CASE_ANALYZED` ou `FAILED`.
- Ao atingir `CASE_ANALYZED`, o app deve carregar e exibir `CaseSummaryDto`.
- Ao acionar **Regerar resumo**, o app deve limpar o resumo atual, reacionar a sumarização e preservar o documento.
- Ao acionar **Buscar precedentes**, o app deve iniciar `AnalysisPrecedentsBubble` e exibir loading, erro, vazio ou conteúdo conforme o presenter do componente.
- Cada precedente deve exibir percentual de aplicabilidade, classificação e status visual quando houver risco jurídico no status remoto.
- O detalhe do precedente deve exibir a justificativa de aderência gerada pela IA; para baixa aplicabilidade, a justificativa deve indicar o ponto de distinção quando esse conteúdo vier no payload.
- A opção **Gerar minuta** deve aparecer apenas após haver pelo menos um precedente confirmado.
- Ao gerar minuta, o app deve exibir loading, carregar `PetitionDraftDto` ao atingir `DONE` e mostrar preview com ação **Ver minuta**.
- Ao acionar **Regerar minuta**, o app deve limpar a minuta atual, reacionar a geração e substituir a versão anterior.
- Em `FAILED`, a tela deve exibir `MessageBox` e ação primária contextual de retry para a etapa mais avançada conhecida.

## 3.2 Não funcionais

- **Performance:** polling com intervalo mínimo de **3 segundos** para leitura de status.
- **Performance:** timeout local de **10 segundos** para chamadas HTTP comuns e **60 segundos** para a tentativa de geração da minuta, conforme PRD.
- **Acessibilidade:** CTAs principais devem manter área mínima de toque Material e texto explícito.
- **Offline/Conectividade:** falhas de rede devem aparecer como erro inline em `MessageBox` ou estado de erro do componente, sem travar a tela.
- **Arquitetura:** `View` não acessa `RestClient`, não monta payload REST e não faz parse de JSON.
- **Arquitetura:** `Presenter` consome `IntakeService`, `StorageService`, `FileStorageDriver` e `DocumentPickerDriver` via providers.
- **Segurança:** o app não deve persistir conteúdo da minuta fora dos DTOs em memória durante a tela.

---

# 4. O que já existe?

## Core

- **`AnalysisDto`** (`lib/core/intake/dtos/analysis_dto.dart`) — DTO principal da análise com `type`, `status`, `name`, `summary`, `folderId`, `isArchived` e `id`.
- **`AnalysisTypeDto`** (`lib/core/intake/dtos/analysis_type_dto.dart`) — enum já possui `caseAssessment`, `firstInstance` e `secondInstance`.
- **`AnalysisStatusDto`** (`lib/core/intake/dtos/analysis_status_dto.dart`) — contrato legado compartilhado pela UI, já mapeia `CaseAssessmentAnalysisStatusDto` para `waitingDocumentUpload`, `documentUploaded`, `analyzingCase`, `caseAnalyzed`, `searchingPrecedents`, `analyzingPrecedentsSimilarity`, `analyzingPrecedentsApplicability`, `generatingPetitionDraft`, `done` e `failed`.
- **`CaseAssessmentAnalysisStatusDto`** (`lib/core/intake/dtos/case_assessment_analysis_status_dto.dart`) — enum específico do fluxo de Avaliação de Caso.
- **`AnalysisDocumentDto`** (`lib/core/intake/dtos/analysis_document_dto.dart`) — DTO do documento enviado.
- **`CaseSummaryDto`** (`lib/core/intake/dtos/case_summary_dto.dart`) — DTO do resumo estruturado do caso.
- **`AnalysisPrecedentDto`** (`lib/core/intake/dtos/analysis_precedent_dto.dart`) — DTO de precedente da análise, com `synthesis`, `similarityScore`, `finalRank`, `applicabilityLevel` e `isChosen`.
- **`PetitionDraftDto`** (`lib/core/intake/dtos/petition_draft_dto.dart`) — DTO da minuta de petição inicial, com `analysisId` e `content`.
- **`IntakeService`** (`lib/core/intake/interfaces/intake_service.dart`) — contrato central do `intake`, já expõe `getAnalysis`, `getAnalysisStatus`, `createAnalysisDocument`, `getAnalysisDocument`, `getCaseSummary`, `getPetitionDraft`, `searchAnalysisPrecedents`, `listAnalysisPrecedents`, `chooseAnalysisPrecedent`, `unchooseAnalysisPrecedent`, `renameAnalysis` e `archiveAnalysis`.
- **`StorageService`** (`lib/core/storage/interfaces/storage_service.dart`) — gera URL de upload para documento da análise.

## REST

- **`IntakeRestService`** (`lib/rest/services/intake_rest_service.dart`) — implementa endpoints de análise, documento, resumo, precedentes e minuta por `GET /intake/analyses/{analysisId}/petition-drafts`.
- **`AnalysisMapper`** (`lib/rest/mappers/intake/analysis_mapper.dart`) — mapeia `type` remoto para `AnalysisTypeDto` e status conforme o tipo de análise.
- **`AnalysisPrecedentMapper`** (`lib/rest/mappers/intake/analysis_precedent_mapper.dart`) — mapeia `synthesis`, `similarity_score`, `final_rank`, `applicability_level`, `classification_level` e `is_chosen` para `AnalysisPrecedentDto`.
- **`PetitionDraftMapper`** (`lib/rest/mappers/intake/petition_draft_mapper.dart`) — mapeia `analysis_id` e `content` para `PetitionDraftDto`.
- **`intakeServiceProvider`** (`lib/rest/services/index.dart`) — compõe `IntakeRestService` para consumo via `Riverpod`.

## Drivers

- **`DocumentPickerDriver`** (`lib/core/storage/interfaces/drivers/document_picker_driver.dart`) — contrato para seleção local de documentos por extensão.
- **`FileStorageDriver`** (`lib/core/storage/interfaces/drivers/file_storage_driver.dart`) — contrato usado pelos fluxos existentes para upload de arquivo.

## UI

- **`SecondInstanceAnalysisScreenView`** (`lib/ui/intake/widgets/pages/second_instance_analysis_screen/second_instance_analysis_screen_view.dart`) — referência principal de estrutura da tela: `ScrollController`, `Watch`, `AnalysisHeader`, `SingleChildScrollView`, `AnalysisActionBar`, scroll to bottom e dialogs fullscreen.
- **`SecondInstanceAnalysisScreenPresenter`** (`lib/ui/intake/widgets/pages/second_instance_analysis_screen/second_instance_analysis_screen_presenter.dart`) — referência de `signals`, `computed`, upload de documento, polling, retry contextual e rename/archive.
- **`FirstInstanceAnalysisScreenPresenter`** (`lib/ui/intake/widgets/pages/first_instance_analysis_screen/first_instance_analysis_screen_presenter.dart`) — referência do upload `pdf/docx`, limite e fluxo de sumarização de primeira instância.
- **`AnalysisPrecedentsBubble`** (`lib/ui/intake/widgets/components/analysis_precedents_bubble/`) — componente global de precedentes com presenter próprio, busca, retry, filtros, limite, escolha/desescolha, abertura de Pangea e estados loading/error/empty/content.
- **`AnalysisPrecedentDialogView`** (`lib/ui/intake/widgets/components/analysis_precedents_bubble/precedent_dialog/precedent_dialog_view.dart`) — detalhe fullscreen do precedente, já exibe status, aplicabilidade e síntese.
- **`AnalysisHeader`** (`lib/ui/intake/widgets/components/analysis_header/analysis_header_view.dart`) — header reutilizável com back, filtros, menu, rename e archive.
- **`AnalysisActionBar`** (`lib/ui/intake/widgets/components/analysis_action_bar/analysis_action_bar_view.dart`) — barra inferior reutilizável com ação de arquivo, ação primária, loading e helper.
- **`AiBubble`** (`lib/ui/intake/widgets/components/ai_bubble/ai_bubble_view.dart`) — bubble de IA reutilizável para mensagens/loading.
- **`CaseSummaryCard`** (`lib/ui/intake/widgets/components/case_summary_card/`) — card global de resumo com presenter e seções internas.
- **`DocumentFileBubble`** (`lib/ui/intake/widgets/components/document_file_bubble/document_file_bubble_view.dart`) — bubble de documento selecionado/enviado.
- **`MessageBox`** (`lib/ui/intake/widgets/components/message_box/message_box_view.dart`) — feedback inline de erro.
- **`HomeScreenPresenter`** (`lib/ui/intake/widgets/pages/home_screen/home_screen_presenter.dart`) — cria análises tipadas e abre a rota conforme `analysis.type`; hoje envia `caseAssessment` para a rota de segunda instância.
- **`Routes`** (`lib/constants/routes.dart`) — possui `analysis` e `secondInstanceAnalysis`; hoje `getAnalysis(...caseAssessment)` também aponta para `getSecondInstanceAnalysis(...)`.
- **`appRouter`** (`lib/router.dart`) — registra primeira e segunda instância; ainda não registra rota de Avaliação de Caso.

## Lacunas identificadas

- Não há `CaseAssessmentAnalysisScreen` implementada em `lib/ui/intake/widgets/pages/`.
- Não há contrato `IntakeService.triggerCaseAssessmentCaseSummarization(...)` com nome semântico para este fluxo.
- Não há contrato `IntakeService.triggerPetitionDraftGeneration(...)` para disparar a geração da minuta.
- `AnalysisPrecedentDto` ainda não possui campo explícito para trecho destacado; a implementação atual usa `synthesis` como justificativa e `PrecedentDto.enunciation` como texto-base do precedente.

---

# 5. O que deve ser criado?

## Camada UI (Presenters)

- **Localização:** `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/case_assessment_analysis_screen_presenter.dart` (**novo arquivo**)
- **Dependências injetadas:** `IntakeService`, `StorageService`, `FileStorageDriver`, `DocumentPickerDriver` via `Riverpod`.
- **Estado (`signals`):**
  - `Signal<AnalysisStatusDto> status` — status atual da análise.
  - `Signal<File?> selectedFile` — documento selecionado localmente.
  - `Signal<AnalysisDocumentDto?> analysisDocument` — documento persistido da análise.
  - `Signal<bool> isUploading` — loading do upload.
  - `Signal<double?> uploadProgress` — progresso do upload.
  - `Signal<CaseSummaryDto?> caseSummary` — resumo carregado.
  - `Signal<PetitionDraftDto?> petitionDraft` — minuta carregada.
  - `Signal<String?> generalError` — erro inline da tela.
  - `Signal<String> analysisName` — título exibido no header.
  - `Signal<bool> isArchived` — flag visual de análise arquivada.
  - `Signal<bool> isManagingAnalysis` — bloqueio de ações concorrentes.
  - `Signal<bool> precedentsReady` — indica lista de precedentes disponível.
  - `Signal<bool> hasChosenPrecedents` — indica se há precedentes confirmados.
- **Computeds:**
  - `ReadonlySignal<bool> canPickDocument` — verdadeiro quando não há upload ou ação em andamento.
  - `ReadonlySignal<bool> canAnalyzeCase` — verdadeiro em `DOCUMENT_UPLOADED` ou `FAILED` com documento disponível.
  - `ReadonlySignal<bool> canRegenerateSummary` — verdadeiro em `CASE_ANALYZED` ou estados posteriores com resumo carregado.
  - `ReadonlySignal<bool> canSearchPrecedents` — verdadeiro em `CASE_ANALYZED` com `caseSummary != null`.
  - `ReadonlySignal<bool> canGenerateDraft` — verdadeiro quando `precedentsReady` e `hasChosenPrecedents` são verdadeiros.
  - `ReadonlySignal<bool> canRegenerateDraft` — verdadeiro em `DONE` com `petitionDraft != null`.
  - `ReadonlySignal<bool> showCaseProcessingBubble` — verdadeiro em `ANALYZING_CASE`.
  - `ReadonlySignal<bool> showDraftProcessingBubble` — verdadeiro em `GENERATING_PETITION_DRAFT`.
  - `ReadonlySignal<String> primaryActionLabel` — resolve `Analisar`, `Buscar precedentes`, `Gerar minuta`, `Regerar minuta` ou `Tentar novamente` conforme estado.
- **Provider Riverpod:** `caseAssessmentAnalysisScreenPresenterProvider` como `Provider.autoDispose.family<CaseAssessmentAnalysisScreenPresenter, String>`.
- **Métodos:**
  - `Future<void> load()` — carrega `AnalysisDto`, documento, resumo, precedentes/minuta quando aplicável e restaura estado visual conforme status atual.
  - `Future<void> pickDocument()` — seleciona `pdf/docx`, valida extensão e limite de 20MB, faz upload e cria `AnalysisDocumentDto`.
  - `Future<void> analyze()` — dispara `IntakeService.triggerCaseAssessmentCaseSummarization(...)`, atualiza status para processamento e inicia polling até `CASE_ANALYZED`.
  - `Future<void> retrySummarize()` — limpa `caseSummary`, `petitionDraft`, `precedentsReady` e reaciona `analyze()` sem reenviar documento.
  - `Future<void> searchPrecedents()` — marca estado de precedentes como pronto para o `AnalysisPrecedentsBubble` iniciar busca via seu próprio presenter.
  - `Future<void> retrySearchPrecedents()` — limpa `petitionDraft`, `hasChosenPrecedents` e força nova busca no componente de precedentes por callback da View.
  - `Future<void> generateDraft()` — dispara `IntakeService.triggerPetitionDraftGeneration(...)`, aplica timeout de 60s e faz polling até `DONE` para carregar `PetitionDraftDto`.
  - `Future<void> retryGenerateDraft()` — limpa `petitionDraft` e reaciona `generateDraft()` preservando documento, resumo e precedentes.
  - `Future<bool> renameAnalysis(String name)` — delega renomeação para `IntakeService.renameAnalysis(...)` e atualiza `analysisName`.
  - `Future<bool> archiveAnalysis()` — delega arquivamento para `IntakeService.archiveAnalysis(...)`.
  - `void markPrecedentsReady()` — sinaliza que o componente de precedentes carregou conteúdo.
  - `void syncChosenPrecedents(List<AnalysisPrecedentDto> precedents)` — atualiza `hasChosenPrecedents` a partir dos precedentes escolhidos.
  - `String fileName(File file)` — resolve nome exibido no `DocumentFileBubble`.
  - `String formatFileSize(int sizeInBytes)` — formata tamanho do arquivo para UI.
  - `void dispose()` — descarta todos os `signals` e `computed`.

- **Localização:** `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/petition_draft_card/petition_draft_card_presenter.dart` (**novo arquivo**)
- **Dependências injetadas:** nenhuma dependência externa.
- **Estado (`signals`):** não aplicável.
- **Provider Riverpod:** `petitionDraftCardPresenterProvider` como `Provider.autoDispose<PetitionDraftCardPresenter>`.
- **Métodos:**
  - `String buildPreview(PetitionDraftDto draft, {int maxLength = 420})` — retorna preview truncado da minuta para o card.
  - `Future<void> openDraftDialog(BuildContext context, PetitionDraftDto draft)` — abre `PetitionDraftDialog` em fullscreen.

## Camada UI (Views)

- **Localização:** `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/case_assessment_analysis_screen_view.dart` (**novo arquivo**)
- **Base class:** `ConsumerStatefulWidget`.
- **Props:** `final String analysisId`.
- **Bibliotecas de UI:** `flutter/material.dart`, `flutter_animate`, `flutter_riverpod`, `signals_flutter`, `go_router`.
- **Header:** reutilizar `AnalysisHeader` com `onBack`, `onPrecedentsCount`, `onFilters`, `onRename` e `onArchive`; manter `showExportReport: false` e `onExportReport: null`.
- **Estados visuais:**
  - Loading inicial: header + `AiBubble` orientando envio do documento.
  - Document ready: `DocumentFileBubble` + CTA `Analisar`.
  - Case processing: `AiBubble` com texto `Analisando o caso...`.
  - Case analyzed: `CaseSummaryCard` + CTA local `Regerar resumo`.
  - Precedents loading/error/empty/content: `AnalysisPrecedentsBubble`.
  - Draft processing: `GeneratePetitionDraftCard`.
  - Done: `PetitionDraftCard` com preview, ação **Ver minuta** e ação **Regerar minuta**.
  - Failed: `MessageBox` + retry contextual no `AnalysisActionBar`.

## Camada UI (Widgets Internos)

- **Localização:** `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/generate_petition_draft_card/` (**novo arquivo**)
- **Tipo:** `View only`.
- **Props:** nenhuma.
- **Responsabilidade:** renderizar card de loading enquanto a minuta de petição é gerada.

- **Localização:** `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/petition_draft_card/` (**novo arquivo**)
- **Tipo:** `View + Presenter`.
- **Props:** `PetitionDraftDto draft`, `VoidCallback? onRegenerate`.
- **Responsabilidade:** renderizar preview truncado da minuta, CTA `Ver minuta` e CTA `Regerar minuta`.

- **Localização:** `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/petition_draft_dialog/` (**novo arquivo**)
- **Tipo:** `View only`.
- **Props:** `PetitionDraftDto draft`.
- **Responsabilidade:** exibir a minuta completa em fullscreen dialog, sem edição.

- **Localização:** `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/petition_draft_dialog/draft_content_section/` (**novo arquivo**)
- **Tipo:** `View only`.
- **Props:** `String title`, `String content`, `IconData icon`, `bool emphasize`.
- **Responsabilidade:** renderizar blocos de texto da minuta no dialog, permitindo futura separação visual de seções se o backend devolver conteúdo estruturado.

## Camada UI (Barrel Files / `index.dart`)

- **Localização:** `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/index.dart` (**novo arquivo**)
- **`typedef` exportado:** `typedef CaseAssessmentAnalysisScreen = CaseAssessmentAnalysisScreenView`.
- **Widgets internos exportados:** não exportar subwidgets internos no barrel da tela; cada pasta interna expõe seu próprio `index.dart`.

- **Localização:** `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/generate_petition_draft_card/index.dart` (**novo arquivo**)
- **`typedef` exportado:** `typedef GeneratePetitionDraftCard = GeneratePetitionDraftCardView`.

- **Localização:** `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/petition_draft_card/index.dart` (**novo arquivo**)
- **`typedef` exportado:** `typedef PetitionDraftCard = PetitionDraftCardView`.

- **Localização:** `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/petition_draft_dialog/index.dart` (**novo arquivo**)
- **`typedef` exportado:** `typedef PetitionDraftDialog = PetitionDraftDialogView`.

- **Localização:** `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/petition_draft_dialog/draft_content_section/index.dart` (**novo arquivo**)
- **`typedef` exportado:** `typedef DraftContentSection = DraftContentSectionView`.

## Camada UI (Providers Riverpod — se isolados)

- **Localização:** `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/case_assessment_analysis_screen_presenter.dart` (**novo arquivo**)
- **Nome do provider:** `caseAssessmentAnalysisScreenPresenterProvider`.
- **Tipo:** `Provider.autoDispose.family<CaseAssessmentAnalysisScreenPresenter, String>`.
- **Dependências:** `intakeServiceProvider`, `storageServiceProvider`, `fileStorageDriverProvider`, `documentPickerDriverProvider`.

- **Localização:** `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/petition_draft_card/petition_draft_card_presenter.dart` (**novo arquivo**)
- **Nome do provider:** `petitionDraftCardPresenterProvider`.
- **Tipo:** `Provider.autoDispose<PetitionDraftCardPresenter>`.
- **Dependências:** nenhuma.

## Rotas (`go_router`)

- **Localização:** `lib/constants/routes.dart`.
- **Caminho da rota:** `/analyses/:analysisId/case-assessment`.
- **Widget principal:** `CaseAssessmentAnalysisScreen`.
- **Guards / redirecionamentos:** mesmo guard local das rotas existentes; se `analysisId` estiver vazio, redirecionar para `Routes.home`.

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
    petition_draft_card_presenter.dart
  petition_draft_dialog/
    index.dart
    petition_draft_dialog_view.dart
    draft_content_section/
      index.dart
      draft_content_section_view.dart
```

---

# 6. O que deve ser modificado?

## Core

- **Arquivo:** `lib/core/intake/interfaces/intake_service.dart`
- **Mudança:** adicionar `Future<RestResponse<void>> triggerCaseAssessmentCaseSummarization({required String analysisId});`.
- **Justificativa:** evitar que o fluxo de Avaliação de Caso use um método nomeado para `FirstInstanceAnalysis`, mantendo o contrato do `core` alinhado ao domínio.

- **Arquivo:** `lib/core/intake/interfaces/intake_service.dart`
- **Mudança:** adicionar `Future<RestResponse<void>> triggerPetitionDraftGeneration({required String analysisId});`.
- **Justificativa:** a UI precisa disparar explicitamente a geração da minuta antes de consumir `getPetitionDraft(...)`.

- **Arquivo:** `lib/core/intake/dtos/analysis_precedent_dto.dart`
- **Mudança:** adicionar `final String highlightedExcerpt` ao DTO, com valor vazio como fallback no mapper.
- **Justificativa:** o PRD exige trecho destacado no detalhe do precedente, separado da justificativa (`synthesis`) e do texto geral do precedente (`PrecedentDto.enunciation`).

## REST

- **Arquivo:** `lib/rest/services/intake_rest_service.dart`
- **Mudança:** implementar `triggerCaseAssessmentCaseSummarization(...)` usando `POST /intake/analyses/{analysisId}/case-summaries` e `toVoidResponse(...)`.
- **Justificativa:** o endpoint de sumarização já segue esse padrão no fluxo existente; o método novo dá semântica correta ao fluxo de Avaliação de Caso.

- **Arquivo:** `lib/rest/services/intake_rest_service.dart`
- **Mudança:** implementar `triggerPetitionDraftGeneration(...)` usando `POST /intake/analyses/{analysisId}/petition-drafts` e `toVoidResponse(...)`.
- **Justificativa:** decisão confirmada para assumir o padrão REST análogo ao `GET /intake/analyses/{analysisId}/petition-drafts` já existente.

- **Arquivo:** `lib/rest/mappers/intake/analysis_precedent_mapper.dart`
- **Mudança:** mapear `highlighted_excerpt` ou `highlightedExcerpt` para `AnalysisPrecedentDto.highlightedExcerpt`, com fallback para string vazia.
- **Justificativa:** suportar o trecho destacado exigido pelo PRD sem colocar parsing na UI.

- **Arquivo:** `lib/rest/services/index.dart`
- **Mudança:** não alterar provider; `intakeServiceProvider` continua retornando `IntakeRestService`, agora com os métodos novos.
- **Justificativa:** preservar composição atual de dependências.

## UI

- **Arquivo:** `lib/constants/routes.dart`
- **Mudança:** adicionar `static const String caseAssessmentAnalysis = '/analyses/:analysisId/case-assessment';`, `getCaseAssessmentAnalysis({required String analysisId})` e atualizar `getAnalysis(...caseAssessment)` para essa rota.
- **Justificativa:** o tipo `caseAssessment` não deve abrir a tela de segunda instância.

- **Arquivo:** `lib/router.dart`
- **Mudança:** importar `case_assessment_analysis_screen/index.dart` e registrar `GoRoute` para `Routes.caseAssessmentAnalysis` com redirect por `analysisId` vazio.
- **Justificativa:** tornar a tela acessível por rota tipada.

- **Arquivo:** `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/case_assessment_analysis_screen_view.dart` (**novo arquivo**)
- **Mudança:** configurar `AnalysisHeader` com as ações `onBack`, `onPrecedentsCount`, `onFilters`, `onRename` e `onArchive`, deixando `showExportReport: false`.
- **Justificativa:** manter paridade operacional com as outras telas de análise sem incluir exportação de PDF no escopo.

- **Arquivo:** `lib/ui/intake/widgets/pages/home_screen/home_screen_presenter.dart`
- **Mudança:** atualizar o branch `AnalysisTypeDto.caseAssessment` em `openAnalysis(...)` para `Routes.getCaseAssessmentAnalysis(...)`.
- **Justificativa:** abrir análises existentes do tipo correto na tela correta.

- **Arquivo:** `lib/ui/intake/widgets/components/analysis_precedents_bubble/precedent_dialog/precedent_dialog_view.dart`
- **Mudança:** exibir `highlightedExcerpt` em seção própria quando não estiver vazio, mantendo `synthesis` como justificativa explicativa.
- **Justificativa:** cumprir regra do PRD de mostrar trecho destacado no detalhe, não na listagem.

- **Arquivo:** `lib/ui/intake/widgets/components/analysis_precedents_bubble/analysis_precedents_bubble_presenter.dart`
- **Mudança:** preservar `highlightedExcerpt` em todas as reconstruções manuais de `AnalysisPrecedentDto` feitas durante escolha e desescolha de precedentes.
- **Justificativa:** o novo campo obrigatório do DTO não pode ser perdido quando o presenter atualiza `isChosen` localmente.

---

# 7. O que deve ser removido?

Não aplicável.

---

# 8. Decisões Técnicas e Trade-offs

- **Decisão:** usar `CaseAssessmentAnalysisScreen` em vez de `LawyerAnalysisScreen`.
- **Alternativas consideradas:** manter a nomenclatura do Jira (`LawyerAnalysisScreen`) ou criar uma tela genérica de advogado.
- **Motivo da escolha:** a codebase já usa `AnalysisTypeDto.caseAssessment` e `CaseAssessmentAnalysisStatusDto`; manter o nome de domínio evita duplicidade semântica.
- **Impactos / trade-offs:** o nome diverge do rascunho do Jira, mas fica consistente com contratos existentes e com os tipos do backend.

- **Decisão:** criar métodos dedicados `triggerCaseAssessmentCaseSummarization(...)` e `triggerPetitionDraftGeneration(...)` no `IntakeService`.
- **Alternativas consideradas:** reutilizar `triggerFirstInstanceCaseSummarization(...)` ou chamar `RestClient` diretamente no presenter.
- **Motivo da escolha:** presenters não podem conhecer HTTP e o método de primeira instância não comunica o domínio correto.
- **Impactos / trade-offs:** adiciona duas assinaturas ao contrato, mas reduz acoplamento e ambiguidade.

- **Decisão:** assumir `POST /intake/analyses/{analysisId}/petition-drafts` para disparar a geração da minuta.
- **Alternativas consideradas:** bloquear a spec até confirmação do backend ou usar endpoint com plural.
- **Motivo da escolha:** usuário confirmou a opção de assumir o padrão REST; já existe `GET /intake/analyses/{analysisId}/petition-drafts`.
- **Impactos / trade-offs:** se o backend usar outro path, a implementação deverá ajustar apenas `IntakeRestService`.

- **Decisão:** adicionar `highlightedExcerpt` em `AnalysisPrecedentDto`.
- **Alternativas consideradas:** reutilizar `synthesis` como justificativa e `PrecedentDto.enunciation` como trecho destacado.
- **Motivo da escolha:** o PRD diferencia trecho destacado de justificativa de aderência; misturar os campos geraria UI ambígua.
- **Impactos / trade-offs:** exige ajuste no mapper e em construções manuais de `AnalysisPrecedentDto`.

- **Decisão:** manter `AnalysisPrecedentsBubble` como componente global e não criar lista de precedentes específica da tela.
- **Alternativas consideradas:** duplicar o componente para Avaliação de Caso.
- **Motivo da escolha:** o componente já encapsula busca, polling, filtros, limite, estados visuais e escolha de precedentes.
- **Impactos / trade-offs:** a tela precisa sincronizar `hasChosenPrecedents` via callback, mas evita duplicação de presenter e UI.

---

# 9. Diagramas e Referências

- **Fluxo de dados:**

```text
CaseAssessmentAnalysisScreenView
  -> CaseAssessmentAnalysisScreenPresenter
      -> caseAssessmentAnalysisScreenPresenterProvider
          -> StorageService.generateAnalysisDocumentUploadUrl(...)
          -> FileStorageDriver.uploadFile(...)
          -> IntakeService.createAnalysisDocument(...)
          -> IntakeService.triggerCaseAssessmentCaseSummarization(...)
          -> IntakeService.getAnalysis(...)
          -> IntakeService.getCaseSummary(...)
          -> IntakeService.triggerPetitionDraftGeneration(...)
          -> IntakeService.getPetitionDraft(...)

AnalysisPrecedentsBubbleView
  -> AnalysisPrecedentsBubblePresenter
      -> analysisPrecedentsBubblePresenterProvider
          -> IntakeService.searchAnalysisPrecedents(...)
          -> IntakeService.getAnalysis(...)
          -> IntakeService.listAnalysisPrecedents(...)
          -> IntakeService.chooseAnalysisPrecedent(...)
          -> IntakeService.unchooseAnalysisPrecedent(...)
```

- **Hierarquia de widgets:**

```text
CaseAssessmentAnalysisScreenView
  Scaffold
    SafeArea
      Stack
        DotGridBackground
        Column
          AnalysisHeader
          SingleChildScrollView
            AiBubble (orientação inicial)
            DocumentFileBubble
            AiBubble (loading de análise)
            MessageBox
            CaseSummaryCard
            AnalysisPrecedentsBubble
              AnalysisPrecedentDialog (fullscreen)
            GeneratePetitionDraftCard
            PetitionDraftCard
              PetitionDraftDialog (fullscreen)
                DraftContentSection
          AnalysisActionBar
```

- **Mapeamento de status para estados visuais:**

```text
WAITING_DOCUMENT_UPLOAD              -> WaitingDocument
DOCUMENT_UPLOADED                    -> DocumentReady
ANALYZING_CASE                       -> CaseProcessing
CASE_ANALYZED                        -> CaseSummary / PrecedentsReady quando lista carregada
SEARCHING_PRECEDENTS                 -> PrecedentsProcessing
ANALYZING_PRECEDENTS_SIMILARITY      -> PrecedentsProcessing
ANALYZING_PRECEDENTS_APPLICABILITY   -> PrecedentsProcessing ou PrecedentsReady conforme bubble
GENERATING_PETITION_DRAFT            -> PetitionDraftProcessing
DONE                                 -> PetitionDraftReady
FAILED                               -> Failed / RetryContextual
```

- **Referências:**
  - `documentation/architecture.md`
  - `documentation/rules/ui-layer-rules.md`
  - `documentation/rules/core-layer-rules.md`
  - `documentation/rules/rest-layer-rules.md`
  - `documentation/rules/code-conventions-rules.md`
  - `documentation/features/intake/second-instance-analysis/second-instance-analysis-screen-spec.md`
  - `documentation/features/intake/second-instance-analysis/case-summary-and-statuses-for-lawyer-and-judge-analyses-spec.md`
  - `lib/core/intake/interfaces/intake_service.dart`
  - `lib/rest/services/intake_rest_service.dart`
  - `lib/ui/intake/widgets/pages/second_instance_analysis_screen/`
  - `lib/ui/intake/widgets/components/analysis_precedents_bubble/`

---

# 10. Pendências / Dúvidas

Sem pendências.

- Nenhum `screen_id` foi informado; a hierarquia visual foi definida a partir dos componentes existentes e da tela de segunda instância como referência.

---

# Restrições

- Não incluir testes automatizados nesta spec.
- A `View` não deve conter lógica de negócio.
- Presenters não fazem chamadas diretas a `RestClient`.
- O `CaseAssessmentAnalysisScreenPresenter` deve permanecer enxuto e orquestrador; a lógica de precedentes permanece em `AnalysisPrecedentsBubblePresenter`.
- Todo widget novo deve seguir o padrão `View + Presenter`; `Presenter` é opcional apenas em widgets puramente visuais sem estado, handlers ou lógica.
- Widgets internos com responsabilidade própria devem ter pasta própria com `index.dart`, `*_view.dart` e `*_presenter.dart` quando houver estado, handlers ou lógica.
- Todos os DTOs consumidos pela UI devem vir tipados do `core`; nenhum `Map<String, dynamic>` deve chegar à renderização.
- Use componentes Flutter Material alinhados ao tema atual do projeto.
