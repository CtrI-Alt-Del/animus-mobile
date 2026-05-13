---
title: Atualizacao de case summary, tipos e reports para analises de intake
prd: https://joaogoliveiragarcia.atlassian.net/wiki/x/AYDsAg
ticket: https://joaogoliveiragarcia.atlassian.net/browse/ANI-115
status: closed
last_updated_at: 2026-05-12
---

# 1. Objetivo

Alinhar o dominio mobile de `intake` ao contrato introduzido por `ANI-92`, preparando o app para os fluxos `RF 07` e `RF 08` sem vazar JSON cru para a UI. O recorte desta spec renomeia `PetitionSummaryDto` para `CaseSummaryDto`, introduz `AnalysisTypeDto`, publica enums explicitos para os tres tipos de analise (`CaseAssessmentAnalysis`, `FirstInstanceAnalysis` e `SecondInstanceAnalysis`), cria contracts agregados de report por tipo, atualiza `IntakeService` e `IntakeRestService` para os novos endpoints e mantem a `analysis_screen` atual como fluxo legado de `FirstInstanceAnalysis` com a menor mudanca correta para continuar compilando enquanto as telas dedicadas nao existem.

> **Atualizacao de direcionamento (2026-05-12):** o produto deixou de trabalhar com dois tipos (`lawyer` e `judge`) e passa a adotar tres tipos de analise no dominio: `CaseAssessmentAnalysis`, `FirstInstanceAnalysis` e `SecondInstanceAnalysis`. A `FirstInstanceAnalysis` corresponde ao fluxo ja implementado no app atual e deve ser o default de criacao enquanto os demais fluxos nao estiverem disponiveis na UI.

---

# 2. Escopo

## 2.1 In-scope

- Renomear o contrato de resumo de caso de `PetitionSummaryDto` para `CaseSummaryDto` no `core`, `rest` e consumidores ja existentes.
- Introduzir `AnalysisTypeDto` com os tipos `caseAssessment`, `firstInstance` e `secondInstance`.
- Criar `CaseAssessmentAnalysisStatusDto`, `FirstInstanceAnalysisStatusDto` e `SecondInstanceAnalysisStatusDto` no `core` para refletir a taxonomia do server.
- Manter `AnalysisDto.type` e `AnalysisDto.status` alinhados ao payload remoto, com mapeamento do status para o `AnalysisStatusDto` legado apenas como camada de compatibilidade para a UI atual.
- Atualizar `IntakeService` e `IntakeRestService` com `createAnalysis(type: ...)`, `getCaseSummary(...)`, `getPetitionDraft(...)`, `getJudgmentDraft(...)` e `unarchiveAnalysis(...)`.
- Criar os mappers REST necessarios para `CaseSummaryDto`, `PetitionDraftDto`, `JudgmentDraftDto` e para os reports `CaseAssessmentAnalysisReportDto`, `FirstInstanceAnalysisReportDto` e `SecondInstanceAnalysisReportDto`.
- Ajustar os consumidores atuais do app que dependem diretamente de `PetitionSummaryDto`, `getPetitionSummary(...)` ou dos nomes antigos de status, limitando a mudanca a compatibilidade de compilacao e leitura de dados.
- Manter a criacao atual de analise da Home apontando para `AnalysisTypeDto.firstInstance` ate a entrega do dialog de selecao por tipo em `ANI-101`.

## 2.2 Out-of-scope

- Criacao do dialog de selecao de tipo na Home (`ANI-101`).
- Criacao de telas dedicadas para `CaseAssessmentAnalysis` e `SecondInstanceAnalysis`.
- Split de rotas por tipo de analise.
- Novo layout, novos widgets ou nova hierarquia visual para os fluxos `RF 07` e `RF 08`.
- Reescrita funcional completa da `analysis_screen` atual para um fluxo tipado por tela dedicada.
- Qualquer alteracao em `design/animus.pen` ou validacao via Stitch; nenhum `screen_id` foi informado.

---

# 3. Requisitos

## 3.1 Funcionais

- O `core` deve expor `CaseSummaryDto` como substituto direto de `PetitionSummaryDto`, preservando os mesmos campos de negocio ja consumidos hoje pela UI e pelo PDF.
- O `core` deve expor `AnalysisTypeDto` com `caseAssessment`, `firstInstance` e `secondInstance`, para que a criacao e leitura de analises distingam explicitamente os tres fluxos.
- O `core` deve expor `CaseAssessmentAnalysisStatusDto`, `FirstInstanceAnalysisStatusDto` e `SecondInstanceAnalysisStatusDto` como enums independentes, refletindo os status do server.
- `AnalysisDto` deve carregar `type: AnalysisTypeDto`, e `AnalysisMapper` deve traduzir o status remoto para o `AnalysisStatusDto` legado consumido pela UI atual conforme o tipo da analise.
- `IntakeService.createAnalysis({required AnalysisTypeDto type, String? folderId})` deve se tornar obrigatoriamente tipado por analise.
- `IntakeService.getCaseSummary({required String analysisId})` deve substituir `getPetitionSummary({required String petitionId})`, eliminando a dependencia da UI de conhecer o `petitionId` para carregar o resumo.
- `IntakeService.getPetitionDraft({required String analysisId})` deve retornar `PetitionDraftDto`.
- `IntakeService.getJudgmentDraft({required String analysisId})` deve retornar `JudgmentDraftDto`.
- `IntakeService.unarchiveAnalysis({required String analysisId})` deve retornar `AnalysisDto` com o estado atualizado.
- `IntakeRestService` deve mapear `type` e os novos status ao desserializar `AnalysisDto`.
- `IntakeRestService` deve enviar `type` no `POST` de criacao de analise.
- O fluxo atual da Home deve continuar criando uma analise valida mesmo antes de `ANI-101`; para isso, o caller atual deve enviar `AnalysisTypeDto.firstInstance`.
- Os consumidores atuais de listagem/status na Home devem continuar rotulando `FirstInstanceAnalysis` sem cair em status desconhecido, preservando a semantica visual ja existente.
- Os contratos agregados de report devem ser separados por tipo: `CaseAssessmentAnalysisReportDto`, `FirstInstanceAnalysisReportDto` e `SecondInstanceAnalysisReportDto`.
- A exportacao atual da `analysis_screen` deve consumir `FirstInstanceAnalysisReportDto`, porque a tela atual representa o fluxo de `FirstInstanceAnalysis`.

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
- **`AnalysisStatusDto`** (`lib/core/intake/dtos/analysis_status_dto.dart`) - objeto legado compartilhado do mobile, mantido como camada de compatibilidade para a UI atual enquanto os tipos de analise ainda nao possuem telas dedicadas.
- **`PetitionSummaryDto`** (`lib/core/intake/dtos/petition_summary_dto.dart`) - contrato atual de resumo; serve de referencia direta para `CaseSummaryDto`.
- **`FirstInstanceAnalysisReportDto`** (`lib/core/intake/dtos/first_instance_analysis_report_dto.dart`) - agregado usado pelo export em PDF da `analysis_screen` atual.
- **`AnalysisPetitionDto`** (`lib/core/intake/dtos/analysis_petition_dto.dart`) - DTO agregado que tambem carrega o resumo atual como `summary` opcional.
- **`IntakeService`** (`lib/core/intake/interfaces/intake_service.dart`) - contrato central do modulo `intake`; hoje ainda expoe `createAnalysis()` sem tipo e `getPetitionSummary(petitionId)`.

## REST

- **`IntakeRestService`** (`lib/rest/services/intake_rest_service.dart`) - implementacao concreta de `IntakeService`; ja concentra criacao de analise, resumo, listagem, export e escolha de precedente.
- **`AnalysisMapper`** (`lib/rest/mappers/intake/analysis_mapper.dart`) - mapper atual de `AnalysisDto`; ja traduz `status` string para enum do mobile.
- **`PetitionSummaryMapper`** (`lib/rest/mappers/intake/petition_summary_mapper.dart`) - referencia direta para a renomeacao de mapper.
- **`AnalysisReportMapper`** (`lib/rest/mappers/intake/analysis_report_mapper.dart`) - mapper agregado que hoje usa `PetitionSummaryMapper` e popula `summary`.
- **`AnalysisPetitionMapper`** (`lib/rest/mappers/intake/analysis_petition_mapper.dart`) - mapper agregado que hoje popula `summary` ou `petition_summary`.

## Drivers

- **`PdfDriver`** (`lib/core/shared/interfaces/pdf_driver.dart`) - contrato de geracao e compartilhamento de PDF que hoje consome `FirstInstanceAnalysisReportDto` para sustentar a `analysis_screen` atual.
- **`PrintingPdfDriver`** (`lib/drivers/pdf-driver/printing/printing_pdf_driver.dart`) - implementacao atual que acessa `report.caseSummary.*`, `report.document.*` e resolve o precedente escolhido a partir de `report.precedents`.

## UI

- **`HomeScreenPresenter`** (`lib/ui/intake/widgets/pages/home_screen/home_screen_presenter.dart`) - caller atual de `IntakeService.createAnalysis()`; hoje cria explicitamente uma analise `firstInstance`.
- **`RecentAnalysesSectionView`** (`lib/ui/intake/widgets/pages/home_screen/recent_analyses_section/recent_analyses_section_view.dart`) - resolve labels e estados visuais a partir do enum legado de status.
- **`AnalysisScreenPresenter`** (`lib/ui/intake/widgets/pages/analysis_screen/analysis_screen_presenter.dart`) - usa `CaseSummaryDto`, `getCaseSummary(analysisId)` e preserva guards baseados no `AnalysisStatusDto` legado, agora alimentado pelo mapeamento de `FirstInstanceAnalysisStatusDto`.
- **`RelevantPrecedentsBubblePresenter`** (`lib/ui/intake/widgets/pages/analysis_screen/relevant_precedents_bubble/relevant_precedents_bubble_presenter.dart`) - continua dependente do `AnalysisStatusDto` legado e do fluxo atual de escolha de precedente, sustentado pelo mapeamento de compatibilidade do fluxo de `firstInstance`.
- **`PetitionSummaryCardView`** (`lib/ui/intake/widgets/pages/analysis_screen/petition_summary_card/petition_summary_card_view.dart`) - consumidor visual direto do DTO de resumo atual.
- **`PetitionSummaryCardPresenter`** (`lib/ui/intake/widgets/pages/analysis_screen/petition_summary_card/petition_summary_card_presenter.dart`) - gera o texto de copiar resumo com base no DTO atual.

## Lacunas identificadas

- Nao existe nenhum DTO de `draft` em `lib/core/intake/dtos/`.
- Nao existe `AnalysisTypeDto` no `core`.
- Nao existe mapper REST para `petition draft` nem para `judgment draft`.
- Ainda nao existe UI dedicada para `caseAssessment` nem para `secondInstance`; a unica tela atual continua sendo a `analysis_screen`, que corresponde ao fluxo de `firstInstance`.
- O recorte de criacao por tipo e de rotas separadas ja foi desmembrado para `ANI-101`, portanto nao deve ser reintroduzido aqui.

---

# 5. O que deve ser criado?

## Camada Core (DTOs)

- **Localizacao:** `lib/core/intake/dtos/case_summary_dto.dart` (**novo arquivo**)
- **Atributos:** replicar os campos atuais de `PetitionSummaryDto` com os mesmos tipos Dart e `final`: `caseSummary`, `legalIssue`, `centralQuestion`, `relevantLaws`, `keyFacts`, `searchTerms`, `typeOfAction`, `jurisdictionIssue`, `standingIssue`, `secondaryLegalIssues`, `alternativeQuestions`, `requestedRelief`, `proceduralIssues`, `excludedOrAccessoryTopics`.
- **Factory `fromJson` (se aplicavel):** Nao aplicavel; o projeto concentra parsing na camada REST.

- **Localizacao:** `lib/core/intake/dtos/analysis_type_dto.dart` (**novo arquivo**)
- **Atributos:** enum `AnalysisTypeDto { caseAssessment, firstInstance, secondInstance }` com `final String value` para o transporte remoto.
- **Factory `fromJson` (se aplicavel):** Nao aplicavel.

- **Localizacao:** `lib/core/intake/dtos/case_assessment_analysis_status_dto.dart` (**novo arquivo**)
- **Atributos:** enum `CaseAssessmentAnalysisStatusDto` com `waitingDocumentUpload`, `documentUploaded`, `analyzingCase`, `caseAnalyzed`, `searchingPrecedents`, `analyzingPrecedentsSimilarity`, `analyzingPrecedentsApplicability`, `generatingPetitionDraft`, `done`, `failed` e `final String value`.
- **Factory `fromJson` (se aplicavel):** Nao aplicavel.

- **Localizacao:** `lib/core/intake/dtos/first_instance_analysis_status_dto.dart` (**novo arquivo**)
- **Atributos:** enum `FirstInstanceAnalysisStatusDto` com `waitingDocumentUpload`, `documentUploaded`, `analyzingCase`, `caseAnalyzed`, `searchingPrecedents`, `analyzingPrecedentsSimilarity`, `analyzingPrecedentsApplicability`, `done`, `failed` e `final String value`.

- **Localizacao:** `lib/core/intake/dtos/second_instance_analysis_status_dto.dart` (**novo arquivo**)
- **Atributos:** enum `SecondInstanceAnalysisStatusDto` com `waitingDocumentUpload`, `documentUploaded`, `extractingPetition`, `analyzingCase`, `caseAnalyzed`, `searchingPrecedents`, `analyzingPrecedentsSimilarity`, `analyzingPrecedentsApplicability`, `generatingJudgmentDraft`, `done`, `failed` e `final String value`.
- **Factory `fromJson` (se aplicavel):** Nao aplicavel.

- **Localizacao:** `lib/core/intake/dtos/petition_draft_dto.dart` (**novo arquivo**)
- **Atributos:** `final String analysisId`, `final String content`.
- **Factory `fromJson` (se aplicavel):** Nao aplicavel.

- **Localizacao:** `lib/core/intake/dtos/judgment_draft_dto.dart` (**novo arquivo**)
- **Atributos:** `final String content`.
- **Factory `fromJson` (se aplicavel):** Nao aplicavel.

- **Localizacao:** `lib/core/intake/dtos/first_instance_analysis_report_dto.dart` (**novo arquivo**)
- **Atributos:** `final AnalysisDto analysis`, `final AnalysisDocumentDto document`, `final CaseSummaryDto caseSummary`, `final List<AnalysisPrecedentDto> precedents`, `final JudgmentDraftDto judgmentDraft`.
- **Factory `fromJson` (se aplicavel):** Nao aplicavel.

- **Localizacao:** `lib/core/intake/dtos/case_assessment_analysis_report_dto.dart` (**novo arquivo**)
- **Atributos:** `final AnalysisDto analysis`, `final AnalysisDocumentDto document`, `final CaseSummaryDto caseSummary`, `final List<AnalysisPrecedentDto> precedents`, `final PetitionDraftDto petitionDraft`.

- **Localizacao:** `lib/core/intake/dtos/second_instance_analysis_report_dto.dart` (**novo arquivo**)
- **Atributos:** `final AnalysisDto analysis`, `final AnalysisDocumentDto document`, `final CaseSummaryDto caseSummary`, `final List<AnalysisPrecedentDto> precedents`, `final AnalysisPrecedentDto? chosenPrecedent`.
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

- **Arquivo:** `lib/core/intake/dtos/analysis_dto.dart`
- **Mudanca:** adicionar `final AnalysisTypeDto type`, mantendo `AnalysisStatusDto status` no DTO consumido pela UI atual.
- **Justificativa:** o app passa a distinguir explicitamente `caseAssessment`, `firstInstance` e `secondInstance`, mas a UI atual ainda depende do `AnalysisStatusDto` legado para preservar o fluxo existente com a menor mudanca correta.

- **Arquivo:** `lib/core/intake/interfaces/intake_service.dart`
- **Mudanca:** adicionar `getCaseAssessmentAnalysisReport(...)`, `getFirstInstanceAnalysisReport(...)` e `getSecondInstanceAnalysisReport(...)`, mantendo `createAnalysis(type: ...)`, `getCaseSummary(...)`, `getPetitionDraft(...)`, `getJudgmentDraft(...)` e `unarchiveAnalysis(...)`.
- **Justificativa:** o `core` precisa refletir os novos contratos agregados de report por tipo e os endpoints separados expostos pelo server.

- **Arquivo:** `lib/core/intake/dtos/analysis_petition_dto.dart`
- **Mudanca:** renomear `summary` para `caseSummary` e trocar o tipo para `CaseSummaryDto?`.
- **Justificativa:** manter consistencia com o novo vocabulario do dominio nas estruturas agregadas ja existentes.

## REST

- **Arquivo:** `lib/rest/mappers/intake/analysis_mapper.dart`
- **Mudanca:** mapear `type` para `AnalysisTypeDto` e traduzir o status remoto para `AnalysisStatusDto` conforme `type`, preservando a semantica atual da UI para o fluxo de `firstInstance`.
- **Justificativa:** a desserializacao de `AnalysisDto` passa a depender de dois eixos do payload remoto (`type` e `status`), mas a UI atual ainda precisa continuar operando com o contrato legado compartilhado.

- **Arquivo:** `lib/rest/mappers/intake/analysis_petition_mapper.dart`
- **Mudanca:** trocar `PetitionSummaryDto` por `CaseSummaryDto`, usar `CaseSummaryMapper` e renomear o campo agregado de saida para `caseSummary`.
- **Justificativa:** o agregado precisa refletir a nova linguagem de dominio sem manter nomes obsoletos.

- **Arquivo:** `lib/rest/mappers/intake/case_assessment_analysis_report_mapper.dart`, `lib/rest/mappers/intake/first_instance_analysis_report_mapper.dart` e `lib/rest/mappers/intake/second_instance_analysis_report_mapper.dart`
- **Mudanca:** criar mappers agregados separados por tipo de report, consumindo `CaseSummaryMapper` e os drafts/documentos correspondentes.
- **Justificativa:** os payloads agregados deixaram de ser um unico `AnalysisReportDto` e passaram a ser especializados por tipo de analise.

- **Arquivo:** `lib/rest/services/intake_rest_service.dart`
- **Mudanca:**
- enviar `type.value` no body de `createAnalysis(...)`.
- substituir `getPetitionSummary(petitionId)` por `getCaseSummary(analysisId)` no endpoint de resumo do caso indexado por analise.
- implementar `getPetitionDraft(...)` usando `PetitionDraftMapper`.
- implementar `getJudgmentDraft(...)` usando `JudgmentDraftMapper` e o endpoint `GET /intake/analyses/{analysis_id}/judgment-draft` ja especificado em `ANI-114`.
- implementar `getCaseAssessmentAnalysisReport(...)` usando `GET /intake/analyses/{analysis_id}/case-assessment-analysis-report`.
- implementar `getFirstInstanceAnalysisReport(...)` usando `GET /intake/analyses/{analysis_id}/first-instance-analysis-report`.
- implementar `getSecondInstanceAnalysisReport(...)` usando `GET /intake/analyses/{analysis_id}/second-instance-analysis-report`.
- implementar `unarchiveAnalysis(...)` usando o endpoint `PATCH /intake/analyses/{analysis_id}/unarchive`, conforme `ANI-95`.
- **Justificativa:** toda evolucao de endpoint, payload e serializacao deve permanecer encapsulada em `lib/rest/`.

## Drivers

- **Arquivo:** `lib/core/shared/interfaces/pdf_driver.dart`
- **Mudanca:** passar a consumir `FirstInstanceAnalysisReportDto` no contrato de geracao do PDF da tela atual.
- **Justificativa:** a `analysis_screen` atual representa o fluxo de `FirstInstanceAnalysis`, logo o contrato de exportacao usado por ela deve refletir esse report especifico.

- **Arquivo:** `lib/drivers/pdf-driver/printing/printing_pdf_driver.dart`
- **Mudanca:** consumir `report.caseSummary.*`, `report.document.*` e detectar o precedente escolhido por `precedent.isChosen` dentro de `report.precedents`.
- **Justificativa:** o export atual deixa de depender do agregado antigo e passa a refletir a estrutura real de `FirstInstanceAnalysisReportDto`.

## UI

- **Arquivo:** `lib/ui/intake/widgets/pages/home_screen/home_screen_presenter.dart`
- **Mudanca:** manter o metodo publico atual `Future<void> createAnalysis()`, mas fazer a chamada interna a `IntakeService.createAnalysis(type: AnalysisTypeDto.firstInstance)`.
- **Justificativa:** preserva o comportamento atual da Home ate `ANI-101`, sem bloquear a introducao obrigatoria do parametro `type` no contrato de service.

- **Arquivo:** `lib/ui/intake/widgets/pages/home_screen/recent_analyses_section/recent_analyses_section_view.dart`
- **Mudanca:** manter a listagem baseada em `AnalysisStatusDto`, com labels preservados para o fluxo atual de `firstInstance` sustentado pelo mapeamento de compatibilidade no `AnalysisMapper`.
- **Justificativa:** a Home continua operando sobre o fluxo legado implementado; o recorte atual nao introduz telas ou labels finais dedicadas para os demais tipos.

- **Arquivo:** `lib/ui/intake/widgets/pages/analysis_screen/analysis_screen_presenter.dart`
- **Mudanca:** trocar `PetitionSummaryDto` por `CaseSummaryDto`, substituir `getPetitionSummary(...)` por `getCaseSummary(analysisId: analysisId)` e consumir `getFirstInstanceAnalysisReport(...)` no export.
- **Justificativa:** a tela atual continua transitoria, mas corresponde explicitamente ao fluxo de `FirstInstanceAnalysis` e precisa usar o report correto desse tipo.

- **Arquivo:** `lib/ui/intake/widgets/pages/analysis_screen/analysis_screen_view.dart`
- **Mudanca:** nao aplicavel alem da compatibilidade automatica provida pelo mapeamento do `AnalysisStatusDto` legado.
- **Justificativa:** a View atual continua compilando sem reescrita estrutural porque o contrato consumido pela tela foi preservado por compatibilidade.

- **Arquivo:** `lib/ui/intake/widgets/pages/analysis_screen/relevant_precedents_bubble/relevant_precedents_bubble_presenter.dart`
- **Mudanca:** nao aplicavel alem da compatibilidade automatica provida pelo mapeamento do `AnalysisStatusDto` legado.
- **Justificativa:** o componente continua dependente do fluxo atual de precedentes e nao foi reestruturado nesta task.

- **Arquivo:** `lib/ui/intake/widgets/pages/analysis_screen/petition_summary_card/petition_summary_card_view.dart`
- **Mudanca:** trocar o tipo recebido para `CaseSummaryDto`, mantendo o widget e a estrutura visual atuais.
- **Justificativa:** a tela ainda reutiliza o mesmo card visual; a mudanca aqui e contratual, nao de UX.

- **Arquivo:** `lib/ui/intake/widgets/pages/analysis_screen/petition_summary_card/petition_summary_card_presenter.dart`
- **Mudanca:** trocar o tipo recebido para `CaseSummaryDto`, preservando o algoritmo atual de montagem do texto para clipboard.
- **Justificativa:** o presenter e consumidor direto do DTO renomeado.

---

# 7. O que deve ser removido?

Não aplicável.

---

# 8. Decisoes Tecnicas e Trade-offs

- **Decisao:** manter `AnalysisStatusDto` como contrato legado de compatibilidade na UI atual, mesmo introduzindo enums especificos por tipo no `core`.
- **Alternativas consideradas:** remover `AnalysisStatusDto` imediatamente; migrar toda a UI atual para enums por tipo nesta mesma task.
- **Motivo da escolha:** `FirstInstanceAnalysis` corresponde exatamente ao fluxo ja implementado na `analysis_screen` e na Home; preservar a semantica atual via mapeamento evita reescrita ampla da UI antes das telas dedicadas.
- **Impactos / trade-offs:** o `core` passa a ter enums mais fieis ao backend, mas a UI continua dependendo de uma camada de compatibilidade temporaria ate a migracao funcional das telas.

- **Decisao:** `HomeScreenPresenter.createAnalysis()` continua sem parametro publico e envia internamente `AnalysisTypeDto.firstInstance`.
- **Alternativas consideradas:** mudar a assinatura publica agora; bloquear a criacao de analise ate `ANI-101`; introduzir o dialog de selecao de tipo nesta mesma task.
- **Motivo da escolha:** `ANI-101` ja existe para tratar a criacao por tipo e a navegacao dedicada; este recorte precisa apenas destravar o contrato do service sem quebrar a Home atual.
- **Impactos / trade-offs:** o app continua criando apenas analises `firstInstance` pela Home ate a entrega do dialog dedicado; isso e uma compatibilidade temporaria explicita, nao o estado final do produto.

- **Decisao:** nao renomear widgets visuais atuais (`petition_summary_card`, `analysis_screen`) nesta task.
- **Alternativas consideradas:** renomear todos os widgets e pastas para `case_summary_*`; reestruturar a tela atual em `first_instance_analysis_screen` imediatamente.
- **Motivo da escolha:** a tarefa e de dominio/contrato; a `analysis_screen` atual deve ser mantida como artefato legado de compatibilidade, enquanto as telas dedicadas por tipo permanecem fora deste recorte.
- **Impactos / trade-offs:** permanecera uma discrepancia temporaria entre nome de widget e nome do DTO de dominio; isso deve ser resolvido junto das telas dedicadas por tipo, nao nesta fundacao tecnica.

- **Decisao:** separar os reports por tipo e fazer a `analysis_screen` atual exportar via `FirstInstanceAnalysisReportDto`.
- **Alternativas consideradas:** manter um unico `AnalysisReportDto`; exportar a tela atual com `SecondInstanceAnalysisReportDto` enquanto a UI dedicada nao existe.
- **Motivo da escolha:** a tela atual representa `FirstInstanceAnalysis`, entao o contrato de export usado por ela deve refletir esse fluxo real e nao um tipo diferente de analise.
- **Impactos / trade-offs:** o export atual continua funcional com mudanca localizada em presenter, driver e testes, enquanto os outros reports ficam prontos para consumo por futuras telas dedicadas.

---

# 9. Diagramas e Referencias

- **Fluxo de dados:**

```text
HomeScreenPresenter.createAnalysis()
  -> IntakeService.createAnalysis(type: AnalysisTypeDto.firstInstance)
      -> IntakeRestService.createAnalysis(...)
          -> RestClient -> API

AnalysisScreenPresenter.load()
  -> IntakeService.getAnalysis(analysisId)
      -> IntakeRestService.getAnalysis(...)
          -> AnalysisMapper(type + status -> AnalysisStatusDto compat)
  -> IntakeService.getCaseSummary(analysisId)
      -> IntakeRestService.getCaseSummary(...)
          -> CaseSummaryMapper.toDto(...)
  -> IntakeService.getFirstInstanceAnalysisReport(analysisId)
      -> IntakeRestService.getFirstInstanceAnalysisReport(...)
          -> FirstInstanceAnalysisReportMapper.toDto(...)
  -> View / PdfDriver consomem apenas DTOs tipados
```

- **Hierarquia de widgets (se aplicavel):** Nao aplicavel.

- **Referencias:**
- `https://joaogoliveiragarcia.atlassian.net/wiki/x/AYDsAg` - `RF 07`, referencia funcional primaria deste recorte.
- `https://joaogoliveiragarcia.atlassian.net/wiki/x/AQDxAg` - `RF 08`, referencia funcional complementar para os fluxos adicionais de intake fora da tela atual.
- `lib/core/intake/dtos/petition_summary_dto.dart` - referencia direta para a estrutura do novo `CaseSummaryDto`.
- `lib/core/intake/dtos/analysis_status_dto.dart` - referencia do contrato legado mantido como compatibilidade para a UI atual.
- `lib/core/intake/interfaces/intake_service.dart` - contrato central a ser expandido.
- `lib/rest/mappers/intake/analysis_mapper.dart` - referencia para o mapeamento atual de status e para a adicao de `type`.
- `lib/rest/services/intake_rest_service.dart` - referencia para todos os novos metodos REST do modulo.
- `lib/ui/intake/widgets/pages/home_screen/home_screen_presenter.dart` - caller atual de criacao de analise.
- `lib/ui/intake/widgets/pages/analysis_screen/analysis_screen_presenter.dart` - consumidor atual de resumo e status.
- `lib/ui/intake/widgets/pages/home_screen/recent_analyses_section/recent_analyses_section_view.dart` - referencia real de labels de status exibidos ao usuario.
- `documentation/features/intake/analysis-exporting/specs/export-analysis-button-spec.md` - referencia interna de estilo de spec para mudancas multi-camada em `intake`.
- `documentation/features/intake/analysis-precedents/specs/precedents-searching-spec.md` - referencia interna de estilo de spec para ajustes em `analysis_screen` e seus presenters filhos.

---

# 10. Alinhamentos Fechados

- **Status da analise:** os enums tipados por tipo (`CaseAssessmentAnalysisStatusDto`, `FirstInstanceAnalysisStatusDto`, `SecondInstanceAnalysisStatusDto`) passam a refletir o contrato do backend, enquanto `AnalysisStatusDto` permanece como compatibilidade para a UI atual.
- **Tela legada:** a `analysis_screen` atual corresponde explicitamente ao fluxo de `FirstInstanceAnalysis`, inclusive no export do report; a migracao funcional para telas dedicadas continua fora deste recorte.
- **Referencia funcional:** esta spec usa `RF 07` como referencia primaria do fluxo hoje implementado na UI e cita `RF 08` apenas como referencia complementar para os demais fluxos ainda sem tela dedicada.

---

# Restricoes

- **Nao inclua testes automatizados na spec.**
- A `View` nao deve conter logica de negocio; toda orquestracao continua fora da camada visual.
- Presenters nao fazem chamadas diretas a `RestClient`; consomem sempre `IntakeService` ou drivers do `core`.
- Todos os caminhos citados existem no projeto ou estao marcados como **novo arquivo**.
- Nenhum contrato acima depende de `Dio`, `BuildContext`, `GoRouter`, `pdf` ou qualquer SDK concreto no `core`.
- Todo ajuste de UI previsto aqui e mecanico e de compatibilidade; novas telas, novos widgets e nova navegacao por tipo ficam fora deste recorte.
- O `Presenter` da tela atual continua transitorio; a distribuicao correta da logica por widgets e telas dedicadas permanece fora deste recorte.
- Use componentes Flutter Material ja presentes no projeto; esta spec nao introduz novo design system nem nova arvore visual.
