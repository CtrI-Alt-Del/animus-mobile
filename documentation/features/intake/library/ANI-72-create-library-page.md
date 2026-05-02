---
title: "[mobile] Tela de biblioteca"
prd: "../prd.md"
ticket: "ANI-72"
status: "open"
last_updated_at: "2026-04-28"
---

# 1. Objetivo

Implementar a tela principal da biblioteca do app para substituir o placeholder atual por uma experiência funcional de consulta das análises salvas, combinando a área "Sem pasta", a listagem de pastas do usuário e o fluxo de criação de nova pasta. A entrega deve respeitar a navegação autenticada do app e preparar a entrada para a tela de pasta individual, conforme o design estabelecido no node `smS6d` e no modal `DFD2M`.

---

# 2. Escopo

## 2.1 In-scope

- Implementação do layout principal da biblioteca com abas/seções para "Sem pasta" e "Pastas".
- Consumo dos endpoints de listagem de pastas (`listFolders`) e análises sem pasta (`listUnfolderedAnalyses`).
- Fluxo de criação de uma nova pasta via modal overlay (node `DFD2M`).
- Tratamento de estados visuais da tela da biblioteca (loading, error, empty).
- Navegação a partir da biblioteca para visualização de análises "Sem pasta" e para uma pasta específica.

## 2.2 Out-of-scope

- Visualização do conteúdo interno de uma pasta (será tratado na task da tela da pasta individual - ANI-73).
- Funcionalidades de mover análises para outras pastas.
- Exclusão ou renomeação de pastas.
- Busca/filtragem por texto de análises e pastas.

---

# 3. Requisitos

## 3.1 Funcionais

- Exibir a seção "Sem pasta" para acesso às análises não organizadas.
- Exibir a seção "Pastas" com as pastas disponíveis da conta autenticada.
- Permitir abrir a área "Sem pasta" e cada pasta listada a partir da tela principal.
- Permitir criar nova pasta a partir da biblioteca usando um modal.
- Exibir estado vazio amigável quando não houver análises salvas nem pastas cadastradas.
- Exibir feedback de erro recuperável (retry) quando a carga da biblioteca falhar.

## 3.2 Não funcionais

- **Performance:** Manter tempo de carregamento com navegação suave, preferencialmente carregando pastas e análises sem pasta em paralelo ou via paginação apropriada.
- **Acessibilidade:** Garantir semântica correta nos botões de pastas e modais, permitindo leitura por leitores de tela e contraste adequado de acordo com o tema.

---

# 4. O que já existe?

## Camada Core (DTOs)

- **`FolderDto`** (`lib/core/library/dtos/folder_dto.dart`) — DTO de pasta existente no domínio mobile.
- **`AnalysisDto`** (`lib/core/intake/dtos/analysis_dto.dart`) — DTO de análise que já expõe `folderId`.

## Camada Core (Interfaces)

- **`LibraryService`** (`lib/core/library/interfaces/library_service.dart`) — Contrato com métodos `listFolders`, `listUnfolderedAnalyses` e `createFolder` que serão utilizados.

## Camada UI (Views & Rotas)

- **`LibraryScreenView`** (`lib/ui/storage/widgets/pages/library_screen/library_screen_view.dart`) — Atual placeholder da biblioteca que será refatorado.
- **`Routes`** (`lib/constants/routes.dart`) — Tabela de rotas para suportar a navegação.
- **Router Configuration** (`lib/router.dart`) — Configuração da aba autenticada da biblioteca.

---

# 5. O que deve ser criado?

## Camada REST (Services)

- **Localização:** `lib/rest/services/library_rest_service.dart` (**novo arquivo**)
- **Interface implementada:** `LibraryService` (de `lib/core/library/interfaces/library_service.dart`)
- **Dependências:** `RestClient` injetado via construtor.
- **Métodos:**
  - `Future<RestResponse<CursorPaginationResponse<FolderDto>>> listFolders({String? cursor, required int limit})` — Faz o GET em `/library/folders`.
  - `Future<RestResponse<CursorPaginationResponse<AnalysisDto>>> listUnfolderedAnalyses({String? cursor, required int limit})` — Faz o GET em `/library/unfoldered-analyses` (ou rota similar mapeada no back-end para carregar análises sem pasta).
  - `Future<RestResponse<FolderDto>> createFolder({required String name})` — Faz POST em `/library/folders`.

## Camada UI (Presenters)

- **Localização:** `lib/ui/storage/widgets/pages/library_screen/library_screen_presenter.dart` (**novo arquivo**)
- **Dependências injetadas:** `LibraryService` (via provider).
- **Estado (`signals`):**
  - `signal<bool> isLoading = signal(true)`
  - `signal<bool> hasError = signal(false)`
  - `signal<List<FolderDto>> folders = signal([])`
  - `signal<int> unfolderedCount = signal(0)` (Opcional caso a API retorne count, ou extraído do retorno de `listUnfolderedAnalyses`).
- **Provider Riverpod:** `final libraryScreenPresenterProvider = Provider.autoDispose<LibraryScreenPresenter>(...);`
- **Métodos:**
  - `Future<void> load()` — Executa `listFolders` e `listUnfolderedAnalyses` em paralelo. Atualiza estado ou exibe erro.
  - `Future<void> retry()` — Limpa estado de erro e re-chama `load()`.
  - `Future<void> createFolder(String name)` — Chama `LibraryService.createFolder`, e ao obter sucesso adiciona a nova pasta à lista em `folders` e fecha o modal. Em erro, emite alerta ou erro inline.
  - `void openFolder(String folderId)` — Usa `NavigationDriver` ou similar para navegar à rota da pasta.
  - `void openUnfoldered()` — Usa `NavigationDriver` ou similar para navegar à rota "Sem Pasta".

## Camada UI (Widgets Internos - Componentes)

- **Localização:** `lib/ui/storage/widgets/pages/library_screen/create_folder_modal/` (**novo arquivo**)
- **Tipo:** View + Presenter (se a validação/envio ocorrer internamente, senão apenas View que aciona o Presenter da tela).
- **Responsabilidade:** Modal overlay com campo de texto e ações Cancelar/Criar. Valida `name` não vazio.

- **Localização:** `lib/ui/storage/widgets/pages/library_screen/components/folder_list_item.dart` (**novo arquivo**)
- **Tipo:** View only
- **Props:** `FolderDto folder`, `VoidCallback onTap`.
- **Responsabilidade:** Renderiza o card ou list tile que representa uma pasta visualmente.

## Camada UI (Barrel Files)

- **Localização:** `lib/ui/storage/widgets/pages/library_screen/index.dart`
- **`typedef` exportado:** Exporta o view e presenter atualizados.

---

# 6. O que deve ser modificado?

## Camada UI (Views)

- **Arquivo:** `lib/ui/storage/widgets/pages/library_screen/library_screen_view.dart`
- **Mudança:**
  - Converter para consumir o `LibraryScreenPresenter` (via `ConsumerWidget` ou `StatelessWidget` injetando watch manual se usar `signals_flutter`).
  - Substituir o conteúdo estático placeholder pela composição baseada no node `smS6d`.
  - Implementar os blocos visuais de "Sem pasta", lista de "Pastas", header com botão de criação.
  - Renderizar estados de Loading (shimmer ou spinner), Error (mensagem e botão de tentar novamente) e Empty (ilustração amigável).
- **Justificativa:** Materializar a funcionalidade de listagem de biblioteca demandada pelo PRD RF 04.

## Rotas (`go_router`)

- **Arquivo:** `lib/constants/routes.dart` e `lib/router.dart`
- **Mudança:** Garantir rotas para navegação às telas que a biblioteca referenciará:
  - Adicionar constante para sub-rotas, como `/library/unfoldered` e `/library/folder/:id`.
- **Justificativa:** Permitir que o presenter execute navegação após clique nos itens da lista.

## Camada REST (Providers)

- **Arquivo:** (onde as dependências REST são injetadas, ex: `lib/rest/providers.dart` se houver)
- **Mudança:** Adicionar provider para `LibraryRestService` (ex: `libraryServiceProvider`).
- **Justificativa:** Permitir a injeção do service recém-criado nos Presenters.

---

# 7. O que deve ser removido?

- **Não aplicável.** Apenas o código placeholder do view existente será sobrescrito.

---

# 8. Decisões Técnicas e Trade-offs

- **Decisão:** Realizar carregamento de `listFolders` e `listUnfolderedAnalyses` em paralelo no `load()` inicial da Library.
  - **Alternativas consideradas:** Carregar em série (um após o outro) ou usar "lazy load" em tabs se o layout tivesse tabs rígidas.
  - **Motivo da escolha:** Reduz tempo de loading total inicial para a experiência do usuário. O usuário precisa de uma visão holística instantânea de "Sem pasta" e suas pastas.
  - **Impactos / trade-offs:** Dependência do sucesso em ambas as rotas. Caso uma delas falhe a tela inteira entra em erro (o que é condizente com a coesão da tela), em vez de loading parcial.
- **Decisão:** Validação e persistência da criação de pasta na responsabilidade do Presenter da página (passada ao modal via callback) ou do próprio modal.
  - **Alternativas consideradas:** Manter todo o submit no presenter da view e injetá-lo no modal.
  - **Motivo da escolha:** Mantém o domínio da tela (incluindo o refresh imediato ou append na lista visual) centralizado no presenter principal, simplificando a comunicação da UI.

---

# 9. Diagramas e Referências

**Fluxo de dados da biblioteca:**

```text
View (LibraryScreen) → Presenter (LibraryScreenPresenter)
           ↓                      ↓
      signals (load)        LibraryService (interface)
           ↓                      ↓
    CreateFolderModal      LibraryRestService
           ↓                      ↓
     Navega via router     RestClient (Dio) → API
```

**Hierarquia de widgets:**

```text
lib/ui/storage/widgets/pages/library_screen/
  index.dart
  library_screen_view.dart
  library_screen_presenter.dart
  components/
    folder_list_item.dart
  create_folder_modal/
    create_folder_modal_view.dart
```

---

# 10. Pendências / Dúvidas

- **Descrição da pendência:** Rota exata para consultar análises `Sem Pasta`.
  - **Impacto na implementação:** Precisamos do caminho da API (ex: `GET /library/analyses?folderId=null` ou rota dedicada como `/library/unfoldered-analyses`) para ser mapeada no `LibraryRestService`.
  - **Ação sugerida:** Confirmar o contrato no Swagger/Postman e atualizar `LibraryRestService` conforme a implementação real do back-end para esse endpoint em específico.

- **Descrição da pendência:** Ausência de `LibraryRestService` base.
  - **Impacto na implementação:** Foi sugerida a criação de um novo arquivo.
  - **Ação sugerida:** Validar se os métodos deveriam de fato estar num novo serviço ou se a equipe espera que seja acoplado no `IntakeRestService` (Apesar da interface já estar em `library_service.dart`, a implementação do RestService não estava lá). Pela lógica de responsabilidades e isolamento, a criação de `LibraryRestService` é a ideal.
