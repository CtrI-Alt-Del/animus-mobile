---
title: Exportacao de relatorio PDF na tela de analise
status: closed
prd: https://joaogoliveiragarcia.atlassian.net/wiki/x/AYAVAQ
ticket: https://joaogoliveiragarcia.atlassian.net/browse/ANI-51
last_updated_at: 2026-04-05
---

# 1. Objetivo

Entregar o recorte mobile de `ANI-51` dentro da `analysis_screen`: quando a analise ja estiver concluida com precedente escolhido, o menu do header deve expor a acao `Exportar PDF`, buscar o contrato agregado de `GET /intake/analyses/{analysis_id}/report`, gerar o documento em memoria usando os pacotes `pdf` + `printing`, aplicar um tema visual inspirado nos nodes `k2yVd` e `uefyz` de `design/animus.pen` com paleta amber e composicoes estaveis para o renderer do `dart_pdf`, e abrir o share sheet nativo do dispositivo com o arquivo `[Nome da analise] — Relatorio.pdf`. A implementacao deve respeitar as fronteiras entre `ui`, `core`, `rest` e `drivers`, reutilizar o `AnalysisReportDto` ja existente, e manter o feedback de loading, sucesso e erro sem levar SDKs concretos para a View.

---

# 2. Escopo

## 2.1 In-scope

- Adicionar a opcao `Exportar PDF` ao popover do header em `analysis_screen`.
- Disponibilizar a acao apenas quando `AnalysisStatusDto.precedentChosen` estiver ativo.
- Buscar o payload agregado do relatorio via `IntakeService.getAnalysisReport(...)`.
- Mapear o payload HTTP para `AnalysisReportDto` usando mapper dedicado.
- Gerar o PDF em memoria com `Uint8List`, sem persistencia local obrigatoria em arquivo temporario.
- Abrir o share sheet nativo com `Printing.sharePdf(...)` encapsulado em driver.
- Exibir indicador de carregamento enquanto request + montagem + share estiverem em andamento.
- Exibir feedback de sucesso apos o PDF ficar disponivel para compartilhamento.
- Exibir erro recuperavel quando a busca do relatorio, a geracao do PDF ou a abertura do share sheet falharem.
- Reproduzir a hierarquia visual do node `k2yVd` de `design/animus.pen` para o conteudo do PDF: pagina de cabecalho, pagina de sintese da peticao, pagina de precedentes analisados e pagina de precedente escolhido.
- Adaptar o layout decorativo do PDF quando necessario para manter estabilidade do renderer (`dart_pdf`), preservando a hierarquia visual e a leitura do node validado.
- Reutilizar o `AnalysisReportDto` ja existente em `lib/core/intake/dtos/analysis_report_dto.dart`.
- Adicionar os pacotes Flutter necessarios em `pubspec.yaml`.

## 2.2 Out-of-scope

- Preview interno do PDF dentro do app com `PdfPreview`.
- Persistencia do PDF em cache local, historico de exports ou reabertura offline do ultimo relatorio.
- Exportacao em formatos diferentes de `PDF`.
- Edicao manual do conteudo do relatorio antes do compartilhamento.
- Alteracao do fluxo de precedentes, da escolha do precedente ou da rota `/analyses/:analysisId`.
- Busca de fidelidade pixel-perfect para ornamentos do node `k2yVd` quando isso comprometer a estabilidade do renderer de PDF.
- O campo funcional `Questao` do PRD, no contexto de cada precedente, deve ser interpretado neste fluxo como o mesmo conteudo hoje exposto em `precedent.enunciation` e rotulado visualmente como `Enunciado` no layout validado; isso nao se confunde com `summary.centralQuestion`, que pertence a sintese da peticao.

---

# 3. Requisitos

## 3.1 Funcionais

- O menu `AnalysisHeaderActions` deve incluir a acao `Exportar PDF` no mesmo popover que hoje concentra `Renomear`, `Arquivar`, `Filtros` e `Qtd. precedentes`.
- A acao `Exportar PDF` so deve ficar visivel quando `AnalysisScreenPresenter.status == AnalysisStatusDto.precedentChosen`.
- Depois que um precedente for confirmado no fluxo da propria tela, a disponibilidade de `Exportar PDF` deve aparecer imediatamente no popover sem exigir recarga manual da `analysis_screen`.
- Ao selecionar `Exportar PDF`, a tela deve bloquear novas tentativas de exportacao ate o termino do fluxo atual.
- Durante a exportacao, o header deve refletir estado ocupado e impedir novas acoes concorrentes de menu.
- O presenter da tela deve chamar `IntakeService.getAnalysisReport(analysisId: String)` antes de qualquer montagem de PDF local.
- O `IntakeRestService` deve consumir `GET /intake/analyses/{analysis_id}/report`, respeitando a autenticacao ja aplicada pela classe base `Service`.
- O mapper do relatorio deve preencher `AnalysisReportDto.analysis`, `petition`, `summary`, `precedents` e `chosenPrecedent` (precedente escolhido) a partir do payload remoto.
- O payload do endpoint deve sempre trazer `chosen_precedent`, e o mapper deve tratar sua ausencia como falha contratual de integracao, sem fallback derivado da lista.
- O PDF deve ser gerado inteiramente em memoria e devolvido como `Uint8List`.
- O driver de PDF deve encapsular a chamada nativa de compartilhamento, sem expor `Printing.sharePdf(...)` para a UI.
- O nome do arquivo compartilhado deve seguir o formato `[Nome da analise] — Relatorio.pdf`.
- Se `analysis.name` vier vazio, o presenter deve aplicar fallback deterministico antes de compor o nome do arquivo.
- O cabecalho do PDF deve exibir o titulo da analise e a data de geracao do relatorio.
- A pagina de sintese da peticao deve reutilizar os dados de `PetitionSummaryDto` (`caseSummary`, `centralQuestion`, `legalIssue`, `keyFacts`, `relevantLaws`) e deve aceitar quebra automatica de pagina quando o conteudo exceder a altura util.
- A pagina de precedentes analisados deve listar todos os itens de `AnalysisReportDto.precedents`, ordenados por `applicabilityPercentage` decrescente.
- A secao de precedentes analisados deve suportar quantidade arbitraria de itens, com quebra automatica em multiplas paginas quando a lista exceder a altura util da pagina atual.
- Cada card de precedente no PDF deve seguir a hierarquia validada no node `k2yVd`, com grupo identificador (`court`, tipo derivado de `kind`, `number`), label textual de classificacao com borda na cor correspondente, destaque textual para `NN% de aplicabilidade`, bloco `Enunciado` (atendendo ao requisito funcional de `Questao`), bloco `Tese firmada` quando houver conteudo e bloco `Sintese explicativa`.
- Cards de precedente nao devem ser truncados verticalmente por quebra no meio do card; quando o volume textual ultrapassar o limite seguro do renderer do `dart_pdf`, os campos longos do card podem ser truncados com reticencias para preservar a geracao do documento.
- A pagina final do PDF deve sempre destacar `chosenPrecedent` (precedente escolhido), assumindo a presenca obrigatoria desse campo no contrato do endpoint, e deve aceitar quebra automatica de pagina quando o conteudo exceder a altura util.
- Em sucesso, a tela deve exibir confirmacao visual breve e abrir o share sheet nativo.
- Em falha do request remoto, da geracao do documento ou do share sheet, a tela deve exibir mensagem amigavel e permitir nova tentativa pelo mesmo menu.

## 3.2 Nao funcionais

- **Performance:** o app deve manter no maximo uma exportacao em andamento por `analysis_screen`; taps repetidos durante `isExportingReport == true` devem ser ignorados.
- **Performance:** a geracao do documento deve operar em memoria (`Uint8List`) e nao depender de escrita permanente em disco.
- **Offline/Conectividade:** falhas de rede ao buscar o relatorio devem resultar em erro recuperavel sem alterar o estado da analise na tela.
- **Seguranca:** o app nao deve persistir o PDF exportado em cache proprio antes do share; os bytes devem existir apenas pelo tempo necessario para o compartilhamento.
- **Compatibilidade:** a implementacao deve permanecer aderente ao stack Flutter atual e funcionar em `Android` e `iOS` via `printing`.
- **Compatibilidade / Robustez:** o layout do PDF deve evitar composicoes conhecidas por gerar distorcoes ou excecoes no `dart_pdf`, como ornamentos com `borderRadius` desproporcional ou widgets nao paginaveis com altura infinita.
- **Arquitetura:** a `View` nao deve importar `pdf`, `printing` nem qualquer SDK de compartilhamento; essas dependencias devem ficar isoladas em `drivers`.
- **Arquitetura:** o contrato publico do `core` nao deve depender de `ThemeData`, `BuildContext` ou tipos do pacote `pdf`.

---

# 4. O que ja existe?

## Core

- **`AnalysisReportDto`** (`lib/core/intake/dtos/analysis_report_dto.dart`) - DTO agregado ja existente com `analysis`, `petition`, `summary`, `precedents` e `chosenPrecedent`; deve ser reutilizado como contrato central do export, tratando `chosenPrecedent` como o precedente escolhido obrigatorio neste fluxo.
- **`AnalysisDto`** (`lib/core/intake/dtos/analysis_dto.dart`) - DTO da analise contendo `name`, `status`, `createdAt` e `id`; fornece titulo e contexto para o nome do arquivo e cabecalho do PDF.
- **`PetitionSummaryDto`** (`lib/core/intake/dtos/petition_summary_dto.dart`) - DTO com o resumo da peticao, ja estruturado para as secoes da pagina 2 do relatorio.
- **`AnalysisPrecedentDto`** (`lib/core/intake/dtos/analysis_precedent_dto.dart`) - DTO atual dos precedentes associados a analise, com `isChosen`, `applicabilityPercentage`, `classificationLevel` e `synthesis`.
- **`PrecedentDto`** (`lib/core/intake/dtos/precedent_dto.dart`) - DTO do precedente ja usado pelo app, contendo `identifier`, `enunciation`, `thesis`, `status` e `synthesis`.
- **`PrecedentIdentifierDto`** (`lib/core/intake/dtos/precedent_identifier_dto.dart`) - estrutura tipada com `court`, `kind` e `number`; deve compor o cabecalho de cada card de precedente no PDF.
- **`IntakeService`** (`lib/core/intake/interfaces/intake_service.dart`) - gateway remoto do modulo `intake`; precisa ser estendido com a operacao de relatorio.
- **`RestResponse`** (`lib/core/shared/responses/rest_response.dart`) - wrapper padrao de sucesso/falha que deve continuar protegendo a UI de detalhes de transporte.

## REST

- **`IntakeRestService`** (`lib/rest/services/intake_rest_service.dart`) - implementacao concreta de `IntakeService`, ja autenticando requests e consumindo `RestClient`.
- **`AnalysisMapper`** (`lib/rest/mappers/intake/analysis_mapper.dart`) - mapper atual do DTO de analise, a ser reutilizado dentro do mapper agregado do relatorio.
- **`PetitionMapper`** (`lib/rest/mappers/intake/petition_mapper.dart`) - mapper atual da peticao, reutilizavel no payload do relatorio.
- **`PetitionSummaryMapper`** (`lib/rest/mappers/intake/petition_summary_mapper.dart`) - mapper atual do resumo da peticao.
- **`AnalysisPrecedentMapper`** (`lib/rest/mappers/intake/analysis_precedent_mapper.dart`) - mapper atual dos precedentes da analise, reutilizavel na lista do relatorio.
- **`Service`** (`lib/rest/services/service.dart`) - classe base que concentra autenticacao e normalizacao de respostas.
- **`intakeServiceProvider`** (`lib/rest/services/index.dart`) - provider Riverpod ja usado pelos presenters do modulo `intake`.

## Drivers

- **`externalLinkDriverProvider`** (`lib/drivers/external-link-driver/index.dart`) - referencia real de pattern para encapsular plugin externo atras de interface do `core`.
- **`fileStorageDriverProvider`** (`lib/drivers/storage/file_storage/index.dart`) - referencia de provider de driver exposto na fronteira da camada.
- **`GcsFileStorageDriver`** (`lib/drivers/storage/file_storage/gcs_file_storage_driver.dart`) - referencia de implementacao concreta que recebe dependencias tecnicas e isola detalhes de transporte fora da UI.

## UI

- **`AnalysisScreenPresenter`** (`lib/ui/intake/widgets/pages/analysis_screen/analysis_screen_presenter.dart`) - presenter atual da tela, ja dono do estado de `analysis`, `summary`, erros gerais e acoes do header; e o ponto mais coeso para orquestrar a exportacao.
- **`AnalysisScreenView`** (`lib/ui/intake/widgets/pages/analysis_screen/analysis_screen_view.dart`) - tela atual que ja conecta `AnalysisHeader`, `MessageBox`, resumo, precedentes e action bar.
- **`AnalysisHeaderView`** (`lib/ui/intake/widgets/pages/analysis_screen/analysis_header/analysis_header_view.dart`) - wrapper visual do header que repassa as acoes para `AnalysisHeaderActions`.
- **`AnalysisHeaderActionsView`** (`lib/ui/intake/widgets/pages/analysis_screen/analysis_header/analysis_header_actions/analysis_header_actions_view.dart`) - popover atual do menu `tune`; sera o ponto de entrada direto para `Exportar PDF`.
- **`RelevantPrecedentsBubblePresenter`** (`lib/ui/intake/widgets/pages/analysis_screen/relevant_precedents_bubble/relevant_precedents_bubble_presenter.dart`) - referencia de presenter filho que ja consome os dados de precedentes e mantem `selectedPrecedent`; continua responsavel por confirmar o precedente escolhido, com sincronizacao posterior do estado do header na tela pai.
- **`ChosenPrecedentSummaryView`** (`lib/ui/intake/widgets/pages/analysis_screen/chosen_precedent_summary/chosen_precedent_summary_view.dart`) - referencia visual do precedente escolhido, util para manter coerencia entre UI e pagina final do PDF.
- **`PrecedentDialogView`** (`lib/ui/intake/widgets/pages/analysis_screen/precedent_dialog/precedent_dialog_view.dart`) - referencia visual atual dos campos juridicos do precedente na experiencia mobile (`enunciation`, `thesis`, `synthesis`).
- **`HomeScreenPresenter.formatCreatedAt`** (`lib/ui/intake/widgets/pages/home_screen/home_screen_presenter.dart`) - referencia simples ja existente para formatacao de datas em `dd/MM/yyyy`.

## Design

- **`PDF Juridico / Relatorio Recriado`** (`design/animus.pen`, node `k2yVd`) - referencia visual principal do relatorio exportado.
- **`PDF / Pagina 1 — Cabecalho`** (`design/animus.pen`, node `ivnUM`) - referencia da capa/cabecalho do relatorio.
- **`PDF / Pagina 2 — Sintese da peticao`** (`design/animus.pen`, node `uefyz`) - referencia da pagina de resumo da peticao.
- **`PDF / Pagina 3 — Precedentes analisados`** (`design/animus.pen`, node `ZeOxL`) - referencia da listagem de precedentes e seus cards.
- **`PDF / Pagina 4 — Precedente escolhido`** (`design/animus.pen`, node `nHH0B`) - referencia do destaque final do precedente escolhido.

---

# 5. O que deve ser criado?

## Camada REST (Mappers)

- **Localizacao:** `lib/rest/mappers/intake/analysis_report_mapper.dart` (**novo arquivo**)
- **Metodos:**
- `AnalysisReportDto toDto(Map<String, dynamic> json)` - mapeia `analysis`, `petition`, `summary`, `precedents` e `chosen_precedent` para `AnalysisReportDto`, reutilizando `AnalysisMapper`, `PetitionMapper`, `PetitionSummaryMapper` e `AnalysisPrecedentMapper`.
- `AnalysisPrecedentDto _toChosenPrecedent(Map<String, dynamic> json)` - mapeia `chosen_precedent` para `AnalysisPrecedentDto` e falha quando o campo obrigatorio vier ausente ou invalido.

## Camada Core (Interfaces / Contratos)

- **Localizacao:** `lib/core/shared/interfaces/pdf_driver.dart` (**novo arquivo**)
- **Metodos:**
- `Future<Uint8List> generateAnalysisReport({required AnalysisReportDto report})` - gera o documento PDF em memoria a partir do DTO agregado, sem depender de tipos de Flutter no contrato publico.
- `Future<void> sharePdf({required Uint8List bytes, required String filename})` - abre o mecanismo nativo de compartilhamento para os bytes ja gerados.

## Camada Drivers (Adaptadores)

- **Localizacao:** `lib/drivers/pdf-driver/printing/printing_pdf_driver.dart` (**novo arquivo**)
- **Interface implementada (port do `core`):** `PdfDriver`
- **Biblioteca/pacote utilizado:** `pdf`, `printing`
- **Metodos:**
- `Future<Uint8List> generateAnalysisReport({required AnalysisReportDto report})` - monta o `pw.Document`, adiciona as paginas do relatorio e retorna `doc.save()`.
- `List<pw.Widget> buildPrecedentCards({required List<AnalysisPrecedentDto> precedents})` - constroi os cards da secao de precedentes em formato compativel com `pw.MultiPage`, preservando ordenacao, integridade visual do card e quebra automatica entre paginas.
- `Future<void> sharePdf({required Uint8List bytes, required String filename})` - delega ao `Printing.sharePdf(bytes: bytes, filename: filename)` para abrir o share sheet nativo.

- **Localizacao:** `lib/drivers/pdf-driver/printing/animus_pdf_theme.dart` (**novo arquivo**)
- **Interface implementada (port do `core`):** Nao aplicavel.
- **Biblioteca/pacote utilizado:** `pdf`, `printing`
- **Metodos:**
- `Future<pw.ThemeData> load()` - monta o tema tipografico Unicode-safe do PDF com `PdfGoogleFonts`, mantendo a configuracao visual confinada ao driver.
- `String formatKindLabel(PrecedentKindDto kind)` - traduz o enum tecnico para o rotulo exibido nos chips do relatorio (`Sumula`, `Tema repetitivo`, `Apelacao`, etc.).

- **Localizacao:** `lib/drivers/pdf-driver/index.dart` (**novo arquivo**)
- **Interface implementada (port do `core`):** fronteira publica do driver
- **Biblioteca/pacote utilizado:** `flutter_riverpod`
- **Metodos:**
- `pdfDriverProvider` - disponibiliza a implementacao concreta `PrintingPdfDriver` para os presenters do modulo `intake`.

## Camada UI (Barrel Files / `index.dart`)

**Nao aplicavel**.

## Camada UI (Presenters)

**Nao aplicavel**.

## Camada UI (Views)

**Nao aplicavel**.

## Camada UI (Widgets Internos)

**Nao aplicavel**.

## Camada UI (Providers Riverpod — se isolados)

**Nao aplicavel**.

## Rotas (`go_router`) — se aplicavel

**Nao aplicavel**.

## Estrutura de Pastas (Obrigatorio quando ha widgets internos)

**Nao aplicavel**.

---

# 6. O que deve ser modificado?

## App / Dependencias

- **Arquivo:** `pubspec.yaml`
- **Mudanca:** adicionar os pacotes `pdf` e `printing` em `dependencies`.
- **Justificativa:** o app ainda nao possui a stack necessaria para gerar e compartilhar documentos PDF nativamente.

## Core

- **Arquivo:** `lib/core/intake/interfaces/intake_service.dart`
- **Mudanca:** adicionar `Future<RestResponse<AnalysisReportDto>> getAnalysisReport({required String analysisId});`.
- **Justificativa:** o presenter da tela precisa consumir o contrato agregado do relatorio sem conhecer `RestClient`.

## REST

- **Arquivo:** `lib/rest/services/intake_rest_service.dart`
- **Mudanca:** implementar `getAnalysisReport(...)`, consumindo `GET /intake/analyses/{analysis_id}/report` e retornando `RestResponse<AnalysisReportDto>` via `AnalysisReportMapper.toDto`.
- **Justificativa:** a camada REST deve isolar endpoint, autenticacao e parsing do payload agregado.

## UI

- **Arquivo:** `lib/ui/intake/widgets/pages/analysis_screen/analysis_screen_presenter.dart`
- **Mudanca:** injetar `PdfDriver`; adicionar `signal<bool> isExportingReport`; adicionar `computed<bool> canExportReport`; adicionar `Future<bool> exportAnalysisReport()`, helper interno para compor o nome do arquivo e sincronizacao local de `status` para `precedentChosen` quando a escolha do precedente for confirmada na propria tela.
- **Justificativa:** a exportacao e uma acao de tela, depende do `analysisId` atual e precisa orquestrar request remoto, geracao do PDF, share e tratamento de erro no mesmo presenter.

- **Arquivo:** `lib/ui/intake/widgets/pages/analysis_screen/analysis_screen_view.dart`
- **Mudanca:** conectar a nova acao `onExportReport` no header, reagir a `isExportingReport`, disparar `presenter.exportAnalysisReport()`, sincronizar o status da tela apos a confirmacao de precedente e exibir `SnackBar` de sucesso quando o share sheet ficar disponivel.
- **Justificativa:** a View precisa apenas despachar o evento e refletir feedback visual, sem assumir logica de negocio nem importacao de SDKs.

- **Arquivo:** `lib/ui/intake/widgets/pages/analysis_screen/analysis_header/analysis_header_view.dart`
- **Mudanca:** adicionar props `VoidCallback? onExportReport`, `bool showExportReport`, `bool isExportingReport` e repassa-las para `AnalysisHeaderActions`.
- **Justificativa:** o wrapper do header precisa conhecer o novo item de menu e o estado de carregamento local da exportacao.

- **Arquivo:** `lib/ui/intake/widgets/pages/analysis_screen/analysis_header/analysis_header_actions/analysis_header_actions_view.dart`
- **Mudanca:** incluir o item `Exportar PDF` no `PopupMenuButton`, exibi-lo apenas quando `showExportReport == true`, e tratar o estado ocupado enquanto `isExportingReport == true`.
- **Justificativa:** este e o ponto de entrada visual exigido pelo PRD e pelo ticket.

---

# 7. O que deve ser removido?

**Nao aplicavel**.

---

# 8. Decisoes Tecnicas e Trade-offs

- **Decisao:** encapsular `pdf` + `printing` em um `PdfDriver` do `core`.
- **Alternativas consideradas:** chamar `Printing.sharePdf(...)` diretamente na View; deixar a UI gerar `pw.Document`; dividir o fluxo entre um builder utilitario solto e um driver de share.
- **Motivo da escolha:** as regras arquiteturais do projeto proíbem SDKs concretos na UI e no `core`; um driver unico preserva a fronteira da capacidade externa.
- **Impactos / trade-offs:** o contrato do driver fica um pouco mais amplo, mas a UI continua desacoplada de plugins e pacotes concretos.

- **Decisao:** manter `AnalysisReportDto` como agregador central do export, sem criar DTO paralelo para a feature.
- **Alternativas consideradas:** montar o PDF a partir de varias chamadas ja existentes (`getAnalysis`, `getAnalysisPetition`, `getPetitionSummary`, `listAnalysisPrecedents`); criar um DTO especifico so para exportacao mobile.
- **Motivo da escolha:** o endpoint de `ANI-50` e o DTO agregado ja existem e reduzem roundtrips, duplicidade de composicao e logica de sincronizacao no presenter.
- **Impactos / trade-offs:** o mobile passa a depender da disponibilidade do endpoint agregado para exportar, mas ganha um fluxo mais simples e deterministico.

- **Decisao:** renderizar a secao `Precedentes analisados` com `pw.MultiPage`, sem limite fixo de itens por pagina.
- **Alternativas consideradas:** limitar o PDF aos primeiros precedentes; truncar a lista com CTA textual; tentar encaixar todos os cards em uma pagina unica reduzindo tipografia e espacamentos.
- **Motivo da escolha:** o relatorio precisa refletir todos os precedentes retornados pelo backend e manter legibilidade, mesmo quando a analise gerar uma lista extensa.
- **Impactos / trade-offs:** a secao de precedentes deixa de corresponder a uma pagina fixa do layout e passa a ocupar `N` paginas, mas preserva integridade do conteudo e evita compressao visual artificial.

- **Decisao:** permitir que a pagina de sintese da peticao e a pagina do precedente escolhido usem `pw.MultiPage` quando o conteudo crescer alem da altura util.
- **Alternativas consideradas:** manter ambas como paginas fixas e reduzir texto/espacamento ate caber; dividir manualmente o conteudo em paginas estaticas extras.
- **Motivo da escolha:** os textos reais do backend podem exceder o layout de referencia, e o fluxo nao pode depender de altura fixa para continuar funcional.
- **Impactos / trade-offs:** o PDF pode ganhar paginas extras nesses casos, mas evita sumico de conteudo e cortes silenciosos.

- **Decisao:** nao expor `ThemeData` nem tipos do pacote `pdf` no contrato publico do `core`.
- **Alternativas consideradas:** seguir literalmente o contrato descrito no ticket com `theme: ThemeData`; passar `pw.ThemeData` pelo presenter.
- **Motivo da escolha:** `core` nao pode depender de Flutter nem de tipos concretos de pacote externo; o acoplamento visual deve ficar confinado a `drivers`.
- **Impactos / trade-offs:** a implementacao concreta do driver precisa ler `AppTheme` internamente, mas a arquitetura continua correta.

- **Decisao:** manter a logica de exportacao no `AnalysisScreenPresenter`, sem criar presenter filho dedicado para o header.
- **Alternativas consideradas:** criar um `analysis_export_action_presenter` ou um presenter exclusivo para `AnalysisHeaderActions`.
- **Motivo da escolha:** a exportacao e uma unica acao de tela, parametrizada pelo `analysisId` atual e dependente do estado principal da analise; mover isso para um presenter filho acrescentaria mais acoplamento do que organizacao.
- **Impactos / trade-offs:** o presenter da tela ganha mais um handler, mas continua agindo como orquestrador de acoes de cabecalho sem concentrar subfluxos inteiros de UI.

- **Decisao:** seguir o `AnalysisReportDto` atual e o layout validado no node `k2yVd` para os campos do PDF, mesmo com divergencia em relacao ao RF-06.
- **Alternativas consideradas:** forcar a spec a incluir `Questao` e `Status` por precedente conforme o PRD; bloquear a spec ate alinhamento entre produto, backend e design.
- **Motivo da escolha:** `Questao` foi definido como equivalente ao campo atual `enunciation`, e `Status` foi removido do escopo funcional do PDF.
- **Impactos / trade-offs:** o relatorio fica alinhado ao contrato e ao layout atuais sem exigir mudancas adicionais no backend ou no design.

- **Decisao:** usar `PdfGoogleFonts.inter*` como base tipografica do PDF para garantir suporte Unicode e evitar fallback involuntario para Helvetica.
- **Alternativas consideradas:** fontes padrao do pacote `pdf`; fontes embarcadas manualmente em assets do app.
- **Motivo da escolha:** as fontes padrao do pacote `pdf` nao cobrem adequadamente acentos e alguns caracteres usados pelo app, e o uso de `PdfGoogleFonts` simplifica a composicao Unicode-safe dentro do driver.
- **Impactos / trade-offs:** a configuracao do tema depende do carregamento dessas fontes pela stack do `printing`, mas elimina os erros de glyph observados com Helvetica.

- **Decisao:** priorizar estabilidade do renderer do `dart_pdf` sobre reproducao literal de ornamentos decorativos do Pencil.
- **Alternativas consideradas:** reproduzir integralmente badges ovais, selo de pagina no canto superior direito e barras com `borderRadius` muito alto.
- **Motivo da escolha:** alguns desses ornamentos geraram deformacoes visuais, altura infinita ou erros de renderizacao no mobile.
- **Impactos / trade-offs:** o PDF final preserva hierarquia, paleta amber e leitura do layout, mas simplifica adornos mais sensiveis do design original.

- **Decisao:** truncar textos longos dos cards de precedentes com reticencias quando excederem um limite seguro de renderizacao.
- **Alternativas consideradas:** deixar o renderer tentar paginar cards gigantes; limitar a quantidade de precedentes exportados.
- **Motivo da escolha:** evita `TooManyPagesException` e mantem o fluxo de exportacao robusto diante de teses e sinteses excepcionalmente longas.
- **Impactos / trade-offs:** em cenarios extremos o PDF pode resumir parte do texto de um card, mas continua gerando o documento sem falha para o usuario.

- **Decisao:** usar `SnackBar` para confirmacao breve de sucesso, alem da abertura do share sheet.
- **Alternativas consideradas:** exibir `MessageBox` inline; nao exibir nenhuma confirmacao adicional; abrir dialog modal de sucesso.
- **Motivo da escolha:** `SnackBar` e um feedback transitorio coerente com a UX atual e nao polui a tela com estado persistente apos o share.
- **Impactos / trade-offs:** o feedback de sucesso fica na View como preocupacao puramente visual e precisa ser disparado apenas em sucesso confirmado do presenter.

---

# 9. Diagramas e Referencias

- **Fluxo de dados:**

```text
PopupMenuItem("Exportar PDF")
  -> AnalysisHeaderActionsView.onSelected
  -> AnalysisScreenView
  -> AnalysisScreenPresenter.exportAnalysisReport()
     -> IntakeService.getAnalysisReport(analysisId)
        -> IntakeRestService.get('/intake/analyses/{analysis_id}/report')
        -> AnalysisReportMapper.toDto(json)
     -> PdfDriver.generateAnalysisReport(report)
        -> AnimusPdfTheme.load()
        -> pw.Document.addPage(...)
        -> Uint8List bytes
     -> PdfDriver.sharePdf(bytes, filename)
        -> Printing.sharePdf(...)
        -> share sheet nativo
```

- **Hierarquia de widgets (feature):**

```text
AnalysisScreenView
  AnalysisHeader
    AnalysisHeaderActions
      PopupMenuButton
        Exportar PDF
  body
    PetitionSummaryCard
    RelevantPrecedentsBubble
    ChosenPrecedentSummary
```

- **Hierarquia do PDF (node `k2yVd`):**

```text
PDF Juridico / Relatorio Recriado
  Pagina 1 - Cabecalho
    titulo da analise
    dados da analise
    dados da peticao
  Pagina 2 - Sintese da peticao
    resumo do caso
    questao central
    enquadramento juridico
    fatos relevantes
    legislacao aplicavel
  Pagina 3..N - Precedentes analisados
    lista ordenada de cards de precedente
    destaque textual de aplicabilidade
    quebra automatica entre paginas
  Pagina final..N - Precedente escolhido
    card destacado do precedente final
    quebra automatica quando necessario
```

- **Referencias:**
- `lib/core/intake/dtos/analysis_report_dto.dart`
- `lib/core/intake/interfaces/intake_service.dart`
- `lib/rest/services/intake_rest_service.dart`
- `lib/rest/mappers/intake/analysis_mapper.dart`
- `lib/rest/mappers/intake/petition_summary_mapper.dart`
- `lib/rest/mappers/intake/analysis_precedent_mapper.dart`
- `lib/ui/intake/widgets/pages/analysis_screen/analysis_screen_presenter.dart`
- `lib/ui/intake/widgets/pages/analysis_screen/analysis_screen_view.dart`
- `lib/ui/intake/widgets/pages/analysis_screen/analysis_header/analysis_header_actions/analysis_header_actions_view.dart`
- `lib/ui/intake/widgets/pages/analysis_screen/relevant_precedents_bubble/relevant_precedents_bubble_presenter.dart`
- `lib/drivers/external-link-driver/index.dart`
- `lib/drivers/storage/file_storage/gcs_file_storage_driver.dart`
- `design/animus.pen` (nodes `k2yVd`, `ivnUM`, `uefyz`, `ZeOxL`, `nHH0B`)

---

# 10. Pendencias / Duvidas

**Sem pendencias**.

---

# Restricoes

- **Nao inclua testes automatizados na spec.**
- A `View` nao deve conter logica de negocio; toda orquestracao de exportacao fica no `AnalysisScreenPresenter`.
- Presenters nao fazem chamadas diretas a `RestClient`; a busca do relatorio passa sempre por `IntakeService`.
- Todos os caminhos citados nesta spec existem no projeto ou estao marcados como **novo arquivo**.
- Nenhum contrato novo do `core` deve depender de `ThemeData`, `BuildContext`, `pw.ThemeData` ou qualquer tipo de SDK/pacote concreto.
- O share sheet nativo deve ficar encapsulado em `drivers`; a UI nao pode importar `printing`.
- O `AnalysisScreenPresenter` continua enxuto como orquestrador de acoes de tela; nao deve absorver montagem visual do PDF nem detalhes de pacote externo.
- Use componentes Flutter Material alinhados ao tema atual do projeto para o feedback visual de loading e sucesso na tela.
- A spec segue o padrao atual da codebase: arquivos em `snake_case`, classes em `PascalCase`, `Provider` Riverpod para composicao e barrel files apenas quando houver nova pasta publica.
