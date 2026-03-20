# Regras da Camada Drivers

> Referencia principal para adaptadores de infraestrutura em [`lib/drivers/`](../../lib/drivers/).

# Visao Geral

## Missao da camada

- A camada Drivers deve adaptar bibliotecas externas e recursos da plataforma para os contratos definidos no Core.
- Deve encapsular o contato direto com SDKs, plugins e APIs da plataforma sem levar regra de negocio para perto dessas dependencias.

## Responsabilidades principais

- Implementar contratos de cache, navegacao, env, geolocalizacao, arquivos, media, autenticacao social e notificacoes.
- Expor pontos de composicao para Riverpod na fronteira da camada.
- Normalizar falhas tecnicas e formatos de retorno para o contrato interno esperado pela aplicacao.

## Limites da camada

- Nao deve conter widgets.
- Nao deve conter logica de produto.
- Nao deve orquestrar fluxo de tela.
- Nao deve assumir trabalho de `rest` ou `websocket`.

# Estrutura de Diretorios Globais

## Mapa atual da camada

```text
lib/drivers/
├── cache-driver/
├── document-picker-driver/
├── env-driver/
├── file-storage-driver/
├── geolocation-driver/
├── google-auth-driver/
├── media-picker-driver/
├── navigation-driver/
└── push-notification-driver/
```

## Organizacao esperada

| Area | Deve concentrar | Observacao |
| --- | --- | --- |
| `lib/drivers/{driver-kebab-case}/` | capacidade de infraestrutura por responsabilidade tecnica | um driver por responsabilidade predominante |
| subpastas internas | fornecedor, plugin ou estrategia concreta | manter a dependencia externa isolada |
| fronteira publica do driver | composicao e exposicao controlada | evitar espalhar construcao manual pela aplicacao |

## Regras de organizacao e nomeacao

- Pastas de driver devem usar `kebab-case`.
- Arquivos de implementacao devem usar `snake_case`.
- Classes devem usar `PascalCase` e deixar clara a tecnologia adotada, como `GoRouterNavigationDriver`.
- O retorno publico do driver deve usar tipos do Core, tipos primitivos ou wrappers internos.

# Glossario arquitetural da camada

| Termo | Significado | Exemplo |
| --- | --- | --- |
| `Driver` | implementacao concreta de interface do Core | `SharedPreferencesCacheDriver` |
| `Adapter` | classe que traduz a API do SDK para o contrato interno | adaptador de `go_router` ou `shared_preferences` |
| `Provider de composicao` | provider Riverpod que disponibiliza o driver | provider de navegacao, cache ou env |
| `Vendor subfolder` | subpasta que revela a tecnologia concreta | pasta interna por plugin ou fornecedor |

# Padroes de Projeto

## Adapter ou wrapper

- E o padrao principal da camada.
- O driver deve traduzir chamadas, erros e retorno do SDK para o contrato do Core.

## Riverpod na fronteira

- Deve ser usado para compor e compartilhar a implementacao concreta.
- A UI nao deve precisar conhecer construtor, factory ou setup tecnico do SDK.

## Isolamento por capacidade

- Cache continua em cache.
- Navegacao continua em navegacao.
- Media continua em media.
- Se duas integracoes nao compartilham o mesmo contrato, nao devem ser espremidas na mesma pasta.

## Tratamento tecnico de erro

- Deve acontecer na borda do SDK.
- O driver pode normalizar dados tecnicos para cumprir o contrato.
- O driver nao deve tomar decisao de negocio, de produto ou de fluxo.

# Regras de Integracao com Outras Camadas

| Relacao | Permitido | Proibido |
| --- | --- | --- |
| Drivers -> Core | implementar contratos definidos em `lib/core/` | inventar contrato paralelo fora do Core |
| App/UI -> Drivers | consumir por provider ou interface | depender do SDK concreto |
| Drivers -> pacotes externos | uso tecnico necessario para adaptacao | vazamento de tipos do SDK para fora da camada |

## Regras operacionais

- Drivers podem depender de pacotes externos necessarios para cumprir o contrato.
- A composicao publica do driver pode consumir dependencias da aplicacao quando isso permanecer restrito a fronteira da camada.
- Drivers nao devem depender de widgets, presenters, services REST, canais WebSocket ou mappers HTTP para cumprir sua funcao.

# Checklist Rapido para Novas Features na Camada

- [ ] Existe um contrato correspondente no Core antes da implementacao concreta.
- [ ] A responsabilidade do driver esta clara e nao mistura capacidades sem relacao.
- [ ] O SDK externo ficou encapsulado e nenhum tipo dele vazou para fora da camada.
- [ ] O provider de composicao esta exposto na fronteira correta.
- [ ] Falhas tecnicas foram tratadas de modo previsivel.

## ✅ O que DEVE conter

- Implementacoes concretas de interfaces do Core para capacidades externas da aplicacao.
- Adaptacao de SDKs e plugins para tipos internos, com isolamento por responsabilidade.
- Providers de composicao e classes com nomes explicitos sobre a tecnologia usada.
- Tratamento tecnico de erros e normalizacao minima para cumprir o contrato interno.

## ❌ O que NUNCA deve conter

- Regra de negocio, decisao de produto ou montagem de fluxo de tela.
- Chamadas REST, parse de payload de socket ou conhecimento de rotas remotas fora do escopo do proprio driver.
- Vazamento de tipos concretos do SDK para o restante do app.
- Drivers utilitarios genericos demais, com varias responsabilidades desconexas ou sem contrato claro no Core.
