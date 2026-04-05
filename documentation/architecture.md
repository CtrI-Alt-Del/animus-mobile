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

## Fluxo de Precedentes na Analysis Screen

O fluxo de precedentes do modulo `intake` segue a mesma separacao arquitetural e acontece sem abrir nova rota:

1. `AnalysisScreenPresenter` carrega `analysis`, `petition` e `summary`, inclusive em reentrada nos estados de precedentes.
2. `RelevantPrecedentsBubblePresenter` orquestra o fluxo assíncrono de precedentes na UI: dispara a busca, faz polling do status da analise, carrega a lista final e confirma a escolha.
3. `IntakeService` define os contratos tipados de busca, listagem e escolha de precedentes no `core`.
4. `IntakeRestService` encapsula `POST /precedents/search`, `GET /precedents` e `PATCH /precedents/choose`, devolvendo `RestResponse` e `ListResponse` tipados para a UI.
5. `CacheDriver` persiste a quantidade de precedentes configurada para reutilizacao no fluxo.
6. `ExternalLinkDriver` encapsula a abertura externa do Pangea, evitando acoplamento da UI a plugins concretos.

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
