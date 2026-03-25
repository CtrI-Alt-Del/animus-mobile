# Regras da Camada REST

> Referencia principal para integracoes HTTP em [`lib/rest/`](../../lib/rest/).

# Visao Geral

## Missao da camada

- A camada REST deve implementar comunicacao HTTP com APIs externas e entregar contratos tipados para o restante do app.
- Deve manter protocolo, serializacao e tratamento tecnico de erros confinados a borda da aplicacao.

## Responsabilidades principais

- Encapsular clientes HTTP, services remotos, mappers de serializacao e pontos de composicao da camada.
- Transformar payloads remotos em DTOs, responses e tipos do Core.
- Padronizar autenticacao, headers, base URL e parse de respostas variaveis quando necessario.

## Limites da camada

- Nao deve conter widgets.
- Nao deve orquestrar fluxo de tela.
- Nao deve carregar regra de negocio de produto.
- Nao deve vazar `Dio`, `Response`, `Json` cru ou detalhes de endpoint para fora da camada.

# Estrutura de Diretorios Globais

## Mapa atual da camada

```text
lib/rest/
├── dio/
├── ibge/
├── mappers/
├── providers/
├── services/
├── rest_client.dart
└── services.dart
```

## Organizacao esperada

| Area | Deve concentrar | Observacao |
| --- | --- | --- |
| `lib/rest/services/` | implementacoes de contratos remotos por dominio | manter service orientado a contexto claro |
| `lib/rest/mappers/{dominio}/` | conversores entre payload remoto e modelos internos | mapper nao deve conter regra de negocio |
| `lib/rest/dio/` | adaptador HTTP concreto | biblioteca concreta deve ficar confinada aqui |
| `lib/rest/ibge/` | integracoes auxiliares com estrutura propria | separar client, mappers e constantes quando necessario |
| raiz de `lib/rest/` | fronteira publica de composicao | evitar instanciacao manual pela UI |

## Regras de organizacao e nomeacao

- Arquivos devem usar `snake_case`.
- Classes devem usar `PascalCase`.
- Services devem refletir o dominio remoto que implementam.
- Mappers devem ter nomes explicitos e previsiveis, como `toDto`, `toDtoList` e `toJson`.

# Glossario arquitetural da camada

| Termo | Significado | Exemplo |
| --- | --- | --- |
| `RestClient` | contrato do Core para operacoes HTTP | implementado por um adaptador concreto da camada |
| `Service` | gateway remoto que implementa uma interface do Core | `AuthService`, `ProfilingService` |
| `Mapper` | classe utilitaria que traduz payload remoto e DTO | conversores por dominio em `lib/rest/mappers/` |
| `Json` | forma intermediaria baseada em `Map<String, dynamic>` | uso interno na borda de integracao |
| `Service base` | classe ou utilitario para comportamento repetido | autenticacao, headers ou setup comum |

# Padroes de Projeto

## Adapter HTTP

- A implementacao concreta deve traduzir a biblioteca usada para o contrato `RestClient` do Core.
- `Dio` deve permanecer encapsulado na camada.

## Service implementation

- Cada service deve conectar endpoint, payload, `RestResponse` e mapper do dominio.
- O service deve continuar orientado a um contexto claro.
- Quando um arquivo comecar a carregar varios fluxos sem relacao, ele deve ser quebrado por dominio.

## Mapper estatico

- Deve transformar `Json` em DTOs e DTOs em payloads.
- Deve fazer parse defensivo e evitar efeitos colaterais.
- Nao se deve usar mapper para regra de negocio, decisao de UX ou orquestracao de fluxo.

## Classes base tecnicas

- Podem concentrar preocupacoes repetidas, como header de autenticacao ou configuracao de clients secundarios.
- Nao devem virar deposito de logica transversal sem fronteira clara.

# Regras de Integracao com Outras Camadas

| Relacao | Permitido | Proibido |
| --- | --- | --- |
| REST -> Core | implementar interfaces e devolver DTOs/responses do Core | vazar modelo de transporte para fora |
| REST -> Drivers | dependencia tecnica controlada para cache ou configuracao | acoplamento arbitrario a infraestrutura sem necessidade |
| UI -> REST | consumo por providers e contratos | acesso direto a `Dio`, endpoint ou payload cru |
| REST -> WebSocket | nenhuma dependencia para completar fluxo HTTP | misturar realtime com request/response |

## Regras operacionais

- A camada REST deve devolver DTOs, responses e tipos do proprio Core.
- Pode depender de drivers e providers de infraestrutura quando isso for necessario para composicao tecnica.
- `Dio`, `BaseOptions`, `Response`, headers, codigos de transporte e payloads `snake_case` devem permanecer encapsulados dentro da camada.
- Mappers puros desta camada so podem ser reutilizados em outras integracoes quando a dependencia continuar limitada a traducao de dados.

# Checklist Rapido para Novas Features na Camada

- [ ] Existe contrato correspondente no Core antes da implementacao do service.
- [ ] O endpoint novo retorna `RestResponse<T>` tipado.
- [ ] O payload de request e response foi mapeado por conversores dedicados.
- [ ] Headers, token, base URL e detalhes tecnicos ficaram confinados a client, service base ou provider da camada.
- [ ] A implementacao nao importou nada de UI nem misturou concerns de WebSocket.

## ✅ O que DEVE conter

- Clients HTTP adaptados para contratos internos, services remotos por dominio e mappers de serializacao.
- Conversao explicita entre `snake_case` remoto e DTOs do Core.
- Retorno tipado com `RestResponse<T>` e `PaginationResponse<T>` quando aplicavel.
- Tratamento defensivo de erro e de formatos variaveis de resposta na borda da integracao.
- Mappers de DTO com responsabilidade coesa por agregado ou caso de uso, mantendo cada `{nome}_mapper.dart` restrito ao mapeamento do proprio DTO (`toDto` e, quando necessario, `toJson` do proprio DTO).
- Montagem de payload de request diretamente no service da camada REST, com `Map<String, dynamic>` local ao metodo, quando o payload nao representa DTO compartilhado.

## ❌ O que NUNCA deve conter

- Widgets, navegacao, `BuildContext`, `WidgetRef` ou qualquer logica de apresentacao.
- Regra de negocio de produto escondida em service ou mapper.
- Vazamento de `Dio`, `Response`, `Map<String, dynamic>` cru ou nomes de campos remotos para a UI.
- Services gigantes que agregam dominios sem relacao ou mappers com side effects.
- Centralizar em mapper de DTO serializacao de requests de fluxos nao relacionados ao proprio DTO (ex.: `toSignUpJson`, `toResendVerificationEmailJson`, `toVerifyEmailJson` dentro de mapper de conta).
- Criar mapper dedicado apenas para payload de request que e usado em um unico metodo de service, em vez de montar o `Map<String, dynamic>` diretamente no proprio service.
