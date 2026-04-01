# Regras da Camada UI

> Referencia principal para a camada de apresentacao em [`lib/ui/`](../../lib/ui/).

# Visao Geral

## Missao da camada

- A camada UI deve transformar estado de aplicacao em experiencia visual coerente para o app mobile.
- Deve montar telas, componentes, sheets, modais, feedbacks visuais e fluxos de interacao com base em contratos tipados vindos das demais camadas.

## Responsabilidades principais

- Renderizar views, estados de carregamento, erro, vazio e sucesso.
- Encaminhar eventos do usuario para presenters e providers da aplicacao.
- Refletir atualizacoes de estado sem carregar regras de dominio para dentro da View.

## Limites da camada

- Nao deve conter regra de negocio.
- Nao deve fazer parse de JSON.
- Nao deve conhecer detalhes de protocolo HTTP ou WebSocket.
- Nao deve importar SDKs concretos para assumir responsabilidade de `rest`, `drivers` ou `websocket`.

# Estrutura de Diretorios Globais

## Mapa atual da camada

```text
lib/ui/
├── auth/
├── conversation/
├── matches/
├── profiling/
└── shared/
```

## Organizacao esperada

```text
lib/ui/{modulo}/
├── widgets/
├── components/
└── screens/
```

| Area | Deve concentrar | Nao deve concentrar |
| --- | --- | --- |
| `lib/ui/{modulo}/widgets/` | widgets da modulo que nao sao raiz de rota e nao pertencem a `components/` | telas raiz da modulo ou componentes compartilhados globais |
| `lib/ui/{modulo}/components/` | componentes reutilizaveis dentro da propria modulo | logica transversal da aplicacao |
| `lib/ui/{modulo}/screens/` | telas raiz, fluxos de rota e composicoes de entrada da modulo | widgets internos genericos sem papel de tela |
| `lib/ui/shared/` | tema, shells e composicoes transversais | widgets acoplados a um unico fluxo |

## Regras de organizacao e nomeacao

- Cada widget complexo deve viver em sua propria pasta.
- Cada `{modulo}` deve seguir a estrutura base com `widgets/`, `components/` e `screens/` na raiz da modulo.
- Widgets internos devem abrir subpastas dedicadas dentro do widget pai.
- Nao criar pasta intermediaria `widgets/` dentro da pasta de um widget pai; criar diretamente as pastas dos widgets internos.
- Nao se deve criar pastas genericas extras apenas para agrupar um unico widget interno.
- A pasta publica do widget pode expor um `index.dart` para reduzir imports profundos.

# Glossario arquitetural da camada

| Termo | Significado | Exemplo |
| --- | --- | --- |
| `View` | classe visual que renderiza e encaminha eventos | `sign_up_screen_view.dart` |
| `Presenter` | classe que concentra estado reativo, validacoes e handlers | `sign_up_screen_presenter.dart` |
| `Screen` | widget raiz de rota | `{modulo}_screen_view.dart` |
| `Component` | widget interno ou reutilizavel com responsabilidade propria | `match_notification_modal` |
| `Presenter Provider` | provider Riverpod que compoe dependencias do presenter | `signUpScreenPresenterProvider` |
| `Barrel publico` | `index.dart` usado como fronteira publica da pasta | `typedef SignUpScreen = SignUpScreenView;` |

## Nomenclatura recomendada

- Arquivos devem usar `snake_case`.
- Classes devem usar `PascalCase`.
- Providers, metodos e propriedades devem usar `camelCase`.
- Estados reativos devem ter nome semantico, como `isLoading`, `generalError`, `canSubmit` e `selectedHorse`.

# Padroes de Projeto

## MVP

- A View deve observar estado e renderizar.
- O Presenter deve reagir a eventos, coordenar dependencias e centralizar side effects.
- Widgets puramente visuais podem existir apenas como View quando nao houver estado nem logica relevante.

## Riverpod

- Deve ser usado para composicao de presenters, drivers, services e canais consumidos pela tela.
- A View nao deve instanciar dependencias manualmente.

## Signals

- Deve ser usado para estado local e derivado da interface.
- `Signal`, `ReadonlySignal` e `computed` devem ser priorizados quando o estado pertencer ao presenter e nao ao app inteiro.

## Componentizacao por pasta

- E obrigatoria quando o widget cresce, quando ha subpartes com responsabilidade propria ou quando ha reuso dentro da modulo.
- Se o widget passou a depender de metodos `_build...` demais, isso costuma indicar que ele deve ser quebrado em componentes menores.

## Quando evitar abstracao extra

- Nao se deve criar presenter artificial so para repassar constantes.
- Quando a abstracao nao reduzir acoplamento nem organizar estado, a implementacao deve permanecer simples.

# Regras de Integracao com Outras Camadas

| Relacao | Permitido | Proibido |
| --- | --- | --- |
| UI -> Core | DTOs, interfaces, eventos, constantes e tipos | parse cru de transporte na renderizacao |
| UI -> Rest/Drivers/WebSocket | consumo por providers e barrels publicos | uso direto de SDKs concretos para assumir responsabilidade de outra camada |
| View -> Presenter | dispatch de eventos e leitura de estado tipado | side effects espalhados pela arvore de widgets |

## Regras operacionais

- A View deve consumir apenas dados tipados.
- `Map<String, dynamic>`, payload cru e parsing de resposta nunca devem entrar no fluxo de renderizacao.
- Navegacao, inscricoes em canais, chamadas assincronas e validacoes de formulario devem ficar no Presenter ou em providers dedicados.
- Quando a View precisar de um helper vindo de driver ou provider, o uso deve continuar restrito a preocupacoes visuais.

# Checklist Rapido para Novas Modulos na Camada

- [ ] A tela ou componente novo esta em pasta propria, com fronteira clara entre publico e interno.
- [ ] O fluxo de interacao esta centralizado no Presenter, com estado observavel e handlers nomeados por intencao.
- [ ] Estados de loading, erro, vazio e sucesso foram previstos.
- [ ] A composicao de dependencias acontece via Riverpod.
- [ ] A renderizacao usa apenas modelos tipados e nao conhece detalhes de persistencia ou transporte.

## ✅ O que DEVE conter

- Views focadas em layout, binding e dispatch de eventos.
- Presenters com estado reativo, validacao de formulario, handlers de CTA e coordenacao de dependencias.
- Componentes internos organizados em subpastas quando a tela crescer ou quando houver reuso local.
- Mensagens de validacao de formulario providas pelo Presenter (a View apenas consome os mapas/formatadores).
- Uso consistente de tema, textos, feedbacks e empty states alinhados ao fluxo do produto.
- Widgets privados com responsabilidade visual propria devem ser extraidos para widgets internos em pasta propria dentro da pasta do widget pai.
- Widgets internos extraidos devem seguir o padrao de pasta com nome do proprio widget (ex.: `ai_bubble/typing_dot/`), arquivo `*_view.dart` e `index.dart` com typedef para manter a fronteira publica da pasta.

## ❌ O que NUNCA deve conter

- Regra de negocio dentro de Views.
- Parse de API ou montagem manual de payload na camada visual.
- Chamadas diretas a `Dio`, `SharedPreferences` ou `dotenv` para substituir trabalho de outras camadas.
- Widgets gigantes sustentados por dezenas de `_build...` quando a estrutura ja pede separacao.
- Widgets privados definidos no mesmo arquivo da View quando houver responsabilidade propria que possa ser isolada em widget interno com pasta dedicada.
- Criar pasta generica `widgets/` dentro de widget pai para um unico componente interno ou usar `part/part of` para contornar a organizacao por pasta; o componente deve ser promovido para pasta propria nomeada pelo widget.
