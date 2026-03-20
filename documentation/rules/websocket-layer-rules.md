# Regras da Camada WebSocket

> Referencia principal para realtime e canais em [`lib/websocket/`](../../lib/websocket/).

# Visao Geral

## Missao da camada

- A camada WebSocket deve entregar comunicacao em tempo real sem expor protocolo, client concreto ou parsing cru para a UI.
- Deve manter o transporte realtime isolado, enquanto entrega eventos tipados alinhados aos contratos do Core.

## Responsabilidades principais

- Encapsular o client realtime, canais por dominio, traducao de envelope e pontos de composicao usados pela aplicacao.
- Receber e emitir eventos tipados para fluxos como conversa, presenca e notificacao de match.
- Garantir parse defensivo e contrato previsivel para quem consome a camada.

## Limites da camada

- Nao deve conter widgets.
- Nao deve conter regra de negocio.
- Nao deve fazer persistencia.
- Nao deve fazer chamadas REST nem gerenciar sessao fora da borda de conexao do app.

# Estrutura de Diretorios Globais

## Mapa atual da camada

```text
lib/websocket/
├── channels/
├── wsc/
├── channels.dart
└── websocket_client.dart
```

## Organizacao esperada

| Area | Deve concentrar | Observacao |
| --- | --- | --- |
| `lib/websocket/channels/` | canais e adaptadores por dominio | manter cada canal com responsabilidade propria |
| `lib/websocket/wsc/` | implementacao concreta do client de transporte | biblioteca concreta deve ficar isolada aqui |
| raiz de `lib/websocket/` | fronteira publica de composicao | providers e exposicao controlada da camada |

## Regras de organizacao e nomeacao

- Cada novo canal deve nascer como unidade propria de responsabilidade.
- Helpers de parse e suporte ao protocolo devem ficar confinados a camada.
- A nomenclatura deve refletir o dominio do evento ou do canal, nunca o detalhe cru do payload.

# Glossario arquitetural da camada

| Termo | Significado | Exemplo |
| --- | --- | --- |
| `WebSocketClient` | contrato do Core para conectar, desconectar, escutar dados e enviar payloads | client tipado da camada |
| `Channel` | adaptador de dominio que interpreta envelopes e converte payload em eventos | canais de conversa e profiling |
| `listen` | metodo que registra callbacks tipados | deve devolver `unsubscribe` |
| `emit*Event` | metodo que transforma evento interno em envelope de saida | envio de eventos por nome e payload |
| `Envelope` | carga padrao com `name` e `payload` | pode aceitar fallbacks compativeis |
| `unsubscribe` | funcao que libera a inscricao | evita listeners duplicados |

# Padroes de Projeto

## Adapter do client realtime

- A biblioteca concreta deve ser escondida atras de `WebSocketClient`.
- Nenhum tipo do pacote de socket deve vazar para fora da camada.

## Channel pattern

- Deve separar traducao por dominio, como conversa e profiling.
- Evita um dispatcher global monolitico e reduz acoplamento semantico.

## Event envelope mapping

- Deve converter mensagens recebidas em eventos tipados do Core.
- Deve fazer o caminho inverso para envios.
- O canal nao deve atuar como service remoto paralelo.

## Parse defensivo

- Evento desconhecido deve ser ignorado.
- Payload ausente deve cair em fallback seguro.
- Formatos inesperados nao devem quebrar o listener.

# Regras de Integracao com Outras Camadas

| Relacao | Permitido | Proibido |
| --- | --- | --- |
| WebSocket -> Core | contratos, DTOs, eventos, tipos e interfaces | dependencias concretas da UI |
| WebSocket -> Rest | reutilizar mappers puros quando a dependencia for apenas traducao de dados | importar services HTTP para dentro do canal |
| App/UI -> WebSocket | consumo por providers e interfaces `*Channel` | acesso ao pacote concreto de socket |

## Regras operacionais

- A camada WebSocket deve implementar contratos definidos no Core, como `WebSocketClient` e interfaces `*Channel`.
- A orquestracao de conectar, desconectar e reagir ao lifecycle do app deve continuar na composicao da aplicacao.
- A camada nao deve depender de widgets, presenters, services REST, caches, envs ou drivers para decidir estado de sessao ou fluxo de tela.

# Checklist Rapido para Novas Features na Camada

- [ ] Existe contrato correspondente no Core antes da implementacao do novo canal ou evento.
- [ ] O listener retorna `unsubscribe` e o consumidor consegue liberar a inscricao com facilidade.
- [ ] O parse do envelope cobre nomes esperados, payload opcional e eventos desconhecidos sem exception.
- [ ] O canal entrega eventos e DTOs tipados, sem espalhar `Json` cru para a UI.
- [ ] A implementacao nao puxou service REST, widget, cache ou SDK concreto para fora da borda do transporte.

## ✅ O que DEVE conter

- Client realtime adaptado ao contrato do Core.
- Canais por dominio com metodos `listen` e `emit*Event` nomeados por intencao.
- Parse defensivo de envelope e traducao para eventos e DTOs tipados.
- Providers de composicao para disponibilizar client e canais a quem consome a camada.

## ❌ O que NUNCA deve conter

- Widgets, presenters, `BuildContext`, regra de negocio ou persistencia local ou remota.
- Dependencia de services REST para interpretar ou emitir evento realtime.
- Vazamento de tipos do pacote concreto de socket para outras camadas.
- Listeners sem `unsubscribe`, parse fragil ou estado de sessao escondido dentro do canal.
