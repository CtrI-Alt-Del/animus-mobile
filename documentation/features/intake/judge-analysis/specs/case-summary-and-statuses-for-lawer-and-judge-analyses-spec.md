---
title: Atualizacao de case summary e status tipados para analises de lawyer e judge
prd: https://joaogoliveiragarcia.atlassian.net/wiki/spaces/ANM/pages/131218/Requisitos+do+produto
ticket: https://joaogoliveiragarcia.atlassian.net/browse/ANI-115
last_updated_at: 2026-05-12
---

# 1. Objetivo

Alinhar o dominio mobile de `intake` ao contrato introduzido por `ANI-92`, preparando o app para os fluxos `RF 07` (lawyer) e `RF 08` (judge) sem vazar JSON cru para a UI. O recorte desta spec renomeia `PetitionSummaryDto` para `CaseSummaryDto`, introduz `AnalysisTypeDto`, adiciona enums explicitos para status de `lawyer` e `judge`, publica DTOs e metodos para rascunhos e desarquivamento, e atualiza os mappers e consumidores atuais com a menor mudanca correta para manter o app compilando ate as tasks de UI dedicadas (`ANI-101` e `ANI-103`).

---

# 2. Escopo

## 2.1 In-scope

- Renomear o contrato de resumo de caso de `PetitionSummaryDto` para `CaseSummaryDto` no `core`, `rest` e consumidores ja existentes.
- Introduzir `AnalysisTypeDto` com os tipos `lawyer` e `judge`.
- Criar `LawyerAnalysisStatusDto` e `JudgeAnalysisStatusDto` no `core` para refletir a taxonomia do server.
- Atualizar o status compartilhado consumido hoje pelo mobile para refletir os novos valores remotos (`DOCUMENT_UPLOADED`, `ANALYZING_CASE`, `CASE_ANALYZED`, `EXTRACTING_PETITION`, `SEARCHING_PRECEDENTS`, `GENERATING_PETITION_DRAFT`, `GENERATING_JUDGMENT_DRAFT`, `DONE`, `FAILED`).
- Atualizar `AnalysisDto` para expor `type` e o status remoto mapeado para o enum compartilhado do mobile.
- Atualizar `IntakeService` e `IntakeRestService` com `createAnalysis(type: ...)`, `getCaseSummary(...)`, `getPetitionDraft(...)`, `getJudgmentDraft(...)` e `unarchiveAnalysis(...)`.
- Criar os mappers REST necessarios para `CaseSummaryDto`, `PetitionDraftDto` e `JudgmentDraftDto`.
- Ajustar os consumidores atuais do app que dependem diretamente de `PetitionSummaryDto`, `getPetitionSummary(...)` ou dos nomes antigos de status, limitando a mudanca a compatibilidade de compilacao e leitura de dados.
- Manter a criacao atual de analise da Home apontando para `AnalysisTypeDto.lawyer` ate a entrega do dialog de selecao por tipo em `ANI-101`.

## 2.2 Out-of-scope

- Criacao do dialog de selecao de tipo na Home (`ANI-101`).
- Criacao de `LawyerAnalysisScreenView` / `LawyerAnalysisScreenPresenter` e da tela dedicada de judge.
- Split de rotas para `lawyer` e `judge`.
- Novo layout, novos widgets ou nova hierarquia visual para os fluxos `RF 07` e `RF 08`.
- Reescrita funcional completa da `analysis_screen` atual para o novo fluxo de lawyer.
- Qualquer alteracao em `design/animus.pen` ou validacao via Stitch; nenhum `screen_id` foi informado.

---

# 3. Requisitos

## 3.1 Funcionais

- O `core` deve expor `CaseSummaryDto` como substituto direto de `PetitionSummaryDto`, preservando os mesmos campos de negocio ja consumidos hoje pela UI e pelo PDF.
- O `core` deve expor `AnalysisTypeDto` com `lawyer` e `judge`, para que a criacao e leitura de analises distingam explicitamente os dois fluxos.
- O `core` deve expor `LawyerAnalysisStatusDto` e `JudgeAnalysisStatusDto` como enums independentes, refletindo os status do server descritos em `ANI-92`.
- O mobile deve manter um enum compartilhado de status (`AnalysisStatusDto`) para as telas atuais, removendo os valores obsoletos `waitingPrecedentChoice` e `precedentChosen`, e adicionando `documentUploaded`, `extractingPetition`, `analyzingCase`, `caseAnalyzed`, `generatingPetitionDraft`, `generatingJudgmentDraft` e `done`.
- `AnalysisDto` deve passar a carregar `type: AnalysisTypeDto` e continuar expondo `status: AnalysisStatusDto` para os consumidores atuais do app.
- `IntakeService.createAnalysis({required AnalysisTypeDto type, String? folderId})` deve se tornar obrigatoriamente tipado por analise.
- `IntakeService.getCaseSummary({required String analysisId})` deve substituir `getPetitionSummary({required String petitionId})`, eliminando a dependencia da UI de conhecer o `petitionId` para carregar o resumo.
- `IntakeService.getPetitionDraft({required String analysisId})` deve retornar `PetitionDraftDto`.
- `IntakeService.getJudgmentDraft({required String analysisId})` deve retornar `JudgmentDraftDto`.
- `IntakeService.unarchiveAnalysis({required String analysisId})` deve retornar `AnalysisDto` com o estado atualizado.
- `IntakeRestService` deve mapear `type` e os novos status ao desserializar `AnalysisDto`.
- `IntakeRestService` deve enviar `type` no `POST` de criacao de analise.
- O fluxo atual da Home deve continuar criando uma analise valida mesmo antes de `ANI-101`; para isso, o caller atual deve enviar `AnalysisTypeDto.lawyer`.
- Os consumidores atuais de listagem/status na Home devem conseguir rotular analises `lawyer` e `judge` sem cair em status desconhecido.
- O contrato agregado de exportacao (`AnalysisReportDto`) e o `PdfDriver` devem passar a consumir `CaseSummaryDto` sem alterar o comportamento funcional do export ja existente.

## 3.2 Nao funcionais

- **Arquitetura:** nenhuma `View` ou `Presenter` deve montar `Map<String, dynamic>` ou conhecer nomes `snake_case` dos payloads remotos.
- **Arquitetura:** `Dio`, `Response` e detalhes de endpoint devem continuar confinados a `lib/rest/`.
- **Compatibilidade:** a mudanca nao deve exigir o split imediato de rota `/analyses/:analysisId`; isso fica para `ANI-101` e para as telas dedicadas.
- **Compatibilidade:** os consumidores atuais devem continuar compilando com o menor numero de renomeacoes locais possivel; widgets visuais existentes podem manter seus nomes atuais mesmo passando a consumir `CaseSummaryDto`.
- **Manutenibilidade:** a renomeacao para `CaseSummary` deve ser consistente em `core`, `rest`, DTOs agregados e drivers, evitando alias paralelos permanentes.

---

# 4. O que ja existe?

## Core

- **`AnalysisDto`** (`lib/core/intake/dtos/analysis_dto.dart`) - DTO principal da analise; hoje ainda nao expoe `type` e depende do enum legado `AnalysisStatusDto`.
- **`AnalysisStatusDto`** (`lib/core/intake/dtos/analysis_status_dto.dart`) - enum compartilhado atual do mobile; precisa parar de refletir apenas o fluxo antigo de peticao inicial.
- **`PetitionSummaryDto`** (`lib/core/intake/dtos/petition_summary_dto.dart`) - contrato atual de resumo; serve de referencia direta para `CaseSummaryDto`.
- **`AnalysisReportDto`** (`lib/core/intake/dtos/analysis_report_dto.dart`) - agregado usado pelo export em PDF; hoje ainda referencia `PetitionSummaryDto` no campo `summary`.
- **`AnalysisPetitionDto`** (`lib/core/intake/dtos/analysis_petition_dto.dart`) - DTO agregado que tambem carrega o resumo atual como `summary` opcional.
- **`IntakeService`** (`lib/core/intake/interfaces/intake_service.dart`) - contrato central do modulo `intake`; hoje ainda expoe `createAnalysis()` sem tipo e `getPetitionSummary(petitionId)`.

## REST

- **`IntakeRestService`** (`lib/rest/services/intake_rest_service.dart`) - implementacao concreta de `IntakeService`; ja concentra criacao de analise, resumo, listagem, export e escolha de precedente.
- **`AnalysisMapper`** (`lib/rest/mappers/intake/analysis_mapper.dart`) - mapper atual de `AnalysisDto`; ja traduz `status` string para enum do mobile.
- **`PetitionSummaryMapper`** (`lib/rest/mappers/intake/petition_summary_mapper.dart`) - referencia direta para a renomeacao de mapper.
- **`AnalysisReportMapper`** (`lib/rest/mappers/intake/analysis_report_mapper.dart`) - mapper agregado que hoje usa `PetitionSummaryMapper` e popula `summary`.
- **`AnalysisPetitionMapper`** (`lib/rest/mappers/intake/analysis_petition_mapper.dart`) - mapper agregado que hoje popula `summary` ou `petition_summary`.

## Drivers

- **`PdfDriver`** (`lib/core/shared/interfaces/pdf_driver.dart`) - contrato de geracao e compartilhamento de PDF que consome `AnalysisReportDto`.
- **`PrintingPdfDriver`** (`lib/drivers/pdf-driver/printing/printing_pdf_driver.dart`) - implementacao atual que acessa `report.summary.caseSummary`, `report.summary.centralQuestion`, `report.summary.legalIssue`, `report.summary.keyFacts` e `report.summary.relevantLaws`.

## UI

- **`HomeScreenPresenter`** (`lib/ui/intake/widgets/pages/home_screen/home_screen_presenter.dart`) - caller atual de `IntakeService.createAnalysis()`; hoje cria a analise sem tipo.
- **`RecentAnalysesSectionView`** (`lib/ui/intake/widgets/pages/home_screen/recent_analyses_section/recent_analyses_section_view.dart`) - resolve labels e estados visuais a partir do enum legado de status.
- **`AnalysisScreenPresenter`** (`lib/ui/intake/widgets/pages/analysis_screen/analysis_screen_presenter.dart`) - usa `PetitionSummaryDto`, `getPetitionSummary(petitionId)` e diversos guards baseados nos nomes antigos de status.
- **`RelevantPrecedentsBubblePresenter`** (`lib/ui/intake/widgets/pages/analysis_screen/relevant_precedents_bubble/relevant_precedents_bubble_presenter.dart`) - tambem depende do enum legado de status e do fluxo antigo de escolha de precedente.
- **`PetitionSummaryCardView`** (`lib/ui/intake/widgets/pages/analysis_screen/petition_summary_card/petition_summary_card_view.dart`) - consumidor visual direto do DTO de resumo atual.
- **`PetitionSummaryCardPresenter`** (`lib/ui/intake/widgets/pages/analysis_screen/petition_summary_card/petition_summary_card_presenter.dart`) - gera o texto de copiar resumo com base no DTO atual.

## Lacunas identificadas

- Nao existe nenhum DTO de `draft` em `lib/core/intake/dtos/`.
- Nao existe `AnalysisTypeDto` no `core`.
- Nao existe mapper REST para `petition draft` nem para `judgment draft`.
- Ainda nao existe UI dedicada para `lawyer` nem para `judge`; a unica tela atual e `analysis_screen`.
- O recorte de criacao por tipo e de rotas separadas ja foi desmembrado para `ANI-101`, portanto nao deve ser reintroduzido aqui.

---

# 5. O que deve ser criado?

## Camada Core (DTOs)

- **Localizacao:** `lib/core/intake/dtos/case_summary_dto.dart` (**novo arquivo**)
- **Atributos:** replicar os campos atuais de `PetitionSummaryDto` com os mesmos tipos Dart e `final`: `caseSummary`, `legalIssue`, `centralQuestion`, `relevantLaws`, `keyFacts`, `searchTerms`, `typeOfAction`, `jurisdictionIssue`, `standingIssue`, `secondaryLegalIssues`, `alternativeQuestions`, `requestedRelief`, `proceduralIssues`, `excludedOrAccessoryTopics`.
- **Factory `fromJson` (se aplicavel):** Nao aplicavel; o projeto concentra parsing na camada REST.

- **Localizacao:** `lib/core/intake/dtos/analysis_type_dto.dart` (**novo arquivo**)
- **Atributos:** enum `AnalysisTypeDto { lawyer, judge }` com `final String value` para o transporte remoto.
- **Factory `fromJson` (se aplicavel):** Nao aplicavel.

- **Localizacao:** `lib/core/intake/dtos/lawyer_analysis_status_dto.dart` (**novo arquivo**)
- **Atributos:** enum `LawyerAnalysisStatusDto` com `documentUploaded`, `analyzingCase`, `caseAnalyzed`, `searchingPrecedents`, `generatingPetitionDraft`, `done`, `failed` e `final String value`.
- **Factory `fromJson` (se aplicavel):** Nao aplicavel.

- **Localizacao:** `lib/core/intake/dtos/judge_analysis_status_dto.dart` (**novo arquivo**)
- **Atributos:** enum `JudgeAnalysisStatusDto` com `documentUploaded`, `extractingPetition`, `analyzingCase`, `caseAnalyzed`, `searchingPrecedents`, `generatingJudgmentDraft`, `done`, `failed` e `final String value`.
- **Factory `fromJson` (se aplicavel):** Nao aplicavel.

- **Localizacao:** `lib/core/intake/dtos/petition_draft_dto.dart` (**novo arquivo**)
- **Atributos:** `final String analysisId`, `final String content`.
- **Factory `fromJson` (se aplicavel):** Nao aplicavel.

- **Localizacao:** `lib/core/intake/dtos/judgment_draft_dto.dart` (**novo arquivo**)
- **Atributos:** `final String content`.
- **Factory `fromJson` (se aplicavel):** Nao aplicavel.

## Camada Core (Interfaces / Contratos)

**Nao aplicavel**.

## Camada REST (Services)

**Nao aplicavel**.

## Camada REST (Mappers)

- **Localizacao:** `lib/rest/mappers/intake/case_summary_mapper.dart` (**novo arquivo**)
- **Metodos:**
- `static CaseSummaryDto toDto(Map<String, dynamic> json)` - traduz o payload remoto do resumo do caso para `CaseSummaryDto`, preservando os mesmos fallbacks defensivos hoje usados por `PetitionSummaryMapper`.

- **Localizacao:** `lib/rest/mappers/intake/petition_draft_mapper.dart` (**novo arquivo**)
- **Metodos:**
- `static PetitionDraftDto toDto(Map<String, dynamic> json)` - traduz `analysis_id` e `content` para `PetitionDraftDto`.

- **Localizacao:** `lib/rest/mappers/intake/judgment_draft_mapper.dart` (**novo arquivo**)
- **Metodos:**
- `static JudgmentDraftDto toDto(Map<String, dynamic> json)` - traduz `content` para `JudgmentDraftDto`.

## Camada Drivers (Adaptadores)

**Nao aplicavel**.

## Camada UI (Presenters)

**Nao aplicavel**.

## Camada UI (Views)

**Nao aplicavel**.

## Camada UI (Widgets Internos)

**Nao aplicavel**.

## Camada UI (Barrel Files / `index.dart`)

**Nao aplicavel**.

## Camada UI (Providers Riverpod - se isolados)

**Nao aplicavel**.

## Rotas (`go_router`) - se aplicavel

**Nao aplicavel**.

## Estrutura de Pastas (Obrigatorio quando ha widgets internos)

**Nao aplicavel**.

---

# 6. O que deve ser modificado?

## Core

- **Arquivo:** `lib/core/intake/dtos/analysis_status_dto.dart`
- **Mudanca:** substituir os valores do fluxo antigo por um enum compartilhado do mobile com `waitingPetition` (apenas bootstrap local), `documentUploaded`, `extractingPetition`, `analyzingCase`, `caseAnalyzed`, `searchingPrecedents`, `generatingPetitionDraft`, `generatingJudgmentDraft`, `done` e `failed`.
- **Justificativa:** a UI atual ainda precisa de um enum unico para renderizacao, mas os valores remotos antigos `petitionUploaded`, `analyzingPetition`, `petitionAnalyzed`, `waitingPrecedentChoice` e `precedentChosen` deixaram de representar o contrato do server.

- **Arquivo:** `lib/core/intake/dtos/analysis_dto.dart`
- **Mudanca:** adicionar `final AnalysisTypeDto type`; manter `final AnalysisStatusDto status`; ajustar o construtor para exigir `type`.
- **Justificativa:** `AnalysisDto` passa a distinguir explicitamente `lawyer` e `judge`, e os callers da Home, Library e telas de detalhe precisam dessa informacao para rotular ou decidir comportamento futuro.

- **Arquivo:** `lib/core/intake/dtos/analysis_report_dto.dart`
- **Mudanca:** renomear `summary` para `caseSummary` e trocar o tipo para `CaseSummaryDto`.
- **Justificativa:** o agregado de exportacao deve refletir a nova nomenclatura de dominio sem manter alias paralelos.

- **Arquivo:** `lib/core/intake/dtos/analysis_petition_dto.dart`
- **Mudanca:** renomear `summary` para `caseSummary` e trocar o tipo para `CaseSummaryDto?`.
- **Justificativa:** manter consistencia com o novo vocabulario do dominio nas estruturas agregadas ja existentes.

- **Arquivo:** `lib/core/intake/interfaces/intake_service.dart`
- **Mudanca:**
- `Future<RestResponse<AnalysisDto>> createAnalysis({required AnalysisTypeDto type, String? folderId})` - cria a analise do tipo informado.
- `Future<RestResponse<CaseSummaryDto>> getCaseSummary({required String analysisId})` - busca o resumo do caso pelo `analysisId`.
- `Future<RestResponse<PetitionDraftDto>> getPetitionDraft({required String analysisId})` - busca o rascunho de peticao da analise de `lawyer`.
- `Future<RestResponse<JudgmentDraftDto>> getJudgmentDraft({required String analysisId})` - busca o rascunho de sentenca da analise de `judge`.
- `Future<RestResponse<AnalysisDto>> unarchiveAnalysis({required String analysisId})` - desfaz o arquivamento da analise.
- **Justificativa:** o `core` precisa refletir o novo contrato do server sem depender de tasks posteriores de UI.

## REST

- **Arquivo:** `lib/rest/mappers/intake/analysis_mapper.dart`
- **Mudanca:** mapear `type` para `AnalysisTypeDto` e traduzir os novos status remotos para o `AnalysisStatusDto` compartilhado do mobile; validar os valores contra `LawyerAnalysisStatusDto` ou `JudgeAnalysisStatusDto` conforme `type` antes de colapsar para o enum compartilhado.
- **Justificativa:** a desserializacao de `AnalysisDto` passa a depender de dois eixos do payload remoto (`type` e `status`) e precisa continuar devolvendo um objeto seguro para a UI atual.

- **Arquivo:** `lib/rest/mappers/intake/analysis_petition_mapper.dart`
- **Mudanca:** trocar `PetitionSummaryDto` por `CaseSummaryDto`, usar `CaseSummaryMapper` e renomear o campo agregado de saida para `caseSummary`.
- **Justificativa:** o agregado precisa refletir a nova linguagem de dominio sem manter nomes obsoletos.

- **Arquivo:** `lib/rest/mappers/intake/analysis_report_mapper.dart`
- **Mudanca:** trocar `PetitionSummaryMapper` por `CaseSummaryMapper` e preencher `caseSummary` em vez de `summary`.
- **Justificativa:** o mapper agregado do relatorio e o export em PDF dependem diretamente desse contrato.

- **Arquivo:** `lib/rest/services/intake_rest_service.dart`
- **Mudanca:**
- enviar `type.value` no body de `createAnalysis(...)`.
- substituir `getPetitionSummary(petitionId)` por `getCaseSummary(analysisId)` no endpoint de resumo do caso indexado por analise.
- implementar `getPetitionDraft(...)` usando `PetitionDraftMapper`.
- implementar `getJudgmentDraft(...)` usando `JudgmentDraftMapper` e o endpoint `GET /intake/analyses/{analysis_id}/judgment-draft` ja especificado em `ANI-114`.
- implementar `unarchiveAnalysis(...)` usando o endpoint `PATCH /intake/analyses/{analysis_id}/unarchive`, conforme `ANI-95`.
- **Justificativa:** toda evolucao de endpoint, payload e serializacao deve permanecer encapsulada em `lib/rest/`.

## Drivers

- **Arquivo:** `lib/core/shared/interfaces/pdf_driver.dart`
- **Mudanca:** nenhuma mudanca de assinatura; apenas alinhar o uso indireto de `AnalysisReportDto.caseSummary` no contrato agregado consumido pelos drivers.
- **Justificativa:** o driver nao muda de responsabilidade, mas o DTO agregado usado por ele muda de nomenclatura.

- **Arquivo:** `lib/drivers/pdf-driver/printing/printing_pdf_driver.dart`
- **Mudanca:** trocar todas as leituras de `report.summary.*` para `report.caseSummary.*`.
- **Justificativa:** o export ja existente deve continuar funcionando sobre o novo nome de DTO sem alterar layout ou comportamento do PDF.

## UI

- **Arquivo:** `lib/ui/intake/widgets/pages/home_screen/home_screen_presenter.dart`
- **Mudanca:** manter o metodo publico atual `Future<void> createAnalysis()`, mas fazer a chamada interna a `IntakeService.createAnalysis(type: AnalysisTypeDto.lawyer)`.
- **Justificativa:** preserva o comportamento atual da Home ate `ANI-101`, sem bloquear a introducao obrigatoria do parametro `type` no contrato de service.

- **Arquivo:** `lib/ui/intake/widgets/pages/home_screen/recent_analyses_section/recent_analyses_section_view.dart`
- **Mudanca:** substituir os labels e checks do enum antigo pelos novos nomes compartilhados do mobile; rotular estados de judge sem assumir a existencia de tela dedicada.
- **Justificativa:** a listagem recente e o primeiro ponto de contato com analises `judge`; ela nao pode depender de valores removidos do contrato remoto.

- **Arquivo:** `lib/ui/intake/widgets/pages/analysis_screen/analysis_screen_presenter.dart`
- **Mudanca:** trocar `PetitionSummaryDto` por `CaseSummaryDto`, substituir a chamada `getPetitionSummary(petitionId: ...)` por `getCaseSummary(analysisId: analysisId)`, e alinhar os guards de status aos nomes compartilhados novos (`documentUploaded`, `analyzingCase`, `caseAnalyzed`, `done`, `failed`).
- **Justificativa:** mesmo sendo uma tela transitoria, ela precisa continuar compilando e carregando o resumo do caso com o novo contrato do `core`.

- **Arquivo:** `lib/ui/intake/widgets/pages/analysis_screen/analysis_screen_view.dart`
- **Mudanca:** alinhar comparacoes de status e visibilidade de exportacao ao enum compartilhado novo, usando `done` no lugar do terminal antigo.
- **Justificativa:** a View atual nao pode continuar referenciando valores removidos do enum.

- **Arquivo:** `lib/ui/intake/widgets/pages/analysis_screen/relevant_precedents_bubble/relevant_precedents_bubble_presenter.dart`
- **Mudanca:** alinhar as comparacoes aos nomes novos do enum compartilhado, removendo dependencia direta de `waitingPrecedentChoice` e `precedentChosen`.
- **Justificativa:** o componente atual precisa continuar compilando enquanto o fluxo definitivo de lawyer nao e migrado para `ANI-103`.

- **Arquivo:** `lib/ui/intake/widgets/pages/analysis_screen/petition_summary_card/petition_summary_card_view.dart`
- **Mudanca:** trocar o tipo recebido para `CaseSummaryDto`, mantendo o widget e a estrutura visual atuais.
- **Justificativa:** a tela ainda reutiliza o mesmo card visual; a mudanca aqui e contratual, nao de UX.

- **Arquivo:** `lib/ui/intake/widgets/pages/analysis_screen/petition_summary_card/petition_summary_card_presenter.dart`
- **Mudanca:** trocar o tipo recebido para `CaseSummaryDto`, preservando o algoritmo atual de montagem do texto para clipboard.
- **Justificativa:** o presenter e consumidor direto do DTO renomeado.

---

# 7. O que deve ser removido?

## Core

- **Arquivo:** `lib/core/intake/dtos/petition_summary_dto.dart`
- **Motivo da remocao:** o dominio server e o ticket `ANI-115` migraram o conceito de `PetitionSummary` para `CaseSummary`.
- **Impacto esperado:** todos os imports e tipos precisam passar a usar `case_summary_dto.dart`.

- **Arquivo:** `lib/core/intake/dtos/analysis_status_dto.dart`
- **Motivo da remocao:** remover do enum compartilhado os valores legados `petitionUploaded`, `analyzingPetition`, `petitionAnalyzed`, `waitingPrecedentChoice` e `precedentChosen`.
- **Impacto esperado:** presenters e views que referenciam esses nomes precisam usar os novos nomes compartilhados do mobile.

## REST

- **Arquivo:** `lib/rest/mappers/intake/petition_summary_mapper.dart`
- **Motivo da remocao:** o mapper deve acompanhar a renomeacao oficial de dominio para `CaseSummaryMapper`.
- **Impacto esperado:** `analysis_report_mapper.dart`, `analysis_petition_mapper.dart`, `intake_rest_service.dart` e qualquer outro import devem passar a usar `case_summary_mapper.dart`.

---

# 8. Decisoes Tecnicas e Trade-offs

- **Decisao:** manter `AnalysisStatusDto` como enum compartilhado do mobile e criar `LawyerAnalysisStatusDto` / `JudgeAnalysisStatusDto` como enums adicionais de dominio.
- **Alternativas consideradas:** tipar `AnalysisDto.status` diretamente com dois enums diferentes; usar `String` cru no `AnalysisDto`; criar um `sealed class` hierarquico so para status.
- **Motivo da escolha:** a codebase atual tem muitos consumidores diretos de `AnalysisStatusDto`, e `ANI-103` ainda referencia um enum compartilhado; manter esse eixo reduz churn imediato sem abrir mao dos enums especificos pedidos por `ANI-115`.
- **Impactos / trade-offs:** o mobile passa a conviver com um enum compartilhado e dois enums especificos em paralelo; isso simplifica a migracao incremental, mas exige disciplina para que telas futuras usem o enum correto por fluxo.

- **Decisao:** `HomeScreenPresenter.createAnalysis()` continua sem parametro publico e envia internamente `AnalysisTypeDto.lawyer`.
- **Alternativas consideradas:** mudar a assinatura publica agora; bloquear a criacao de analise ate `ANI-101`; introduzir o dialog de selecao de tipo nesta mesma task.
- **Motivo da escolha:** `ANI-101` ja existe para tratar a criacao por tipo e a navegacao dedicada; este recorte precisa apenas destravar o contrato do service sem quebrar a Home atual.
- **Impactos / trade-offs:** o app continua criando apenas analises `lawyer` pela Home ate a entrega do dialog dedicado; isso e uma compatibilidade temporaria explicita, nao o estado final do produto.

- **Decisao:** nao renomear widgets visuais atuais (`petition_summary_card`, `analysis_screen`) nesta task.
- **Alternativas consideradas:** renomear todos os widgets e pastas para `case_summary_*`; reestruturar a tela atual em `lawyer_analysis_screen` imediatamente.
- **Motivo da escolha:** a tarefa e de dominio/contrato; a UI dedicada ja foi desmembrada para `ANI-103` e a renomeacao ampla agora geraria churn desnecessario em arquivos e imports.
- **Impactos / trade-offs:** permanecera uma discrepancia temporaria entre nome de widget e nome do DTO de dominio; isso deve ser resolvido junto da nova tela de lawyer, nao nesta fundacao tecnica.

- **Decisao:** atualizar `AnalysisReportDto` e `PrintingPdfDriver` para `caseSummary`, sem alterar a geracao de PDF.
- **Alternativas consideradas:** manter alias `summary` no DTO agregado; criar adaptador paralelo apenas para o PDF.
- **Motivo da escolha:** a nomenclatura do dominio deve ficar consistente em todos os contratos compartilhados; criar alias permanente so para um driver manteria divida tecnica no `core`.
- **Impactos / trade-offs:** o export existente precisa de ajuste mecanico em driver e presenter, mas o contrato agregado fica limpo e coerente.

---

# 9. Diagramas e Referencias

- **Fluxo de dados:**

```text
HomeScreenPresenter.createAnalysis()
  -> IntakeService.createAnalysis(type: AnalysisTypeDto.lawyer)
      -> IntakeRestService.createAnalysis(...)
          -> RestClient -> API

AnalysisScreenPresenter.load()
  -> IntakeService.getAnalysis(analysisId)
      -> IntakeRestService.getAnalysis(...)
          -> AnalysisMapper(type + status)
  -> IntakeService.getCaseSummary(analysisId)
      -> IntakeRestService.getCaseSummary(...)
          -> CaseSummaryMapper.toDto(...)
  -> View / PdfDriver consomem apenas DTOs tipados
```

- **Hierarquia de widgets (se aplicavel):** Nao aplicavel.

- **Referencias:**
- `lib/core/intake/dtos/petition_summary_dto.dart` - referencia direta para a estrutura do novo `CaseSummaryDto`.
- `lib/core/intake/dtos/analysis_status_dto.dart` - referencia para o ponto de migracao do status compartilhado atual.
- `lib/core/intake/interfaces/intake_service.dart` - contrato central a ser expandido.
- `lib/rest/mappers/intake/analysis_mapper.dart` - referencia para o mapeamento atual de status e para a adicao de `type`.
- `lib/rest/services/intake_rest_service.dart` - referencia para todos os novos metodos REST do modulo.
- `lib/ui/intake/widgets/pages/home_screen/home_screen_presenter.dart` - caller atual de criacao de analise.
- `lib/ui/intake/widgets/pages/analysis_screen/analysis_screen_presenter.dart` - consumidor atual de resumo e status.
- `lib/ui/intake/widgets/pages/home_screen/recent_analyses_section/recent_analyses_section_view.dart` - referencia real de labels de status exibidos ao usuario.
- `documentation/features/intake/analysis-exporting/specs/export-analysis-button-spec.md` - referencia interna de estilo de spec para mudancas multi-camada em `intake`.
- `documentation/features/intake/analysis-precedents/specs/precedents-searching-spec.md` - referencia interna de estilo de spec para ajustes em `analysis_screen` e seus presenters filhos.

---

# 10. Pendencias / Duvidas

- **Descricao da pendencia:** `ANI-103` ainda descreve a futura tela de lawyer como se existisse um unico `AnalysisStatusDto` atualizado, enquanto `ANI-115` e `ANI-92` pedem `LawyerAnalysisStatusDto` e `JudgeAnalysisStatusDto` separados.
- **Impacto na implementacao:** sem alinhamento, tasks futuras de UI podem assumir um modelo de status diferente do que `ANI-115` implantar no `core`.
- **Acao sugerida:** validar com produto/tech lead se `ANI-103` deve ser atualizado para consumir o enum compartilhado do mobile + os enums especificos, ou se o modelo final de status do mobile sera outro.

- **Descricao da pendencia:** a `analysis_screen` atual e um artefato legado do fluxo antigo; ela nao representa a arquitetura final de `RF 07` nem de `RF 08`.
- **Impacto na implementacao:** `ANI-115` deve limitar-se a compatibilidade contratual e nao deve ser usado como desculpa para crescer a tela atual com logica de lawyer/judge.
- **Acao sugerida:** manter a migracao funcional das telas em `ANI-103` e na task correspondente da tela de judge, reutilizando apenas os contratos entregues por esta spec.

- **Descricao da pendencia:** o frontmatter desta spec aponta para a pagina agregadora `Requisitos do produto`, enquanto o usuario forneceu diretamente o `RF 08` e o ticket cruza `RF 07` + `RF 08`.
- **Impacto na implementacao:** a origem funcional da task esta correta, mas reviews futuros podem precisar lembrar que este recorte suporta dois PRDs funcionais diferentes.
- **Acao sugerida:** manter como referencia primaria a pagina agregadora e citar `RF 07` / `RF 08` na descricao do ticket e no PR de implementacao.

---

# Restricoes

- **Nao inclua testes automatizados na spec.**
- A `View` nao deve conter logica de negocio; toda orquestracao continua fora da camada visual.
- Presenters nao fazem chamadas diretas a `RestClient`; consomem sempre `IntakeService` ou drivers do `core`.
- Todos os caminhos citados existem no projeto ou estao marcados como **novo arquivo**.
- Nenhum contrato acima depende de `Dio`, `BuildContext`, `GoRouter`, `pdf` ou qualquer SDK concreto no `core`.
- Todo ajuste de UI previsto aqui e mecanico e de compatibilidade; novas telas, novos widgets e nova navegacao por tipo ficam fora deste recorte.
- O `Presenter` da tela atual continua transitorio; a distribuicao correta da logica por widgets e telas dedicadas pertence a `ANI-103` e a task correspondente de judge.
- Use componentes Flutter Material ja presentes no projeto; esta spec nao introduz novo design system nem nova arvore visual.
