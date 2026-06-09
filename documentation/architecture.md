# Arquitetura do Projeto Animus Mobile

## Visao Geral

O Animus Mobile usa arquitetura em camadas inspirada em Clean Architecture e em Ports and Adapters. O objetivo e reduzir acoplamento, manter regras de dominio e contratos no `core`, isolar detalhes de infraestrutura em `drivers` e `rest`, e facilitar testes unitarios e de integracao.

## Principios da Arquitetura

- **Dependencias para dentro**: camadas externas dependem das internas; `core` nao depende de Flutter, HTTP, storage local ou SDKs concretos.
- **Separacao de responsabilidades**: cada camada tem um papel unico na experiencia mobile.
- **Ports and Adapters**: o `core` define interfaces; `drivers` e `rest` implementam adaptadores concretos.
- **Presenters como orquestradores da UI**: fluxos de tela passam por presenters, evitando logica espalhada nas views.
- **Inversao de Dependencias**: widgets e presenters consomem contratos do `core`, nao implementacoes concretas.
- **Views finas**: widgets observam estado, renderizam e encaminham eventos; side effects e coordenacao ficam nos presenters.
- **Infraestrutura isolada**: `dio`, `shared_preferences`, `google_sign_in`, links profundos, package info e afins ficam fora do `core`.
- **Testabilidade por design**: desacoplamento entre UI, dominio e adaptadores permite testar presenters e regras sem depender de rede ou plataforma.

## Camadas

- **UI (`lib/ui/`)**: telas, widgets, presenters, componentes visuais e fluxo de navegacao da aplicacao.
- **Core (`lib/core/`)**: DTOs, interfaces, contratos, respostas tipadas e regras de dominio independentes de framework.
- **Rest (`lib/rest/`)**: clientes HTTP, services, mapeadores e integracao com a API do servidor.
- **Drivers (`lib/drivers/`)**: adaptadores de infraestrutura e plataforma, como navegacao, cache local, Google Sign-In, deep links e versao do app.
- **Constants (`lib/constants/`)**: rotas, chaves de cache, envs e valores semanticos usados entre camadas.

## Padroes Principais

- **Clean + Ports and Adapters** para separar dominio e contratos de detalhes de implementacao.
- **MVP na UI** para separar renderizacao (`View`) de estado/handlers (`Presenter`).
- **Port and Adapter** para navegacao, cache, auth social, deep links e servicos remotos.
- **DTO + Mapper** para traducao entre payload HTTP e objetos consumidos pela UI.
- **Dependency Injection** com Riverpod para compor presenters, services e drivers.
- **Reactive State** com Signals para estado local e derivado da interface.

## Decisoes Arquiteturais

- `core` nao depende de Flutter, `dio`, `shared_preferences`, `google_sign_in` ou `go_router`.
- Views sao finas: observam estado, montam layout e delegam interacoes ao presenter.
- Presenters concentram estado reativo, validacoes, handlers e coordenacao de dependencias.
- Integracoes HTTP ficam em `rest`; contratos ficam em `core`.
- Integracoes de plataforma ficam em `drivers`; a UI consome essas capacidades por interfaces.
- Navegacao e efeitos colaterais nao devem ficar espalhados na arvore de widgets.
- Widgets internos com responsabilidade propria devem viver em pasta dedicada e ter presenter proprio quando houver logica ou estado relevante.

## Stack Tecnologica

| Tecnologia | Pacote | Finalidade |
|------------|--------|------------|
| **Framework** | Flutter | Base da aplicacao mobile |
| **Linguagem** | Dart 3.10+ | Linguagem principal |
| **Navegacao** | go_router | Roteamento e shell navigation |
| **DI / Estado global** | flutter_riverpod | Composicao de dependencias |
| **Estado local reativo** | signals_flutter | Estado derivado e reativo de presenters |
| **HTTP** | Dio | Cliente REST |
| **Formularios** | reactive_forms | Validacao e modelagem de formularios |
| **Auth social** | google_sign_in | Login com Google |
| **Env** | flutter_dotenv | Carregamento de configuracoes por ambiente |
| **Persistencia local** | shared_preferences | Cache simples no dispositivo |
| **Deep links** | app_links | Recepcao de links de redefinicao de senha |
| **Info de build** | package_info_plus | Versao do app |
| **Documentos PDF** | pdf | Montagem de relatorios exportaveis em memoria |
| **Compartilhamento de PDF** | printing | Share sheet nativo para exportacao de relatorios |
| **Compartilhamento de arquivos** | share_plus | Share sheet nativo para exportacao de DOCX e outros arquivos |
| **Testes** | flutter_test | Suite de testes |
| **Lint** | flutter_lints | Padroes de qualidade |

## Estrutura de Diretorios (essencial)

```text
lib/
├── app.dart
├── main.dart
├── router.dart
├── theme.dart
├── constants/
├── core/
├── drivers/
├── rest/
└── ui/
```

### Estrutura da camada UI

```text
lib/ui/
├── auth/
├── intake/
├── storage/
├── notification/
└── shared/
```

Cada modulo deve privilegiar a organizacao:

```text
lib/ui/{modulo}/
├── widgets/
├── components/
└── screens/
```

## Dominios Atuais do Produto

- `auth`: cadastro, login, confirmacao de e-mail, perfil, redefinicao de senha e sessao.
- `intake`: envio de peticao inicial, acompanhamento e listagem de analises recentes.
- `storage`: historico, organizacao e exportacao de analises.
- `notification`: notificacoes assincronas sobre eventos importantes do produto.

## Fluxo Entre Camadas

O fluxo padrao da aplicacao segue esta direcao:

1. A `View` recebe interacao do usuario.
2. O `Presenter` processa o evento, valida estado e coordena dependencias.
3. O `Presenter` consome contratos do `core` implementados por `rest` e `drivers`.
4. `rest` conversa com a API do servidor e traduz respostas para DTOs.
5. `drivers` resolvem capacidades locais e de plataforma.
6. O estado reativo e atualizado e a `View` re-renderiza.

## Fluxo de Sessao Autenticada e Refresh Automatico

O fluxo de autenticacao persistida agora fica centralizado na borda REST para evitar duplicacao de responsabilidade nos services:

1. `restClientProvider` compoe `DioRestClient` com `AuthTokenInterceptor`, `CacheDriver` e `NavigationDriver`.
2. `AuthTokenInterceptor.onRequest` le `CacheKeys.accessToken` do cache local e injeta `Authorization: Bearer <token>` apenas quando houver token valido.
3. Services REST protegidos (`AuthRestService`, `IntakeRestService`, `LibraryRestService` e `StorageRestService`) deixam de validar sessao manualmente e passam a depender apenas do contrato `RestClient`.
4. Quando um endpoint protegido retorna `401`, o interceptor compara o token usado na request com o token atual do cache para evitar refresh duplicado em cenarios concorrentes.
5. Se necessario, o interceptor chama `POST /auth/refresh` por um client interno sem interceptors, persiste novos `access_token` e `refresh_token` e repete a request original.
6. Endpoints publicos de autenticacao, como `sign-in`, `sign-up`, verificacoes e reset de senha, nao participam do fluxo de refresh e preservam seus erros funcionais originais.
7. Quando o refresh falha de forma definitiva, os tokens locais sao limpos e a navegacao volta para `Routes.signIn` por meio de `NavigationDriver`, mantendo a decisao visual fora da camada REST.

## Fluxo de Precedentes na Analysis Screen

O fluxo de precedentes do modulo `intake` segue a mesma separacao arquitetural e acontece sem abrir nova rota:

1. `AnalysisPrecedentsBubblePresenter` orquestra o fluxo compartilhado de precedentes na UI: dispara a busca, faz polling do status da analise, carrega a lista final, reconstrói escolhas a partir de `isChosen`, confirma escolhas múltiplas, desfaz escolhas e recarrega a lista após inclusão manual.
2. `FirstInstanceAnalysisScreenPresenter` e `SecondInstanceFirstInstanceAnalysisScreenPresenter` consomem apenas o contrato público do bubble; a 2ª instância sincroniza `chosenPrecedents` para bloquear a geração da minuta sem precedente escolhido.
3. `IntakeService` define no `core` os contratos tipados de busca, listagem, escolha, desescolha, preview por identificador e inclusão manual de precedentes.
4. `IntakeRestService` encapsula `POST /intake/analyses/{analysisId}/precedents/search`, `GET /intake/analyses/{analysisId}/precedents`, `PATCH /intake/analyses/{analysisId}/precedents/choose`, `PATCH /intake/analyses/{analysisId}/precedents/unchoose`, `GET /precedents/identifier` e `POST /analyses/precedents`, devolvendo `RestResponse` e `ListResponse` tipados para a UI.
5. `AddPrecedentDialogPresenter` valida `court`, `kind` e `number`, consulta o precedente por identificador, exibe preview antes da confirmação e delega a persistência da inclusão manual ao `IntakeService`.
6. `CacheDriver` persiste a quantidade de precedentes configurada para reutilizacao no fluxo, e `ExternalLinkDriver` encapsula a abertura externa do Pangea sem acoplar a UI a plugins concretos.

## Fluxo de Exportacao de Relatorio na Analysis Screen

Quando a analise chega ao estado final elegivel para exportacao, o relatorio segue a mesma separacao arquitetural entre UI, Core, Rest e Drivers:

1. `AnalysisHeaderActionsView` exibe a acao `Exportar PDF` no menu do header.
2. `AnalysisScreenView` e `SecondInstanceAnalysisScreenView` apenas delegam a interacao e exibem feedback visual de loading e erro.
3. `FirstInstanceAnalysisScreenPresenter` e `SecondInstanceAnalysisScreenPresenter` orquestram o fluxo e bloqueiam tentativas concorrentes durante a exportacao.
4. `IntakeService` publica contratos tipados por tipo de analise, sem expor HTTP para a UI.
5. `IntakeRestService` encapsula os endpoints agregados por fluxo, incluindo `GET /intake/analyses/{analysis_id}/first-instance-analysis-report` e `GET /intake/analyses/{analysis_id}/second-instance-analysis-report`.
6. Os mappers REST traduzem `analysis`, `document`, `case_summary`, `precedents` e drafts tipados antes de expor dados para a UI.
7. `PdfDriver` define a capacidade de gerar e compartilhar PDFs por tipo de analise, sem expor tipos de `pdf` ou `printing` para a UI.
8. `PrintingPdfDriver` monta o documento em memoria com geradores especializados por fluxo: o relatorio de 1ª instancia destaca o precedente escolhido e o de 2ª instancia consolida resumo do caso, minuta estruturada e precedentes associados antes de delegar o share sheet nativo ao pacote `printing`.

## Fluxo de Regeracao de Minutas nas Telas de Analise

Quando o usuario precisa pedir ajustes em uma minuta ja gerada, o app mantem a mesma separacao arquitetural entre UI, Core e REST:

1. `RegenerateDraftDialogView` coleta comentarios obrigatorios do usuario e fecha imediatamente apos a confirmacao local.
2. `CaseAssessmentAnalysisScreenPresenter` e `SecondInstanceAnalysisScreenPresenter` preservam a minuta atual em memoria, marcam localmente o status de processamento e chamam apenas os contratos tipados de `IntakeService`.
3. `IntakeService` publica os contratos `regeneratePetitionDraft` e `regenerateJudgmentDraft`, sem expor endpoint ou payload para a UI.
4. `IntakeRestService` encapsula `POST /intake/analyses/{analysisId}/petition-drafts/regenerate` e `POST /intake/analyses/{analysisId}/judgment-drafts/regenerate`, montando o payload `{ comments }` na borda REST.
5. O polling existente de `getAnalysis` continua com intervalo de 3 segundos; ao chegar em `DONE`, os presenters recarregam obrigatoriamente `getPetitionDraft` ou `getSecondInstanceJudgmentDraft` para substituir a versao anterior.
6. Em `FAILED`, a minuta anterior permanece disponivel na UI e o erro continua recuperavel por novo disparo do dialog, sem persistencia local dos comentarios.

## Fluxo de Edicao Manual da Minuta de Peticao

Quando a minuta de peticao ja existe no `Case Assessment`, o app permite refinamento manual mantendo a mesma separacao arquitetural entre UI, Core e REST:

1. `CaseAssessmentAnalysisScreenView` abre `PetitionDraftDialog` com o draft atual e, ao fechar o fullscreen, aciona `reloadPetitionDraft()` para atualizar o `PetitionDraftCard` da tela.
2. `PetitionDraftDialogPresenter` concentra o `FormGroup`, o estado reativo das listas (`requests` e `precedentCitations`), a validacao inline e o autosave com debounce de 2 segundos.
3. `DynamicListFieldView` renderiza os campos repetiveis da minuta e respeita o minimo de um item por lista, enquanto `SaveStatusIndicatorView` traduz `idle`, `saving`, `saved` e `error` em feedback discreto no header.
4. `IntakeService` publica o contrato tipado `updatePetitionDraft`, sem expor endpoint, payload HTTP ou serializacao para a UI.
5. `IntakeRestService` encapsula `PUT /intake/analyses/{analysisId}/petition-drafts`, montando o payload `snake_case` na borda REST e devolvendo `PetitionDraftDto` tipado apos cada salvamento.
6. Quando o usuario tenta fechar o dialog com alteracoes invalidas, o presenter bloqueia o fechamento localmente; quando ha alteracoes validas pendentes, ele faz o flush antes de liberar a saida.

## Fluxo de Exportacao da Minuta de Peticao em DOCX

Quando a minuta da analise inicial ja foi gerada, o app permite exportar o estado atual do texto em DOCX sem misturar esse fluxo com a exportacao do relatorio em PDF:

1. `PetitionDraftDialogHeaderView` expoe a acao `Exportar minuta` no header do editor em tela cheia.
2. `PetitionDraftDialogPresenter` valida o formulario, garante o autosave pendente e bloqueia tentativas concorrentes durante a exportacao.
3. `IntakeService` publica o contrato tipado `exportPetitionDraft`, reutilizando `AnalysisDocumentDto` para manter consistencia com os demais contratos de documento do dominio.
4. `IntakeRestService` encapsula `POST /intake/analyses/{analysisId}/petition-drafts/export` e traduz a resposta com `AnalysisDocumentMapper`.
5. `FileStorageDriver` baixa o arquivo do storage remoto para um arquivo temporario local sem expor SDKs concretos para a UI.
6. `FileShareDriver` encapsula o share sheet generico via `share_plus`, permitindo compartilhar DOCX sem acoplar a UI ao fluxo de PDF do `Printing`.
7. O nome compartilhado segue o padrao `[Nome da analise] — Minuta.docx`, preservando o contexto visivel ao advogado.

## Fluxo de Briefing no Case Assessment

O fluxo de `Case Assessment` agora passa a iniciar por um briefing estruturado, mantendo a mesma separacao entre UI, Core, REST e Drivers:

1. `CaseAssessmentAnalysisScreenView` exibe a entrada conversacional (`AiBubble`), o `BriefingFormCard` e a `AnalysisActionBar` como ponto de partida da analise.
2. `BriefingFormCardPresenter` concentra validacao do `reactive_forms`, mensagens inline, carga do briefing existente e submissao do briefing tipado.
3. `SupportDocumentsSectionPresenter` isola a selecao e o upload de anexos opcionais de apoio, reutilizando `StorageService`, `DocumentPickerDriver`, `FileStorageDriver` e `IntakeService` sem devolver essa responsabilidade ao presenter da tela.
4. `CaseAssessmentAnalysisScreenPresenter` permanece enxuto e orquestrador: sincroniza o briefing submetido, dispara a sumarizacao, faz polling do status e preserva resumo, precedentes e minuta no restante do fluxo.
5. `IntakeService` publica no `core` os contratos tipados de `submitCaseAssessmentBriefing` e `getCaseAssessmentBriefing`, sem expor payload remoto para a UI.
6. `IntakeRestService` encapsula `POST /intake/analyses/{analysisId}/case-assessment-briefing` e `GET /intake/analyses/{analysisId}/case-assessment-briefing`, usando `CaseAssessmentBriefingMapper` para traduzir `snake_case` e enums do backend.
7. O briefing nao e persistido em cache local: o estado fica restrito ao formulario em memoria e ao backend, enquanto os anexos de apoio seguem o fluxo de upload remoto ja existente.

## Fluxo da Tela de Pasta da Biblioteca

A tela dedicada de pasta da biblioteca segue o mesmo fluxo MVP e mantem as operacoes de organizacao no bounded context `library`:

1. `LibraryFolderScreenView` recebe o `folderId` pela rota `Routes.libraryFolder`, observa o presenter e apenas compoe loading, erro, vazio, lista, action bar e modais.
2. `LibraryFolderScreenPresenter` centraliza metadados da pasta, paginacao, selecao multipla, erros recuperaveis, movimentacao em lote, arquivamento em lote, renomeacao e arquivamento da pasta.
3. `LibraryService` publica no `core` os contratos tipados de listagem de analises por pasta e operacoes batch, alem dos contratos de pasta ja existentes.
4. `LibraryRestService` encapsula os endpoints remotos: `GET /library/folders/{folderId}`, `GET /intake/analyses` com `folder_id`, `PATCH /intake/analyses/folder`, `PATCH /intake/analyses/archive`, `PATCH /library/folders/{folderId}` e `PATCH /library/folders/{folderId}/archive`.
5. `MoveAnalysesModalPresenter` carrega todos os destinos possiveis via paginacao de `LibraryService.listFolders`, exclui a pasta atual da lista e trata a selecao explicita com `folderId == null` como destino `Sem pasta`.
6. `FolderSettingsModalPresenter` mantem estado local de validacao e delega renomeacao ou arquivamento ao presenter da tela.
7. A navegacao para analises e o retorno para a biblioteca continuam isolados por `NavigationDriver`, sem acoplamento dos presenters ao `go_router`.

## Contrato da API

A integracao com o Animus Server e RESTful com payloads JSON. Os atributos seguem o padrao `snake_case` no transporte. O mobile converte esses payloads em DTOs tipados antes de expor dados para a UI.

## Regras Operacionais Importantes

- A UI nao deve acessar API diretamente.
- Views nao devem conter regra de negocio.
- Presenters nao devem conhecer detalhes concretos de SDKs ou transporte quando existir contrato no `core`.
- `Map<String, dynamic>` e parsing cru nao devem entrar no fluxo de renderizacao.
- Toda evolucao multi-camada deve respeitar as fronteiras entre `ui`, `core`, `rest` e `drivers`.

## API Rest

A API do Animus Server segue o padrao RESTful desenvolvido, cujo padrão de JSON sempre segue o padrao `snake_case`.
