---
title: Exportacao PDF da minuta da analise de segunda instancia do juiz
prd: https://joaogoliveiragarcia.atlassian.net/wiki/x/AQDxAg
ticket: https://joaogoliveiragarcia.atlassian.net/browse/ANI-106
status: closed
last_updated_at: 2026-05-22
---

# 1. Objetivo

Implementar no mobile o fluxo de **exportacao em PDF da minuta de sentenca da analise de segunda instancia do perfil Juiz**, reaproveitando a `SecondInstanceAnalysisScreenView`, consumindo o endpoint dedicado `GET /intake/analyses/{analysis_id}/second-instance-analysis-report`, mapeando o payload agregado para um DTO tipado, gerando o PDF em memoria com `PdfDriver` e acionando o compartilhamento nativo do dispositivo com feedback de loading e erro no header da tela.

---

# 2. Escopo

## 2.1 In-scope

- Expor a acao **Exportar PDF** no `AnalysisHeader` da `SecondInstanceAnalysisScreenView` somente quando a analise estiver em `DONE` e houver minuta carregada.
- Criar o contrato mobile `SecondInstanceAnalysisReportDto` alinhado ao endpoint server `second-instance-analysis-report`.
- Criar mapper REST para o payload agregado do relatorio do Juiz.
- Adicionar `IntakeService.getSecondInstanceAnalysisReport(...)` e sua implementacao em `IntakeRestService`.
- Adicionar capacidade em `PdfDriver` para gerar PDF a partir de `SecondInstanceAnalysisReportDto`.
- Montar PDF com cabecalho, dados da analise, dados do documento, resumo do caso, minuta estruturada e precedentes associados.
- Ajustar a validacao local de upload da `SecondInstanceAnalysisScreenView` para aceitar apenas PDF com limite de **100MB**, refletindo a copia de apoio da tela.
- Incluir aviso de ausencia de precedentes fortes no PDF quando `judgmentDraft.noApplicablePrecedentNotice` estiver preenchido.
- Compartilhar o PDF por `Printing.sharePdf` via `PdfDriver.sharePdf(...)` ja existente.
- Controlar concorrencia de exportacao no presenter da tela.
- Exibir estado visual `Exportando PDF...` e indicador no item do menu ja existente em `AnalysisHeaderActionsView`.
- Exibir erro amigavel no fluxo da tela quando a busca do relatorio, geracao ou compartilhamento falhar.

## 2.2 Out-of-scope

- Criar uma nova `SecondInstanceAnalysisScreenView`; a tela existente de 2ª instancia sera reutilizada.
- Alterar o fluxo de upload, analise, busca de precedentes ou geracao da minuta, exceto pelo ajuste local de validacao de PDF para **100MB** na tela de 2ª instancia.
- Editar a minuta dentro do app.
- Exportar em formatos diferentes de PDF.
- Personalizar layout ou conteudo do PDF pelo usuario.
- Enviar o PDF automaticamente por e-mail.
- Exportar multiplas analises em um unico arquivo.
- Alterar `design/animus.pen`.

---

# 3. Requisitos

## 3.1 Funcionais

- A tela deve exibir **Exportar PDF** apenas quando `status == AnalysisStatusDto.done`, `judgmentDraft != null` e nao houver operacao concorrente.
- Ao tocar em **Exportar PDF**, a `View` deve delegar para o `Presenter` sem acessar service, driver ou regra de negocio.
- O presenter deve buscar o relatorio agregado por `IntakeService.getSecondInstanceAnalysisReport(analysisId: analysisId)`.
- O service REST deve consumir `GET /intake/analyses/{analysis_id}/second-instance-analysis-report`.
- O mapper deve converter `analysis`, `document`, `case_summary`, `precedents` e `judgment_draft` para DTOs do `core`.
- O PDF deve conter, nesta ordem: cabecalho, dados da analise/documento, resumo do caso, minuta estruturada e precedentes associados.
- A minuta no PDF deve conter `report`, `preliminaryIssues` quando existir, `meritAnalysis`, `precedentAdherenceAnalysis`, `ruling` e `noApplicablePrecedentNotice` quando existir.
- A tela de 2ª instancia deve bloquear localmente arquivos acima de **100MB** antes do upload e manter a orientacao visual coerente com esse limite.
- Cada precedente no PDF deve exibir identificador, tese/enunciado quando disponiveis, percentual de similaridade, nivel de aplicabilidade e sintese explicativa.
- O nome do arquivo deve seguir `[Nome da analise] - Minuta de Sentenca.pdf`, sanitizando caracteres invalidos para nome de arquivo.
- Em falha, a tela deve manter o usuario na analise e preencher `generalError` com mensagem amigavel.

## 3.2 Não funcionais

- **Performance:** o PDF deve ser gerado em memoria como `Uint8List`, sem gravacao manual em disco pelo app.
- **Acessibilidade:** o item de exportacao deve preservar texto visivel no menu e indicador de progresso ja existente.
- **Segurança:** o presenter nao deve logar ou persistir conteudo da minuta, precedentes ou bytes do PDF.
- **Offline/Conectividade:** sem rede, a falha de busca do relatorio deve ser tratada por `RestResponse` e exibida como erro amigavel.
- **Arquitetura:** `View` nao deve conhecer `RestClient`, endpoint, `pdf` ou `printing`; o presenter deve consumir `IntakeService` e `PdfDriver` por providers.
- **Concorrencia:** enquanto `isExportingReport == true`, renomear, arquivar e nova exportacao devem ficar bloqueados pelo mesmo gate de gerenciamento da tela.

---

# 4. O que já existe?

## Core

- **`AnalysisDto`** (`lib/core/intake/dtos/analysis_dto.dart`) — DTO da analise usado no relatorio e no nome do arquivo.
- **`AnalysisDocumentDto`** (`lib/core/intake/dtos/analysis_document_dto.dart`) — DTO do documento base da analise.
- **`CaseSummaryDto`** (`lib/core/intake/dtos/case_summary_dto.dart`) — DTO do resumo do caso a ser renderizado no PDF.
- **`AnalysisPrecedentDto`** (`lib/core/intake/dtos/analysis_precedent_dto.dart`) — DTO dos precedentes com `synthesis`, `similarityScore`, `finalRank` e `applicabilityLevel`.
- **`SecondInstanceJudgmentDraftDto`** (`lib/core/intake/dtos/second_instance_judgment_draft_dto.dart`) — DTO da minuta estruturada ja consumido pela tela.
- **`IntakeService`** (`lib/core/intake/interfaces/intake_service.dart`) — interface de dominio que ja expoe operacoes da analise e sera estendida para o relatorio do Juiz.
- **`PdfDriver`** (`lib/core/shared/interfaces/pdf_driver.dart`) — interface de geracao/compartilhamento de PDF, hoje restrita a `FirstInstanceAnalysisReportDto`.

## REST

- **`IntakeRestService`** (`lib/rest/services/intake_rest_service.dart`) — implementacao HTTP de `IntakeService`; ja contem padrao de `requireAuth`, `RestResponse`, `resolveErrorMessage` e tratamento de `FormatException` para relatorios.
- **`AnalysisMapper`** (`lib/rest/mappers/intake/analysis_mapper.dart`) — mapper de `analysis`.
- **`AnalysisDocumentMapper`** (`lib/rest/mappers/intake/analysis_document_mapper.dart`) — mapper de `document`.
- **`CaseSummaryMapper`** (`lib/rest/mappers/intake/case_summary_mapper.dart`) — mapper de `case_summary`.
- **`AnalysisPrecedentMapper`** (`lib/rest/mappers/intake/analysis_precedent_mapper.dart`) — mapper dos precedentes associados.
- **`SecondInstanceJudgmentDraftMapper`** (`lib/rest/mappers/intake/second_instance_judgment_draft_mapper.dart`) — mapper de `judgment_draft` estruturado.
- **`SecondInstanceAnalysisReportMapper`** (`lib/rest/mappers/intake/second_instance_analysis_report_mapper.dart`) — mapper legado do relatorio de 2ª instancia sem `judgment_draft`; deve ser substituido.

## Drivers

- **`PrintingPdfDriver`** (`lib/drivers/pdf-driver/printing/printing_pdf_driver.dart`) — implementacao concreta com `pdf` e `printing`, ja contem helpers para paginas, cards, cabecalho, precedentes e share sheet.
- **`AnimusPdfTheme`** (`lib/drivers/pdf-driver/printing/animus_pdf_theme.dart`) — tema visual do PDF.
- **`pdfDriverProvider`** (`lib/drivers/pdf-driver/index.dart`) — provider Riverpod para injetar `PdfDriver` na UI.

## UI

- **`SecondInstanceAnalysisScreenView`** (`lib/ui/intake/widgets/pages/second_instance_analysis_screen/second_instance_analysis_screen_view.dart`) — tela alvo; hoje passa `showExportReport: false` para `AnalysisHeader`.
- **`SecondInstanceAnalysisScreenPresenter`** (`lib/ui/intake/widgets/pages/second_instance_analysis_screen/second_instance_analysis_screen_presenter.dart`) — presenter da tela de 2ª instancia; ja controla `status`, `judgmentDraft`, `generalError` e `isManagingAnalysis`.
- **`secondInstanceAnalysisScreenPresenterProvider`** (`lib/ui/intake/widgets/pages/second_instance_analysis_screen/second_instance_analysis_screen_presenter.dart`) — provider do presenter da tela.
- **`AnalysisHeader`** (`lib/ui/intake/widgets/components/analysis_header/analysis_header_view.dart`) — header compartilhado que ja recebe `onExportReport`, `showExportReport` e `isExportingReport`.
- **`AnalysisHeaderActions`** (`lib/ui/intake/widgets/components/analysis_header/analysis_header_actions/analysis_header_actions_view.dart`) — menu que ja renderiza `Exportar PDF` e `Exportando PDF...`.
- **`JudgmentDraftCard`** (`lib/ui/intake/widgets/pages/second_instance_analysis_screen/judgment_draft_card/judgment_draft_card_view.dart`) — card da minuta na tela, referencia visual do conteudo a ser exportado.
- **`JudgmentDraftDialog`** (`lib/ui/intake/widgets/pages/second_instance_analysis_screen/judgment_draft_dialog/judgment_draft_dialog_view.dart`) — leitura completa da minuta, referencia de seções e nomenclatura.

## Lacunas identificadas

- Nao existe `lib/ui/intake/widgets/pages/second_instance_screen/`; a codebase materializou o fluxo do Juiz em `second_instance_analysis_screen`.
- Nao existe `SecondInstanceAnalysisReportDto` no mobile, apesar de `ANI-100` definir este contrato no server.
- O contrato mobile atual `SecondInstanceAnalysisReportDto` nao inclui `judgmentDraft`, portanto nao atende a exportacao da minuta.
- O endpoint mobile atual `/second-instance-analysis-report` diverge do endpoint server esperado `/second-instance-analysis-report`.

---

# 5. O que deve ser criado?

## Camada Core (DTOs)

- **Localização:** `lib/core/intake/dtos/second_instance_analysis_report_dto.dart` (**novo arquivo**)
- **Classe:** `SecondInstanceAnalysisReportDto`
- **Atributos:**
  - `final AnalysisDto analysis`
  - `final AnalysisDocumentDto document`
  - `final CaseSummaryDto caseSummary`
  - `final List<AnalysisPrecedentDto> precedents`
  - `final SecondInstanceJudgmentDraftDto judgmentDraft`
- **Factory `fromJson`:** Não aplicável; parsing pertence à camada REST.

## Camada REST (Mappers)

- **Localização:** `lib/rest/mappers/intake/second_instance_report_mapper.dart` (**novo arquivo**)
- **Métodos:**
  - `static SecondInstanceAnalysisReportDto toDto(Json json)` — mapeia `analysis`, `document`, `case_summary`, `precedents` e `judgment_draft` usando mappers existentes.
  - `static List<AnalysisPrecedentDto> _toPrecedents(dynamic value)` — converte lista remota em `List<AnalysisPrecedentDto>`; retorna lista vazia quando o campo vier ausente ou invalido.
  - `static Json _toJsonField(dynamic value)` — normaliza campos agregados para `Json`, evitando cast inseguro.
- **Método `toJson`:** Não aplicável; o fluxo consome apenas resposta da API.

---

# 6. O que deve ser modificado?

## Core

- **Arquivo:** `lib/core/intake/interfaces/intake_service.dart`
- **Mudança:** importar `second_instance_report_dto.dart` e adicionar `Future<RestResponse<SecondInstanceAnalysisReportDto>> getSecondInstanceAnalysisReport({required String analysisId});`.
- **Justificativa:** publicar contrato tipado do relatorio do Juiz para a UI sem acoplamento a HTTP.

- **Arquivo:** `lib/core/shared/interfaces/pdf_driver.dart`
- **Mudança:** importar `second_instance_report_dto.dart` e adicionar `Future<Uint8List> generateSecondInstanceAnalysisReport({required SecondInstanceAnalysisReportDto report});`.
- **Justificativa:** expor capacidade especifica de gerar PDF da minuta do Juiz sem vazar `pdf`/`printing` para UI.

## REST

- **Arquivo:** `lib/rest/services/intake_rest_service.dart`
- **Mudança:** substituir o fluxo `getSecondInstanceAnalysisReport(...)` por `Future<RestResponse<SecondInstanceAnalysisReportDto>> getSecondInstanceAnalysisReport({required String analysisId})`, chamando `GET /intake/analyses/$analysisId/second-instance-analysis-report` e mapeando com `SecondInstanceAnalysisReportMapper.toDto`.
- **Justificativa:** alinhar o mobile ao contrato server `ANI-100` e garantir que a resposta inclua a minuta persistida.

- **Arquivo:** `lib/rest/services/intake_rest_service.dart`
- **Mudança:** manter o mesmo padrao de `requireAuth`, retorno de `RestResponse`, `resolveErrorMessage(response)` em falha e `FormatException` como `HttpStatus.badGateway` usado nos outros relatorios.
- **Justificativa:** preservar comportamento consistente da camada REST.

## Drivers

- **Arquivo:** `lib/drivers/pdf-driver/printing/printing_pdf_driver.dart`
- **Mudança:** implementar `Future<Uint8List> generateSecondInstanceAnalysisReport({required SecondInstanceAnalysisReportDto report})`.
- **Justificativa:** gerar o documento PDF em memoria usando os dados agregados do fluxo do Juiz.

- **Arquivo:** `lib/drivers/pdf-driver/printing/printing_pdf_driver.dart`
- **Mudança:** adicionar helpers privados para o PDF do Juiz, reaproveitando os estilos existentes quando possivel:
  - `pw.Page _buildSecondInstanceHeaderPage(SecondInstanceAnalysisReportDto report, DateTime generatedAt)` — monta cabecalho, nome da analise, data, documento e metadados.
  - `pw.Page _buildSecondInstanceCaseSummaryPage(SecondInstanceAnalysisReportDto report, DateTime generatedAt)` — monta resumo do caso com `CaseSummaryDto`.
  - `pw.Page _buildSecondInstanceDraftPage(SecondInstanceAnalysisReportDto report, DateTime generatedAt)` — monta minuta estruturada com relatorio, preliminares, merito, aderencia aos precedentes, aviso e dispositivo.
  - `pw.Page _buildSecondInstancePrecedentsPage({required List<AnalysisPrecedentDto> precedents, required DateTime generatedAt})` — monta precedentes ordenados por `finalRank`.
  - `pw.Widget _buildJudgmentDraftSection({required String title, required String content})` — renderiza uma secao textual da minuta.
  - `pw.Widget _buildRulingSection(List<String> ruling)` — renderiza os itens do dispositivo.
  - `String _buildApplicabilityPercent(AnalysisPrecedentDto precedent)` — formata `similarityScore` em percentual para exibicao no PDF.
- **Justificativa:** manter a montagem do PDF coesa no driver concreto, sem sobrecarregar presenter ou DTO.

## UI

- **Arquivo:** `lib/ui/intake/widgets/pages/second_instance_analysis_screen/second_instance_analysis_screen_presenter.dart`
- **Mudança:** importar `dart:typed_data`, `SecondInstanceAnalysisReportDto`, `PdfDriver` e `pdfDriverProvider`.
- **Justificativa:** permitir orquestracao da exportacao sem acoplamento ao driver concreto.

- **Arquivo:** `lib/ui/intake/widgets/pages/second_instance_analysis_screen/second_instance_analysis_screen_presenter.dart`
- **Mudança:** injetar `PdfDriver pdfDriver` no construtor e no provider `secondInstanceAnalysisScreenPresenterProvider` via `ref.watch(pdfDriverProvider)`.
- **Justificativa:** seguir o padrao de injecao por `Riverpod` ja usado na tela.

- **Arquivo:** `lib/ui/intake/widgets/pages/second_instance_analysis_screen/second_instance_analysis_screen_presenter.dart`
- **Mudança:** adicionar estado e computeds:
  - `final Signal<bool> isExportingReport = signal<bool>(false)` — indica exportacao em andamento.
  - `late final ReadonlySignal<bool> canExportReport = computed<bool>(...)` — verdadeiro quando `status == AnalysisStatusDto.done`, `judgmentDraft.value != null`, `!isManagingAnalysis.value` e `!isExportingReport.value`.
- **Justificativa:** controlar elegibilidade e feedback visual sem regra na `View`.

- **Arquivo:** `lib/ui/intake/widgets/pages/second_instance_analysis_screen/second_instance_analysis_screen_presenter.dart`
- **Mudança:** adicionar metodo `Future<bool> exportSecondInstanceAnalysisReport()` — valida `canExportReport`, ativa `isExportingReport` e `isManagingAnalysis`, busca `IntakeService.getSecondInstanceAnalysisReport`, gera bytes por `PdfDriver.generateSecondInstanceAnalysisReport`, compartilha via `PdfDriver.sharePdf`, trata falhas em `generalError` e limpa flags no `finally`.
- **Justificativa:** centralizar o fluxo ponta a ponta no presenter, preservando `View` fina.

- **Arquivo:** `lib/ui/intake/widgets/pages/second_instance_analysis_screen/second_instance_analysis_screen_presenter.dart`
- **Mudança:** adicionar metodo privado `String _buildSecondInstanceReportFilename(String rawAnalysisName)` — sanitiza nome da analise e retorna `$safeName - Minuta de Sentenca.pdf`.
- **Justificativa:** manter regra de nome de arquivo no presenter, como no fluxo existente da 1ª instancia.

- **Arquivo:** `lib/ui/intake/widgets/pages/second_instance_analysis_screen/second_instance_analysis_screen_presenter.dart`
- **Mudança:** atualizar `archiveAnalysis()`, `renameAnalysis(...)`, `canPickDocument`, `canAnalyzeCase`, `canRegenerateSummary`, `canSearchPrecedents`, `canGenerateJudgmentDraft` e `canRegenerateJudgmentDraft` para considerar `isExportingReport` quando bloquearem concorrencia.
- **Justificativa:** impedir conflito entre exportacao, alteracao de estado da analise e geracao/regeneracao.

- **Arquivo:** `lib/ui/intake/widgets/pages/second_instance_analysis_screen/second_instance_analysis_screen_presenter.dart`
- **Mudança:** elevar `maxFileSizeInBytes` para `100 * 1024 * 1024` e atualizar a mensagem de validacao local para `O arquivo deve ter no máximo 100MB.`.
- **Justificativa:** alinhar a validacao client-side da tela de 2ª instancia ao novo limite operacional definido para o fluxo.

- **Arquivo:** `lib/ui/intake/widgets/pages/second_instance_analysis_screen/second_instance_analysis_screen_presenter.dart`
- **Mudança:** descartar `isExportingReport` e `canExportReport` em `dispose()`.
- **Justificativa:** evitar vazamento de signals.

- **Arquivo:** `lib/ui/intake/widgets/pages/second_instance_analysis_screen/second_instance_analysis_screen_view.dart`
- **Mudança:** no `AnalysisHeader`, substituir `onExportReport: null`, `showExportReport: false` e `isExportingReport: false` por valores observados do presenter:
  - `onExportReport: canExportReport ? () => unawaited(presenter.exportSecondInstanceAnalysisReport()) : null`
  - `showExportReport: status == AnalysisStatusDto.done && presenter.judgmentDraft.value != null`
  - `isExportingReport: presenter.isExportingReport.watch(context)`
  - `isMenuEnabled: !isManaging || isExportingReport`, mantendo o item visivel enquanto exporta.
- **Justificativa:** habilitar a entrada visual ja existente sem duplicar componentes.

- **Arquivo:** `lib/ui/intake/widgets/pages/second_instance_analysis_screen/second_instance_analysis_screen_view.dart`
- **Mudança:** atualizar o `helperText` da action bar para informar `Somente PDF com ate 100MB. O processamento pode levar alguns minutos.` quando a acao principal da tela for upload de arquivo.
- **Justificativa:** manter a orientacao visual consistente com a validacao local configurada no presenter.

- **Arquivo:** `lib/ui/intake/widgets/pages/second_instance_analysis_screen/index.dart`
- **Mudança:** manter os exports atuais; incluir novos membros apenas se o presenter expuser tipos publicos adicionais necessarios.
- **Justificativa:** preservar o barrel file da tela.

---

# 7. O que deve ser removido?

## Core

- **Arquivo:** `lib/core/intake/dtos/second_instance_analysis_report_dto.dart`
- **Motivo da remoção:** contrato legado nao contempla `judgmentDraft` e diverge do contrato server `SecondInstanceAnalysisReportDto` definido por `ANI-100`.
- **Impacto esperado:** remover import e metodo `getSecondInstanceAnalysisReport(...)` de `IntakeService`; consumidores devem usar `getSecondInstanceAnalysisReport(...)`.

## REST

- **Arquivo:** `lib/rest/mappers/intake/second_instance_analysis_report_mapper.dart`
- **Motivo da remoção:** mapper legado sem `judgment_draft`, substituido por `SecondInstanceAnalysisReportMapper`.
- **Impacto esperado:** atualizar imports em `IntakeRestService` para o novo mapper.

- **Arquivo:** `lib/rest/services/intake_rest_service.dart`
- **Motivo da remoção:** remover metodo `getSecondInstanceAnalysisReport(...)` e endpoint `/second-instance-analysis-report`.
- **Impacto esperado:** evitar dois contratos para a mesma exportacao e alinhar o mobile ao endpoint `/second-instance-analysis-report`.

---

# 8. Decisões Técnicas e Trade-offs

- **Decisão:** reutilizar `SecondInstanceAnalysisScreenView` em vez de criar `SecondInstanceAnalysisScreenView`.
- **Alternativas consideradas:** criar uma nova tela `lib/ui/intake/widgets/pages/second_instance_screen/` conforme texto do ticket; duplicar a tela existente.
- **Motivo da escolha:** a codebase ja materializou o fluxo do Juiz em `second_instance_analysis_screen`, e a spec base `second-instance-analysis-screen-spec.md` define essa pasta como destino da tela.
- **Impactos / trade-offs:** evita duplicidade de tela e mantem a nomenclatura do presenter alinhada ao modulo `second_instance_analysis_screen`.

- **Decisão:** criar `SecondInstanceAnalysisReportDto` e remover `SecondInstanceAnalysisReportDto`.
- **Alternativas consideradas:** evoluir `SecondInstanceAnalysisReportDto` adicionando `judgmentDraft`; manter ambos os contratos.
- **Motivo da escolha:** `ANI-100` define `SecondInstanceAnalysisReportDto` e endpoint `/second-instance-analysis-report`; manter dois DTOs para o mesmo relatorio criaria duplicidade e risco de consumo do endpoint errado.
- **Impactos / trade-offs:** exige ajuste de imports que mencionam `SecondInstanceAnalysisReportDto`, mas reduz ambiguidade futura.

- **Decisão:** adicionar `PdfDriver.generateSecondInstanceAnalysisReport(...)` sem renomear `generateFirstInstanceAnalysisReport(...)`.
- **Alternativas consideradas:** renomear o metodo atual para `generateFirstInstanceAnalysisReport(...)`; criar driver separado para juiz.
- **Motivo da escolha:** menor alteracao no fluxo ja existente de exportacao da 1ª instancia e sem necessidade de novo provider.
- **Impactos / trade-offs:** `PdfDriver` fica com dois metodos especificos de relatorio; a nomenclatura antiga `generateFirstInstanceAnalysisReport` permanece menos explicita por compatibilidade interna.

- **Decisão:** manter a montagem do PDF no `PrintingPdfDriver`.
- **Alternativas consideradas:** montar secoes no presenter; criar mapper de UI para PDF; criar service de PDF na camada REST.
- **Motivo da escolha:** `pdf` e `printing` sao dependencias concretas de infraestrutura e ja estao isoladas em `drivers`.
- **Impactos / trade-offs:** o arquivo `printing_pdf_driver.dart` crescera; se a implementacao ficar extensa demais, a quebra futura deve permanecer dentro de `lib/drivers/pdf-driver/printing/`.

- **Decisão:** usar `generalError` existente para falhas de exportacao.
- **Alternativas consideradas:** criar signal especifica `exportReportError`; criar snackbar direto na `View`.
- **Motivo da escolha:** a tela ja renderiza `MessageBox` a partir de `generalError`, mantendo a `View` simples e consistente.
- **Impactos / trade-offs:** erros de exportacao aparecem no mesmo canal visual de erros gerais da tela.

---

# 9. Diagramas e Referências

- **Fluxo de dados:**

```text
SecondInstanceAnalysisScreenView
  -> SecondInstanceAnalysisScreenPresenter.exportSecondInstanceAnalysisReport()
      -> secondInstanceAnalysisScreenPresenterProvider
          -> IntakeService.getSecondInstanceAnalysisReport(...)
              -> IntakeRestService.getSecondInstanceAnalysisReport(...)
                  -> RestClient (Dio)
                      -> GET /intake/analyses/{analysis_id}/second-instance-analysis-report
                  -> SecondInstanceAnalysisReportMapper.toDto(...)
          -> PdfDriver.generateSecondInstanceAnalysisReport(...)
              -> PrintingPdfDriver (pdf)
          -> PdfDriver.sharePdf(...)
              -> Printing.sharePdf(...)

signals:
  canExportReport, isExportingReport, isManagingAnalysis, generalError
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
            AnalysisHeaderActions
              PopupMenuItem: Exportar PDF / Exportando PDF...
          SingleChildScrollView
            AiBubble
            DocumentFileBubble
            ProcessingBubble
            PetitionNotFoundState
            CaseSummaryCard
            AnalysisPrecedentsBubble
            GenerateJudgmentDraftCard
            JudgmentDraftCard
            MessageBox
          AnalysisActionBar
```

- **Estrutura do PDF:**

```text
PDF - Minuta de Sentenca
  Pagina 1: Capa e metadados
    - Nome da analise
    - Data de geracao
    - Documento base
  Pagina 2: Resumo do caso
    - Resumo
    - Questao central
    - Enquadramento juridico
    - Fatos relevantes
    - Legislacao aplicavel
  Pagina 3+: Minuta estruturada
    - Relatorio
    - Questoes preliminares, se houver
    - Analise do merito
    - Aderencia/distincao dos precedentes
    - Aviso de ausencia de precedente forte, se houver
    - Dispositivo sugerido
  Pagina N+: Precedentes associados
    - Tribunal, tipo e numero
    - Status, tese/enunciado
    - Percentual e nivel de aplicabilidade
    - Sintese explicativa
```

- **Referências:**
  - `documentation/architecture.md`
  - `documentation/rules/ui-layer-rules.md`
  - `documentation/rules/core-layer-rules.md`
  - `documentation/rules/rest-layer-rules.md`
  - `documentation/rules/drivers-layer-rules.md`
  - `documentation/rules/code-conventions-rules.md`
  - `documentation/features/intake/second-instance-analysis/second-instance-analysis-screen-spec.md`
  - `lib/core/intake/interfaces/intake_service.dart`
  - `lib/core/shared/interfaces/pdf_driver.dart`
  - `lib/rest/services/intake_rest_service.dart`
  - `lib/drivers/pdf-driver/printing/printing_pdf_driver.dart`
  - `lib/ui/intake/widgets/pages/second_instance_analysis_screen/second_instance_analysis_screen_presenter.dart`
  - `lib/ui/intake/widgets/pages/second_instance_analysis_screen/second_instance_analysis_screen_view.dart`
  - `lib/ui/intake/widgets/components/analysis_header/analysis_header_view.dart`
  - `lib/ui/intake/widgets/components/analysis_header/analysis_header_actions/analysis_header_actions_view.dart`

---

# 10. Pendências / Dúvidas

- **Descrição da pendência:** o PRD RF 08 define limite de upload de **20MB**, enquanto a implementacao atual da `SecondInstanceAnalysisScreenView` e esta spec consolidam o limite local em **100MB**.
- **Impacto na implementação:** nao afeta o fluxo de geracao do PDF, mas mantem uma divergencia formal de produto na validacao de upload da tela base.
- **Ação sugerida:** atualizar o PRD e a spec base `documentation/features/intake/second-instance-analysis/second-instance-analysis-screen-spec.md` para refletir o novo limite de **100MB**.

- **Descrição da pendência:** o ticket `ANI-106` cita `SecondInstanceAnalysisScreenView`, mas a codebase e a spec base usam `SecondInstanceAnalysisScreenView`.
- **Impacto na implementação:** criar uma nova tela duplicaria fluxo e presenter.
- **Ação sugerida:** implementar na tela existente e, se produto exigir renomeacao para `secondInstance`, abrir refatoracao separada.

- **Descrição da pendência:** o ticket server `ANI-100` define endpoint `/second-instance-analysis-report`, mas a codebase mobile possui endpoint legado `/second-instance-analysis-report`.
- **Impacto na implementação:** consumo do endpoint legado nao entregaria `judgment_draft` conforme contrato esperado.
- **Ação sugerida:** migrar mobile para `/second-instance-analysis-report` nesta spec e remover contrato legado.

---

# Restrições

- Não inclua testes automatizados na spec.
- A `View` não deve conter lógica de negócio; exportacao deve ser delegada ao presenter.
- Presenters não fazem chamadas diretas a `RestClient`; devem consumir `IntakeService`.
- `PdfDriver` deve esconder `pdf`, `printing` e `Uint8List` gerado da camada visual, exceto pelo contrato do `core`.
- Todos os caminhos citados existem no projeto ou estao marcados como **novo arquivo**.
- Não criar `SecondInstanceAnalysisScreenView` nesta spec.
- Não manter dois contratos de relatorio do Juiz/2ª instancia para a mesma exportacao.
- O PDF deve ser gerado a partir de DTO tipado, sem `Map<String, dynamic>` na UI.
- O item **Exportar PDF** deve ficar indisponivel durante exportacao concorrente.
- Use componentes Flutter Material alinhados ao tema do projeto.
- Arquivos novos devem usar `snake_case`, classes `PascalCase` e providers/metodos `camelCase`.
