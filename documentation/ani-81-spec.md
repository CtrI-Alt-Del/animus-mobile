---
title: ANI-81 - Filtros aplicados no PDF da análise
prd: https://joaogoliveiragarcia.atlassian.net/wiki/spaces/anm/pages/18186241/PRD+RF+06+Exporta+o+de+relat+rio
ticket: https://joaogoliveiragarcia.atlassian.net/browse/ANI-81
last_updated_at: 2026-05-02
status: closed
---

# 1. Objetivo

Adicionar ao relatório PDF da análise a seção de **filtros aplicados na busca de precedentes**, garantindo que o documento exportado mostre a quantidade configurada de precedentes, os tribunais selecionados e os tipos de precedente selecionados. A implementação deve evoluir o contrato tipado do relatório, mapear o novo payload vindo do endpoint atual e renderizar a nova seção no PDF antes da listagem de precedentes, preservando o fluxo atual de exportação, nome do arquivo e `share sheet` nativo.

---

# 2. Escopo

## 2.1 In-scope

- Evoluir `AnalysisReportDto` para expor os filtros aplicados no relatório.
- Criar um DTO específico para os filtros do relatório.
- Mapear o bloco de filtros no payload de `GET /intake/analyses/{analysis_id}/report`.
- Renderizar no PDF:
  - quantidade de precedentes configurada;
  - tribunais selecionados;
  - tipos de precedente selecionados;
  - mensagens explícitas quando não houver filtros opcionais por tribunal ou tipo.
- Posicionar a seção de filtros antes da lista de precedentes analisados.
- Manter `AnalysisScreenPresenter.exportAnalysisReport()` como ponto único de entrada da exportação.
- Manter `getAnalysisReport(analysisId)` como fonte única de verdade para o relatório exportado.

## 2.2 Out-of-scope

- Alterar o layout Flutter da `analysis_screen`.
- Montar filtros do PDF a partir do estado transitório da UI.
- Alterar o nome do arquivo exportado.
- Alterar o mecanismo de compartilhamento do PDF.
- Alterar o endpoint chamado pelo mobile.
- Exportar outros formatos além de PDF.
- Personalizar conteúdo ou layout do relatório pelo usuário.
- Incluir testes automatizados nesta spec.

---

# 3. Requisitos

## 3.1 Funcionais

- O PDF exportado deve incluir os filtros efetivamente aplicados na busca de precedentes da análise.
- O PDF deve exibir a **quantidade de precedentes configurada** pelo usuário, mesmo quando não houver filtros opcionais.
- O PDF deve exibir os **tribunais selecionados** quando a busca tiver usado filtro por tribunal.
- O PDF deve exibir os **tipos de precedente selecionados** quando a busca tiver usado filtro por tipo.
- Quando a lista de tribunais vier vazia, o PDF deve exibir `Sem filtros de tribunal`.
- Quando a lista de tipos vier vazia, o PDF deve exibir `Sem filtros de tipo`.
- A exportação deve continuar disponível apenas quando `AnalysisStatusDto.precedentChosen` estiver ativo.
- O fluxo atual de loading, erro e sucesso da exportação deve ser preservado.

## 3.2 Não funcionais

- **Consistência de domínio:** os rótulos de tipos devem reutilizar a mesma semântica de `PrecedentKindDto` já usada no relatório, via `AnimusPdfTheme.formatKindLabel`.
- **Integridade do relatório:** o PDF deve usar somente dados vindos de `AnalysisReportDto`; não deve consultar `precedentsLimit`, `precedentsCourts` ou `precedentsKinds` da tela.
- **Robustez de payload:** o mapper deve falhar com `FormatException` quando o bloco obrigatório de filtros ou a quantidade aplicada não vierem em formato válido.
- **Compatibilidade mobile:** o contrato de `PdfDriver.generateAnalysisReport({required AnalysisReportDto report})` deve permanecer inalterado.

---

# 4. O que já existe?

## Camada Core

- **`AnalysisReportDto`** (`lib/core/intake/dtos/analysis_report_dto.dart`) - agregado atual do relatório com análise, petição, resumo, precedentes e precedente escolhido; ainda não expõe filtros aplicados.
- **`AnalysisPrecedentsSearchFiltersDto`** (`lib/core/intake/dtos/analysis_precedents_search_filters_dto.dart`) - DTO usado no request da busca de precedentes, com `courts`, `precedentKinds` e `limit`.
- **`CourtDto`** (`lib/core/intake/dtos/court_dto.dart`) - enum tipado dos tribunais suportados.
- **`PrecedentKindDto`** (`lib/core/intake/dtos/precedent_kind_dto.dart`) - enum tipado dos tipos de precedente suportados.
- **`IntakeService`** (`lib/core/intake/interfaces/intake_service.dart`) - contrato atual de `getAnalysisReport({required String analysisId})`.
- **`PdfDriver`** (`lib/core/shared/interfaces/pdf_driver.dart`) - contrato de geração e compartilhamento de PDF.
x
## Camada REST

- **`AnalysisReportMapper`** (`lib/rest/mappers/intake/analysis_report_mapper.dart`) - mapper atual do payload do relatório; ponto de extensão para incluir `filters`.
- **`PrecedentMapper`** (`lib/rest/mappers/intake/precedent_mapper.dart`) - referência de parse defensivo de `CourtDto` e `PrecedentKindDto`.
- **`IntakeRestService`** (`lib/rest/services/intake_rest_service.dart`) - chama `GET /intake/analyses/{analysisId}/report` e aplica `AnalysisReportMapper.toDto`.

## Camada Drivers

- **`PrintingPdfDriver`** (`lib/drivers/pdf-driver/printing/printing_pdf_driver.dart`) - gera o PDF atual em páginas de cabeçalho, síntese, precedentes e precedente escolhido.
- **`AnimusPdfTheme`** (`lib/drivers/pdf-driver/printing/animus_pdf_theme.dart`) - centraliza cores, fontes e `formatKindLabel(PrecedentKindDto kind)`.
- **`pdfDriverProvider`** (`lib/drivers/pdf-driver/index.dart`) - provider Riverpod que expõe `PrintingPdfDriver` como `PdfDriver`.

## Camada UI

- **`AnalysisScreenPresenter`** (`lib/ui/intake/widgets/pages/analysis_screen/analysis_screen_presenter.dart`) - orquestra a exportação via `getAnalysisReport`, `generateAnalysisReport` e `sharePdf`.
- **`RelevantPrecedentsBubblePresenter`** (`lib/ui/intake/widgets/pages/analysis_screen/relevant_precedents_bubble/relevant_precedents_bubble_presenter.dart`) - referência da semântica atual dos filtros: `selectedLimit`, `selectedCourts` e `selectedKinds`.
- **`AnalysisHeaderActionsView`** (`lib/ui/intake/widgets/pages/analysis_screen/analysis_header/analysis_header_actions/analysis_header_actions_view.dart`) - entrada visual atual para `Exportar PDF`.
- **`PrecedentsFiltersDialogView`** (`lib/ui/intake/widgets/pages/analysis_screen/precedents_filters_dialog/precedents_filters_dialog_view.dart`) - referência visual e textual dos filtros por tribunal e tipo.

---

# 5. O que deve ser criado?

## Camada Core (DTOs)

- **Localização:** `lib/core/intake/dtos/analysis_report_filters_dto.dart` (**novo arquivo**)
- **Classe:** `AnalysisReportFiltersDto`
- **Atributos:**
  - `final int limit` - quantidade de precedentes configurada na busca que originou o relatório.
  - `final List<CourtDto> courts` - tribunais aplicados na busca; lista vazia significa ausência de filtro opcional por tribunal.
  - `final List<PrecedentKindDto> precedentKinds` - tipos aplicados na busca; lista vazia significa ausência de filtro opcional por tipo.
- **Construtor:** `const AnalysisReportFiltersDto({required int limit, required List<CourtDto> courts, required List<PrecedentKindDto> precedentKinds})`.
- **Factory `fromJson`:** **Não aplicável**. O parse de JSON deve permanecer na camada REST.

## Camada REST (Mappers)

- **Localização:** `lib/rest/mappers/intake/analysis_report_filters_mapper.dart` (**novo arquivo**)
- **Métodos:**
  - `static AnalysisReportFiltersDto toDto(Json json)` - converte o payload de filtros do relatório para `AnalysisReportFiltersDto`.
  - `static List<CourtDto> _toCourts(dynamic value)` - converte lista de strings do payload para `CourtDto`, ignorando valores desconhecidos.
  - `static List<PrecedentKindDto> _toPrecedentKinds(dynamic value)` - converte lista de strings do payload para `PrecedentKindDto`, ignorando valores desconhecidos.
  - `static int _toRequiredLimit(dynamic value)` - converte `limit` para `int` e lança `FormatException` quando ausente, inválido ou menor/igual a zero.
- **Campos mapeados:**
  - `limit` -> `AnalysisReportFiltersDto.limit`
  - `courts` -> `AnalysisReportFiltersDto.courts`
  - `precedent_kinds` -> `AnalysisReportFiltersDto.precedentKinds`
- **Payload esperado:**

```text
filters: {
  limit: int,
  courts: string[],
  precedent_kinds: string[]
}
```

---

# 6. O que deve ser modificado?

## Camada Core

- **Arquivo:** `lib/core/intake/dtos/analysis_report_dto.dart`
- **Mudança:** importar `analysis_report_filters_dto.dart`, adicionar `final AnalysisReportFiltersDto filters` e tornar o campo obrigatório no construtor.
- **Justificativa:** expor no domínio mobile os filtros usados na busca de precedentes, mantendo o PDF dependente de um agregado tipado.

## Camada REST

- **Arquivo:** `lib/rest/mappers/intake/analysis_report_mapper.dart`
- **Mudança:** importar `AnalysisReportFiltersMapper`, validar `json['filters']` como `Json` e passar `filters: AnalysisReportFiltersMapper.toDto(filtersJson)` para `AnalysisReportDto`.
- **Justificativa:** centralizar o parse do novo bloco de payload no mapper do relatório, sem levar `Map<String, dynamic>` para `core`, `drivers` ou `ui`.

- **Arquivo:** `lib/rest/services/intake_rest_service.dart`
- **Mudança:** manter o endpoint `GET /intake/analyses/{analysisId}/report` e o método `Future<RestResponse<AnalysisReportDto>> getAnalysisReport({required String analysisId})` sem alteração de assinatura; apenas validar que a falha de mapper continua retornando `RestResponse<AnalysisReportDto>` com `HttpStatus.badGateway`.
- **Justificativa:** preservar o contrato consumido pela UI e limitar a evolução ao payload retornado pelo endpoint.

## Camada Drivers

- **Arquivo:** `lib/drivers/pdf-driver/printing/printing_pdf_driver.dart`
- **Mudança:** alterar a chamada de `_buildPrecedentsPage` para receber `report.filters` junto da lista ordenada de precedentes.
- **Justificativa:** a seção de filtros pertence à página de precedentes e deve usar o agregado do relatório.

- **Arquivo:** `lib/drivers/pdf-driver/printing/printing_pdf_driver.dart`
- **Mudança:** ajustar a assinatura para `pw.Page _buildPrecedentsPage({required List<AnalysisPrecedentDto> precedents, required AnalysisReportFiltersDto filters, required DateTime generatedAt})`.
- **Justificativa:** deixar explícito que a página depende dos precedentes e dos filtros aplicados.

- **Arquivo:** `lib/drivers/pdf-driver/printing/printing_pdf_driver.dart`
- **Mudança:** criar helpers privados:
  - `pw.Widget _buildAppliedFiltersSection(AnalysisReportFiltersDto filters)` - renderiza o bloco visual de filtros antes dos cards de precedentes.
  - `pw.Widget _buildFilterRow(String title, String content)` - renderiza uma linha de metadado do bloco de filtros.
  - `String _formatCourts(List<CourtDto> courts)` - retorna tribunais separados por vírgula ou `Sem filtros de tribunal`.
  - `String _formatPrecedentKinds(List<PrecedentKindDto> kinds)` - retorna tipos formatados por `AnimusPdfTheme.formatKindLabel` ou `Sem filtros de tipo`.
- **Justificativa:** manter a montagem visual coesa no driver PDF e evitar duplicação de strings/estrutura dentro da página.

- **Arquivo:** `lib/drivers/pdf-driver/printing/printing_pdf_driver.dart`
- **Mudança:** inserir a seção após o título `Precedentes analisados (...)` e antes de `buildPrecedentCards(precedents: precedents)`.
- **Justificativa:** o usuário deve ver o contexto da busca antes de ler os resultados.

## Camada UI

- **Arquivo:** `lib/ui/intake/widgets/pages/analysis_screen/analysis_screen_presenter.dart`
- **Mudança:** **Não aplicável para código funcional**. O método `Future<bool> exportAnalysisReport()` deve continuar buscando o relatório via `getAnalysisReport`, gerando o PDF via `PdfDriver` e compartilhando o arquivo com o nome atual.
- **Justificativa:** os filtros do PDF devem vir do relatório persistido, não do estado local da tela.

---

# 7. O que deve ser removido?

**Não aplicável**.

---

# 8. Decisões Técnicas e Trade-offs

- **Decisão:** criar `AnalysisReportFiltersDto` em vez de reutilizar `AnalysisPrecedentsSearchFiltersDto`.
- **Alternativas consideradas:** reutilizar o DTO de request da busca de precedentes.
- **Motivo da escolha:** o relatório representa filtros já aplicados e persistidos; o DTO de busca representa input transitório de uma operação.
- **Impactos / trade-offs:** cria um arquivo novo, mas evita acoplamento semântico entre request de busca e payload agregado de relatório.

- **Decisão:** manter `PdfDriver.generateAnalysisReport({required AnalysisReportDto report})` sem alteração de assinatura.
- **Alternativas consideradas:** adicionar um parâmetro `filters` ao driver.
- **Motivo da escolha:** os filtros fazem parte do relatório e devem trafegar junto do agregado `AnalysisReportDto`.
- **Impactos / trade-offs:** exige adicionar o campo obrigatório ao DTO, mas preserva a fronteira pública do driver.

- **Decisão:** renderizar a seção de filtros dentro de `_buildPrecedentsPage`.
- **Alternativas consideradas:** adicionar uma nova página exclusiva para filtros.
- **Motivo da escolha:** os filtros contextualizam diretamente a lista de precedentes; colocá-los antes dos cards reduz ruptura de leitura.
- **Impactos / trade-offs:** aumenta o conteúdo da página de precedentes, mas mantém o relatório mais direto.

- **Decisão:** lançar `FormatException` quando `filters.limit` estiver ausente ou inválido.
- **Alternativas consideradas:** usar fallback silencioso para `AnalysisScreenPresenter.defaultPrecedentsLimit`.
- **Motivo da escolha:** fallback local poderia gerar PDF com contexto incorreto; o relatório precisa refletir a execução real da busca.
- **Impactos / trade-offs:** um payload inconsistente falha a exportação, preservando integridade do documento.

---

# 9. Diagramas e Referências

- **Fluxo de dados:**

```text
AnalysisHeaderActionsView
  -> AnalysisScreenPresenter.exportAnalysisReport()
  -> IntakeService.getAnalysisReport(analysisId)
  -> IntakeRestService.getAnalysisReport(analysisId)
  -> RestClient.get('/intake/analyses/{analysis_id}/report')
  -> AnalysisReportMapper.toDto(json)
  -> AnalysisReportFiltersMapper.toDto(json['filters'])
  -> AnalysisReportDto(filters: AnalysisReportFiltersDto)
  -> PdfDriver.generateAnalysisReport(report)
  -> PrintingPdfDriver._buildPrecedentsPage(precedents, filters, generatedAt)
  -> Printing.sharePdf(bytes, filename)
```

- **Composição do PDF:**

```text
Relatório PDF
  Página 1: cabeçalho e dados da análise
  Página 2: síntese da petição
  Página 3: precedentes analisados
    Título da seção
    Bloco "Filtros aplicados"
      Quantidade de precedentes
      Tribunais selecionados ou "Sem filtros de tribunal"
      Tipos selecionados ou "Sem filtros de tipo"
    Cards dos precedentes ordenados por aplicabilidade
  Página 4: precedente escolhido
```

- **Hierarquia de widgets Flutter:** **Não aplicável**. A feature não cria nem altera widgets Flutter; a mudança visual ocorre dentro da composição do PDF via `pdf/widgets.dart`.

- **Referências:**
  - `lib/core/intake/dtos/analysis_report_dto.dart`
  - `lib/core/intake/dtos/analysis_precedents_search_filters_dto.dart`
  - `lib/core/intake/dtos/court_dto.dart`
  - `lib/core/intake/dtos/precedent_kind_dto.dart`
  - `lib/rest/mappers/intake/analysis_report_mapper.dart`
  - `lib/rest/mappers/intake/precedent_mapper.dart`
  - `lib/rest/services/intake_rest_service.dart`
  - `lib/drivers/pdf-driver/printing/printing_pdf_driver.dart`
  - `lib/drivers/pdf-driver/printing/animus_pdf_theme.dart`
  - `lib/ui/intake/widgets/pages/analysis_screen/analysis_screen_presenter.dart`
  - `lib/ui/intake/widgets/pages/analysis_screen/relevant_precedents_bubble/relevant_precedents_bubble_presenter.dart`
  - `lib/ui/intake/widgets/pages/analysis_screen/analysis_header/analysis_header_actions/analysis_header_actions_view.dart`

---

# 10. Pendências / Dúvidas

Sem pendências.

Registro de contexto: o rascunho local de `documentation/ani-81-spec.md` apontava inicialmente para um tiny link que resolve para RF 02. Esta spec foi alinhada ao PRD RF 06 indicado no ticket ANI-81, pois o escopo da tarefa é exportação de relatório.

---

# Restrições

- Não incluir testes automatizados na spec.
- A `View` não deve conter lógica de negócio.
- Presenters não fazem chamadas diretas a `RestClient`.
- O PDF deve consumir `AnalysisReportDto.filters`, não estado local da UI.
- Todos os caminhos citados existem no projeto ou estão marcados como **novo arquivo**.
- Não criar novos widgets Flutter para esta entrega.
- Não alterar o mecanismo atual de geração do nome do arquivo.
- Não alterar o mecanismo atual de compartilhamento via `Printing.sharePdf`.
- Manter código novo em inglês e textos exibidos no PDF em português.
- Manter imports organizados conforme as convenções do projeto.
