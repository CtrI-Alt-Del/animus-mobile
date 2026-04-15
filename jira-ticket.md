## Objetivo

Implementar a tela principal da biblioteca do app para substituir o placeholder atual por uma experiencia funcional de consulta das analises salvas, combinando a area `Sem pasta`, a listagem de pastas do usuario e o fluxo de criacao de nova pasta. A entrega deve seguir os nodes de design `smS6d` (`F - Biblioteca`) e `DFD2M` (`Modal - Criar Pasta`), respeitando a navegacao autenticada do app e preparando a entrada para a tela de pasta individual.

Camadas impactadas: `ui` · `core` · `rest` · `constants`

## Requisitos de Produto

PRD: `https://joaogoliveiragarcia.atlassian.net/wiki/spaces/ANM/pages/17989633/PRD+RF+04+Armazenamento+e+organiza+o+de+an+lises`

- [ ] Exibir uma tela de biblioteca aderente ao layout do node `smS6d`
- [ ] Exibir a secao `Sem pasta` com acesso claro as analises nao organizadas
- [ ] Exibir a secao `Pastas` com as pastas disponiveis da conta autenticada
- [ ] Permitir abrir a area `Sem pasta` e cada pasta listada a partir da tela principal da biblioteca
- [ ] Permitir criar nova pasta a partir da propria biblioteca usando o modal do node `DFD2M`
- [ ] Exibir estado vazio amigavel quando nao houver analises salvas nem pastas cadastradas
- [ ] Exibir feedback de erro recuperavel quando a carga da biblioteca falhar

## Requisitos Tecnicos

Camadas impactadas: `ui` · `core` · `rest` · `constants`

Fluxo - `renderizacao da tela principal da biblioteca`:

```text
1. Substituir o placeholder atual de `LibraryScreenView` pela composicao real da biblioteca.
2. Reproduzir a hierarquia visual do node `smS6d`: status bar, cabecalho com CTA, tab local, bloco `Sem pasta`, bloco `Pastas` e navegacao inferior.
3. Manter a tela dentro do shell autenticado existente, preservando a navegacao atual por aba.
4. Garantir aderencia ao limite visual mobile observado no design e ao tema atual do app.
```

Fluxo - `carregamento da biblioteca`:

```text
1. Introduzir um presenter para a `LibraryScreen` seguindo o padrao MVP adotado no projeto.
2. Carregar a lista de pastas do usuario a partir da rota `GET /library/folders`, seguindo o contrato definido no ticket ANI-65.
3. Carregar o resumo da area `Sem pasta` a partir do endpoint de analises sem `folderId`, mantendo esse bloco separado da listagem de pastas.
4. Exibir loading inicial coerente com a tela antes da renderizacao do conteudo.
5. Em falha, exibir erro recuperavel com opcao de retry sem forcar o usuario a sair da aba.
6. Em sucesso sem conteudo, exibir estado vazio claro e aderente ao RF 04.
```

Fluxo - `entrada para Sem pasta e pastas`:

```text
1. Mapear a area `Sem pasta` como entrada para as analises sem `folderId`.
2. Ao tocar em `Sem pasta`, navegar para a visualizacao correspondente das analises nao organizadas.
3. Ao tocar em uma pasta, navegar para a tela de pasta especifica usando seu identificador, que sera carregada a partir da rota `GET /library/folders/{folder_id}` definida no ANI-65.
4. Preparar a biblioteca como hub de navegacao para a tela de pasta individual prevista no escopo relacionado.
```

Fluxo - `criacao de pasta pela biblioteca`:

```text
1. Implementar a acao de criar pasta no cabecalho da biblioteca.
2. Abrir o modal seguindo o node `DFD2M`, com overlay, card central, campo de nome e acoes de cancelar/criar.
3. Validar nome da pasta no mobile antes do envio: campo obrigatorio e limite maximo coerente com o RF 04.
4. Enviar a criacao para o backend via `POST /library/folders`, seguindo o contrato definido no ANI-65.
5. Em sucesso, atualizar a lista de pastas da biblioteca sem necessidade de recarregar a aba inteira.
6. Em erro, manter o modal aberto com feedback amigavel e possibilidade de nova tentativa.
```

Fluxo - `consistencia com a organizacao de analises`:

```text
1. Reaproveitar a semantica de `folderId` ja presente no dominio mobile para distinguir pastas e `Sem pasta`.
2. Garantir que a tela principal da biblioteca seja compativel com os fluxos de tela de pasta, mover analises e arquivar analises definidos em tickets relacionados.
3. Tratar a biblioteca como a entrada principal do RF 04, separando claramente a navegacao por pastas da visualizacao das analises sem pasta.
```

Contratos esperados:

- `IntakeService.listFolders({String? cursor, int? limit}) -> RestResponse<CursorPaginationResponse<FolderDto>>` - consumir `GET /library/folders` para carregar as pastas da conta autenticada
- `IntakeService.listUnfolderedAnalyses(...) -> RestResponse<CursorPaginationResponse<AnalysisDto>>` - carregar a area `Sem pasta`
- `IntakeService.getFolder({required String folderId}) -> RestResponse<FolderDto>` - consumir `GET /library/folders/{folder_id}` para abrir a pasta selecionada
- `IntakeService.createFolder({required String name}) -> RestResponse<FolderDto>` - consumir `POST /library/folders` para criar nova pasta a partir do modal da biblioteca
- `LibraryScreenPresenter.load() -> Future<void>` - orquestrar a carga inicial da biblioteca
- `LibraryScreenPresenter.retry() -> Future<void>` - repetir a carga em caso de erro
- `LibraryScreenPresenter.openCreateFolderModal() -> void` - abrir o modal de criacao de pasta
- `LibraryScreenPresenter.createFolder(String name) -> Future<void>` - validar e persistir a nova pasta
- `NavigationDriver.goTo(route) -> void` - navegar para `Sem pasta` e para a tela de pasta individual

## Referencias na Codebase

- `lib/ui/storage/widgets/pages/library_screen/library_screen_view.dart` - placeholder atual que deve ser substituido pela tela real da biblioteca
- `lib/ui/storage/widgets/pages/library_screen/index.dart` - ponto de entrada da tela no modulo de storage
- `lib/router.dart` - configuracao atual da aba autenticada da biblioteca
- `lib/constants/routes.dart` - tabela de rotas que precisara suportar a navegacao da biblioteca para seus detalhes
- `lib/core/intake/dtos/folder_dto.dart` - DTO de pasta ja existente no dominio mobile
- `lib/core/intake/dtos/analysis_dto.dart` - DTO de analise que ja expoe `folderId` para distinguir `Sem pasta`
- `lib/core/intake/interfaces/intake_service.dart` - contrato atual de intake a ser evoluido para listagem de pastas e criacao de pasta na biblioteca
- `lib/rest/services/intake_rest_service.dart` - implementacao REST onde os endpoints da biblioteca precisarao ser integrados
- `design/animus.pen` - arquivo de design com os nodes `smS6d` e `DFD2M`
- `ANI-73` - dependencia funcional para a tela de pasta individual acessada a partir da biblioteca

## Observacoes / Dependencias

DoR - Verificar antes de iniciar o desenvolvimento:

- [ ] Vinculada a uma US no Jira no padrao correto
- [ ] Campo de requisito preenchido com URL do RF/RNF/PRD no Confluence
- [ ] Estimativa adequada ao escopo; se exceder o limite acordado, dividir a task
- [ ] Responsavel atribuido
- [ ] Criterio de conclusao definido

DoD - Verificar antes de mover para Concluido:

- [ ] Criterio de conclusao tecnica atingido e verificado
- [ ] Testes escritos ou atualizados quando aplicavel
- [ ] Code review realizado e PR aprovado
- [ ] Commits seguem o padrao adotado pelo projeto
- [ ] Nenhum erro critico ou warning relevante introduzido no build
- [ ] Documentacao atualizada quando aplicavel
