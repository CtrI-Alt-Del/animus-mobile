---
description: Prompt para criar uma especificação técnica detalhada com base no PRD e na arquitetura do animus.
---

# Prompt: Criar Spec

**Objetivo:** Detalhar a implementação técnica de uma feature, fix ou
refatoração no `animus`, atuando como um Tech Lead Sênior. O documento
deve servir como uma ponte estritamente definida entre o PRD e o código, com
nível de detalhe suficiente para que a implementação seja direta e sem
ambiguidades.

## Entrada

- **PRD:** deve existir e estar finalizado antes de iniciar a spec.
- **Esboço da tarefa:** descrição da feature, fix ou refatoração a implementar.
- **Acesso à codebase:** necessário para pesquisa e validação de padrões.
- **`screen_id` no Google Stitch** *(opcional):* quando houver impacto visual,
  informe o ID da tela para validação de layout e hierarquia de widgets.

> Se o PRD estiver ausente ou incompleto, não inicie a spec.
> Registre a lacuna em **Pendências / Dúvidas** e use a tool `question`.

---

## Diretrizes de Execução

### 1. Pesquisa e Contextualização

**1.1 Leitura obrigatória antes de escrever:**

- PRD associado à spec (localizado um nível acima na árvore de documentos).
- `documentation/architecture.md` — fluxo de dados, princípios e armadilhas.
- `documentation/rules/rules.md` — índice de regras; leia os docs acionados
  pelas camadas impactadas.

**1.2 Identificação de camadas impactadas**

Com base no PRD e no esboço da tarefa, classifique as camadas envolvidas:

| Camada | Localização | Responsabilidade |
|---|---|---|
| `core` | `lib/core/` | DTOs, interfaces (contratos), tipos de resposta (`RestResponse`) |
| `rest` | `lib/rest/` | Implementações HTTP, Services, Mappers (Dio + API RESTful) |
| `drivers` | `lib/drivers/` | Adaptadores de infraestrutura (env, navegação, cache, media picker, storage) |
| `ui` | `lib/ui/` | Widgets, telas e presenters (padrão MVP, Riverpod, Signals) |

Consulte as regras específicas por camada conforme o escopo:

- `documentation/rules/ui-layer-rules.md` — MVP, Material UI, Signals, Riverpod
- `documentation/rules/core-layer-rules.md` — DTOs, interfaces, tipos de resposta
- `documentation/rules/rest-layer-rules.md` — Services, Mappers, RestClient, Dio
- `documentation/rules/drivers-layer-rules.md` — adaptadores de infra externos
- `documentation/rules/code-conventions-rules.md` — nomenclatura, barrel files, organização

**1.3 Mapeamento da codebase**

Use **Serena** para localizar arquivos e implementações similares. Reporte:

- Arquivos e módulos diretamente relacionados à feature (caminhos relativos reais)
- Implementações análogas que devem servir de referência
- Contratos existentes que a feature deve respeitar (interfaces, DTOs)
- Fluxo de dados atual e onde ele precisa ser estendido ou alterado
- Pontos de atenção: acoplamentos, riscos, arquivos que serão impactados
- Lacunas: o que não foi encontrado e seria esperado

**1.4 Layout e hierarquia visual (quando aplicável)**

Se houver `screen_id` informado, use **Google Stitch** para:

- Validar a hierarquia de widgets e componentes visuais
- Identificar subwidgets que precisarão de pasta própria
- Confirmar estados visuais (loading, error, empty, content)

**1.5 Síntese e decisões**

Com base na pesquisa, tome as decisões de implementação:

- Defina o que será criado, modificado e removido — com justificativa baseada
  nas evidências coletadas
- Reutilize/estenda componentes existentes; evite duplicidade de `Presenter`,
  `Widget`, `DTO`, `Service` e `Driver`
- Mapeie o fluxo de dados principal da feature:
  `View → Presenter → Provider → Interface de Serviço → Implementação REST/Driver → RestClient → API`
- Se houver widgets internos complexos, planeje a estrutura de pastas antes de
  detalhar cada componente
- Registre em **Pendências / Dúvidas** (seção 11) tudo que não teve evidência
  suficiente para decidir

---

### 2. Uso de Ferramentas Auxiliares

- **MCP Serena:** use para localizar arquivos e implementações similares na
  codebase. Acione sempre na fase de pesquisa.
- **MCP Context7:** use quando houver dúvida sobre uso correto de uma biblioteca
  específica (ex: `signals`, `go_router`, `dio`, `riverpod`,
  `reactive_forms`). Não use para decisões de arquitetura.
- **Google Stitch:** use quando houver `screen_id` para validar layout e
  hierarquia visual antes de detalhar widgets.
- **Tool `question`:** use quando houver lacunas no PRD, incongruências com a
  codebase ou decisões críticas sem evidência suficiente. Não avance sem
  resposta quando o impacto for alto.

---

### 3. Qualidade e Densidade

- Seja direto; prefira listas e tabelas a blocos longos de texto.
- Use **negrito** para conceitos/decisões e `code` para termos técnicos
  (ex: `Riverpod`, `Signals`, `GoRouter`, `Dio`, `DTO`).
- Escreva em PT-BR; mantenha termos de programação em inglês e em `code`.
- **Nível de detalhe esperado em métodos:** descreva a assinatura Dart (nome,
  parâmetros tipados e retorno) e uma linha de responsabilidade. Não escreva
  implementação — a spec define contratos, não código.

  Exemplo: `Future<void> submit()` — valida o form, chama `AuthService.signIn`,
  persiste o token via `CacheDriver` e navega para `Routes.home`; trata erros
  de campo e exibe `generalError` em caso de falha inesperada.

---

## Estrutura do Documento (modelo obrigatório)

Use frontmatter e hierarquia de cabeçalhos sem pular níveis.

### Cabeçalho (Frontmatter)

```md
---
title: <Título claro>
prd: <caminho para o PRD referente à spec, localizado um nível acima do diretório da spec>
ticket: <link do ticket da tarefa no Jira>
status: <open|closed>
last_updated_at: <YYYY-MM-DD>
---
```

---

# 1. Objetivo (Obrigatório)

[Resumo claro em um parágrafo do que será entregue funcionalmente e tecnicamente.]

---

# 2. Escopo (Obrigatório)

## 2.1 In-scope

[Liste o que está contemplado por esta spec.]

## 2.2 Out-of-scope

[Liste explicitamente o que não será tratado nesta spec.]

---

# 3. Requisitos (Obrigatório)

## 3.1 Funcionais

[Liste os requisitos funcionais relevantes para implementação, resumidos a partir do PRD.]

## 3.2 Não funcionais

[Liste apenas requisitos técnicos verificáveis/mensuráveis, quando aplicável.]

Categorias relevantes para o mobile (usar apenas se aplicável):

- **Performance:** ex: tempo de renderização, tamanho de payload
- **Acessibilidade:** semântica, contraste, tamanho de toque
- **Offline/Conectividade:** comportamento sem rede
- **Segurança:** armazenamento de tokens, dados sensíveis em cache
- **Compatibilidade:** versão mínima de Android/iOS

> Evite requisitos vagos (ex: "ser rápido"). Prefira critérios verificáveis.

---

# 4. O que já existe? (Obrigatório)

[Liste recursos da codebase que serão utilizados ou impactados. Inclua apenas
itens realmente relevantes para implementar a mudança.]

## [Nome da Camada]

- **`NomeDaClasseOuInterface`** (`lib/camada/modulo/arquivo.dart`) — *[Breve
  descrição do uso (ex: interface a implementar, service a chamar, DTO base).]*

---

# 5. O que deve ser criado? (Depende da tarefa)

[Descreva novos componentes dividindo por camadas. Para cada arquivo novo,
detalhe e marque explicitamente como **novo arquivo**.]

> Se uma camada não se aplicar, **não inclua ela na spec**.

## Camada Core (DTOs)

- **Localização:** `lib/core/<modulo>/dtos/` (**novo arquivo** se aplicável)
- **Atributos:** propriedades com tipos Dart (`final`)
- **Factory `fromJson` (se aplicável):** assinatura e campos mapeados

## Camada Core (Interfaces / Contratos)

- **Localização:** `lib/core/<modulo>/interfaces/` (**novo arquivo** se aplicável)
- **Métodos:** assinatura Dart com tipos e uma linha de responsabilidade

## Camada REST (Services)

- **Localização:** `lib/rest/<modulo>/services/` (**novo arquivo** se aplicável)
- **Interface implementada:** port do `core`
- **Dependências:** `RestClient`, outros services ou drivers necessários
- **Métodos:** assinatura com tipos e responsabilidade; retorno como
  `RestResponse<T>` ou `Future<T>`

## Camada REST (Mappers)

- **Localização:** `lib/rest/<modulo>/mappers/` (**novo arquivo** se aplicável)
- **Métodos:**
  - `toDto(Map<String, dynamic> json) -> XxxDto` — assinatura e campos mapeados
  - `toJson(XxxDto dto) -> Map<String, dynamic>` — se aplicável

## Camada Drivers (Adaptadores)

- **Localização:** `lib/drivers/<nome>-driver/<implementacao>/` (**novo arquivo** se aplicável)
- **Interface implementada (port do `core`):** ex: `NavigationDriver`, `CacheDriver`, `MediaPickerDriver`
- **Biblioteca/pacote utilizado:** ex: `go_router`, `shared_preferences`, `image_picker`
- **Métodos:** assinatura com tipos e responsabilidade

## Camada UI (Presenters)

- **Localização:** `lib/ui/<modulo>/widgets/<pasta>/<nome>_presenter.dart` (**novo arquivo** se aplicável)
- **Dependências injetadas:** services e drivers consumidos (via Riverpod provider)
- **Estado (`signals`):**
  - Signals simples: `signal<T>` — nome e tipo
  - Signals assíncronos: `futureSignal<T>` — nome e tipo
  - Computeds: `computed<T>` — nome, tipo e lógica derivada
- **Provider Riverpod:** nome do provider e dependências injetadas
- **Métodos:** assinatura Dart e responsabilidade

## Camada UI (Views)

- **Localização:** `lib/ui/<modulo>/widgets/<pasta>/<nome>_view.dart` (**novo arquivo** se aplicável)
- **Base class:** `ConsumerWidget` | `StatelessWidget`
- **Props:** parâmetros recebidos com tipos
- **Bibliotecas de UI:** ex: `flutter_riverpod`, `signals_flutter`, `reactive_forms`
- **Estados visuais** *(quando aplicável):* Loading, Error, Empty, Content

## Camada UI (Widgets Internos)

> Para cada subwidget que exige pasta própria, detalhe separadamente.

- **Localização:** `lib/ui/<modulo>/widgets/<tela>/<componente>/` (**novo arquivo** se aplicável)
- **Tipo:** View only | View + Presenter
- **Props:** parâmetros recebidos com tipos
- **Responsabilidade:** o que renderiza ou orquestra

## Camada UI (Barrel Files / `index.dart`)

- **Localização:** `lib/ui/<modulo>/widgets/<pasta>/index.dart` (**novo arquivo** se aplicável)
- **`typedef` exportado:** ex: `typedef SignInScreen = SignInScreenView`
- **Widgets internos exportados:** lista de subwidgets encapsulados

## Camada UI (Providers Riverpod — se isolados)

- **Localização:** onde declarado (presenter ou arquivo dedicado)
- **Nome do provider:** ex: `signInScreenPresenterProvider`
- **Tipo:** `Provider`, `AutoDisposeProvider`, `ChangeNotifierProvider`, etc.
- **Dependências:** providers consumidos via `ref.watch` / `ref.read`

## Rotas (`go_router`) — se aplicável

- **Localização:** `lib/router.dart` ou arquivo de rotas do módulo
- **Caminho da rota:** ex: `/horses/:id`
- **Widget principal:** widget de tela registrado na rota
- **Guards / redirecionamentos:** lógica de proteção de rota, se houver

## Estrutura de Pastas (Obrigatório quando há widgets internos)

[Quando a feature criar widgets internos, inclua um diagrama ASCII com a
estrutura completa de pastas e arquivos.]

```text
lib/ui/<modulo>/widgets/screens/<tela>/
  index.dart
  <tela>_screen_view.dart
  <tela>_screen_presenter.dart
  <componente_interno>/
    index.dart
    <componente_interno>_view.dart
    <componente_interno>_presenter.dart  (se houver lógica)
```

---

# 6. O que deve ser modificado? (Depende da tarefa)

[Descreva alterações em código existente.]

## [Nome da Camada]

- **Arquivo:** `lib/camada/modulo/arquivo.dart`
- **Mudança:** [Descreva a mudança específica]
- **Justificativa:** [Por que a mudança é necessária]

> Se não houver alterações em código existente, escrever: **Não aplicável**.

---

# 7. O que deve ser removido? (Depende da tarefa)

[Descreva remoções de código legado, widgets obsoletos ou limpeza de
refatoração.]

## [Nome da Camada]

- **Arquivo:** `lib/camada/modulo/arquivo.dart`
- **Motivo da remoção:** [Por que pode ser removido]
- **Impacto esperado:** [Dependências que precisam ser atualizadas]

> Se não houver remoções, escrever: **Não aplicável**.

---

# 8. Decisões Técnicas e Trade-offs (Obrigatório)

[Registre decisões relevantes para revisão futura.]

Para cada decisão importante:

- **Decisão**
- **Alternativas consideradas**
- **Motivo da escolha**
- **Impactos / trade-offs**

---

# 9. Diagramas e Referências (Obrigatório)

- **Fluxo de dados:** diagrama em notação ASCII mostrando a interação entre
  camadas para o fluxo principal da feature. Ex:

```text
View → Presenter → presenterProvider → AuthService (interface)
     ↓                                      ↓
signals (isLoading, form)        AuthServiceImpl (rest)
                                       ↓
                                 RestClient (Dio) → API
```

- **Hierarquia de widgets (se aplicável):** diagrama ASCII mostrando a composição
  da tela e seus subwidgets.
- **Referências:** caminhos de arquivos similares na codebase para servir de
  exemplo de implementação.

---

# 10. Pendências / Dúvidas (Quando aplicável)

[Liste perguntas em aberto, incongruências e pontos que dependem de
confirmação.]

Para cada item:

- **Descrição da pendência**
- **Impacto na implementação**
- **Ação sugerida:** (ex: usar tool `question`, validar com produto, validar
  com design no Stitch)

> Se não houver pendências, escrever: **Sem pendências**.

---

# Restrições (Obrigatório)

- **Não inclua testes automatizados na spec.**
- A `View` não deve conter lógica de negócio — toda orquestração fica no
  `Presenter`. Se a spec violar isso, corrija antes de escrever.
- Presenters não fazem chamadas diretas a `RestClient` — consomem sempre uma
  interface de serviço do `core`.
- Todos os caminhos citados devem existir no projeto **ou** estar
  explicitamente marcados como **novo arquivo**.
- **Não invente** arquivos, métodos, contratos, DTOs ou integrações sem
  evidência no PRD ou na codebase.
- Quando faltar informação suficiente, registrar em **Pendências / Dúvidas** e
  usar a tool `question` se necessário.
- Toda referência a código existente deve incluir caminho relativo real
  (`lib/...`).
- Se uma seção não se aplicar, preencher explicitamente com **Não aplicável**.
- Toda widget com lógica ou subwidgets complexos deve ter pasta própria com
  `index.dart`, `*_view.dart` e `*_presenter.dart` (quando houver estado).
- Use componentes Flutter Material alinhados ao tema do projeto.
- A spec deve ser consistente com os padrões da codebase (nomenclatura
  `snake_case` para arquivos, `PascalCase` para classes, barrel files por
  widget).
