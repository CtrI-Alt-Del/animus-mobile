# Arquitetura do Animus Mobile

## Visao Geral

O Animus Mobile e um aplicativo Flutter para apoiar a analise de precedentes juridicos. A arquitetura segue separacao por camadas para reduzir acoplamento, facilitar testes e permitir evolucao incremental dos dominios.

Dominios de negocio do produto:

- `auth`: cadastro, login, perfil e sessao do usuario.
- `intake`: envio de peticao e analise com IA de precedentes.
- `storage`: historico, organizacao e exportacao de analises.
- `notification`: notificacoes assicronas de eventos importantes.

## Camadas

- **UI (`lib/ui/`)**: telas, widgets e fluxo de navegacao.
- **Core (`lib/core/`)**: contratos, DTOs e regras de dominio.
- **REST (`lib/rest/`)**: clientes HTTP, services e mapeadores.
- **Drivers (`lib/drivers/`)**: infraestrutura e adaptadores externos.

## Estado atual do repositorio

Este repositorio esta em fase de bootstrap. A base inicial contem:

- ponto de entrada da aplicacao (`lib/main.dart`);
- configuracao da app e tema (`lib/app.dart`, `lib/theme.dart`);
- rotas iniciais (`lib/router.dart`, `lib/constants/routes.dart`);
- primeira tela de autenticacao (`lib/ui/auth/widgets/pages/sign_up_screen/index.dart`).

As pastas `core`, `rest` e `drivers` estao previstas na arquitetura e serao expandidas conforme as proximas entregas.

## Integracoes previstas

- API backend para autenticacao e analise juridica.
- Persistencia local para configuracoes de sessao.
- Servicos de notificacao push.

A URL do backend deve ser configurada via `--dart-define` (`ANIMUS_SERVER_APP_URL`) para evitar acoplamento a ambiente local.

## Principios arquiteturais

1. UI nao acessa API diretamente.
2. Regras de dominio ficam na camada Core.
3. Drivers e REST implementam contratos definidos no Core.
4. Componentes de UI devem ser pequenos e focados em responsabilidade unica.
5. Evolucoes multi-camada devem respeitar fronteiras e nomenclatura do projeto.
