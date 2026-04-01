# Guia de Documentacao de Diretrizes do Projeto

Este arquivo e o indice principal das regras do projeto. Use-o para descobrir rapidamente qual guia consultar antes de alterar arquitetura, UI, infraestrutura, integracoes ou processos de desenvolvimento.

## Visao rapida

| Guia | Arquivo | Quando consultar |
| --- | --- | --- |
| UI | [`ui-layer-rules.md`](./ui-layer-rules.md) | telas, widgets, MVP, presenters, estado visual |
| Core | [`core-layer-rules.md`](./core-layer-rules.md) | DTOs, contratos, eventos, respostas tipadas |
| Drivers | [`drivers-layer-rules.md`](./drivers-layer-rules.md) | adaptadores de SDK, plugins e infraestrutura |
| REST | [`rest-layer-rules.md`](./rest-layer-rules.md) | services HTTP, mappers, clients remotos |
| WebSocket | [`websocket-layer-rules.md`](./websocket-layer-rules.md) | canais realtime, envelopes e listeners |
| Convencoes de codigo | [`code-conventions-rules.md`](./code-conventions-rules.md) | nomenclatura, imports, organizacao geral |
| Testes unitarios | [`widgets-testing-rules.md`](./widgets-testing-rules.md) | mocks, fakers e estrutura de testes |
| Desenvolvimento | [`developement-rules.md`](./developement-rules.md) | fluxo Git, commits, branches e versionamento |

## Como usar este indice

- Consulte primeiro a regra da camada que sera impactada pela mudanca.
- Se a alteracao atravessar mais de uma camada, leia as regras de todas as camadas envolvidas.
- Em caso de duvida sobre nomenclatura, imports e organizacao geral, complemente a leitura com [`code-conventions-rules.md`](./code-conventions-rules.md).

## Guias por contexto

### UI

**Arquivo:** [`ui-layer-rules.md`](./ui-layer-rules.md)

**Consulte quando:**

- criar ou modificar widgets Flutter
- estruturar View e Presenter no padrao MVP
- trabalhar com `signals`, `riverpod` e componentes visuais

### Core

**Arquivo:** [`core-layer-rules.md`](./core-layer-rules.md)

**Consulte quando:**

- definir DTOs, contratos, eventos e tipos compartilhados
- criar interfaces que serao implementadas por outras camadas
- validar fronteiras arquiteturais e independencia do dominio

### Drivers

**Arquivo:** [`drivers-layer-rules.md`](./drivers-layer-rules.md)

**Consulte quando:**

- adaptar bibliotecas externas ou recursos da plataforma
- implementar cache, navegacao, env, geolocalizacao, storage ou notificacoes
- isolar dependencias concretas atras de contratos do Core

### REST

**Arquivo:** [`rest-layer-rules.md`](./rest-layer-rules.md)

**Consulte quando:**

- implementar clientes HTTP e services remotos
- mapear requests e responses para DTOs do Core
- tratar autenticacao, headers, base URL e erros de integracao

### WebSocket

**Arquivo:** [`websocket-layer-rules.md`](./websocket-layer-rules.md)

**Consulte quando:**

- criar ou modificar canais WebSocket
- alterar listeners, envelopes ou ciclo de vida de conexao
- integrar eventos realtime sem parse de JSON na UI

### Convencoes de codigo

**Arquivo:** [`code-conventions-rules.md`](./code-conventions-rules.md)

**Consulte quando:**

- validar nomenclatura de variaveis, funcoes, classes e arquivos
- revisar imports, barrel files e organizacao geral
- alinhar estilo de codigo antes de abrir PR

### Testes unitarios

**Arquivo:** [`widgets-testing-rules.md`](./widgets-testing-rules.md)

**Consulte quando:**

- escrever testes para presenters, services e logica de negocio
- padronizar uso de mocks, stubs e fakers
- revisar estrutura e nome dos cenarios de teste

### Desenvolvimento

**Arquivo:** [`developement-rules.md`](./developement-rules.md)

**Consulte quando:**

- preparar commits, branches e PRs
- seguir padrao de versionamento e mensagens
- alinhar fluxo de trabalho do time
