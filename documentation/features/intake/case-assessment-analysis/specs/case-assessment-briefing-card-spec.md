---
title: Formulário de briefing do caso na tela de Case Assessment
prd: https://joaogoliveiragarcia.atlassian.net/wiki/x/AYDsAg
ticket: N/A
last_updated_at: 2026-06-06
status: closed
---

# 1. Objetivo

Implementar no mobile o novo ponto de entrada da `CaseAssessmentAnalysisScreen`: um **formulário estruturado de briefing do caso** que substitui o upload de documento único como pré-condição da análise do advogado. A entrega cria contratos tipados no `core`, implementação REST para envio/leitura do briefing, mapeamento `snake_case`/`camelCase`, atualização dos status de Case Assessment e novos widgets MVP para formulário e documentos de apoio opcionais, mantendo o restante do pipeline atual de resumo, precedentes, minuta e exportação PDF.

---

# 2. Escopo

## 2.1 In-scope

- Criar `LegalAreaDto` com as 12 áreas jurídicas definidas no PRD.
- Criar `CaseAssessmentBriefingDto` com os dados estruturados do briefing.
- Atualizar `CaseAssessmentAnalysisStatusDto` e `AnalysisStatusDto` para suportar `WAITING_BRIEFING` e `BRIEFING_SUBMITTED`.
- Adicionar contratos em `IntakeService` para enviar e consultar o briefing.
- Implementar `IntakeRestService` para `POST` e `GET` do briefing, usando os endpoints assumidos no rascunho atual.
- Criar `CaseAssessmentBriefingMapper` para converter payload remoto em DTO e DTO em payload.
- Substituir a entrada primária por documento na `CaseAssessmentAnalysisScreenView` por `BriefingFormCard`.
- Criar `BriefingFormCard` com `reactive_forms`, campos obrigatórios e validação inline em PT-BR.
- Criar `SupportDocumentsSection` para anexos opcionais múltiplos de apoio, com progresso individual e remoção local/remota.
- Reutilizar `StorageService.generateAnalysisDocumentUploadUrl`, `DocumentPickerDriver`, `FileStorageDriver` e `IntakeService.createAnalysisDocument/removeAnalysisDocument` para documentos de apoio.
- Atualizar `CaseAssessmentAnalysisScreenPresenter` para orquestrar status, reentrada, resumo, precedentes e minuta a partir do briefing submetido.
- Manter o fluxo posterior existente: geração de `CaseSummaryDto`, busca/seleção de precedentes, geração/regeneração de `PetitionDraftDto` e exportação PDF.

## 2.2 Out-of-scope

- Backend dos endpoints de briefing.
- Edição manual campo a campo da minuta de petição inicial.
- Exportação da minuta em `DOCX`.
- Alterações no fluxo de Juiz, 1ª instância ou 2ª instância.
- Alterações funcionais no `AnalysisPrecedentsBubble`.
- Criação de endpoint dedicado para listar múltiplos documentos de apoio.
- Validação jurídica/semântica dos campos pela IA antes do envio.
- Testes automatizados.
- Validação visual via Google Stitch, pois nenhum `screen_id` foi informado.

---

# 3. Requisitos

## 3.1 Funcionais

- A tela deve iniciar o fluxo de `AnalysisTypeDto.caseAssessment` exibindo `AiBubble` de boas-vindas e `BriefingFormCard` quando o status for `WAITING_BRIEFING`.
- O formulário deve conter os campos obrigatórios `legalArea`, `courtJurisdiction`, `mainClaims` e `intendedThesis`.
- `legalArea` deve ser selecionado a partir de: Constitucional, Administrativo, Tributário, Previdenciário, Civil, Família e Sucessões, Consumidor, Empresarial, Trabalhista, Penal, Ambiental e Processual.
- `courtJurisdiction` deve reutilizar `CourtDto.values` para tribunal/UF, mantendo o mesmo vocabulário usado na busca de precedentes.
- `mainClaims` e `intendedThesis` devem ser campos multilinha com placeholders orientativos do PRD.
- O CTA **Analisar** deve ficar desabilitado enquanto qualquer campo obrigatório estiver inválido.
- Ao acionar **Analisar** em `WAITING_BRIEFING`, o app deve submeter o briefing, avançar para `BRIEFING_SUBMITTED` e iniciar a geração do resumo do caso via `triggerCaseAssessmentCaseSummarization`.
- Ao reabrir a tela com status posterior a `BRIEFING_SUBMITTED`, o app deve consultar `getCaseAssessmentBriefing` e popular o `FormGroup`.
- O usuário pode editar e reenviar o briefing a qualquer momento antes ou depois do resumo; o reenvio substitui o briefing anterior, mas deve preservar precedentes e minuta já existentes no estado local.
- O usuário pode anexar documentos de apoio opcionais em PDF ou DOCX, com limite local de **20MB por arquivo**.
- Cada documento de apoio deve exibir nome, status/progresso de upload e ação de remoção quando aplicável.
- O fluxo deve preservar os dados do formulário em caso de falha recuperável ou timeout.
- Após `CASE_ANALYZED`, a tela continua exibindo `CaseSummaryCard` e o fluxo de precedentes/minuta permanece funcional.

## 3.2 Não funcionais

- **Performance:** o formulário deve atualizar `canSubmit` por `signals` sem chamadas remotas a cada alteração de campo.
- **Performance:** polling de análise continua com intervalo mínimo de **3 segundos**.
- **Acessibilidade:** campos devem ter labels visíveis, mensagens inline e área de toque mínima compatível com componentes Material.
- **Offline/Conectividade:** falhas de upload, submissão ou polling devem aparecer em `generalError` ou erro inline recuperável, sem apagar o formulário.
- **Segurança:** nenhum conteúdo de briefing deve ser persistido em cache local; os dados ficam no `FormGroup` e no backend.
- **Compatibilidade:** reutilizar `reactive_forms`, `flutter_riverpod` e `signals_flutter` já presentes no projeto, sem introduzir nova biblioteca.

---

# 4. O que já existe?

## Core

- **`AnalysisDto`** (`lib/core/intake/dtos/analysis_dto.dart`) — DTO da análise, usado no `load()` e no polling de status.
- **`AnalysisStatusDto`** (`lib/core/intake/dtos/analysis_status_dto.dart`) — wrapper de status compartilhado entre telas de análise.
- **`CaseAssessmentAnalysisStatusDto`** (`lib/core/intake/dtos/case_assessment_analysis_status_dto.dart`) — enum específico de Case Assessment, hoje baseado em documento (`WAITING_DOCUMENT_UPLOAD`/`DOCUMENT_UPLOADED`).
- **`AnalysisDocumentDto`** (`lib/core/intake/dtos/analysis_document_dto.dart`) — DTO de documento anexado à análise, reutilizado para documentos de apoio.
- **`CourtDto`** (`lib/core/intake/dtos/court_dto.dart`) — enum de tribunais/UFs usado em precedentes e reaproveitado para `courtJurisdiction`.
- **`CaseSummaryDto`** (`lib/core/intake/dtos/case_summary_dto.dart`) — DTO do resumo gerado após a submissão do briefing.
- **`PetitionDraftDto`** (`lib/core/intake/dtos/petition_draft_dto.dart`) — DTO da minuta de petição exibida ao fim do fluxo.
- **`IntakeService`** (`lib/core/intake/interfaces/intake_service.dart`) — contrato atual para análise, documento, resumo, precedentes, minuta, relatório, renomeação e arquivamento.
- **`StorageService`** (`lib/core/storage/interfaces/storage_service.dart`) — gera signed URL para upload de documento de análise.
- **`DocumentPickerDriver`** (`lib/core/storage/interfaces/drivers/document_picker_driver.dart`) — porta para seleção de arquivo local.
- **`FileStorageDriver`** (`lib/core/storage/interfaces/drivers/file_storage_driver.dart`) — porta para upload com callback de progresso.
- **`PdfDriver`** (`lib/core/shared/interfaces/pdf_driver.dart`) — usado pela exportação PDF já existente na tela.
- **`CacheDriver`** (`lib/core/shared/interfaces/cache_driver.dart`) — injetado no presenter atual para suporte ao fluxo de precedentes.

## REST

- **`IntakeRestService`** (`lib/rest/services/intake_rest_service.dart`) — implementa `IntakeService` e encapsula endpoints de análise, documentos, resumo, precedentes, minuta e relatório.
- **`AnalysisDocumentMapper`** (`lib/rest/mappers/intake/analysis_document_mapper.dart`) — converte documento remoto em `AnalysisDocumentDto`.
- **`CaseSummaryMapper`** (`lib/rest/mappers/intake/case_summary_mapper.dart`) — converte `case_summary` e campos derivados em `CaseSummaryDto`.
- **`AnalysisMapper`** (`lib/rest/mappers/intake/analysis_mapper.dart`) — converte análise remota em `AnalysisDto`.
- **`PetitionDraftMapper`** (`lib/rest/mappers/intake/petition_draft_mapper.dart`) — converte minuta de petição remota em `PetitionDraftDto`.
- **`CaseAssessmentAnalysisReportMapper`** (`lib/rest/mappers/intake/case_assessment_analysis_report_mapper.dart`) — usado na exportação PDF do fluxo de Case Assessment.
- **`intakeServiceProvider`** (`lib/rest/services/index.dart`) — provider Riverpod que expõe `IntakeRestService` como `IntakeService`.
- **`storageServiceProvider`** (`lib/rest/services/index.dart`) — provider Riverpod que expõe `StorageRestService` como `StorageService`.

## Drivers

- **`FilePickerDocumentPickerDriver`** (`lib/drivers/document-picker-driver/file_picker/file_picker_document_picker_driver.dart`) — implementação concreta do picker de documentos.
- **`documentPickerDriverProvider`** (`lib/drivers/document-picker-driver/index.dart`) — provider usado pelo presenter atual.
- **`GcsFileStorageDriver`** (`lib/drivers/file_storage/gcs_file_storage_driver.dart`) — implementação concreta de upload remoto.
- **`fileStorageDriverProvider`** (`lib/drivers/file_storage/index.dart`) — provider usado pelo presenter atual.
- **`cacheDriverProvider`** (`lib/drivers/cache/index.dart`) — provider de cache já injetado na tela.
- **`pdfDriverProvider`** (`lib/drivers/pdf-driver/index.dart`) — provider de PDF já injetado na tela.

## UI

- **`CaseAssessmentAnalysisScreenPresenter`** (`lib/ui/intake/widgets/pages/case_assessment_analysis_screen/case_assessment_analysis_screen_presenter.dart`) — presenter atual do fluxo; ainda concentra seleção/upload do documento primário e estados posteriores.
- **`CaseAssessmentAnalysisScreenView`** (`lib/ui/intake/widgets/pages/case_assessment_analysis_screen/case_assessment_analysis_screen_view.dart`) — view atual; ainda renderiza `DocumentFileBubble` e `AnalysisActionBar` com ação de arquivo.
- **`AnalysisActionBar`** (`lib/ui/intake/widgets/components/analysis_action_bar/`) — action bar inferior reutilizada pela tela.
- **`DocumentFileBubble`** (`lib/ui/intake/widgets/components/document_file_bubble/`) — componente visual atual para documento único; não deve ser usado como entrada primária do briefing.
- **`AiBubble`** (`lib/ui/intake/widgets/components/ai_bubble/`) — componente de mensagem conversacional reutilizado no estado inicial e processamento.
- **`CaseSummaryCard`** (`lib/ui/intake/widgets/components/case_summary_card/`) — card do resumo gerado, mantido após `CASE_ANALYZED`.
- **`AnalysisPrecedentsBubble`** (`lib/ui/intake/widgets/components/analysis_precedents_bubble/`) — fluxo de precedentes mantido sem alteração funcional.
- **`AddPrecedentDialogPresenter`** (`lib/ui/intake/widgets/components/analysis_precedents_bubble/add_precedent_dialog/add_precedent_dialog_presenter.dart`) — referência de `reactive_forms` + `signals` + provider Riverpod em `intake`.
- **`AddPrecedentDialogView`** (`lib/ui/intake/widgets/components/analysis_precedents_bubble/add_precedent_dialog/add_precedent_dialog_view.dart`) — referência de `ReactiveDropdownField`, `ReactiveTextField` e `validationMessages`.

---

# 5. O que deve ser criado?

## Camada Core (DTOs)

### `LegalAreaDto`

- **Localização:** `lib/core/intake/dtos/legal_area_dto.dart` (**novo arquivo**).
- **Tipo:** `enum LegalAreaDto`.
- **Atributos:** `final String value`.
- **Valores:** `constitucional('CONSTITUCIONAL')`, `administrativo('ADMINISTRATIVO')`, `tributario('TRIBUTÁRIO')`, `previdenciario('PREVIDENCIÁRIO')`, `civil('CIVIL')`, `familiaESucessoes('FAMÍLIA_E_SUCESSÕES')`, `consumidor('CONSUMIDOR')`, `empresarial('EMPRESARIAL')`, `trabalhista('TRABALHISTA')`, `penal('PENAL')`, `ambiental('AMBIENTAL')`, `processual('PROCESSUAL')`.
- **Regra de valor remoto:** todos os valores enviados ao backend devem ser devidamente acentuados, conforme definido acima.
- **Responsabilidade:** representar a lista estruturada de áreas jurídicas aceitas no briefing.

### `CaseAssessmentBriefingDto`

- **Localização:** `lib/core/intake/dtos/case_assessment_briefing_dto.dart` (**novo arquivo**).
- **Atributos:** `final String analysisId`, `final LegalAreaDto legalArea`, `final CourtDto courtJurisdiction`, `final String mainClaims`, `final String intendedThesis`.
- **Construtor:** `const CaseAssessmentBriefingDto({required String analysisId, required LegalAreaDto legalArea, required CourtDto courtJurisdiction, required String mainClaims, required String intendedThesis})`.
- **Factory `fromJson`:** **Não aplicável**; parsing fica na camada REST.
- **Responsabilidade:** transportar o briefing tipado entre `ui`, `core` e `rest` sem expor payload remoto.

## Camada Core (Interfaces / Contratos)

- **Localização:** `lib/core/intake/interfaces/intake_service.dart`.
- **Método:** `Future<RestResponse<CaseAssessmentBriefingDto>> submitCaseAssessmentBriefing({required String analysisId, required CaseAssessmentBriefingDto briefing})` — envia ou substitui o briefing estruturado de uma análise.
- **Método:** `Future<RestResponse<CaseAssessmentBriefingDto>> getCaseAssessmentBriefing({required String analysisId})` — consulta o briefing já submetido para popular a reentrada da tela.

## Camada REST (Services)

- **Localização:** `lib/rest/services/intake_rest_service.dart`.
- **Interface implementada:** `IntakeService`.
- **Dependências:** `RestClient` já injetado por construtor.
- **Método:** `Future<RestResponse<CaseAssessmentBriefingDto>> submitCaseAssessmentBriefing({required String analysisId, required CaseAssessmentBriefingDto briefing})` — chama `POST /intake/analyses/$analysisId/case-assessment-briefing` com payload do mapper e retorna DTO tipado.
- **Método:** `Future<RestResponse<CaseAssessmentBriefingDto>> getCaseAssessmentBriefing({required String analysisId})` — chama `GET /intake/analyses/$analysisId/case-assessment-briefing` e retorna DTO tipado.

## Camada REST (Mappers)

- **Localização:** `lib/rest/mappers/intake/case_assessment_briefing_mapper.dart` (**novo arquivo**).
- **Método:** `static CaseAssessmentBriefingDto toDto(Json json)` — mapeia `analysis_id`, `legal_area`, `court_jurisdiction`, `main_claims` e `intended_thesis` para `CaseAssessmentBriefingDto`.
- **Método:** `static Json toJson(CaseAssessmentBriefingDto dto)` — mapeia `legalArea.value`, `courtJurisdiction.value`, `mainClaims.trim()` e `intendedThesis.trim()` para o payload remoto.
- **Responsabilidade:** encapsular conversão `snake_case`/`camelCase` e normalização defensiva de enum por `value`.

## Camada UI (Presenters)

### `BriefingFormCardPresenter`

- **Localização:** `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/briefing_form_card/briefing_form_card_presenter.dart` (**novo arquivo**).
- **Dependências injetadas:** `IntakeService` via `intakeServiceProvider`.
- **Estado (`signals`):** `briefing: Signal<CaseAssessmentBriefingDto?>`, `isSubmitting: Signal<bool>`, `generalError: Signal<String?>`, `isReadOnly: Signal<bool>`.
- **Estado (`reactive_forms`):** `form: FormGroup` com `legalArea: FormControl<LegalAreaDto>`, `courtJurisdiction: FormControl<CourtDto>`, `mainClaims: FormControl<String>`, `intendedThesis: FormControl<String>`.
- **Computeds:** `canSubmit: ReadonlySignal<bool>` — `true` quando `form.valid`, `!isSubmitting` e `!isReadOnly`.
- **Provider Riverpod:** `briefingFormCardPresenterProvider` (`Provider.autoDispose.family<BriefingFormCardPresenter, String>`).
- **Método:** `Future<void> load()` — consulta `IntakeService.getCaseAssessmentBriefing`, popula `briefing` e aplica valores no `FormGroup` quando o backend retornar dados.
- **Método:** `Future<CaseAssessmentBriefingDto?> submitBriefing()` — valida o formulário, chama `IntakeService.submitCaseAssessmentBriefing`, atualiza `briefing` e retorna o DTO submetido.
- **Método:** `CaseAssessmentBriefingDto? buildBriefingFromForm()` — monta DTO tipado a partir dos controles válidos.
- **Método:** `void fillForm(CaseAssessmentBriefingDto briefing)` — aplica os valores do DTO nos controles sem recriar o `FormGroup`.
- **Método:** `String? fieldErrorMessage(FormControl<Object?> control)` — retorna mensagens inline em PT-BR para campos inválidos.
- **Método:** `void resetAfterResubmit()` — limpa erros locais e marca o formulário como editável para reenvio.
- **Método:** `void dispose()` — cancela subscriptions do formulário e descarta signals.

### `SupportDocumentsSectionPresenter`

- **Localização:** `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/briefing_form_card/support_documents_section/support_documents_section_presenter.dart` (**novo arquivo**).
- **Dependências injetadas:** `StorageService`, `IntakeService`, `DocumentPickerDriver`, `FileStorageDriver`.
- **Estado (`signals`):** `documents: Signal<List<AnalysisDocumentDto>>`, `uploadingDocuments: Signal<Map<String, double?>>`, `isPicking: Signal<bool>`, `generalError: Signal<String?>`.
- **Computeds:** `canAddDocument: ReadonlySignal<bool>` — `true` quando não está selecionando arquivo e não há upload concorrente bloqueante.
- **Provider Riverpod:** `supportDocumentsSectionPresenterProvider` (`Provider.autoDispose.family<SupportDocumentsSectionPresenter, String>`).
- **Método:** `Future<void> addSupportDocument()` — seleciona PDF/DOCX, valida extensão/tamanho de 20MB, gera signed URL, faz upload, chama `createAnalysisDocument` e adiciona o DTO na lista local.
- **Método:** `Future<void> removeSupportDocument(AnalysisDocumentDto document)` — chama `removeAnalysisDocument` com `document.filePath` e remove o item da lista local em caso de sucesso.
- **Método:** `String fileName(File file)` — extrai nome amigável do arquivo selecionado.
- **Método:** `String formatFileSize(int sizeInBytes)` — formata bytes para `B`, `KB` ou `MB`.
- **Método:** `String extensionFromPath(String path)` — extrai extensão normalizada para validação.
- **Método:** `void dispose()` — descarta signals.

### `CaseAssessmentAnalysisScreenPresenter` (existente, modificado)

- **Localização:** `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/case_assessment_analysis_screen_presenter.dart`.
- **Dependências mantidas:** `IntakeService`, `CacheDriver`, `PdfDriver`.
- **Dependências removidas do presenter da Screen:** `StorageService`, `DocumentPickerDriver`, `FileStorageDriver` para o fluxo primário; ficam no `SupportDocumentsSectionPresenter`.
- **Estado removido:** `selectedFile`, `analysisDocument`, `isUploading`, `uploadProgress` como estado do documento primário.
- **Estado adicionado:** `briefing: Signal<CaseAssessmentBriefingDto?>`.
- **Computeds atualizados:** `canAnalyzeCase` — `true` quando `briefing != null`, status `BRIEFING_SUBMITTED` ou `FAILED` recuperável, e não há gerenciamento em andamento.
- **Computeds atualizados:** `primaryActionLabel` — retorna `Analisar` em `WAITING_BRIEFING`/`BRIEFING_SUBMITTED`, preservando labels posteriores.
- **Método:** `void markBriefingSubmitted(CaseAssessmentBriefingDto briefing)` — sincroniza `briefing`, status local `BRIEFING_SUBMITTED` e preserva resumo, precedentes e minuta já carregados.
- **Método:** `Future<void> analyzeCase()` — chama `triggerCaseAssessmentCaseSummarization`, aplica status `ANALYZING_CASE` e inicia `_pollUntilCaseReady`.
- **Método atualizado:** `Future<void> load()` — carrega `AnalysisDto`, sincroniza status e carrega briefing quando status não for `WAITING_BRIEFING`.
- **Método atualizado:** `Future<void> reanalyzeCase()` — preserva briefing, limpa resultados derivados e chama `analyzeCase`.
- **Método removido:** `Future<void> pickDocument()` — substituído por `SupportDocumentsSectionPresenter.addSupportDocument`.
- **Método removido:** `Future<void> replaceDocument()` — substituído por reenvio do briefing.
- **Método privado removido:** `Future<void> _uploadAnalysisDocument(File file)` — substituído pelo presenter de documentos de apoio.

## Camada UI (Views)

### `BriefingFormCardView`

- **Localização:** `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/briefing_form_card/briefing_form_card_view.dart` (**novo arquivo**).
- **Base class:** `ConsumerWidget`.
- **Props:** `final String analysisId`, `final bool enabled`, `final void Function(CaseAssessmentBriefingDto briefing)? onSubmitted`.
- **Bibliotecas de UI:** `flutter_riverpod`, `signals_flutter`, `reactive_forms`, `flutter/material.dart`.
- **Estados visuais:** Content com formulário, Error inline, Submitting com botão/estado ocupado refletido no presenter.
- **Responsabilidade:** renderizar `ReactiveForm`, dropdowns de `LegalAreaDto` e `CourtDto`, campos multilinha, mensagens de erro e `SupportDocumentsSection`.

### `SupportDocumentsSectionView`

- **Localização:** `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/briefing_form_card/support_documents_section/support_documents_section_view.dart` (**novo arquivo**).
- **Base class:** `ConsumerWidget`.
- **Props:** `final String analysisId`, `final bool enabled`.
- **Bibliotecas de UI:** `flutter_riverpod`, `signals_flutter`, `flutter/material.dart`.
- **Estados visuais:** Empty sem anexos, Uploading com progresso individual, Content com lista, Error inline.
- **Responsabilidade:** renderizar lista de documentos de apoio, botão **Adicionar documento**, progresso e remoção.

### `SupportDocumentItemView`

- **Localização:** `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/briefing_form_card/support_documents_section/support_document_item/support_document_item_view.dart` (**novo arquivo**).
- **Base class:** `StatelessWidget`.
- **Props:** `final AnalysisDocumentDto document`, `final double? progress`, `final bool isUploading`, `final bool enabled`, `final VoidCallback? onRemove`.
- **Tipo:** `View only`.
- **Responsabilidade:** renderizar uma linha/card visual de documento com ícone, nome, estado de upload e ação de remover.

### `CaseAssessmentAnalysisScreenView` (existente, modificado)

- **Localização:** `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/case_assessment_analysis_screen_view.dart`.
- **Base class:** `ConsumerStatefulWidget` mantida.
- **Mudança:** remover renderização de `DocumentFileBubble` como entrada primária.
- **Mudança:** renderizar `BriefingFormCard` logo após o `AiBubble` inicial nos status `WAITING_BRIEFING`, `BRIEFING_SUBMITTED` e estados posteriores quando o briefing já existir.
- **Mudança:** no CTA **Analisar**, quando o status for `WAITING_BRIEFING`, submeter o briefing pelo `BriefingFormCardPresenter`, chamar `screenPresenter.markBriefingSubmitted(briefing)` e então `screenPresenter.analyzeCase()`.
- **Mudança:** quando o status for `BRIEFING_SUBMITTED`, acionar diretamente `screenPresenter.analyzeCase()`.
- **Mudança:** preservar renderização posterior de `CaseSummaryCard`, `AnalysisPrecedentsBubble`, `GeneratePetitionDraftCard`, `PetitionDraftCard`, `PetitionDraftModal` e `MessageBox`.

## Camada UI (Widgets Internos)

### `BriefingFormCard`

- **Localização:** `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/briefing_form_card/` (**novo arquivo**).
- **Tipo:** `View + Presenter`.
- **Props:** `analysisId`, `enabled`, `onSubmitted`.
- **Responsabilidade:** gerenciar e renderizar o formulário de briefing, isolando validação e submissão do presenter da Screen.

### `SupportDocumentsSection`

- **Localização:** `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/briefing_form_card/support_documents_section/` (**novo arquivo**).
- **Tipo:** `View + Presenter`.
- **Props:** `analysisId`, `enabled`.
- **Responsabilidade:** gerenciar documentos de apoio opcionais, seleção, upload, progresso e remoção.

### `SupportDocumentItem`

- **Localização:** `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/briefing_form_card/support_documents_section/support_document_item/` (**novo arquivo**).
- **Tipo:** `View only`.
- **Props:** `document`, `progress`, `isUploading`, `enabled`, `onRemove`.
- **Responsabilidade:** renderizar um documento de apoio individual.

## Camada UI (Barrel Files / `index.dart`)

- **Localização:** `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/briefing_form_card/index.dart` (**novo arquivo**).
- **`typedef` exportado:** `typedef BriefingFormCard = BriefingFormCardView`.
- **Exports:** `BriefingFormCardPresenter`, `briefingFormCardPresenterProvider`, `BriefingFormCardView`.
- **Localização:** `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/briefing_form_card/support_documents_section/index.dart` (**novo arquivo**).
- **`typedef` exportado:** `typedef SupportDocumentsSection = SupportDocumentsSectionView`.
- **Exports:** `SupportDocumentsSectionPresenter`, `supportDocumentsSectionPresenterProvider`, `SupportDocumentsSectionView`.
- **Localização:** `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/briefing_form_card/support_documents_section/support_document_item/index.dart` (**novo arquivo**).
- **`typedef` exportado:** `typedef SupportDocumentItem = SupportDocumentItemView`.

## Camada UI (Providers Riverpod — se isolados)

- **Localização:** `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/briefing_form_card/briefing_form_card_presenter.dart`.
- **Nome do provider:** `briefingFormCardPresenterProvider`.
- **Tipo:** `Provider.autoDispose.family<BriefingFormCardPresenter, String>`.
- **Dependências:** `intakeServiceProvider` via `ref.watch`.
- **Localização:** `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/briefing_form_card/support_documents_section/support_documents_section_presenter.dart`.
- **Nome do provider:** `supportDocumentsSectionPresenterProvider`.
- **Tipo:** `Provider.autoDispose.family<SupportDocumentsSectionPresenter, String>`.
- **Dependências:** `storageServiceProvider`, `intakeServiceProvider`, `documentPickerDriverProvider`, `fileStorageDriverProvider` via `ref.watch`.

## Rotas (`go_router`) — se aplicável

**Não aplicável.** A rota `CaseAssessmentAnalysisScreen` já existe e a mudança ocorre dentro da tela atual.

## Estrutura de Pastas

```text
lib/ui/intake/widgets/pages/case_assessment_analysis_screen/
  index.dart
  case_assessment_analysis_screen_view.dart
  case_assessment_analysis_screen_presenter.dart
  briefing_form_card/
    index.dart
    briefing_form_card_view.dart
    briefing_form_card_presenter.dart
    support_documents_section/
      index.dart
      support_documents_section_view.dart
      support_documents_section_presenter.dart
      support_document_item/
        index.dart
        support_document_item_view.dart
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

---

# 6. O que deve ser modificado?

## Core

- **Arquivo:** `lib/core/intake/dtos/case_assessment_analysis_status_dto.dart`.
- **Mudança:** adicionar `waitingBriefing('WAITING_BRIEFING')` e `briefingSubmitted('BRIEFING_SUBMITTED')`; remover ou deixar de usar `waitingDocumentUpload`/`documentUploaded` no fluxo de Case Assessment.
- **Justificativa:** o PRD substitui documento primário por formulário estruturado.

- **Arquivo:** `lib/core/intake/dtos/analysis_status_dto.dart`.
- **Mudança:** adicionar constantes `waitingBriefing` e `briefingSubmitted`, incluir em `values` e mapear no factory `AnalysisStatusDto.caseAssessment(...)`.
- **Justificativa:** a UI e REST trabalham com `AnalysisStatusDto` como wrapper comum.

- **Arquivo:** `lib/core/intake/interfaces/intake_service.dart`.
- **Mudança:** importar `CaseAssessmentBriefingDto` e declarar `submitCaseAssessmentBriefing`/`getCaseAssessmentBriefing`.
- **Justificativa:** presenters devem consumir contratos do `core`, nunca `RestClient`.

## REST

- **Arquivo:** `lib/rest/services/intake_rest_service.dart`.
- **Mudança:** importar `CaseAssessmentBriefingDto` e `CaseAssessmentBriefingMapper`, implementar os dois métodos de briefing e atualizar `_mapAnalysisStatus` indiretamente via `AnalysisStatusDto.values`.
- **Justificativa:** encapsular endpoints e payload remoto na borda REST.

## UI

- **Arquivo:** `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/case_assessment_analysis_screen_presenter.dart`.
- **Mudança:** remover lógica de documento primário, adicionar estado de briefing, carregar briefing na reentrada, atualizar `canAnalyzeCase`, `primaryActionLabel`, `load`, `reanalyzeCase` e retry contextual.
- **Justificativa:** o presenter da Screen passa a orquestrar apenas o fluxo de alto nível, delegando formulário e documentos de apoio a presenters internos.

- **Arquivo:** `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/case_assessment_analysis_screen_view.dart`.
- **Mudança:** substituir `DocumentFileBubble` + `FileActionButton` de entrada por `BriefingFormCard`; ajustar `AnalysisActionBar` para usar o estado do briefing e disparar submissão/análise.
- **Justificativa:** o ponto de entrada visual da análise passa a ser o briefing estruturado.

- **Arquivo:** `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/index.dart`.
- **Mudança:** manter export da Screen e não expor widgets internos além dos barrels das suas próprias pastas.
- **Justificativa:** preservar fronteira pública da tela.

## Drivers

**Não aplicável.** A feature reutiliza drivers existentes e não cria novo adaptador.

## Rotas

**Não aplicável.** A rota da tela não muda.

---

# 7. O que deve ser removido?

## UI

- **Arquivo:** `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/case_assessment_analysis_screen_presenter.dart`.
- **Motivo da remoção:** remover do presenter da Screen os signals e métodos específicos de documento primário (`selectedFile`, `analysisDocument`, `isUploading`, `uploadProgress`, `pickDocument`, `replaceDocument`, `_uploadAnalysisDocument`, `_deletePendingUploadDocument`).
- **Impacto esperado:** a responsabilidade de anexos opcionais passa para `SupportDocumentsSectionPresenter`; o fluxo principal deixa de depender de `AnalysisDocumentDto` para habilitar análise.

- **Arquivo:** `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/case_assessment_analysis_screen_view.dart`.
- **Motivo da remoção:** remover renderização de `DocumentFileBubble` como requisito de entrada e a ação `showFileAction` para documento primário.
- **Impacto esperado:** `DocumentFileBubble` permanece no projeto para outros fluxos/componentes, mas não é usado como entrada do Case Assessment após esta feature.

---

# 8. Decisões Técnicas e Trade-offs

## 8.1 Briefing como DTO próprio no `core`

- **Decisão:** criar `CaseAssessmentBriefingDto` em vez de reutilizar `CaseSummaryDto`.
- **Alternativas consideradas:** reutilizar `CaseSummaryDto` porque o resumo final deriva dos campos do briefing.
- **Motivo da escolha:** briefing é entrada do advogado; resumo é saída da IA. Misturar os dois acoplaria dados de origem e dados gerados.
- **Impactos / trade-offs:** cria um DTO e mapper novos, mas preserva semântica clara e evita payload cru na UI.

## 8.2 Formulário com presenter próprio

- **Decisão:** criar `BriefingFormCardPresenter` com `FormGroup`, validações e submissão.
- **Alternativas consideradas:** manter o `FormGroup` no `CaseAssessmentAnalysisScreenPresenter`.
- **Motivo da escolha:** as regras do projeto exigem widgets internos com estado/handlers em pasta própria e presenter próprio; o presenter da Screen deve ser enxuto.
- **Impactos / trade-offs:** a View precisa coordenar dispatch entre o presenter do formulário e o presenter da Screen no CTA principal, mas a lógica de validação e submissão fica isolada.

## 8.3 Documentos de apoio como seção interna independente

- **Decisão:** criar `SupportDocumentsSectionPresenter` separado do `BriefingFormCardPresenter`.
- **Alternativas consideradas:** colocar upload e lista de anexos dentro do presenter do formulário.
- **Motivo da escolha:** upload, progresso e remoção são responsabilidades próprias, com dependências de drivers e services distintas da submissão do briefing.
- **Impactos / trade-offs:** aumenta a componentização, mas evita que o form presenter vire um orquestrador de infraestrutura.

## 8.4 Reutilizar endpoints/drivers de documento existentes

- **Decisão:** usar `StorageService.generateAnalysisDocumentUploadUrl`, `FileStorageDriver.uploadFile`, `IntakeService.createAnalysisDocument` e `removeAnalysisDocument` para documentos de apoio.
- **Alternativas consideradas:** criar contratos dedicados de support documents.
- **Motivo da escolha:** o PRD afirma que não há necessidade de endpoint backend dedicado para listar múltiplos documentos neste recorte; signed URL e persistência de metadados já existem como capacidades próximas.
- **Impactos / trade-offs:** a listagem persistida de múltiplos documentos na reentrada fica limitada ao contrato backend disponível; pendência registrada na seção 10.

## 8.5 Status de briefing assumidos a partir do rascunho atual

- **Decisão:** usar `WAITING_BRIEFING` e `BRIEFING_SUBMITTED`.
- **Alternativas consideradas:** manter `WAITING_DOCUMENT_UPLOAD`/`DOCUMENT_UPLOADED` e reinterpretar semanticamente.
- **Motivo da escolha:** o rascunho atual e o novo PRD indicam substituição real do ponto de entrada; manter status de documento seria enganoso para UI e suporte.
- **Impactos / trade-offs:** depende de alinhamento backend; registrado como pendência porque o PRD do Confluence não lista nomes oficiais de status.

## 8.6 Endpoint de briefing assumido a partir do rascunho atual

- **Decisão:** usar `POST /intake/analyses/{analysis_id}/case-assessment-briefing` e `GET /intake/analyses/{analysis_id}/case-assessment-briefing`.
- **Alternativas consideradas:** bloquear a spec até contrato backend oficial.
- **Motivo da escolha:** o usuário confirmou usar o rascunho atual como base para contratos REST/status.
- **Impactos / trade-offs:** se o backend divergir, os métodos de `IntakeRestService` e mapper precisarão ajuste pontual sem alterar a arquitetura da UI.

## 8.7 Reenvio preserva resultados posteriores

- **Decisão:** ao reenviar briefing, atualizar apenas o briefing e preservar localmente `caseSummary`, `petitionDraft`, `precedentsReady` e `hasChosenPrecedents`.
- **Alternativas consideradas:** limpar resumo, precedentes e minuta antes de nova análise.
- **Motivo da escolha:** a regra refinada pelo usuário exige manter precedentes e minuta; a tela não deve apagar resultados posteriores apenas por alteração do briefing.
- **Impactos / trade-offs:** resultados já exibidos podem refletir uma versão anterior do briefing até que uma nova análise seja disparada/concluída; a implementação deve evitar sugerir que eles foram recalculados automaticamente.

---

# 9. Diagramas e Referências

## 9.1 Fluxo de dados

```text
CaseAssessmentAnalysisScreenView
  -> BriefingFormCardView
      -> BriefingFormCardPresenter
          -> briefingFormCardPresenterProvider
              -> IntakeService.submitCaseAssessmentBriefing(...)
                  -> IntakeRestService
                      -> RestClient (Dio) -> API

CaseAssessmentAnalysisScreenView
  -> CaseAssessmentAnalysisScreenPresenter
      -> caseAssessmentAnalysisScreenPresenterProvider
          -> IntakeService.triggerCaseAssessmentCaseSummarization(...)
          -> IntakeService.getAnalysis(...) [polling]
          -> IntakeService.getCaseSummary(...)
          -> AnalysisPrecedentsBubblePresenter
          -> IntakeService.triggerPetitionDraftGeneration(...)
          -> IntakeService.getPetitionDraft(...)

SupportDocumentsSectionView
  -> SupportDocumentsSectionPresenter
      -> DocumentPickerDriver.pickDocument(...)
      -> StorageService.generateAnalysisDocumentUploadUrl(...)
      -> FileStorageDriver.uploadFile(...)
      -> IntakeService.createAnalysisDocument(...)
```

## 9.2 Hierarquia de widgets

```text
CaseAssessmentAnalysisScreenView
  Scaffold
    SafeArea
      Center
        ConstrainedBox(maxWidth: 402)
          Stack
            DotGridBackground
            Column
              AnalysisHeader
              Expanded
                SingleChildScrollView
                  AiBubble (boas-vindas)
                  BriefingFormCard
                    ReactiveForm
                      ReactiveDropdownField<LegalAreaDto>
                      ReactiveDropdownField<CourtDto>
                      ReactiveTextField<String> (mainClaims)
                      ReactiveTextField<String> (intendedThesis)
                      SupportDocumentsSection
                        SupportDocumentItem[]
                  AiBubble (ANALYZING_CASE)
                  MessageBox (FAILED)
                  CaseSummaryCard
                  AnalysisPrecedentsBubble
                  GeneratePetitionDraftCard
                  PetitionDraftCard -> PetitionDraftModal
              AnalysisActionBar
```

## 9.3 Referências

- `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/case_assessment_analysis_screen_presenter.dart` — fluxo atual de polling, resumo, precedentes, minuta e exportação.
- `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/case_assessment_analysis_screen_view.dart` — ponto de substituição de `DocumentFileBubble` por `BriefingFormCard`.
- `lib/ui/intake/widgets/components/analysis_precedents_bubble/add_precedent_dialog/add_precedent_dialog_presenter.dart` — referência de `FormGroup`, `FormControl`, `signals` e provider.
- `lib/ui/intake/widgets/components/analysis_precedents_bubble/add_precedent_dialog/add_precedent_dialog_view.dart` — referência de `ReactiveDropdownField`, `ReactiveTextField` e validações inline.
- `lib/ui/intake/widgets/components/case_summary_card/case_summary_card_view.dart` — referência visual de card denso em `intake`.
- `lib/rest/services/intake_rest_service.dart` — referência de implementação de métodos REST e `RestResponse<T>`.
- `lib/rest/mappers/intake/analysis_document_mapper.dart` — referência de mapper simples de DTO.
- `lib/core/intake/interfaces/intake_service.dart` — contrato a ser estendido.
- `lib/core/storage/interfaces/storage_service.dart` — contrato de signed URL existente.
- `lib/core/storage/interfaces/drivers/file_storage_driver.dart` — contrato de upload com progresso.
- `https://joaogoliveiragarcia.atlassian.net/wiki/x/AYDsAg` — PRD RF 07, versão 7, atualizado em 2026-06-04.

---

# 10. Pendências / Dúvidas

## 10.1 PRD local ausente

- **Descrição da pendência:** não existe `documentation/features/intake/case-assessment-analysis/prd.md`; o PRD validado está no Confluence.
- **Impacto na implementação:** baixo para implementação, mas diverge do modelo que pede PRD localizado um nível acima da spec.
- **Ação sugerida:** criar ou sincronizar `documentation/features/intake/case-assessment-analysis/prd.md` em tarefa documental separada.

## 10.2 Ticket Jira não identificado

- **Descrição da pendência:** busca Atlassian não encontrou ticket específico para o briefing; usuário confirmou `ticket: N/A`.
- **Impacto na implementação:** baixo; dificulta rastreabilidade da entrega.
- **Ação sugerida:** vincular ticket Jira quando ele existir.

## 10.3 Contratos REST/status dependem do rascunho atual

- **Descrição da pendência:** o PRD do Confluence não explicita endpoints nem nomes de status; a spec usa os contratos do rascunho atual por decisão do usuário.
- **Impacto na implementação:** médio; divergência backend exige ajuste em `IntakeService`, `IntakeRestService`, mapper e status.
- **Ação sugerida:** validar com backend antes da implementação final.

## 10.4 Listagem persistida de documentos de apoio na reentrada

- **Descrição da pendência:** o PRD diz que não há endpoint backend dedicado para listar múltiplos documentos anexados no recorte atual; a codebase tem `getAnalysisDocument` tipado para um único `AnalysisDocumentDto`.
- **Impacto na implementação:** médio; documentos anexados na sessão podem ser exibidos localmente, mas reentrada com múltiplos anexos depende de contrato backend não evidenciado.
- **Ação sugerida:** validar se `GET /intake/analyses/{analysisId}/case-assessment-briefing` retornará metadados de anexos ou se a reentrada não exibirá anexos anteriores.

---

# Restrições

- Não incluir testes automatizados nesta spec.
- A `View` não deve conter lógica de negócio; ela apenas observa estado e despacha eventos para presenters.
- Presenters não fazem chamadas diretas a `RestClient`; consomem sempre `IntakeService`, `StorageService` ou drivers por interfaces do `core`.
- `BriefingFormCard` deve ter `View + Presenter`, pois contém estado, validação e submissão.
- `SupportDocumentsSection` deve ter `View + Presenter`, pois contém seleção, upload, progresso e remoção.
- `SupportDocumentItem` pode ser `View only`, pois é puramente visual.
- Todos os arquivos citados como existentes foram encontrados na codebase; novos arquivos estão explicitamente marcados como **novo arquivo**.
- Não criar novos drivers para esta feature.
- Não alterar rotas para esta feature.
- Não introduzir nova biblioteca para formulário, upload ou estado.
- Usar componentes Flutter Material alinhados ao tema do projeto.
- Arquivos e diretórios novos devem usar `snake_case`; classes devem usar `PascalCase`; providers e métodos devem usar `camelCase`.
