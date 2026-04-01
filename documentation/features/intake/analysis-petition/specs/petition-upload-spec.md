---
title: Upload e analise de petição inicial
prd: documentation/features/intake/analysis-petition/prd.md
ticket: https://joaogoliveiragarcia.atlassian.net/browse/ANI-46
status: open
last_updated_at: 2026-04-01
---

# 1. Objetivo

Entregar a tela `Nova Analise` do fluxo de `intake`, recebendo um `analysisId` ja criado, permitindo selecionar um unico arquivo `PDF` ou `DOCX`, validar tamanho maximo de `20MB`, solicitar `Signed URL`, fazer upload direto ao `GCS`, persistir a `Petition` no backend, solicitar o resumo sincrono com timeout de `60s` e refletir o estado da tela a partir de `AnalysisStatusDto`, combinado com estados locais transitivos de selecao de arquivo, upload e erro, em uma UI estilo chat consistente com o design validado no `design/animus.pen`.

---

# 2. Escopo

## 2.1 In-scope

- Tela `Nova Analise` parametrizada por `analysisId`.
- Selecao nativa de arquivo com filtro para `pdf` e `docx`.
- Validacao client-side de extensao e limite de `20MB` antes de qualquer chamada remota.
- Orquestracao completa do fluxo `generatePetitionUploadUrl -> uploadFile -> createPetition -> summarizePetition`.
- Exibicao dos estados visuais derivada de `AnalysisStatusDto`, combinada com estados locais de selecao de arquivo, upload em andamento e erro recuperavel.
- Exibicao do bubble do usuario com nome e tamanho do arquivo selecionado.
- Exibicao de `PetitionSummaryCard` com secoes para `caseSummary`, `legalIssue`, `centralQuestion`, `relevantLaws`, `keyFacts` e `searchTerms`.
- Acao de `Enviar outro documento` reiniciando o fluxo local para a mesma `analysisId`.
- Contratos, services REST, drivers e providers necessarios para manter a arquitetura por camadas.
- Registro/alinhamento da rota da tela de analise para consumir `analysisId` por path parameter.

## 2.2 Out-of-scope

- Criacao da `analysis` antes de abrir a tela; isso pertence ao fluxo da home/FAB descrito em `ANI-60`.
- Navegacao final apos `Buscar precedentes`; o destino funcional depende de `ANI-49`.
- Suporte a formatos diferentes de `PDF` e `DOCX`.
- Upload multiplo, drag and drop ou edicao manual do resumo.
- OCR, leitura de imagens embutidas ou documentos sem camada textual.
- Listagem, exclusao ou download de arquivos genericos de storage fora do caso de uso de petição.

---

# 3. Requisitos

## 3.1 Funcionais

- Ao abrir a tela, exibir bubble inicial da IA com a mensagem de boas-vindas e a legenda `Formatos aceitos: PDF, DOCX • Max. 20MB`.
- O botao de CTA principal deve permanecer desabilitado enquanto nenhum arquivo valido estiver selecionado.
- Ao tocar em `Selecionar arquivo`, abrir o picker nativo do dispositivo filtrado para `pdf` e `docx`.
- A tela deve manter somente um arquivo selecionado por vez.
- Se o arquivo for invalido por extensao ou tamanho, a tela deve impedir o envio e exibir erro inline.
- Ao tocar em `Analisar`, a tela deve solicitar a `Signed URL` de upload para a `analysisId` atual e para o `document_type` derivado da extensao do arquivo.
- Durante o upload para o `GCS`, a tela deve refletir progresso e bloquear novas interacoes de pick/analyze.
- Depois do upload concluido, a tela deve persistir a `Petition` via `POST /petitions`.
- Depois da `Petition` criada, a tela deve solicitar `POST /petitions/{petition_id}/summary` e exibir o estado de processamento da IA.
- O sucesso deste recorte deve deixar a `analysis` compativel com o status de dominio `PETITION_ANALYZED`, sem antecipar as etapas posteriores de precedentes e sintese.
- Em sucesso, a tela deve exibir `PetitionSummaryCard`, trocar a acao secundaria para `Enviar outro documento` e trocar a acao primaria para `Buscar precedentes`.
- Abaixo do `PetitionSummaryCard`, a tela deve exibir um botao de retry do resumo para reexecutar `summarizePetition` na mesma `petition` atual.
- Em falha de upload, criacao da petição, resumo, timeout ou resposta de negocio, a tela deve exibir erro inline e permitir nova tentativa sem perder o arquivo selecionado.
- Toda falha futura desta tela deve reutilizar a mesma shell visual e a mesma mensagem base de erro definida para o estado `Failed`, evitando variacoes de UX entre tipos diferentes de erro.

## 3.2 Nao funcionais

- **Performance:** o request de resumo deve ser abortado no cliente apos `60s` com mensagem explicita de timeout.
- **Performance:** o upload deve refletir progresso a partir de bytes enviados pelo `GCS PUT`, sem polling paralelo.
- **Offline/Conectividade:** falhas de rede no upload, criacao da petição ou resumo devem resultar em erro recuperavel com retry manual.
- **Seguranca:** o app nao deve persistir o conteudo do arquivo localmente; apenas manter referencia temporaria ao arquivo selecionado enquanto a tela estiver ativa.
- **Compatibilidade:** o picker e o upload devem funcionar em `Android` e `iOS` usando plugins/pacotes suportados no projeto Flutter atual.
- **Usabilidade:** botoes devem ficar desabilitados durante upload local e enquanto `AnalysisStatusDto` indicar processamento da petição para evitar chamadas duplicadas.

---

# 4. O que ja existe?

## Core

- **`PetitionDto`** (`lib/core/intake/dtos/petition_dto.dart`) — DTO base do `POST /petitions`, ja contendo `analysisId`, `uploadedAt` e `document`.
- **`AnalysisStatusDto`** (`lib/core/intake/dtos/analysis_status_dto.dart`) — enum de status da analise no dominio `intake`, incluindo `WAITING_PETITION`, `ANALYZING_PETITION`, `PETITION_ANALYZED` e estados posteriores do fluxo completo. Este enum deve dirigir o estado funcional da tela.
- **`PetitionDocumentDto`** (`lib/core/intake/dtos/petition_document_dto.dart`) — DTO do documento anexado, contendo `filePath` e `name` alinhados ao contrato atual.
- **`PetitionSummaryDto`** (`lib/core/intake/dtos/petition_summary_dto.dart`) — DTO do resumo, contendo `caseSummary`, `legalIssue`, `centralQuestion`, `relevantLaws`, `keyFacts` e `searchTerms`.
- **`UploadUrlDto`** (`lib/core/storage/dtos/upload_url_dto.dart`) — DTO retornado pelo endpoint de `Signed URL`, com `url`, `token` e `filePath`.
- **`IntakeService`** (`lib/core/intake/interfaces/intake_service.dart`) — contrato ainda vazio, reservado para os gateways remotos de `intake`.
- **`StorageService`** (`lib/core/storage/interfaces/storage_service.dart`) — contrato atual de storage ainda generico e nao aderente ao endpoint de upload de petição.
- **`FileStorageDriver`** (`lib/core/storage/interfaces/drivers/file_storage_driver.dart`) — porta de infraestrutura para arquivos; ainda nao existe implementacao concreta no app.
- **`RestResponse`** (`lib/core/shared/responses/rest_response.dart`) — envelope padrao de sucesso/falha usado pela UI para tratar erros sem vazar detalhes de transporte.

## REST

- **`RestClient`** (`lib/core/shared/interfaces/rest_client.dart`) — contrato HTTP consumido pelos services.
- **`DioRestClient`** (`lib/rest/dio/dio_rest_client.dart`) — implementacao concreta baseada em `Dio`, ja usada pelo app.
- **`AuthRestService`** (`lib/rest/services/auth_rest_service.dart`) — referencia de implementacao de interface do `core`, uso de `RestResponse` e tratamento de erros.
- **`authServiceProvider`** (`lib/rest/services/index.dart`) — referencia de composicao Riverpod para gateways REST.
- **`lib/rest/mappers/intake/`** — pasta existente, ainda sem mappers implementados para o dominio.

## Drivers

- **`SharedPreferencesCacheDriver`** (`lib/drivers/caches/shared_preferences/shared_preferences_cache_driver.dart`) — referencia de provider + implementacao concreta em driver.
- **`GoogleSignInGoogleAuthDriver`** (`lib/drivers/google-auth-driver/google_sign_in/google_sign_in_google_auth_driver.dart`) — referencia de wrapper de plugin atras de contrato do `core`.
- **`lib/drivers/storage/file_storage/`** — pasta reservada para o driver concreto de storage, atualmente vazia.

## UI

- **`SignInScreenPresenter`** (`lib/ui/auth/widgets/pages/sign_in_screen/sign_in_screen_presenter.dart`) — referencia principal de presenter com `signals`, `computed`, `Provider.autoDispose` e tratamento de `RestResponse`.
- **`CheckEmailScreenPresenter`** (`lib/ui/auth/widgets/pages/check_email_screen/check_email_screen_presenter.dart`) — referencia de `Provider.autoDispose.family`, padrao necessario para parametrizar a tela por `analysisId`.
- **`SignInScreenView`** (`lib/ui/auth/widgets/pages/sign_in_screen/sign_in_screen_view.dart`) — referencia de `Scaffold` com `ConstrainedBox(maxWidth: 402)` e uso de `AppThemeTokens`.
- **`Routes.analysis`** (`lib/constants/routes.dart`) — constante de rota existente para analise, ainda sem parametrizacao por `analysisId`.
- **`router.dart`** (`lib/router.dart`) — ponto de registro das rotas do app.
- **`lib/ui/intake/widgets/pages/`** — pasta do modulo `intake`, ainda sem tela implementada.

---

# 5. O que deve ser criado?

## Camada Core (Interfaces / Contratos)

- **Localizacao:** `lib/core/storage/interfaces/drivers/document_picker_driver.dart` (**novo arquivo**)
- **Metodos:**
- `Future<File?> pickDocument({required List<String> allowedExtensions})` — abre o picker nativo filtrado pelas extensoes permitidas e retorna o arquivo selecionado ou `null` em cancelamento.

## Camada REST (Services)

- **Localizacao:** `lib/rest/services/intake_rest_service.dart` (**novo arquivo**)
- **Interface implementada:** `IntakeService`
- **Dependencias:** `RestClient`
- **Metodos:**
- `Future<RestResponse<PetitionDto>> createPetition({required PetitionDto petition})` — envia `POST /petitions` com payload mapeado para `snake_case` e retorna a petição persistida com `id`.
- `Future<RestResponse<PetitionSummaryDto>> summarizePetition({required String petitionId})` — envia `POST /petitions/{petition_id}/summary` e retorna o resumo da petição.

- **Localizacao:** `lib/rest/services/storage_rest_service.dart` (**novo arquivo**)
- **Interface implementada:** `StorageService`
- **Dependencias:** `RestClient`
- **Metodos:**
- `Future<RestResponse<UploadUrlDto>> generatePetitionUploadUrl({required String analysisId, required String documentType})` — envia `POST /storage/analyses/{analysis_id}/petitions/upload?document_type=pdf|docx` e retorna a `Signed URL` para upload direto.

## Camada REST (Mappers)

- **Localizacao:** `lib/rest/mappers/intake/petition_mapper.dart` (**novo arquivo**)
- **Metodos:**
- `PetitionDto toDto(Map<String, dynamic> json)` — mapeia `id`, `analysis_id`, `uploaded_at`, `document.file_path` e `document.name` para `PetitionDto`.
- `Map<String, dynamic> toJson(PetitionDto dto)` — mapeia `analysisId`, `uploadedAt` e `document.filePath/name` para o body do endpoint.

- **Localizacao:** `lib/rest/mappers/intake/petition_summary_mapper.dart` (**novo arquivo**)
- **Metodos:**
- `PetitionSummaryDto toDto(Map<String, dynamic> json)` — mapeia `case_summary`, `legal_issue`, `central_question`, `relevant_laws`, `key_facts` e `search_terms` para `PetitionSummaryDto`.

- **Localizacao:** `lib/rest/mappers/storage/upload_url_mapper.dart` (**novo arquivo**)
- **Metodos:**
- `UploadUrlDto toDto(Map<String, dynamic> json)` — mapeia `url`, `token` e `file_path` para `UploadUrlDto`.

## Camada Drivers (Adaptadores)

- **Localizacao:** `lib/drivers/document-picker-driver/file_picker/file_picker_document_picker_driver.dart` (**novo arquivo**)
- **Interface implementada (port do `core`):** `DocumentPickerDriver`
- **Biblioteca/pacote utilizado:** `file_picker`
- **Metodos:**
- `Future<File?> pickDocument({required List<String> allowedExtensions})` — usa o picker nativo com filtro por extensao e retorna `File` pronto para leitura local.

- **Localizacao:** `lib/drivers/document-picker-driver/index.dart` (**novo arquivo**)
- **Interface implementada (port do `core`):** fronteira publica do driver
- **Biblioteca/pacote utilizado:** `flutter_riverpod`
- **Metodos:**
- `documentPickerDriverProvider` — disponibiliza `DocumentPickerDriver` concreto para presenters.

- **Localizacao:** `lib/drivers/storage/file_storage/gcs_file_storage_driver.dart` (**novo arquivo**)
- **Interface implementada (port do `core`):** `FileStorageDriver`
- **Biblioteca/pacote utilizado:** `dio`
- **Metodos:**
- `Future<void> uploadFile(File file, UploadUrlDto uploadUrl, {void Function(int sentBytes, int totalBytes)? onProgress})` — faz `PUT` direto na `Signed URL` do `GCS`, reportando bytes enviados para a UI quando houver callback.

- **Localizacao:** `lib/drivers/storage/file_storage/index.dart` (**novo arquivo**)
- **Interface implementada (port do `core`):** fronteira publica do driver
- **Biblioteca/pacote utilizado:** `flutter_riverpod`
- **Metodos:**
- `fileStorageDriverProvider` — disponibiliza `FileStorageDriver` concreto para presenters.

## Camada UI (Presenters)

- **Localizacao:** `lib/ui/intake/widgets/pages/analysis_screen/analysis_screen_presenter.dart` (**novo arquivo**)
- **Dependencias injetadas:** `IntakeService`, `StorageService`, `FileStorageDriver`, `DocumentPickerDriver`
- **Estado (`signals`):**
- `signal<AnalysisStatusDto> status` — estado funcional principal da tela, derivado do dominio, iniciando em `AnalysisStatusDto.waitingPetition` e evoluindo para `analyzingPetition`, `petitionAnalyzed` ou `failed` conforme o fluxo.
- `signal<File?> selectedFile` — referencia temporaria ao arquivo escolhido.
- `signal<bool> isUploading` — estado transitivo local usado durante o `PUT` para a `Signed URL`.
- `signal<double?> uploadProgress` — progresso do upload em faixa `0..1`; `null` quando nao houver upload local em andamento.
- `signal<PetitionDto?> petition` — petição criada no backend para uso interno do fluxo.
- `signal<PetitionSummaryDto?> summary` — resumo retornado pelo backend.
- `signal<String?> generalError` — mensagem inline de falha de validacao, upload ou resumo. Para erros do fluxo remoto, deve reutilizar a mensagem padrao definida para o estado `Failed`.
- `computed<bool> canPickDocument` — habilita o picker quando a tela nao esta ocupada.
- `computed<bool> canAnalyze` — habilita `Analisar` somente quando houver arquivo selecionado, sem `generalError` bloqueante, sem upload local em andamento e com `status` compativel com `AnalysisStatusDto.waitingPetition` ou retry apos `failed`.
- `computed<bool> showProcessingBubble` — exibe o bubble da IA quando `status == AnalysisStatusDto.analyzingPetition`.
- `computed<String> primaryActionLabel` — alterna entre `Analisar` e `Buscar precedentes`.
- `computed<String> fileActionLabel` — alterna entre `Selecionar arquivo` e `Enviar outro documento`.
- **Provider Riverpod:** `analysisScreenPresenterProvider`
- **Metodos:**
- `Future<void> pickDocument()` — abre o picker, valida extensao/tamanho, limpa erro anterior, substitui a selecao local e preserva `status` compativel com a etapa atual da analise.
- `Future<void> analyze()` — orquestra `generatePetitionUploadUrl`, upload ao `GCS` com progresso local, `createPetition` e `summarizePetition` com timeout de `60s`, atualizando `status` com base em `AnalysisStatusDto` e preenchendo mensagens de erro quando necessario.
- `Future<void> retrySummary()` — reexecuta `summarizePetition` para a `petition` atual quando a tela ja estiver em `AnalysisStatusDto.petitionAnalyzed`.
- `Future<void> replaceDocument()` — reaproveita `pickDocument()` quando `status == AnalysisStatusDto.petitionAnalyzed`, limpando `petition`, `summary`, `uploadProgress` e retornando o fluxo para `AnalysisStatusDto.waitingPetition` antes da nova selecao.
- `void confirmAndViewPrecedents()` — preserva o ponto unico de integracao com `ANI-49`; nesta task nao deve acoplar rota inexistente, mesmo com o CTA rotulado como `Buscar precedentes`.
- `void dispose()` — libera `signals` internos do presenter.

## Camada UI (Views)

- **Localizacao:** `lib/ui/intake/widgets/pages/analysis_screen/analysis_screen_view.dart` (**novo arquivo**)
- **Base class:** `ConsumerWidget`
- **Props:** `String analysisId`
- **Bibliotecas de UI:** `flutter/material.dart`, `flutter_riverpod`, `signals_flutter`
- **Estados visuais:**
- `WaitingPetition` — derivado de `AnalysisStatusDto.waitingPetition`, com header, bubble da IA, hint de formatos e action bar com CTA principal desabilitado ate haver arquivo valido.
- `Uploading` — estado transitivo local com barra/indicador de progresso durante o `PUT` para a `Signed URL`.
- `AnalyzingPetition` — derivado de `AnalysisStatusDto.analyzingPetition`, com bubble do arquivo e bubble de processamento.
- `Failed` — derivado de `AnalysisStatusDto.failed` ou erro local recuperavel, com a shell visual padrao de erro, manutencao do arquivo selecionado para retry e reutilizacao da mesma mensagem base para erros futuros desta tela.
- `PetitionAnalyzed` — derivado de `AnalysisStatusDto.petitionAnalyzed`, com resumo exibido em card, action bar em modo de reenvio, CTA final `Buscar precedentes` e botao de retry do resumo abaixo do card.

## Camada UI (Widgets Internos)

- **Localizacao:** `lib/ui/intake/widgets/pages/analysis_screen/ai_bubble/` (**novo arquivo**)
- **Tipo:** View only
- **Props:** `String? message`, `bool isTyping`, `String? footerText`
- **Responsabilidade:** renderiza o avatar da IA, o bubble inicial de boas-vindas e o bubble de processamento com texto auxiliar.

- **Localizacao:** `lib/ui/intake/widgets/pages/analysis_screen/petition_file_bubble/` (**novo arquivo**)
- **Tipo:** View only
- **Props:** `String fileName`, `String fileSizeLabel`
- **Responsabilidade:** renderiza o bubble do usuario com icone de arquivo, nome e tamanho do documento selecionado.

- **Localizacao:** `lib/ui/intake/widgets/pages/analysis_screen/petition_summary_card/` (**novo arquivo**)
- **Tipo:** View only
- **Props:** `PetitionSummaryDto summary`
- **Responsabilidade:** renderiza o card `Resumo da Analise`, exibindo as secoes do `PetitionSummaryDto` atual com listas para `relevantLaws`, `keyFacts` e `searchTerms`.
- **Responsabilidade adicional na tela:** a `AnalysisScreenView` deve exibir abaixo desse card um CTA secundario de retry para reexecutar apenas `summarizePetition`.

- **Localizacao:** `lib/ui/intake/widgets/pages/analysis_screen/analysis_action_bar/` (**novo arquivo**)
- **Tipo:** View only
- **Props:** `String fileActionLabel`, `VoidCallback? onFileAction`, `String primaryActionLabel`, `VoidCallback? onPrimaryAction`, `bool isPrimaryBusy`, `double? uploadProgress`, `String? helperText`
- **Responsabilidade:** renderiza a area fixa inferior com acao de picker/reupload, CTA principal e helper text contextual.

## Camada UI (Barrel Files / `index.dart`)

- **Localizacao:** `lib/ui/intake/widgets/pages/analysis_screen/index.dart` (**novo arquivo**)
- **`typedef` exportado:** `typedef AnalysisScreen = AnalysisScreenView`
- **Widgets internos exportados:** `ai_bubble`, `petition_file_bubble`, `petition_summary_card`, `analysis_action_bar`

- **Localizacao:** `lib/ui/intake/widgets/pages/analysis_screen/ai_bubble/index.dart` (**novo arquivo**)
- **`typedef` exportado:** `typedef AiBubble = AiBubbleView`
- **Widgets internos exportados:** Nao aplicavel.

- **Localizacao:** `lib/ui/intake/widgets/pages/analysis_screen/petition_file_bubble/index.dart` (**novo arquivo**)
- **`typedef` exportado:** `typedef PetitionFileBubble = PetitionFileBubbleView`
- **Widgets internos exportados:** Nao aplicavel.

- **Localizacao:** `lib/ui/intake/widgets/pages/analysis_screen/petition_summary_card/index.dart` (**novo arquivo**)
- **`typedef` exportado:** `typedef PetitionSummaryCard = PetitionSummaryCardView`
- **Widgets internos exportados:** Nao aplicavel.

- **Localizacao:** `lib/ui/intake/widgets/pages/analysis_screen/analysis_action_bar/index.dart` (**novo arquivo**)
- **`typedef` exportado:** `typedef AnalysisActionBar = AnalysisActionBarView`
- **Widgets internos exportados:** Nao aplicavel.

## Camada UI (Providers Riverpod — se isolados)

- **Localizacao:** `lib/ui/intake/widgets/pages/analysis_screen/analysis_screen_presenter.dart`
- **Nome do provider:** `analysisScreenPresenterProvider`
- **Tipo:** `Provider.autoDispose.family<AnalysisScreenPresenter, String>`
- **Dependencias:** `intakeServiceProvider`, `storageServiceProvider`, `fileStorageDriverProvider`, `documentPickerDriverProvider`

## Rotas (`go_router`) — se aplicavel

- **Localizacao:** `lib/router.dart` e `lib/constants/routes.dart`
- **Caminho da rota:** `/analyses/:analysisId`
- **Widget principal:** `AnalysisScreen(analysisId: state.pathParameters['analysisId']!)`
- **Guards / redirecionamentos:** redirecionar para a home quando `analysisId` estiver ausente ou vazio; alinhar com a navegacao criada por `ANI-60`.

## Estrutura de Pastas (Obrigatorio quando ha widgets internos)

```text
lib/ui/intake/widgets/pages/analysis_screen/
  index.dart
  analysis_screen_view.dart
  analysis_screen_presenter.dart
  ai_bubble/
    index.dart
    ai_bubble_view.dart
  petition_file_bubble/
    index.dart
    petition_file_bubble_view.dart
  petition_summary_card/
    index.dart
    petition_summary_card_view.dart
  analysis_action_bar/
    index.dart
    analysis_action_bar_view.dart
```

---

# 6. O que deve ser modificado?

## Core

- **Arquivo:** `lib/core/intake/dtos/petition_document_dto.dart`
- **Mudanca:** nenhuma adicional nesta task; o DTO ja usa `filePath` e `name`, alinhado ao contrato real de `ANI-44/45`.
- **Justificativa:** a spec deve refletir o estado atual do `core` e evitar indicar uma refatoracao ja concluida.

- **Arquivo:** `lib/core/intake/dtos/petition_summary_dto.dart`
- **Mudanca:** nenhuma adicional nesta task; o DTO ja esta restrito a campos imutaveis e construtor, sem serializacao embutida.
- **Justificativa:** a spec deve refletir o estado atual do `core` e manter a serializacao concentrada na camada `rest`.

- **Arquivo:** `lib/core/intake/interfaces/intake_service.dart`
- **Mudanca:** preencher o contrato com `createPetition` e `summarizePetition`, ambos retornando `RestResponse` tipado.
- **Justificativa:** a UI nao pode chamar `RestClient` diretamente; o fluxo precisa de um gateway remoto proprio do dominio `intake`.

- **Arquivo:** `lib/core/storage/interfaces/storage_service.dart`
- **Mudanca:** substituir o contrato generico atual nao utilizado por `generatePetitionUploadUrl({required String analysisId, required String documentType}) -> Future<RestResponse<UploadUrlDto>>`.
- **Justificativa:** o endpoint de `Signed URL` depende de `analysisId` e `document_type`; o contrato atual recebe `filePath`, que so existe depois da resposta do backend.

- **Arquivo:** `lib/core/storage/interfaces/drivers/file_storage_driver.dart`
- **Mudanca:** reduzir a porta para o caso de uso realmente implementado e adicionar callback opcional de progresso em `uploadFile`.
- **Justificativa:** a task exige progresso visual de upload, e os demais metodos do contrato atual nao possuem implementacao nem demanda nesta entrega.

## REST

- **Arquivo:** `lib/rest/services/index.dart`
- **Mudanca:** adicionar `intakeServiceProvider` e `storageServiceProvider`, mantendo o padrao ja usado por `authServiceProvider`.
- **Justificativa:** presenters de `intake` devem receber gateways REST via Riverpod, sem instanciacao manual.

## UI

- **Arquivo:** `lib/constants/routes.dart`
- **Mudanca:** alinhar a rota de analise para `/analyses/:analysisId` e adicionar helper `getAnalysis({required String analysisId})`.
- **Justificativa:** os endpoints do fluxo dependem de uma `analysis` ja existente; `ANI-60` ja define a navegacao a partir da home/FAB usando esse padrao.

- **Arquivo:** `lib/router.dart`
- **Mudanca:** registrar a rota parametrizada da tela de analise e instanciar `AnalysisScreen` com `analysisId` vindo de `pathParameters`.
- **Justificativa:** a tela precisa receber o `analysisId` de forma tipada e consistente com o fluxo de criacao de analise.

## Dependencias / Configuracao

- **Arquivo:** `pubspec.yaml`
- **Mudanca:** adicionar o pacote `file_picker` em `dependencies`.
- **Justificativa:** a selecao de `PDF`/`DOCX` deve usar picker nativo filtrado, e o projeto ainda nao possui dependencia equivalente instalada.

---

# 7. O que deve ser removido?

**Nao aplicavel**.

---

# 8. Decisoes Tecnicas e Trade-offs

- **Decisao:** a tela de analise deve receber `analysisId` por rota (`/analyses/:analysisId`) em vez de criar a analise dentro do proprio presenter.
- **Alternativas consideradas:** manter a rota atual sem parametro; criar `analysis` na abertura da tela.
- **Motivo da escolha:** os endpoints `ANI-44/45` exigem `analysisId` previamente existente, e `ANI-60` ja define a criacao via FAB da home.
- **Impactos / trade-offs:** a feature passa a depender da rota parametrizada; se `ANI-60` ainda nao tiver sido mergeada, esta spec precisa assumir tambem a evolucao da rota placeholder.

- **Decisao:** introduzir `DocumentPickerDriver` para encapsular `file_picker`.
- **Alternativas consideradas:** usar o plugin diretamente no presenter; colocar a selecao de arquivo dentro do `FileStorageDriver`.
- **Motivo da escolha:** preserva a fronteira arquitetural de `drivers`, evita plugin na UI e separa claramente selecao local de upload remoto.
- **Impactos / trade-offs:** adiciona uma porta nova no `core`, mas evita acoplamento futuro da UI a detalhes do plugin.

- **Decisao:** expor progresso real de upload por callback opcional em `FileStorageDriver.uploadFile`.
- **Alternativas consideradas:** spinner indeterminado sem progresso; polling paralelo; progresso fake baseado em tempo.
- **Motivo da escolha:** o ticket pede indicador de progresso, e `Dio` ja suporta `onSendProgress` sem dependencia extra.
- **Impactos / trade-offs:** o contrato do driver fica mais especifico para upload; em troca, a UI consegue refletir o estado transitivo local de upload com feedback real.

- **Decisao:** manter serializacao JSON na camada `rest` e alinhar a spec aos DTOs ja atualizados de `PetitionDocumentDto` e `PetitionSummaryDto`.
- **Alternativas consideradas:** manter a spec descrevendo `content/mainPoints`; manter `fileKey` como alias local na documentacao.
- **Motivo da escolha:** reduz divergencia entre documentacao, `core`, regras arquiteturais e contratos remotos efetivos de `ANI-44/45`.
- **Impactos / trade-offs:** a UI e os mappers passam a depender explicitamente da estrutura atual do resumo, em troca de eliminar ambiguidade documental.

- **Decisao:** manter o CTA primario final como `Buscar precedentes`, mas isolar o handler em metodo proprio sem inventar a navegacao final nesta task.
- **Alternativas consideradas:** esconder o CTA ate `ANI-49`; navegar para rota provisoria; acoplar em rota ainda nao definida.
- **Motivo da escolha:** o design e o ticket exigem a mudanca visual do CTA, enquanto `ANI-49` ainda nao define o destino funcional.
- **Impactos / trade-offs:** a tela fica pronta visualmente e com ponto unico de extensao, mas a navegacao final permanece pendente de especificacao.

- **Decisao:** documentar explicitamente que este fluxo cobre apenas o recorte ate `AnalysisStatusDto.petitionAnalyzed`.
- **Alternativas consideradas:** nao citar `AnalysisStatusDto` na spec; assumir implicitamente a transicao de status apenas pelo resumo retornado.
- **Motivo da escolha:** o `core` agora materializa os estados do backend, e a spec precisa deixar claro o limite entre upload/resumo da petição e as etapas posteriores do pipeline.
- **Impactos / trade-offs:** reduz ambiguidade com `ANI-49` e tarefas futuras, mas explicita uma dependencia maior da spec sobre o enum de dominio atual.

---

# 9. Diagramas e Referencias

- **Fluxo de dados:**

```text
AnalysisScreenView(analysisId)
  -> AnalysisScreenPresenter
      -> DocumentPickerDriver.pickDocument()
      -> StorageService.generatePetitionUploadUrl(analysisId, documentType)
          -> StorageRestService
              -> RestClient.post('/storage/analyses/{analysisId}/petitions/upload')
      -> FileStorageDriver.uploadFile(file, uploadUrl, onProgress)
          -> GcsFileStorageDriver
              -> Dio PUT signed URL -> GCS
      -> IntakeService.createPetition(petition)
          -> IntakeRestService
              -> RestClient.post('/petitions')
      -> IntakeService.summarizePetition(petitionId)
          -> IntakeRestService
              -> RestClient.post('/petitions/{petition_id}/summary')
      -> signals(status, isUploading, uploadProgress, summary, generalError)
  -> renderizacao da tela
```

- **Hierarquia de widgets (se aplicavel):**

```text
AnalysisScreenView
  Scaffold
    SafeArea
      Column
        _HeaderRow
        Expanded
          SingleChildScrollView
            Column
              AiBubble(message: boas-vindas)
              hintText (waitingPetition apenas)
              PetitionFileBubble(fileName, fileSizeLabel)            [arquivo selecionado/analyzingPetition/petitionAnalyzed/failed]
              AiBubble(isTyping: true, footerText: status)           [analyzingPetition]
              PetitionSummaryCard(summary)                           [petitionAnalyzed]
              inlineError                                            [failed]
        AnalysisActionBar
          fileAction (Selecionar arquivo / Enviar outro documento)
          primaryAction (Analisar / Buscar precedentes)
              retrySummaryAction (Retry resumo)                      [petitionAnalyzed]
          helperText (Substitui o documento atual)                   [petitionAnalyzed]
```

- **Referencias:**
- `lib/ui/auth/widgets/pages/sign_in_screen/sign_in_screen_presenter.dart` — padrao de presenter com `signals`, `computed` e `Provider.autoDispose`.
- `lib/ui/auth/widgets/pages/check_email_screen/check_email_screen_presenter.dart` — padrao de `Provider.autoDispose.family` parametrizado.
- `lib/rest/services/auth_rest_service.dart` — padrao de gateway REST implementando interface do `core`.
- `lib/drivers/google-auth-driver/google_sign_in/google_sign_in_google_auth_driver.dart` — padrao de wrapper de plugin em `drivers`.
- `lib/drivers/caches/shared_preferences/shared_preferences_cache_driver.dart` — padrao de provider Riverpod na fronteira de driver.
- `design/animus.pen` — nodes `jhO0x` (estado inicial), `vp2P7` (processando) e `pw1KC` (resumo).

---

# 10. Pendencias / Decisoes Abertas

- **`ANI-44` (endpoint de `Signed URL`):** a implementacao deve seguir com a ressalva de que o ticket de backend ainda esta em aberto. O fluxo de storage deve ser construido conforme o contrato previsto, assumindo dependencia externa ainda pendente de entrega.

- **Navegacao apos `Buscar precedentes`:** permanece fora do escopo desta entrega. O CTA deve existir visualmente e manter um ponto unico de extensao, sem acoplamento a rota final ou contrato ainda nao definidos em `ANI-49`.

- **Estados visuais de upload local e `AnalysisStatusDto.failed`:** permanecem fora do escopo de validacao adicional com design. A implementacao pode reutilizar a shell prevista na spec com feedback inline e indicador de progresso Material alinhado ao tema atual.

- **Semantica de `Enviar outro documento`:** um novo envio na mesma `analysisId` deve sempre criar uma nova `Petition`. A spec nao deve assumir comportamento de replace ou idempotencia por `analysisId`.

- **Rota parametrizada e dado de teste:** a implementacao deve absorver nesta entrega a parametrizacao `/analyses/:analysisId`, usando `01KMQTN9YCHWG20ZZEPNBRYW87` como `analysisId` de teste durante o desenvolvimento local.

---

# Restricoes

- **Nao inclua testes automatizados na spec.**
- A `View` nao deve conter logica de negocio; toda a orquestracao do fluxo de upload e resumo fica no `Presenter`.
- Presenters nao fazem chamadas diretas a `RestClient`; devem consumir sempre `StorageService` e `IntakeService` do `core`.
- Todos os caminhos citados nesta spec existem no projeto ou estao marcados como **novo arquivo**.
- **Nao invente** rotas finais de precedentes, contratos de replace de petição ou endpoints alem dos documentados em `ANI-44`, `ANI-45`, `ANI-46` e `ANI-60`.
- Toda referencia a codigo existente inclui caminho relativo real em `lib/...`.
- Quando uma informacao ainda nao tem evidencia suficiente, ela foi registrada em **Pendencias / Duvidas**.
- A estrutura da tela segue `snake_case` para arquivos, `PascalCase` para classes e `index.dart` como barrel publico por widget.
