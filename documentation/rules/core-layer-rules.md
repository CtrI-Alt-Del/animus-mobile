# Regras da Camada Core

> Referencia principal para contratos e modelos compartilhados em [`lib/core/`](../../lib/core/).

# Visao Geral

## Missao da camada

- A camada Core deve definir o vocabulario de dominio, os contratos e os modelos compartilhados pelo app.
- Deve ser a fronteira mais estavel da arquitetura: outras camadas podem depender dela, mas ela nao deve depender de implementacoes concretas da aplicacao.

## Responsabilidades principais

- Concentrar DTOs, interfaces, eventos, enums, constantes, responses tipadas e tipos utilitarios.
- Publicar contratos claros para `rest`, `drivers` e `websocket` implementarem.
- Oferecer modelos consistentes para que a UI trabalhe com tipos semanticamente corretos.

## Limites da camada

- Nao deve conter widgets.
- Nao deve conhecer detalhes de transporte HTTP ou WebSocket.
- Nao deve depender de Flutter, Riverpod, Dio, GoRouter ou SDKs externos.

# Estrutura de Diretorios Globais

## Mapa atual da camada

```text
lib/core/
├── auth/
├── conversation/
├── matching/
├── profiling/
├── shared/
└── storage/
```

## Organizacao esperada

| Area | Deve concentrar | Observacao |
| --- | --- | --- |
| `lib/core/{dominio}/dtos/` | entidades e estruturas de transferencia | manter foco em modelos do dominio |
| `lib/core/{dominio}/interfaces/` | contratos de service, driver ou channel | interfaces pequenas e orientadas por capacidade |
| `lib/core/{dominio}/events/` | eventos tipados e semanticamente claros | nome deve refletir o evento de negocio |
| `lib/core/shared/` | artefatos transversais | responses, tipos, constantes e abstracoes comuns |

## Regras de organizacao e nomeacao

- A organizacao deve privilegiar semantica de dominio antes de semantica tecnica.
- Nao se deve criar estruturas vazias ou genericas sem uso real.
- Cada pasta deve existir para sustentar um contrato ou modelo efetivamente compartilhado.

# Glossario arquitetural da camada

| Termo | Significado | Exemplo |
| --- | --- | --- |
| `Dto` | objeto de transferencia imutavel | `OwnerDto`, `HorseDto` |
| `Service` | interface de capacidade de dominio consumida pela UI | `ProfilingService` |
| `Driver` | interface de infraestrutura definida pelo Core | `NavigationDriver`, `CacheDriver` |
| `Channel` | interface de realtime | `ConversationChannel` |
| `Event` | objeto com nome e payload tipado | `MessageReceivedEvent` |
| `Response wrapper` | envelope interno de sucesso ou falha | `RestResponse`, `PaginationResponse` |

## Nomenclatura recomendada

- Arquivos devem usar `snake_case`.
- Classes devem usar `PascalCase`.
- Metodos e propriedades devem usar `camelCase`.
- DTOs devem ter campos imutaveis e nomes alinhados ao dominio do produto.

# Padroes de Projeto

## DTO imutavel

- Campos devem ser `final`.
- Construtores devem ser explicitos.
- O objeto deve existir para representar dados, nao efeitos colaterais.

## Ports and adapters

- O Core define interfaces.
- As demais camadas implementam essas portas.
- A abstracao deve nascer para estabilizar contrato, nao para enfeitar arquitetura.

## Event object

- Deve ser usado quando a semantica do dominio precisar circular por realtime ou por orquestracao tipada.
- O payload deve continuar tipado e independente do transporte.

## Response wrapper

- Deve padronizar comunicacao com servicos remotos sem propagar detalhes de transporte para a UI.
- Quando um contrato remoto evoluir, o ajuste deve acontecer na camada implementadora, preservando a API do Core quando possivel.

# Regras de Integracao com Outras Camadas

| Relacao | Permitido | Proibido |
| --- | --- | --- |
| Core -> Dart | tipos da linguagem e recursos neutros | acoplamento a framework de app |
| Rest/Drivers/WebSocket -> Core | implementacao de contratos | criar semantica paralela fora do Core |
| UI -> Core | consumo de DTOs, eventos, interfaces e constantes | depender de implementacoes concretas |

## Regras operacionais

- Todas as demais camadas podem depender do Core.
- O Core nao deve depender de `ui`, `rest`, `drivers` ou `websocket`.
- Tipos de bibliotecas externas, objetos de framework, payloads crus e modelos de transporte nao devem vazar para DTOs, eventos ou interfaces do Core.
- Quando um dado remoto exigir adaptacao, a adaptacao pertence a camada implementadora.
- A camada `lib/core` nao deve receber testes novos no projeto atual. Qualquer lacuna de cobertura deve ser registrada como diagnostico tecnico, sem abrir suites novas nessa camada.

# Checklist Rapido para Novas Features na Camada

- [ ] O novo artefato representa um conceito realmente compartilhado ou contratual do dominio.
- [ ] O nome escolhido esta alinhado com a linguagem do produto.
- [ ] DTOs estao imutaveis, interfaces estao pequenas e eventos carregam payload tipado.
- [ ] Nenhum import puxa Flutter, Riverpod, Dio, drivers concretos ou classes de UI.
- [ ] O contrato esta pronto para ser implementado fora do Core sem exigir detalhes de tecnologia.

## ✅ O que DEVE conter

- Contratos estaveis de dominio, DTOs, eventos, enums, responses e tipos compartilhados.
- Nomes orientados ao negocio e a capacidade do sistema.
- Interfaces pequenas, payloads tipados e wrappers que facilitem teste e evolucao.
- Independencia arquitetural suficiente para que outras camadas consumam o Core sem acoplamento reverso.

## ❌ O que NUNCA deve conter

- Widgets, providers, `BuildContext`, `WidgetRef`, `Dio`, `GoRouter` ou `WebSocketChannel`.
- Parse de JSON, headers HTTP, rotas remotas ou detalhes de SDKs externos.
- Interfaces gigantes, DTOs mutaveis ou contratos que misturam varias responsabilidades.
- Dependencias circulares ou imports apontando para camadas implementadoras.
